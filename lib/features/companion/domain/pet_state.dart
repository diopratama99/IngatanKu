import 'dart:math' as math;

import 'companion_style.dart';

enum FeedResult { ate, full, alreadyEaten }

class FeedOutcome {
  final PetState state;
  final FeedResult result;

  /// True when this meal hatched the egg.
  final bool hatched;

  /// Set when this meal pushed the pet into a new life stage.
  final PetStage? evolvedTo;

  /// How much fuller it got (a snack past the day's limit adds nothing).
  final double filled;

  /// How much it grew.
  final int grew;

  const FeedOutcome(this.state, this.result,
      {this.hatched = false,
      this.evolvedTo,
      this.filled = 0,
      this.grew = 0});
}

/// Immutable snapshot of the virtual pet's vitals.
///
/// Fullness and happiness are stored as "value at timestamp" and decay
/// lazily on read, so nothing has to tick in the background — opening
/// the app after a day away simply finds a hungry pet.
///
/// The pet never dies; at worst it's hungry and lonely until the user
/// feeds it knowledge or gives it some attention.
///
/// Food: its real meals are the daily quiz — every answer feeds it (a
/// right one more than a wrong one), and the weekly quiz is a feast that
/// makes it grow. Each new note is a snack: a little filling, up to a
/// limit a day, so it can't live on snacks alone.
class PetState {
  final DateTime bornAt;
  final DateTime? hatchedAt;
  final double fullness;
  final DateTime fullnessUpdatedAt;
  final double happiness;
  final DateTime happinessUpdatedAt;

  /// Lifetime nutrition eaten — drives [stage].
  final int growth;

  /// What it has already eaten, newest last (capped at [maxEatenIds]):
  /// note ids (snacks) and `quiz:<id>:<n>` keys (quiz answers).
  final List<String> eaten;
  final DateTime? lastFedAt;

  /// The last quiz meal — the care streak counts days with one.
  final DateTime? lastMealAt;

  /// The day ([dayKey]) of [snackToday]: how much fullness snacks gave
  /// that day.
  final String? snackDay;
  final double snackToday;

  /// Consecutive days with a quiz meal.
  final int careStreak;
  final int petCount;
  final String? lastDigestId;

  const PetState({
    required this.bornAt,
    this.hatchedAt,
    required this.fullness,
    required this.fullnessUpdatedAt,
    required this.happiness,
    required this.happinessUpdatedAt,
    this.growth = 0,
    this.eaten = const [],
    this.lastFedAt,
    this.lastMealAt,
    this.snackDay,
    this.snackToday = 0,
    this.careStreak = 0,
    this.petCount = 0,
    this.lastDigestId,
  });

  factory PetState.newborn(DateTime now) => PetState(
        bornAt: now,
        fullness: 60,
        fullnessUpdatedAt: now,
        happiness: 70,
        happinessUpdatedAt: now,
      );

  /// One full daily meal keeps it fed into the next day.
  static const fullnessDecayPerHour = 2.8;
  static const happinessDecayPerHour = 3.0;

  /// Extra happiness loss per hour while the pet is hungry.
  static const hungryGloomPerHour = 1.5;
  static const hungryBelow = 25.0;
  static const lonelyBelow = 25.0;
  static const refuseAbove = 95.0;
  static const maxEatenIds = 600;

  // ── Food ──────────────────────────────────────────────────────────

  /// A daily-quiz answer: fullness and growth for a right answer, and for
  /// a wrong one (trying still counts).
  static const mealRight = 20;
  static const mealWrong = 8;

  /// A weekly-feast answer: less filling per question (there are many),
  /// but it makes the pet grow.
  static const feastRightFull = 8;
  static const feastWrongFull = 3;
  static const feastRightGrowth = 14;
  static const feastWrongGrowth = 5;

  /// A new note: a snack.
  static const snackFull = 7.0;
  static const snackGrowth = 4;

  /// Fullness snacks can give in a day.
  static const snackCapPerDay = 30.0;

  bool get hatched => hatchedAt != null;

  PetStage get stage => hatched ? PetStage.forGrowth(growth) : PetStage.egg;

  static double _hours(DateTime from, DateTime to) =>
      math.max(0, to.difference(from).inSeconds / 3600);

  /// The egg doesn't get hungry or bored — decay starts at hatching.
  double fullnessAt(DateTime now) => hatched
      ? (fullness - _hours(fullnessUpdatedAt, now) * fullnessDecayPerHour)
          .clamp(0.0, 100.0)
      : fullness;

