import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Where the pet's daily meal (the daily quiz) stands.
enum MealState {
  /// Not enough notes to quiz on yet.
  locked,

  /// Today's meal is waiting.
  ready,

  /// Fed for today.
  done,
}

/// The pet's daily meal on Beranda: an onigiri in a soap bubble
/// (`assets/food/onigiri_bubble.png`) floating over its vitals, two little
/// bubbles trailing down to them. A red dot while the meal waits; faded
/// with a padlock until there are enough notes to quiz on. Bump [refused]
/// to make it wobble (the pet turned it down).
class MealBubble extends StatefulWidget {
  final MealState state;

  /// Notes saved so far, and how many open the meals (for the label).
  final int notes;
  final int needNotes;
  final int refused;
  final VoidCallback onTap;
  const MealBubble({
    super.key,
    required this.state,
    required this.notes,
    required this.needNotes,
    required this.onTap,
    this.refused = 0,
  });

  @override
  State<MealBubble> createState() => _MealBubbleState();
}

class _MealBubbleState extends State<MealBubble> with TickerProviderStateMixin {
  /// A slow, small float — it's a bubble.
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();
  late final AnimationController _wobble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _down = false;

  @override
  void didUpdateWidget(MealBubble old) {
    super.didUpdateWidget(old);
    if (widget.refused != old.refused) _wobble.forward(from: 0);
  }

  @override
  void dispose() {
    _float.dispose();
    _wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final state = widget.state;
    final label = switch (state) {
      MealState.ready => '${l10n.homeMealReady}. ${l10n.homeMealReadySub}',
      MealState.done => l10n.homeMealDone,
      MealState.locked =>
        '${l10n.homeMealLocked}. ${l10n.homeMealLockedSub(math.min(widget.notes, widget.needNotes), widget.needNotes)}',
    };
    const size = 62.0;

    final bubble = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: state == MealState.locked ? 0.55 : 1,
              child: Image.asset(
                'assets/food/onigiri_bubble.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                excludeFromSemantics: true,
              ),
            ),
          ),
          if (state == MealState.ready)
            Positioned(
              right: 4,
              top: 3,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.danger,
                  border: Border.all(color: palette.bgPrimary, width: 2),
                ),
              ),
            ),
          if (state == MealState.locked)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surface,
                  border: Border.all(color: palette.surfaceStroke),
                ),
                child: Icon(Icons.lock_rounded,
                    size: 12, color: palette.textTertiary),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_float, _wobble]),
          builder: (_, __) {
            final a = _float.value * 2 * math.pi;
            // Wobbles "no" when the pet turns it down.
            final w = _wobble.value;
            final shake = math.sin(w * 5 * math.pi) * 7 * (1 - w);
            return AnimatedScale(
              scale: _down ? 0.92 : 1,
              duration: const Duration(milliseconds: 110),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: Offset(shake, math.sin(a) * 2.5),
                    child: Transform.rotate(
                      angle: math.sin(a + 1.1) * 0.035,
                      child: bubble,
                    ),
                  ),
                  // Two little bubbles trailing down, each on its own beat.
                  Transform.translate(
                    offset:
                        Offset(14 + shake * 0.5, 2 + math.sin(a + 1.6) * 1.6),
                    child: const _SmallBubble(size: 11),
                  ),
                  Transform.translate(
                    offset:
                        Offset(7 + shake * 0.3, 2 + math.sin(a + 2.8) * 1.2),
                    child: const _SmallBubble(size: 7),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A tiny soap bubble, like the big one.
class _SmallBubble extends StatelessWidget {
  final double size;
  const _SmallBubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.4),
          colors: [
            Colors.white.withValues(alpha: 0.95),
            (const Color(0xFFD7E9F7)).withValues(alpha: 0.75),
          ],
        ),
        border: Border.all(
          color: (const Color(0xFFA9C8E6)).withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
