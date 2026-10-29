import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/companion/domain/companion_style.dart';
import 'package:ingatanku/features/companion/presentation/widgets/blob_mascot.dart';
import 'package:ingatanku/features/dashboard/presentation/widgets/coin_drop.dart';

void main() {
  group('shaking the pet while it is held', () {
    Future<(int lifts, int shakes)> handle(
      WidgetTester tester,
      Future<void> Function(TestGesture g) moves,
    ) async {
      var lifts = 0, shakes = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: BlobMascot(
              size: 120,
              color: BlobColor.honey,
              accessory: BlobAccessory.none,
              onLift: () => lifts++,
              onCarry: (_) {},
              onDrop: () {},
              onShaken: () => shakes++,
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      final g = await tester.startGesture(
          tester.getCenter(find.byType(BlobMascot)) + const Offset(0, 40));
      // Lift it: drag upwards.
      for (var i = 0; i < 4; i++) {
        await g.moveBy(const Offset(0, -15));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await moves(g);
      await g.up();
      await tester.pump(const Duration(seconds: 3));
      return (lifts, shakes);
    }

    testWidgets('a quick back-and-forth shakes coins loose', (tester) async {
      final (lifts, shakes) = await handle(tester, (g) async {
        for (var i = 0; i < 8; i++) {
          await g.moveBy(Offset(i.isEven ? 40 : -40, 0));
          await tester.pump(const Duration(milliseconds: 60));
        }
      });
      expect(lifts, 1);
      // The first couple of turns only get it going.
      expect(shakes, greaterThanOrEqualTo(4));
    });

    testWidgets('up and down counts too', (tester) async {
      final (_, shakes) = await handle(tester, (g) async {
        for (var i = 0; i < 8; i++) {
          await g.moveBy(Offset(0, i.isEven ? 35 : -35));
          await tester.pump(const Duration(milliseconds: 60));
        }
      });
      expect(shakes, greaterThanOrEqualTo(4));
    });

    testWidgets('just carrying it about is not shaking', (tester) async {
      final (_, shakes) = await handle(tester, (g) async {
        // Slowly over to one side and back once.
        for (var i = 0; i < 6; i++) {
          await g.moveBy(const Offset(20, 0));
          await tester.pump(const Duration(milliseconds: 200));
        }
        for (var i = 0; i < 6; i++) {
          await g.moveBy(const Offset(-20, 0));
          await tester.pump(const Duration(milliseconds: 200));
        }
      });
      expect(shakes, 0);
    });
  });

  // Signing out takes Beranda down. A floor that never had a coin used to
  // make its ticker in dispose(), which threw and left the page half taken
  // down: signing in again then showed a red screen.
  testWidgets('a floor no coin ever fell on goes away cleanly', (tester) async {
    final walk = AnimationController(vsync: const TestVSync());
    addTearDown(walk.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CoinFloor(
          controller: CoinController(),
          sceneWidth: 400,
          groundY: 350,
          petS: 120,
          walkScale: 96,
          bodyHeight: 90,
          walk: walk,
        ),
      ),
    ));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('coins fall, lie on the floor and get picked up', (tester) async {
    final coins = CoinController();
    final walk = AnimationController(vsync: const TestVSync());
    addTearDown(walk.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: CoinFloor(
            controller: coins,
            sceneWidth: 400,
            groundY: 350,
            petS: 120,
            walkScale: 96,
            bodyHeight: 90,
            walk: walk,
          ),
        ),
      ),
    ));
    for (var i = 0; i < CoinFloor.most + 4; i++) {
      coins.drop(const Offset(200, 200));
    }
    // There's only so much room on the floor.
    expect(coins.count, CoinFloor.most);
    expect(coins.falling, CoinFloor.most);
    expect(coins.nearest(0), isNull);

    await tester.pump();
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(coins.falling, 0);
    expect(coins.count, CoinFloor.most);

    // Walk to each and pick it up: all gone in the end.
    var picked = 0;
    for (var i = 0; i < CoinFloor.most && coins.count > 0; i++) {
      final spot = coins.nearest(walk.value)!;
      // Still within the pet's reach of the floor.
      expect(spot.abs() * 96, lessThanOrEqualTo(200 - 120 * 0.45 + 0.01));
      walk.value = spot;
      picked += coins.pickUp(spot);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(picked, CoinFloor.most);
    expect(coins.count, 0);
    // The last ones fly into the pet, then they're gone.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 16));
    expect(coins.nearest(0), isNull);
  });
}