  double happinessAt(DateTime now) {
    if (!hatched) return happiness;
    var rate = happinessDecayPerHour;
    if (fullnessAt(now) < hungryBelow) rate += hungryGloomPerHour;
    return (happiness - _hours(happinessUpdatedAt, now) * rate)
        .clamp(0.0, 100.0);
  }

  int careStreakAt(DateTime now) {
    final last = lastMealAt ?? lastFedAt;
    if (last == null) return 0;
    return _dayGap(last, now) <= 1 ? careStreak : 0;
  }

  /// Snacks (notes) eaten so far — quiz meals aren't counted.
  int get notesEaten => eaten.where((e) => !e.startsWith('quiz:')).length;

  /// Whether it has had a quiz meal on [now]'s day.
  bool hadMealOn(DateTime now) {
    final last = lastMealAt;
    return last != null && _dayGap(last, now) == 0;
  }

  /// The day of [d], e.g. "2026-10-15".
  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// "Day N" since hatching, 1-based; 0 while still an egg.
  int ageDays(DateTime now) => hatched ? _dayGap(hatchedAt!, now) + 1 : 0;

  static int _dayGap(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inHours ~/ 24;
  }

  CompanionMood moodAt(DateTime now) {
    if (!hatched) return CompanionMood.content;
    final h = now.hour;
    if (h >= 22 || h < 5) return CompanionMood.sleepy;
    final full = fullnessAt(now);
    final happy = happinessAt(now);
    if (full < hungryBelow) return CompanionMood.hungry;
    if (happy < lonelyBelow) return CompanionMood.lonely;
    if (full > 75 && happy > 75) return CompanionMood.happy;
    return CompanionMood.content;
  }

  bool hasEaten(String noteId) => eaten.contains(noteId);

  List<String> _eatenWith(String key) {
    final ids = [...eaten, key];
    return ids.length > maxEatenIds
        ? ids.sublist(ids.length - maxEatenIds)
        : ids;
  }

  /// A new note as a snack: a little fuller (no more than
  /// [snackCapPerDay] a day from snacks), a little growth and a little
  /// happier. Its first snack hatches the egg. Refused when it's full.
  FeedOutcome snack({
    required String noteId,
    required FoodKind food,
    required DateTime now,
  }) {
    if (hasEaten(noteId)) return FeedOutcome(this, FeedResult.alreadyEaten);
    final full = fullnessAt(now);
    if (hatched && full >= refuseAbove) {
      return FeedOutcome(this, FeedResult.full);
    }
    final before = stage;
    final day = dayKey(now);
    final had = snackDay == day ? snackToday : 0.0;
    final gain = math.max(0.0, math.min(snackFull, snackCapPerDay - had));
    final next = _copy(
      hatchedAt: hatchedAt ?? now,
      fullness: (full + gain).clamp(0.0, 100.0),
      fullnessUpdatedAt: now,
      happiness: (happinessAt(now) + 4).clamp(0.0, 100.0),
      happinessUpdatedAt: now,
      growth: growth + snackGrowth,
      eaten: _eatenWith(noteId),
      lastFedAt: now,
      snackDay: day,
      snackToday: had + gain,
      lastDigestId: noteId,
    );
    final after = next.stage;
    return FeedOutcome(
      next,
      FeedResult.ate,
      hatched: !hatched,
      evolvedTo: hatched && after != before ? after : null,
      filled: gain,
      grew: snackGrowth,
    );
  }

  /// One quiz answer as a meal ([key] identifies the answer, so it's only
  /// eaten once): a daily-quiz answer fills it up, a weekly-feast answer
  /// mostly makes it grow. A wrong answer still feeds it, less. Meals are
  /// never refused, and count towards the care streak.
  FeedOutcome meal({
    required String key,
    required bool correct,
    bool feast = false,
    required DateTime now,
  }) {
    if (hasEaten(key)) return FeedOutcome(this, FeedResult.alreadyEaten);
    final before = stage;
    final filled = feast
        ? (correct ? feastRightFull : feastWrongFull)
        : (correct ? mealRight : mealWrong);
    final grew = feast
        ? (correct ? feastRightGrowth : feastWrongGrowth)
        : (correct ? mealRight : mealWrong);
    // (Before the first quiz meal, the streak carries on from the days
    // when notes were its meals.)
    final last = lastMealAt ?? lastFedAt;
    final streak = last == null
        ? 1
        : switch (_dayGap(last, now)) {
            0 => math.max(careStreak, 1),
            1 => careStreak + 1,
            _ => 1,
          };
    final next = _copy(
      hatchedAt: hatchedAt ?? now,
      fullness: (fullnessAt(now) + filled).clamp(0.0, 100.0),
      fullnessUpdatedAt: now,
      happiness: (happinessAt(now) + (correct ? 6 : 3)).clamp(0.0, 100.0),
      happinessUpdatedAt: now,
      growth: growth + grew,
      eaten: _eatenWith(key),
      lastFedAt: now,
      lastMealAt: now,
      careStreak: streak,
    );
    final after = next.stage;
    return FeedOutcome(
      next,
      FeedResult.ate,
      hatched: !hatched,
      evolvedTo: hatched && after != before ? after : null,
      filled: filled.toDouble(),
      grew: grew,
    );
  }

