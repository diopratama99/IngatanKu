import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/companion_style.dart';
import '../domain/pet_state.dart';

/// Home of the virtual pet: its look (name, colour, accessory, outfit), its
/// vitals ([PetState]) and the premium things bought for it ([owned]).
///
/// Kept in SharedPreferences so the pet works offline from the first
/// frame; [PetSync] keeps it in the user's account too. Widgets listen via
/// [ChangeNotifier]; vitals decay lazily, so readers pass `DateTime.now()`
/// instead of this class ticking.
class PetStore extends ChangeNotifier {
  PetStore(this._prefs, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    final raw = _prefs.getString(_keyState);
    PetState? loaded;
    if (raw != null) {
      try {
        loaded = PetState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt blob — start over with a fresh egg rather than crash.
      }
    }
    _state = loaded ?? PetState.newborn(_clock());
  }

  static const _keyName = 'pet.name';

  /// The account last asked (on this device) to name the pet.
  static const _keyNamingAsked = 'pet.namingAskedFor';
  static const _keyColor = 'pet.color';
  static const _keyAccessory = 'pet.accessory';
  static const _keyOutfit = 'pet.outfit';
  static const _keyOwned = 'pet.owned';
  static const _keyState = 'pet.state';

  static const maxNameLength = 12;

  final SharedPreferences _prefs;
  final DateTime Function() _clock;
  late PetState _state;

  PetState get state => _state;

  // ─── look ──────────────────────────────────────────────────────────

  /// User-chosen name, or null for the localized default.
  /// Whether [user] has been asked to name the pet here — once is enough,
  /// even if they kept the default.
  bool namingAskedFor(String user) =>
      _prefs.getString(_keyNamingAsked) == user;

  void markNamingAsked(String user) =>
      _prefs.setString(_keyNamingAsked, user);

  String? get customName {
    final raw = _prefs.getString(_keyName)?.trim();
    return (raw == null || raw.isEmpty) ? null : raw;
  }

  BlobColor get color => BlobColor.fromId(_prefs.getString(_keyColor));

  /// What it has on. A premium thing that isn't (or is no longer) owned
  /// comes off.
  BlobAccessory get accessory {
    final a = BlobAccessory.fromId(_prefs.getString(_keyAccessory));
    return a.premium && !owns(a.itemId) ? BlobAccessory.sprout : a;
  }

  BlobOutfit get outfit {
    final o = BlobOutfit.fromId(_prefs.getString(_keyOutfit));
    return canWearOutfit(o) ? o : BlobOutfit.none;
  }

  /// The premium things bought for it (`BlobAccessory.itemId`,
  /// `BlobOutfit.itemId`), as the account last said; set by [PetSync].
  Set<String> get owned => {...?_prefs.getStringList(_keyOwned)};

  bool owns(String itemId) =>
      _prefs.getStringList(_keyOwned)?.contains(itemId) ?? false;

  /// A free accessory once it's grown into it; a premium one once bought.
  bool canWearAccessory(BlobAccessory a) =>
      a.premium ? owns(a.itemId) : a.unlockedAt(_state.stage);

  bool canWearOutfit(BlobOutfit o) => !o.premium || owns(o.itemId);

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_keyName);
    } else {
      await _prefs.setString(
        _keyName,
        trimmed.length > maxNameLength
            ? trimmed.substring(0, maxNameLength)
            : trimmed,
      );
    }
    notifyListeners();
  }

  Future<void> setColor(BlobColor c) async {
    await _prefs.setString(_keyColor, c.name);
    notifyListeners();
  }

  Future<void> setAccessory(BlobAccessory a) async {
    await _prefs.setString(_keyAccessory, a.name);
    notifyListeners();
  }

  Future<void> setOutfit(BlobOutfit o) async {
    // Nothing on and nothing ever worn: nothing to keep (or send — see
    // PetSnapshot.toRow).
    if (o == BlobOutfit.none && outfitId == null) return;
    await _prefs.setString(_keyOutfit, o.name);
    notifyListeners();
  }

  // ─── care ──────────────────────────────────────────────────────────

  /// A new note, as a snack (see [PetState.snack]).
  FeedOutcome snack({required String noteId, required FoodKind food}) {
    final outcome = _state.snack(noteId: noteId, food: food, now: _clock());
    if (outcome.result == FeedResult.ate) _commit(outcome.state);
    return outcome;
  }

  /// A quiz answer, as a meal (see [PetState.meal]).
  FeedOutcome meal({
    required String key,
    required bool correct,
    bool feast = false,
  }) {
    final outcome =
        _state.meal(key: key, correct: correct, feast: feast, now: _clock());
    if (outcome.result == FeedResult.ate) _commit(outcome.state);
    return outcome;
  }

  void pet() => _commit(_state.pet(_clock()));

  void play() => _commit(_state.play(_clock()));

  // ─── the account's copy (see PetSync) ─────────────────────────────

  /// The stored colour, accessory and outfit ids (null for the defaults).
  String? get colorId => _prefs.getString(_keyColor);
  String? get accessoryId => _prefs.getString(_keyAccessory);
  String? get outfitId => _prefs.getString(_keyOutfit);

  /// Takes on a copy of the pet — from the account, or a fresh egg —
  /// quietly; [announce] it once everything else is in place too.
  void restore({
    required PetState state,
    String? name,
    String? color,
    String? accessory,
    String? outfit,
  }) {
    void put(String key, String? value) =>
        value == null ? _prefs.remove(key) : _prefs.setString(key, value);
    put(_keyName, name);
    put(_keyColor, color);
    put(_keyAccessory, accessory);
    put(_keyOutfit, outfit);
    _state = state;
    _prefs.setString(_keyState, jsonEncode(state.toJson()));
  }

  /// What the account says has been bought.
  void setOwned(Set<String> items) {
    final now = owned;
    if (now.length == items.length && now.containsAll(items)) return;
    _prefs.setStringList(_keyOwned, items.toList()..sort());
    notifyListeners();
  }

  /// Lets everyone know the pet changed (after [restore]).
  void announce() => notifyListeners();

  void _commit(PetState next) {
    _state = next;
    _prefs.setString(_keyState, jsonEncode(next.toJson()));
    notifyListeners();
  }
}
