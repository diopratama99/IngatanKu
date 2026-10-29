import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/companion/data/pet_hurt.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/presentation/widgets/blob_mascot.dart';

void main() {
  testWidgets('the pet cries on every page it is on until petted', (
    tester,
  ) async {
    // Two pages with the pet on them (say Catatan and Beranda).
    final notes = BlobController();
    final home = BlobController();
    Widget pet(BlobController c, Key key) => BlobMascot(
          key: key,
          size: 120,
          color: BlobColor.honey,
          accessory: BlobAccessory.none,
          controller: c,
          ownPet: true,
        );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          pet(notes, const Key('notes')),
          pet(home, const Key('home')),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    Offset body(String key) =>
        tester.getCenter(find.byKey(Key(key))) + const Offset(0, 40);

    // Smacked to tears in Catatan…
    for (var i = 0; i < BlobController.cryAfter; i++) {
      await tester.tapAt(body('notes'));
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(notes.crying.value, isTrue);
    // …and it's still crying, bruised, on Beranda.
    expect(home.crying.value, isTrue);
    expect(PetHurt.instance.bruisedAt, isNotNull);

    // Petted better on Beranda: it stops crying everywhere.
    for (var i = 0; i < 3; i++) {
      await tester.timedDragFrom(body('home'), const Offset(120, 0),
          const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(home.crying.value, isFalse);
    expect(notes.crying.value, isFalse);

    // The bruises heal a few seconds later.
    await tester.pump(PetHurt.healIn + const Duration(seconds: 1));
    PetHurt.instance.heal(DateTime.now().add(PetHurt.healIn * 2));
    expect(PetHurt.instance.active, isFalse);
  });
}
