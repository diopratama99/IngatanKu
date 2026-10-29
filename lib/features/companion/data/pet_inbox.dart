import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/companion_style.dart';
import '../domain/pet_state.dart';
import 'pet_store.dart';

/// What a note in the pet's inbox is about.
enum PetNoticeKind {
  /// Right now: it's hungry.
  hungry,

  /// Right now: it's lonely.
  lonely,

  /// Right now: it hasn't eaten today and its care streak is at stake.
  unfed,

  /// Right now: today's meal (the daily quiz) is waiting.
  quiz,

  /// It hatched.
  hatched,

  /// It grew into a new stage ([PetNotice.stage]).
  evolved,

  /// Its care streak reached a milestone ([PetNotice.days]).
  streak,
}

/// One note from the pet: how things are right now (hungry, quiz ready…)
/// or something that happened (it hatched, it grew).
class PetNotice {
  final String id;
  final PetNoticeKind kind;
  final DateTime at;
  final PetStage? stage;
  final int? days;

  const PetNotice(this.id, this.kind, this.at, {this.stage, this.days});

  /// About how things are now, rather than something that happened.
  bool get isCurrent => switch (kind) {
        PetNoticeKind.hungry ||
        PetNoticeKind.lonely ||
        PetNoticeKind.unfed ||
        PetNoticeKind.quiz =>
          true,
        _ => false,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'at': at.millisecondsSinceEpoch,
        if (stage != null) 'stage': stage!.name,
        if (days != null) 'days': days,
      };

  static PetNotice? fromJson(Map<String, dynamic> j) {
    final kind = PetNoticeKind.values.asNameMap()[j['kind']];
    final at = j['at'];
    if (kind == null || at is! num) return null;
    return PetNotice(
      j['id'] as String? ?? '${kind.name}:$at',
      kind,
      DateTime.fromMillisecondsSinceEpoch(at.toInt()),
      stage: PetStage.values.asNameMap()[j['stage']],
      days: (j['days'] as num?)?.toInt(),
    );
  }
}

