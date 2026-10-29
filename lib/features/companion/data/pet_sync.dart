import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pet_inbox.dart';
import 'pet_remote.dart';
import 'pet_store.dart';

/// Keeps the user's pet in their account ([PetRemote]), so it's the same
/// pet on every device, and an account signing in on a phone never takes
/// over the previous user's pet.
///
/// Local first: the pet lives on the device ([PetStore], [PetInbox]) and
/// works offline from the first frame. Changes go up a few seconds later
/// (and straight away when the app goes to the background); when a user
/// signs in, their pet comes down. When the device and the account both
/// have one:
///  * the device's pet belongs to another user → the account's pet (or a
///    fresh egg) takes its place;
///  * the account has none yet → the device's pet becomes theirs;
///  * the device's pet is from before pets were kept in accounts → the one
///    that has grown more wins, so no one loses their pet's progress;
///  * otherwise → the newer copy wins.
///
/// Nothing goes up until the account's copy has been fetched, so an
/// offline start can't overwrite a newer pet saved from another device.
///
/// What's been bought for the pet ([PetStore.owned]) only ever comes down:
/// with the pet, and again each time the app comes back.
class PetSync with WidgetsBindingObserver {
  PetSync(
    this._prefs,
    this._store,
    this._inbox,
    this._remote, {
    DateTime Function()? clock,
    this.debounce = const Duration(seconds: 3),
    this.retry = const Duration(seconds: 45),
  }) : _clock = clock ?? DateTime.now;

  /// Whose pet is on this device (unset: from before pets were kept in
  /// accounts), when it last changed, and whether that change still has
  /// to go up.
  static const _keyOwner = 'pet.owner';
  static const _keyUpdatedAt = 'pet.updatedAt';
  static const _keyDirty = 'pet.dirty';

  final SharedPreferences _prefs;
  final PetStore _store;
  final PetInbox _inbox;
  final PetRemote _remote;
  final DateTime Function() _clock;
  final Duration debounce;
  final Duration retry;

  StreamSubscription<String?>? _users;
  String? _user;

  /// The account's copy has been fetched for [_user]: changes may go up.
  bool _ready = false;

  /// Applying a copy: its notifications aren't changes to send.
  bool _applying = false;
  Timer? _push;
  Timer? _retry;

  bool get _dirty => _prefs.getBool(_keyDirty) ?? false;

  DateTime get _updatedAt =>
      DateTime.fromMillisecondsSinceEpoch(_prefs.getInt(_keyUpdatedAt) ?? 0);

  /// Follows [users] (the signed-in user's id, null when signed out),
  /// starting with [current].
  void start(String? current, Stream<String?> users) {
    _store.addListener(_changed);
    _inbox.addListener(_changed);
    WidgetsBinding.instance.addObserver(this);
    signedIn(current);
    _users = users.listen(signedIn);
  }

  void dispose() {
    _users?.cancel();
    _push?.cancel();
    _retry?.cancel();
    _store.removeListener(_changed);
    _inbox.removeListener(_changed);
    WidgetsBinding.instance.removeObserver(this);
  }

  /// The account's own pet has come down (or the account had none): what
  /// the device shows now is theirs.
  bool get ready => _ready;

  /// [user] signed in (or null: signed out). The device keeps the pet when
  /// someone signs out, marked as theirs; the next sign-in sorts it out.
  Future<void> signedIn(String? user) async {
    if (user == _user) return;
    await flush();
    _user = user;
    _ready = false;
    _retry?.cancel();
    if (user != null) await _pull(user);
  }

  /// Sends the pet up now if it has changes that haven't gone up yet.
  Future<void> flush() async {
    _push?.cancel();
    final user = _user;
    if (user == null || !_ready || !_dirty) return;
    try {
      await _remote.save(user, _snapshot());
      // Only clear it if nothing changed while it was on its way.
      if (!(_push?.isActive ?? false)) _prefs.setBool(_keyDirty, false);
    } catch (_) {
      // Offline or the server's down: it stays dirty and goes up with the
      // next change, or when the app comes back.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      flush();
    } else if (state == AppLifecycleState.resumed) {
      final user = _user;
      if (user != null && !_ready) {
        _pull(user);
      } else {
        if (user != null) _pullOwned(user);
        if (_dirty) _schedule();
      }
    }
  }

