import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';

/// What the pet says: a white rounded bubble with a little tail pointing
/// down at it. Pops in/out and cross-fades when the line changes.
///
/// [thinking] shows three bouncing dots instead of text. [tailLeft] points
/// the tail at a pet sitting to the bubble's lower left instead of below
/// it (the tail sits near the bubble's bottom edge).
class PetSpeechBubble extends StatelessWidget {
  final String? text;
  final bool thinking;
  final double maxWidth;
  final bool tailLeft;
  const PetSpeechBubble({
    super.key,
    required this.text,
    this.thinking = false,
    this.maxWidth = 210,
    this.tailLeft = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final showing = thinking || text != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(anim),
          alignment: tailLeft ? Alignment.bottomLeft : Alignment.bottomCenter,
          child: child,
        ),
      ),
      child: !showing
          ? const SizedBox.shrink(key: ValueKey('none'))
          : Semantics(
              key: ValueKey(thinking ? '…' : text),
              liveRegion: true,
              child: Flex(
                direction: tailLeft ? Axis.horizontal : Axis.vertical,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: tailLeft
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.center,
                children: [
                  if (tailLeft)
                    Transform.translate(
                      offset: const Offset(1, -9),
                      child: CustomPaint(
                        size: const Size(7, 14),
                        painter: _TailPainter(
                          fill: palette.surface,
                          stroke: palette.surfaceStroke,
                          left: true,
                        ),
                      ),
                    ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 8),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.surfaceStroke),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: thinking
                          ? const _Dots()
                          : Text(
                              text!,
                              textAlign: TextAlign.center,
                              style: AppFonts.body(
                                fontSize: 12.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: palette.textPrimary,
                              ),
                            ),
                    ),
                  ),
                  if (!tailLeft)
                    Transform.translate(
                      offset: const Offset(0, -1),
                      child: CustomPaint(
                        size: const Size(14, 7),
                        painter: _TailPainter(
                          fill: palette.surface,
                          stroke: palette.surfaceStroke,
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.palette.textSecondary;
    return SizedBox(
      width: 34,
      height: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < 3; i++)
              Transform.translate(
                offset: Offset(
                    0,
                    -3 *
                        math
                            .sin((_c.value * 2 * math.pi) - i * 0.9)
                            .clamp(0, 1)),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: color),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  final bool left;
  _TailPainter({required this.fill, required this.stroke, this.left = false});

  @override
  void paint(Canvas canvas, Size size) {
    final open = left
        ? (Path()
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height))
        : (Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0));
    canvas.drawPath(Path.from(open)..close(), Paint()..color = fill);
    canvas.drawPath(
      open,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) =>
      old.fill != fill || old.stroke != stroke || old.left != left;
}
