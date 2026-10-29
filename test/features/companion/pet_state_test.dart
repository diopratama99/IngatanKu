import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/domain/pet_state.dart';

void main() {
  final t0 = DateTime(2026, 10, 14, 9);

  PetState hatchedPet() => PetState.newborn(t0)
      .snack(noteId: 'n0', food: FoodKind.cookie, now: t0)
      .state;

  test('egg does not decay and hatches on its first snack', () {
    final egg = PetState.newborn(t0);
    final later = t0.add(const Duration(days: 3));
    expect(egg.stage, PetStage.egg);
    expect(egg.fullnessAt(later), egg.fullness);

    final out = egg.snack(noteId: 'a', food: FoodKind.donut, now: later);
    expect(out.result, FeedResult.ate);
    expect(out.hatched, isTrue);
    expect(out.state.stage, PetStage.baby);
    expect(out.state.ageDays(later), 1);
  });

  test('fullness decays over time and the pet gets hungry', () {
    final pet = hatchedPet();
    final start = pet.fullnessAt(t0);
    expect(pet.fullnessAt(t0.add(const Duration(hours: 5))),
        closeTo(start - 5 * PetState.fullnessDecayPerHour, 0.01));
    final dayLater = DateTime(2026, 10, 15, 14);
    expect(pet.fullnessAt(dayLater), 0);
    expect(pet.moodAt(dayLater), CompanionMood.hungry);
  });

  test('snacks fill it only so much a day', () {
    var pet = hatchedPet();
    final before = pet.fullnessAt(t0);
    for (var i = 0; i < 8; i++) {
      pet = pet.snack(noteId: 's$i', food: FoodKind.chips, now: t0).state;
    }
    // The hatching snack counted too.
    expect(pet.fullnessAt(t0) - before,
        closeTo(PetState.snackCapPerDay - PetState.snackFull, 0.01));
    // Past the limit it still eats (and grows a little), no fuller.
    final out = pet.snack(noteId: 'late', food: FoodKind.chips, now: t0);
    expect(out.result, FeedResult.ate);
    expect(out.filled, 0);
    expect(out.grew, PetState.snackGrowth);
    // A new day, a new allowance.
    final tomorrow = t0.add(const Duration(days: 1));
    expect(
        out.state
            .snack(noteId: 'next', food: FoodKind.chips, now: tomorrow)
            .filled,
        PetState.snackFull);
  });

  test('every quiz answer is a meal: right ones fill more, wrong ones count',
      () {
    final pet = hatchedPet();
    final full = pet.fullnessAt(t0);
    final right = pet.meal(key: 'quiz:q:0', correct: true, now: t0);
    final wrong = pet.meal(key: 'quiz:q:1', correct: false, now: t0);
    expect(
        right.state.fullnessAt(t0), closeTo(full + PetState.mealRight, 0.01));
    expect(
        wrong.state.fullnessAt(t0), closeTo(full + PetState.mealWrong, 0.01));
    expect(right.state.growth - pet.growth, PetState.mealRight);
    // The same answer is only eaten once.
    expect(right.state.meal(key: 'quiz:q:0', correct: true, now: t0).result,
        FeedResult.alreadyEaten);
    // The weekly feast mostly makes it grow.
    final feast =
        pet.meal(key: 'quiz:w:0', correct: true, feast: true, now: t0);
    expect(feast.state.growth - pet.growth, PetState.feastRightGrowth);
    // Quiz meals don't count as notes eaten.
    expect(right.state.notesEaten, pet.notesEaten);
  });

  test('refuses snacks when full and never eats the same note twice', () {
    var pet = hatchedPet();
    for (var i = 0; i < 4; i++) {
      pet = pet.meal(key: 'quiz:f:$i', correct: true, now: t0).state;
    }
    expect(pet.fullnessAt(t0), greaterThanOrEqualTo(PetState.refuseAbove));
    expect(pet.snack(noteId: 'c', food: FoodKind.chips, now: t0).result,
        FeedResult.full);
    expect(pet.snack(noteId: 'n0', food: FoodKind.chips, now: t0).result,
        FeedResult.alreadyEaten);
  });

  test('growth from meals moves the pet through life stages', () {
    var pet = hatchedPet();
    var now = t0;
    PetStage? evolved;
    for (var i = 0; pet.growth < PetStage.kid.minGrowth; i++) {
      now = now.add(const Duration(hours: 7));
      final out = pet.meal(key: 'quiz:g:$i', correct: true, now: now);
      evolved ??= out.evolvedTo;
      pet = out.state;
    }
    expect(pet.stage, PetStage.kid);
    expect(evolved, PetStage.kid);
  });

  test('care streak counts days with a quiz meal and resets after a gap', () {
    var pet = hatchedPet();
    final d2 = t0.add(const Duration(days: 1));
    final d3 = t0.add(const Duration(days: 2));
    pet = pet.meal(key: 'quiz:a:0', correct: true, now: t0).state;
    // Snacks don't keep it going.
    pet = pet.snack(noteId: 'x', food: FoodKind.chips, now: d2).state;
    pet = pet.meal(key: 'quiz:b:0', correct: false, now: d2).state;
    pet = pet.meal(key: 'quiz:c:0', correct: true, now: d3).state;
    expect(pet.careStreakAt(d3), 3);
    expect(pet.hadMealOn(d3), isTrue);
    expect(pet.careStreakAt(t0.add(const Duration(days: 4))), 0);
  });

  test('survives a JSON round trip', () {
    final pet = hatchedPet()
        .meal(key: 'quiz:j:0', correct: true, now: t0)
        .state
        .pet(t0)
        .play(t0);
    final copy = PetState.fromJson(pet.toJson());
    expect(copy.growth, pet.growth);
    expect(copy.eaten, pet.eaten);
    expect(copy.petCount, 1);
    expect(copy.happinessAt(t0), closeTo(pet.happinessAt(t0), 0.001));
    expect(copy.hatchedAt, pet.hatchedAt);
    expect(copy.lastMealAt, pet.lastMealAt);
    expect(copy.snackDay, pet.snackDay);
    expect(copy.snackToday, pet.snackToday);
  });
}