  void _changed() {
    if (_applying) return;
    _prefs.setInt(_keyUpdatedAt, _clock().millisecondsSinceEpoch);
    _prefs.setBool(_keyDirty, true);
    _schedule();
  }

  void _schedule() {
    if (_user == null || !_ready) return;
    _push?.cancel();
    _push = Timer(debounce, flush);
  }

  Future<void> _pull(String user) async {
    // Fetched alongside; not worth holding the pet up for.
    final owned = _ownedItems(user);
    final PetSnapshot? remote;
    try {
      remote = await _remote.load(user);
    } catch (_) {
      // Offline: keep the device's pet, and don't send anything up until
      // we've seen the account's copy.
      _retry?.cancel();
      _retry = Timer(retry, () {
        if (_user == user && !_ready) _pull(user);
      });
      return;
    }
    final items = await owned;
    if (_user != user) return;
    final owner = _prefs.getString(_keyOwner);
    final now = _clock();
    // Before the pet shows up wearing any of it. When they can't be fetched,
    // the device's list stays only if it's this account's.
    if (items != null || owner != user) _setOwned(items ?? const {});
    if (owner != null && owner != user) {
      // Someone else's pet: this account's own, or a fresh egg.
      _apply(remote ?? PetSnapshot.fresh(now));
      _own(user, changed: remote == null);
    } else if (remote == null) {
      // Nothing in the account yet: this pet becomes theirs.
      _own(user, changed: true);
    } else {
      final keepLocal = owner == null
          ? _store.state.growth > remote.state.growth
          : _dirty && _updatedAt.isAfter(remote.updatedAt);
      if (keepLocal) {
        _own(user, changed: true);
      } else {
        _apply(remote);
        _own(user, changed: false);
      }
    }
    _ready = true;
    if (_dirty) await flush();
  }

  Future<Set<String>?> _ownedItems(String user) => _remote
      .ownedItems(user)
      .then<Set<String>?>((items) => items)
      // Offline: the device's list stands for now.
      .catchError((Object _) => null);

  Future<void> _pullOwned(String user) async {
    final items = await _ownedItems(user);
    if (items != null && _user == user && _ready) _setOwned(items);
  }

  /// Not a change to the pet, nothing to send.
  void _setOwned(Set<String> items) {
    _applying = true;
    try {
      _store.setOwned(items);
    } finally {
      _applying = false;
    }
  }

  /// Marks the device's pet as [user]'s; [changed] means the account
  /// doesn't have this copy yet.
  void _own(String user, {required bool changed}) {
    _prefs.setString(_keyOwner, user);
    if (changed) {
      if (_prefs.getInt(_keyUpdatedAt) == null) {
        _prefs.setInt(_keyUpdatedAt, _clock().millisecondsSinceEpoch);
      }
      _prefs.setBool(_keyDirty, true);
    }
  }

  void _apply(PetSnapshot pet) {
    _applying = true;
    try {
      _store.restore(
        state: pet.state,
        name: pet.name,
        color: pet.color,
        accessory: pet.accessory,
        outfit: pet.outfit,
      );
      _inbox.restore(
        events: pet.events,
        seen: pet.seen,
        mealDoneOn: pet.mealDoneOn,
        feastDoneWeek: pet.feastDoneWeek,
      );
      _prefs.setInt(_keyUpdatedAt, pet.updatedAt.millisecondsSinceEpoch);
      _prefs.setBool(_keyDirty, false);
      _store.announce();
    } finally {
      _applying = false;
    }
  }

  PetSnapshot _snapshot() => PetSnapshot(
        name: _store.customName,
        color: _store.colorId,
        accessory: _store.accessoryId,
        outfit: _store.outfitId,
        state: _store.state,
        events: _inbox.eventsJson,
        seen: _inbox.seenIds,
        mealDoneOn: _inbox.mealDoneDay,
        feastDoneWeek: _inbox.feastDoneWeek,
        updatedAt: _updatedAt,
      );
}