  PetState pet(DateTime now) => _copy(
        happiness: (happinessAt(now) + 2).clamp(0.0, 100.0),
        happinessUpdatedAt: now,
        petCount: petCount + 1,
      );

  /// Playing cheers the pet up but burns a little energy.
  PetState play(DateTime now) => hatched
      ? _copy(
          happiness: (happinessAt(now) + 12).clamp(0.0, 100.0),
          happinessUpdatedAt: now,
          fullness: (fullnessAt(now) - 3).clamp(0.0, 100.0),
          fullnessUpdatedAt: now,
        )
      : this;

  PetState _copy({
    DateTime? hatchedAt,
    double? fullness,
    DateTime? fullnessUpdatedAt,
    double? happiness,
    DateTime? happinessUpdatedAt,
    int? growth,
    List<String>? eaten,
    DateTime? lastFedAt,
    DateTime? lastMealAt,
    String? snackDay,
    double? snackToday,
    int? careStreak,
    int? petCount,
    String? lastDigestId,
  }) =>
      PetState(
        bornAt: bornAt,
        hatchedAt: hatchedAt ?? this.hatchedAt,
        fullness: fullness ?? this.fullness,
        fullnessUpdatedAt: fullnessUpdatedAt ?? this.fullnessUpdatedAt,
        happiness: happiness ?? this.happiness,
        happinessUpdatedAt: happinessUpdatedAt ?? this.happinessUpdatedAt,
        growth: growth ?? this.growth,
        eaten: eaten ?? this.eaten,
        lastFedAt: lastFedAt ?? this.lastFedAt,
        lastMealAt: lastMealAt ?? this.lastMealAt,
        snackDay: snackDay ?? this.snackDay,
        snackToday: snackToday ?? this.snackToday,
        careStreak: careStreak ?? this.careStreak,
        petCount: petCount ?? this.petCount,
        lastDigestId: lastDigestId ?? this.lastDigestId,
      );

  Map<String, dynamic> toJson() => {
        'v': 2,
        'bornAt': bornAt.millisecondsSinceEpoch,
        'hatchedAt': hatchedAt?.millisecondsSinceEpoch,
        'fullness': fullness,
        'fullnessAt': fullnessUpdatedAt.millisecondsSinceEpoch,
        'happiness': happiness,
        'happinessAt': happinessUpdatedAt.millisecondsSinceEpoch,
        'growth': growth,
        'eaten': eaten,
        'lastFedAt': lastFedAt?.millisecondsSinceEpoch,
        'lastMealAt': lastMealAt?.millisecondsSinceEpoch,
        'snackDay': snackDay,
        'snackToday': snackToday,
        'careStreak': careStreak,
        'petCount': petCount,
        'lastDigestId': lastDigestId,
      };

  factory PetState.fromJson(Map<String, dynamic> j) {
    DateTime? ts(String k) => j[k] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((j[k] as num).toInt());
    return PetState(
      bornAt: ts('bornAt')!,
      hatchedAt: ts('hatchedAt'),
      fullness: (j['fullness'] as num).toDouble(),
      fullnessUpdatedAt: ts('fullnessAt')!,
      happiness: (j['happiness'] as num).toDouble(),
      happinessUpdatedAt: ts('happinessAt')!,
      growth: (j['growth'] as num?)?.toInt() ?? 0,
      eaten: ((j['eaten'] as List?) ?? const []).cast<String>(),
      lastFedAt: ts('lastFedAt'),
      lastMealAt: ts('lastMealAt'),
      snackDay: j['snackDay'] as String?,
      snackToday: (j['snackToday'] as num?)?.toDouble() ?? 0,
      careStreak: (j['careStreak'] as num?)?.toInt() ?? 0,
      petCount: (j['petCount'] as num?)?.toInt() ?? 0,
      lastDigestId: j['lastDigestId'] as String?,
    );
  }
}
