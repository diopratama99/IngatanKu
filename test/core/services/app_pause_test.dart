import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/services/app_pause.dart';
import 'package:ingatanku/features/companion/data/pet_hurt.dart';

void main() {
  final pause = AppPause.instance;

  tearDown(() => pause.debugSetPaused(false));

  testWidgets('a timer waits while the app is away', (tester) async {
    var fired = 0;
    AppTimer(const Duration(seconds: 10), () => fired++);
    await tester.pump(const Duration(seconds: 6));
    pause.debugSetPaused(true);
    // A minute away: nothing happens.
    await tester.pump(const Duration(minutes: 1));
    expect(fired, 0);
    pause.debugSetPaused(false);
    // It still had 4 s to go.
    await tester.pump(const Duration(seconds: 3));
    expect(fired, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(fired, 1);
  });

  testWidgets('a repeating timer skips the time away', (tester) async {
    var ticks = 0;
    final timer = AppTimer.periodic(const Duration(seconds: 5), (_) => ticks++);
    await tester.pump(const Duration(seconds: 12));
    expect(ticks, 2);
    pause.debugSetPaused(true);
    await tester.pump(const Duration(seconds: 30));
    expect(ticks, 2);
    pause.debugSetPaused(false);
    await tester.pump(const Duration(seconds: 3));
    expect(ticks, 3);
    timer.cancel();
    await tester.pump(const Duration(seconds: 20));
    expect(ticks, 3);
    expect(timer.isActive, isFalse);
  });

  testWidgets('a delay counts only the time in sight', (tester) async {
    var done = false;
    AppPause.delay(const Duration(seconds: 2)).then((_) => done = true);
    await tester.pump(const Duration(seconds: 1));
    pause.debugSetPaused(true);
    await tester.pump(const Duration(seconds: 10));
    expect(done, isFalse);
    pause.debugSetPaused(false);
    await tester.pump(const Duration(seconds: 1));
    expect(done, isTrue);
  });

  testWidgets('tears and bruises wait for the app to be back', (tester) async {
    final hurt = PetHurt.instance;
    final t0 = DateTime(2026, 10, 15, 9);
    hurt.cry(t0);
    hurt.calm(t0.add(const Duration(seconds: 1)));
    pause.debugSetPaused(true);
    await tester.pump(const Duration(minutes: 5));
    pause.debugSetPaused(false);
    expect(pause.lastGap, const Duration(minutes: 5));
    expect(hurt.calmAt, t0.add(const Duration(minutes: 5, seconds: 1)));
    expect(hurt.bruisedAt, t0.add(const Duration(minutes: 5)));
    // Healed on its own clock: 8 s after calming down, time away aside.
    hurt.heal(t0.add(const Duration(minutes: 5, seconds: 5)));
    expect(hurt.bruisedAt, isNotNull);
    hurt.heal(t0.add(const Duration(minutes: 5, seconds: 10)));
    expect(hurt.bruisedAt, isNull);
  });

  testWidgets('animations pick up where they stopped', (tester) async {
    pause.init();
    final binding = tester.binding;
    late AnimationController anim;
    await tester.pumpWidget(_Anim((c) => anim = c));
    anim.forward();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final before = anim.value;
    expect(before, closeTo(0.4, 0.01));

    // Minimised: no frames for a minute.
    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      binding.handleAppLifecycleStateChanged(s);
    }
    expect(pause.paused, isTrue);
    await binding.delayed(const Duration(minutes: 1));
    for (final s in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(s);
    }
    expect(pause.paused, isFalse);

    // Back: on from 0.4, not done in one go.
    await tester.pump(const Duration(milliseconds: 16));
    expect(anim.value, closeTo(before, 0.03));
    await tester.pump(const Duration(milliseconds: 300));
    expect(anim.value, closeTo(0.7, 0.03));
  });
}

/// A widget with a one-second animation, handed to [onReady].
class _Anim extends StatefulWidget {
  final void Function(AnimationController) onReady;
  const _Anim(this.onReady);

  @override
  State<_Anim> createState() => _AnimState();
}

class _AnimState extends State<_Anim> with SingleTickerProviderStateMixin {
  late final _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    widget.onReady(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
