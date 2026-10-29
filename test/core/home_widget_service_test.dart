import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/services/home_widget_service.dart';
import 'package:ingatanku/features/companion/data/pet_inbox.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/domain/pet_state.dart';
import 'package:ingatanku/features/companion/presentation/widgets/blob_mascot.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 28, 9);
  final id = lookupAppLocalizations(const Locale('id'));

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

  PetState hatched({DateTime? lastMealAt, int careStreak = 0}) => PetState(
        bornAt: now.subtract(const Duration(days: 6)),
        hatchedAt: now.subtract(const Duration(days: 5)),
        fullness: 40,
        fullnessUpdatedAt: now,
        happiness: 70,
        happinessUpdatedAt: now,
        growth: PetStage.kid.minGrowth + 10,
        lastMealAt: lastMealAt,
        careStreak: careStreak,
      );

  test('an egg: the widget knows, in the app language, with no streak',
      () async {
    final (store, inbox) = await setUpWith(null);
    final data = petWidgetData(store, inbox, id, now);
    expect(data['pet.hatched'], '0');
    expect(data['pet.unlocked'], '0');
    expect(data['pet.t.eggBody'], 'Simpan link pertamamu supaya Bolubi menetas.');
    expect(data['pet.t.streak'], '');
    // The hatched faces are drawn as a honey baby with its sprout.
    expect(data['pet.look'], 'honey|sprout|none|baby');
  });

  test('a fed pet: its name in every line, its meal day and streak',
      () async {
    final yesterday = now.subtract(const Duration(days: 1));
    final (store, inbox) = await setUpWith(
      hatched(lastMealAt: yesterday, careStreak: 4),
      extra: {
        'pet.name': 'Mochi',
        'quiz.mealDoneOn': '2026-10-27',
        'quiz.unlocked': true,
      },
    );
    final data = petWidgetData(store, inbox, id, now);
    expect(data['pet.hatched'], '1');
    expect(data['pet.unlocked'], '1');
    expect(data['pet.mealDay'], '2026-10-27');
    expect(data['pet.streakDay'], '2026-10-27');
    expect(data['pet.t.readyTitle'], 'Mochi lapar!');
    expect(data['pet.t.lateTitle'], 'Mochi masih menunggu…');
    expect(data['pet.t.fullTitle'], 'Mochi kenyang');
    expect(data['pet.t.streak'], '4 hari beruntun');
    expect(data['pet.look'], 'honey|sprout|none|kid');
  });

  testWidgets('each face is drawn still: no ticker left running',
      (tester) async {
    final (store, _) = await setUpWith(hatched());
    for (final face in ['egg', 'hungry', 'sad', 'happy']) {
      await tester.pumpWidget(Center(
        child: SizedBox.square(dimension: 120, child: petStill(store, face)),
      ));
      final pet = tester.widget<BlobMascot>(find.byType(BlobMascot));
      expect(pet.animate, isFalse);
      expect(pet.stage, face == 'egg' ? PetStage.egg : PetStage.kid);
      expect(pet.expression, switch (face) {
        'hungry' => BlobExpression.hungry,
        'sad' => BlobExpression.sad,
        _ => null,
      });
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });
}
