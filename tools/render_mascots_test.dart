// Stills of the pet for the landing page (landing/public/mascot). Kept out
// of test/ so it only runs when asked:
//   flutter test tools/render_mascots_test.dart
// It writes PNGs; the page serves them as .webp (cwebp -q 85).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/presentation/widgets/blob_mascot.dart';

class Shot {
  final String name;
  final PetStage stage;
  final CompanionMood mood;
  final BlobExpression? face;
  final BlobColor color;
  final BlobAccessory accessory;
  final BlobOutfit outfit;
  final bool glasses;
  const Shot(this.name,
      {this.stage = PetStage.teen,
      this.mood = CompanionMood.happy,
      this.face,
      this.color = BlobColor.honey,
      this.accessory = BlobAccessory.sprout,
      this.outfit = BlobOutfit.none,
      this.glasses = false});
}

void main() {
  final shots = <Shot>[
    for (final s in PetStage.values)
      Shot('stage-${s.name}', stage: s, mood: s == PetStage.egg ? CompanionMood.content : CompanionMood.happy),
    const Shot('face-happy'),
    const Shot('face-content', mood: CompanionMood.content),
    const Shot('face-hungry', mood: CompanionMood.hungry, face: BlobExpression.hungry),
    const Shot('face-sad', mood: CompanionMood.lonely, face: BlobExpression.sad),
    const Shot('face-smirk', face: BlobExpression.smirk),
    const Shot('face-surprised', face: BlobExpression.surprised),
    const Shot('face-reading', face: BlobExpression.serious, glasses: true),
    const Shot('face-yuck', face: BlobExpression.yuck),
    const Shot('face-dizzy', face: BlobExpression.dizzy),
    const Shot('face-scared', face: BlobExpression.scared),
    const Shot('face-angry', face: BlobExpression.angry),
    const Shot('face-sleepy', mood: CompanionMood.sleepy),
    for (final a in BlobAccessory.values)
      Shot('acc-${a.name}', stage: PetStage.adult, accessory: a),
    for (final o in BlobOutfit.values)
      if (o != BlobOutfit.none) Shot('outfit-${o.name}', stage: PetStage.adult, outfit: o),
    for (final c in BlobColor.values) Shot('color-${c.name}', stage: PetStage.adult, color: c),
  ];

  testWidgets('mascot stills', (tester) async {
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    const side = 160.0;
    for (final s in shots) {
      final body = s.stage == PetStage.egg ? 0.84 * s.stage.scale : 0.74 * s.stage.scale;
      await tester.pumpWidget(Center(
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: SizedBox.square(
            dimension: side,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: BlobMascot(
                size: side * 0.72 / body,
                color: s.color,
                accessory: s.accessory,
                outfit: s.outfit,
                stage: s.stage,
                mood: s.mood,
                expression: s.face,
                glasses: s.glasses,
                interactive: false,
                animate: false,
              ),
            ),
          ),
        ),
      ));
      final box = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      await tester.runAsync(() async {
        final image = await box.toImage(pixelRatio: 3);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('landing/public/mascot/${s.name}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });
}