/// The pet's inbox behind the bell on Beranda: how it's doing right now,
/// plus the moments worth keeping (hatching, growing up, care-streak
/// milestones), newest first. Kept with the pet (in the account too, see
/// PetSync).
///
/// The moments are picked up by watching [PetStore] change, so nothing
/// else has to remember to report them. Also keeps track of the pet's
/// meals: whether the daily quiz is open yet, and whether today's meal
/// and this week's feast have been had.
class PetInbox extends ChangeNotifier {
  PetInbox(this._prefs, this._store, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now {
    _last = _store.state;
    _store.addListener(_onPetChanged);
  }

  static const _keyEvents = 'pet.events';
  static const _keySeen = 'pet.inboxSeen';
  static const _keyUnlocked = 'quiz.unlocked';
  static const _keyMealDone = 'quiz.mealDoneOn';
  static const _keyFeastDone = 'quiz.feastDoneWeek';
  static const _maxEvents = 30;

  /// Care-streak days worth a note.
  static bool isMilestone(int days) =>
      const {3, 7, 14, 30, 50}.contains(days) ||
      (days >= 100 && days % 100 == 0);

  final SharedPreferences _prefs;
  final PetStore _store;
  final DateTime Function() _clock;
  late PetState _last;

  @override
  void dispose() {
    _store.removeListener(_onPetChanged);
    super.dispose();
  }

  // ─── meals: the daily quiz, and the weekly feast ─────────────────────

  /// Whether the daily quiz is open yet — it needs a few notes to ask
  /// about. Beranda keeps this up to date.
  bool get mealsUnlocked => _prefs.getBool(_keyUnlocked) ?? false;
  set mealsUnlocked(bool on) {
    if (on == mealsUnlocked) return;
    _prefs.setBool(_keyUnlocked, on);
    notifyListeners();
  }

  /// Today's quiz has been finished.
  bool mealDoneOn(DateTime now) =>
      _prefs.getString(_keyMealDone) == PetState.dayKey(now);

  void markMealDone() {
    _prefs.setString(_keyMealDone, PetState.dayKey(_clock()));
    notifyListeners();
  }

  /// Today's meal is waiting: the quiz is open, the pet has hatched and it
  /// hasn't eaten it yet.
  bool mealReadyAt(DateTime now) =>
      mealsUnlocked && _store.state.hatched && !mealDoneOn(now);

  /// This week's feast (the weekly quiz) has been finished.
  bool feastDoneFor(DateTime now) =>
      _prefs.getString(_keyFeastDone) == weekKey(now);

  void markFeastDone() {
    _prefs.setString(_keyFeastDone, weekKey(_clock()));
    notifyListeners();
  }

  /// ISO-8601 week, e.g. "2026-42" — the feast comes round each week.
  static String weekKey(DateTime d) {
    final day = DateTime.utc(d.year, d.month, d.day);
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final week =
        thursday.difference(DateTime.utc(thursday.year)).inDays ~/ 7 + 1;
    return '${thursday.year}-$week';
  }

  // ─── the account's copy (see PetSync) ─────────────────────────────

  List<Map<String, dynamic>> get eventsJson =>
      [for (final e in _events()) e.toJson()];
  List<String> get seenIds => _prefs.getStringList(_keySeen) ?? const [];
  String? get mealDoneDay => _prefs.getString(_keyMealDone);
  String? get feastDoneWeek => _prefs.getString(_keyFeastDone);

  /// Takes on the news and meals from a copy of the pet, quietly. Call
  /// after [PetStore.restore] and before [PetStore.announce], so the
  /// pet's new state isn't mistaken for it hatching or growing up here.
  void restore({
    List<Map<String, dynamic>> events = const [],
    List<String> seen = const [],
    String? mealDoneOn,
    String? feastDoneWeek,
  }) {
    _prefs.setString(_keyEvents, jsonEncode(events));
    _prefs.setStringList(_keySeen, seen);
    mealDoneOn == null
        ? _prefs.remove(_keyMealDone)
        : _prefs.setString(_keyMealDone, mealDoneOn);
    feastDoneWeek == null
        ? _prefs.remove(_keyFeastDone)
        : _prefs.setString(_keyFeastDone, feastDoneWeek);
    _last = _store.state;
  }

  // ─── notes ──────────────────────────────────────────────────────────

  /// Everything in the inbox at [now]: how things are, then what happened,
  /// newest first.
  List<PetNotice> notices(DateTime now) => [..._current(now), ..._events()];

  /// Anything not seen yet (the bell's red dot).
  bool hasUnread(DateTime now) {
    final seen = _seen();
    return notices(now).any((n) => !seen.contains(n.id));
  }

  /// Ids of the notes not seen yet.
  Set<String> unreadIds(DateTime now) {
    final seen = _seen();
    return {
      for (final n in notices(now))
        if (!seen.contains(n.id)) n.id,
    };
  }

  /// The inbox was opened: everything in it counts as seen.
  void markAllSeen(DateTime now) {
    final ids = [..._seen(), ...notices(now).map((n) => n.id)];
    final unique = ids.toSet().toList();
    _prefs.setStringList(
        _keySeen, unique.sublist(unique.length > 80 ? unique.length - 80 : 0));
    notifyListeners();
  }

  List<PetNotice> _current(DateTime now) {
    final pet = _store.state;
    final today = _day(now);
    return [
      if (pet.hatched && pet.fullnessAt(now) < PetState.hungryBelow)
        PetNotice('hungry@$today', PetNoticeKind.hungry, now)
      else if (pet.hatched && pet.happinessAt(now) < PetState.lonelyBelow)
        PetNotice('lonely@$today', PetNoticeKind.lonely, now),
      // From late afternoon, if a streak is going and today's meal hasn't
      // been had.
      if (pet.hatched &&
          now.hour >= 17 &&
          pet.careStreakAt(now) > 0 &&
          !pet.hadMealOn(now))
        PetNotice('unfed@$today', PetNoticeKind.unfed, now,
            days: pet.careStreakAt(now)),
      if (mealReadyAt(now))
        PetNotice('meal@$today', PetNoticeKind.quiz, now),
    ];
  }

  List<PetNotice> _events() {
    final raw = _prefs.getString(_keyEvents);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(PetNotice.fromJson)
          .whereType<PetNotice>()
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));
      return list;
    } catch (_) {
      return const [];
    }
  }

  Set<String> _seen() => (_prefs.getStringList(_keySeen) ?? const []).toSet();

  /// Notes the moments worth keeping as the pet changes.
  void _onPetChanged() {
    final before = _last;
    final now = _store.state;
    _last = now;
    final at = _clock();
    if (!before.hatched && now.hatched) {
      _record(PetNotice('hatched', PetNoticeKind.hatched, at));
    }
    if (before.hatched && now.stage.index > before.stage.index) {
      _record(PetNotice('evolved:${now.stage.name}', PetNoticeKind.evolved, at,
          stage: now.stage));
    }
    if (now.careStreak != before.careStreak && isMilestone(now.careStreak)) {
      _record(PetNotice(
          'streak:${now.careStreak}@${_day(at)}', PetNoticeKind.streak, at,
          days: now.careStreak));
    }
    notifyListeners();
  }

  void _record(PetNotice n) {
    final events = _events().where((e) => e.id != n.id).toList()..insert(0, n);
    _prefs.setString(
      _keyEvents,
      jsonEncode(events.take(_maxEvents).map((e) => e.toJson()).toList()),
    );
  }

  static String _day(DateTime d) => '${d.year}-${d.month}-${d.day}';
}
