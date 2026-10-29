import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/companion/data/pet_inbox.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/domain/pet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Late afternoon, so "not fed today" can show.
  final now = DateTime(2026, 10, 14, 18);

  Future<(PetStore, PetInbox)> setUpWith(PetState? pet,
      {Map<String, Object> extra = const {}}) async {
    SharedPreferences.setMockInitialValues({
      if (pet != null) 'pet.state': jsonEncode(pet.toJson()),
      ...extra,
    });
    final prefs = await SharedPreferences.getInstance();
    final store = PetStore(prefs, clock: () => now);
    return (store, PetInbox(prefs, store, clock: () => now));
  }

  test('notes hatching, growing up and a care-streak milestone', () async {
    final (store, inbox) = await setUpWith(null);
    store.snack(noteId: 'a', food: FoodKind.cookie);
    expect(inbox.notices(now).map((n) => n.kind), [PetNoticeKind.hatched]);

    final (store2, inbox2) = await setUpWith(
      PetState(
        bornAt: now.subtract(const Duration(days: 5)),
        hatchedAt: now.subtract(const Duration(days: 4)),
        fullness: 30,
        fullnessUpdatedAt: now,
        happiness: 80,
        happinessUpdatedAt: now,
        growth: PetStage.kid.minGrowth - 5,
        lastMealAt: now.subtract(const Duration(days: 1)),
        careStreak: 2,
      ),
    );
    // A quiz answer: a meal, so it grows and the streak goes on.
    store2.meal(key: 'quiz:q:0', correct: true);
    final kinds = inbox2.notices(now).map((n) => n.kind).toSet();
    expect(kinds, {PetNoticeKind.evolved, PetNoticeKind.streak});
    final evolved =
        inbox2.notices(now).firstWhere((n) => n.kind == PetNoticeKind.evolved);
    expect(evolved.stage, PetStage.kid);
    final streak =
        inbox2.notices(now).firstWhere((n) => n.kind == PetNoticeKind.streak);
    expect(streak.days, 3);
  });

  test('shows how things are now, and the bell clears once seen', () async {
    final (_, inbox) = await setUpWith(
        PetState(
          bornAt: now.subtract(const Duration(days: 5)),
          hatchedAt: now.subtract(const Duration(days: 4)),
          fullness: 10,
          fullnessUpdatedAt: now,
          happiness: 80,
          happinessUpdatedAt: now,
          lastFedAt: now.subtract(const Duration(days: 1)),
          careStreak: 4,
        ),
        extra: {'quiz.unlocked': true});
    final kinds = inbox.notices(now).map((n) => n.kind).toList();
    expect(kinds, [
      PetNoticeKind.hungry,
      PetNoticeKind.unfed,
      PetNoticeKind.quiz,
    ]);
    expect(inbox.hasUnread(now), isTrue);
    inbox.markAllSeen(now);
    expect(inbox.hasUnread(now), isFalse);

    // Finishing today's meal takes it off the list.
    inbox.markMealDone();
    expect(inbox.mealReadyAt(now), isFalse);
    expect(inbox.notices(now).map((n) => n.kind),
        isNot(contains(PetNoticeKind.quiz)));
  });

  test("today's meal waits only once the quiz is open", () async {
    final (_, inbox) = await setUpWith(PetState(
      bornAt: now.subtract(const Duration(days: 2)),
      hatchedAt: now.subtract(const Duration(days: 1)),
      fullness: 80,
      fullnessUpdatedAt: now,
      happiness: 80,
      happinessUpdatedAt: now,
    ));
    expect(inbox.mealReadyAt(now), isFalse);
    inbox.mealsUnlocked = true;
    expect(inbox.mealReadyAt(now), isTrue);
    expect(inbox.notices(now).map((n) => n.kind), contains(PetNoticeKind.quiz));
    expect(inbox.feastDoneFor(now), isFalse);
    inbox.markFeastDone();
    expect(inbox.feastDoneFor(now), isTrue);
  });
}
