import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/di/injection_container.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/features/companion/data/pet_remote.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/domain/pet_state.dart';
import 'package:ingatanku/features/companion/presentation/pages/pet_shop_page.dart';
import 'package:ingatanku/features/companion/presentation/widgets/pet_wardrobe_sheet.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('the catalogue', () {
    test('free things open as it grows; premium ones are bought', () {
      expect(BlobAccessory.beanie.unlockedAt(PetStage.teen), isTrue);
      expect(BlobAccessory.crown.unlockedAt(PetStage.teen), isFalse);
      expect(BlobAccessory.chefHat.unlockedAt(PetStage.sage), isFalse);
      expect(BlobOutfit.values.where((o) => !o.premium), [BlobOutfit.none]);
      // Their ids, as the server takes them (see 20261020_pet_items.sql).
      expect(BlobAccessory.chefHat.itemId, 'accessory.chefHat');
      expect(BlobOutfit.dino.itemId, 'outfit.dino');
      final id = RegExp(r'^(accessory|outfit)\.[A-Za-z]+$');
      for (final a in BlobAccessory.values) {
        expect(id.hasMatch(a.itemId), isTrue, reason: a.itemId);
      }
      for (final o in BlobOutfit.values) {
        expect(id.hasMatch(o.itemId), isTrue, reason: o.itemId);
      }
    });

    test('premium things are worn once owned, and come off if not', () async {
      SharedPreferences.setMockInitialValues({
        'pet.accessory': 'chefHat',
        'pet.outfit': 'dino',
      });
      final store = PetStore(await SharedPreferences.getInstance());
      expect(store.accessory, BlobAccessory.sprout);
      expect(store.outfit, BlobOutfit.none);
      expect(store.canWearAccessory(BlobAccessory.chefHat), isFalse);
      store.setOwned({'accessory.chefHat', 'outfit.dino'});
      expect(store.accessory, BlobAccessory.chefHat);
      expect(store.outfit, BlobOutfit.dino);
      expect(store.canWearAccessory(BlobAccessory.crown), isFalse); // an egg
    });

    test('unknown ids fall back to the defaults', () {
      expect(BlobOutfit.fromId(null), BlobOutfit.none);
      expect(BlobOutfit.fromId('tuxedo'), BlobOutfit.none);
      expect(BlobOutfit.fromId('dino'), BlobOutfit.dino);
    });

    test('the outfit goes to the account only once one is chosen', () {
      final now = DateTime(2026, 10, 20);
      final bare = PetSnapshot(state: PetState.newborn(now), updatedAt: now);
      expect(bare.toRow('ana'), isNot(contains('outfit')));
      final dressed = PetSnapshot(
          state: PetState.newborn(now), updatedAt: now, outfit: 'none');
      expect(dressed.toRow('ana')['outfit'], 'none');
    });
  });

  Future<PetStore> setUpPet(WidgetTester tester,
      {Set<String> owned = const {}}) async {
    final now = DateTime.now();
    final pet = PetState(
      bornAt: now.subtract(const Duration(days: 20)),
      hatchedAt: now.subtract(const Duration(days: 19)),
      fullness: 80,
      fullnessUpdatedAt: now,
      happiness: 90,
      happinessUpdatedAt: now,
      growth: 400,
    );
    SharedPreferences.setMockInitialValues({
      'pet.state': jsonEncode(pet.toJson()),
      'pet.accessory': 'sprout',
      'pet.owned': owned.toList(),
    });
    await sl.reset();
    final store = PetStore(await SharedPreferences.getInstance());
    sl.registerSingleton<PetStore>(store);
    tester.view.physicalSize = const Size(392 * 2, 1700 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    return store;
  }

  Widget app(Widget home) => MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: home,
      );

  testWidgets('the wardrobe has what it can wear, and the way to the shop',
      (tester) async {
    final store = await setUpPet(tester);
    await tester.pumpWidget(app(const Scaffold(body: PetWardrobeSheet())));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Topi koki'), findsNothing);
    expect(find.text('Kostum dino'), findsNothing);
    expect(find.text('Mau tampil beda? Mampir ke Butik'), findsOneWidget);

    await tester.tap(find.text('Pita'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.accessory, BlobAccessory.bow);
    // "No outfit" when it's never worn one stores nothing to send.
    await tester.tap(find.text('Tanpa outfit'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.outfitId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in the boutique things are tried on, never kept',
      (tester) async {
    final store = await setUpPet(tester);
    await tester.pumpWidget(app(const PetShopPage()));
    await tester.pump(const Duration(milliseconds: 100));

    // Sections, from the chips (they scroll sideways, like on a phone).
    Future<void> shelf(String name, double dx) async {
      await tester.dragUntilVisible(
          find.text(name), find.byType(ListView).first, Offset(dx, 0));
      // Let the row stop gliding: a tap on a moving list only stops it.
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text(name));
      await tester.pump(const Duration(milliseconds: 300));
    }

    await shelf('Kostum', -80);
    expect(find.text('Batik'), findsNothing);
    await tester.tap(find.text('Kostum dino'));
    await tester.pump(const Duration(milliseconds: 300));
    // On the rack and in the bar at the bottom.
    expect(find.text('Kostum dino'), findsNWidgets(2));
    expect(find.text('Bisa dibeli segera'), findsOneWidget);

    // A hat takes the hood down; the bar shows the hat.
    await shelf('Aksesori', 80);
    await tester.tap(find.text('Topi koki'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Topi koki'), findsNWidgets(2));
    expect(find.text('Kostum dino'), findsNothing);
    // None of it is kept.
    expect(store.accessory, BlobAccessory.sprout);
    expect(store.outfit, BlobOutfit.none);
    expect(tester.takeException(), isNull);
  });

  testWidgets('what it owns is in the wardrobe too', (tester) async {
    final store = await setUpPet(tester,
        owned: {'accessory.chefHat', 'outfit.dino', 'outfit.hoodie'});
    await tester.pumpWidget(app(const Scaffold(body: PetWardrobeSheet())));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Topi pesta'), findsNothing);
    expect(find.text('Batik'), findsNothing);

    await tester.tap(find.text('Kostum dino'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.outfit, BlobOutfit.dino);
    // A hat takes the hood down.
    await tester.tap(find.text('Topi koki'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.accessory, BlobAccessory.chefHat);
    expect(store.outfit, BlobOutfit.none);
    await tester.tap(find.text('Hoodie'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.outfit, BlobOutfit.hoodie);
    expect(store.accessory, BlobAccessory.chefHat);
    expect(tester.takeException(), isNull);
  });

  testWidgets('in the boutique what it owns can be put on', (tester) async {
    final store = await setUpPet(tester, owned: {'outfit.dino'});
    await tester.pumpWidget(app(const PetShopPage()));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.dragUntilVisible(find.text('Kostum'),
        find.byType(ListView).first, const Offset(-80, 0));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Kostum'));
    await tester.pump(const Duration(milliseconds: 300));

    // Not this one: for sale soon.
    await tester.tap(find.text('Kostum katak'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Bisa dibeli segera'), findsOneWidget);
    expect(find.text('Pakai'), findsNothing);

    // This one's hers (on the rack, and in the bar).
    await tester.tap(find.text('Kostum dino'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Punyamu'), findsNWidgets(2));
    await tester.tap(find.text('Pakai'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.outfit, BlobOutfit.dino);
    expect(find.text('Sedang dipakai'), findsOneWidget);
    expect(find.text('Pakai'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
