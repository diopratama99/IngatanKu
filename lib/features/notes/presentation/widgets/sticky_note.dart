import 'package:flutter/material.dart';

import 'note_paper.dart';

/// How a sticky note is held on the board.
enum StickyFix {
  /// A round pushpin through the top.
  pin,

  /// A strip of washi tape across the top (pinned notes).
  tape,
}

/// A sticky note on a pegboard: a square of pastel paper, turned a little,
/// held on by a pushpin or a strip of washi tape, its bottom edge lifting
/// off the board a touch. Used for your notes in Catatan and for today's
/// saves fanned out on Beranda.
class StickyNote extends StatelessWidget {
  final Color paper;

  /// Turned by this much (radians) — see [tiltFor].
  final double angle;
  final StickyFix fix;

  /// The pin's head, or the tape.
  final Color accent;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final VoidCallback? onTap;
  final Widget child;
  const StickyNote({
    super.key,
    required this.paper,
    required this.child,
    this.angle = 0,
    this.fix = StickyFix.pin,
    this.accent = pinRed,
    this.padding = const EdgeInsets.fromLTRB(13, 18, 13, 14),
    this.minHeight = 0,
    this.onTap,
  });

  static const pinRed = Color(0xFFE0584F);

  /// Pin heads to pick from, so a board doesn't look all one colour.
  static const pins = [
    pinRed,
    Color(0xFF5F86D6),
    Color(0xFF5FA873),
    Color(0xFFE3A33A),
  ];

  /// A small, steady tilt for the note with [id]: each note keeps its own
  /// angle every time it's drawn.
  static double tiltFor(String id, {double max = 0.035}) {
    final h = _hash(id);
    return ((h % 1000) / 999 * 2 - 1) * max;
  }

  /// One of [options], picked steadily for [id].
  static T pick<T>(String id, List<T> options, {int salt = 0}) =>
      options[(_hash(id) ~/ 7 + salt) % options.length];

  static int _hash(String s) {
    var h = 17;
    for (final c in s.codeUnits) {
      h = (h * 31 + c) & 0x3fffffff;
    }
    return h;
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(3);
    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: paper,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 1.5,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: _CurlPainter(),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: radius,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minHeight),
                    child: Padding(padding: padding, child: child),
                  ),
                ),
              ),
            ),
          ),
          if (fix == StickyFix.pin)
            Positioned(
              top: -4,
              left: 0,
              right: 0,
              child: Center(child: Pushpin(color: accent)),
            )
          else
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: WashiTape(color: accent, width: 48, height: 16),
              ),
            ),
        ],
      ),
    );
  }
}

/// The bottom of a sticky note curling up off the board: a little shade
/// along the bottom, deepest at the corners.
class _CurlPainter extends CustomPainter {
  _CurlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final band =
        Rect.fromLTWH(0, size.height * 0.78, size.width, size.height * 0.22);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.035),
          ],
        ).createShader(band),
    );
    for (final x in [0.0, size.width]) {
      final corner = Rect.fromCircle(
          center: Offset(x, size.height), radius: size.shortestSide * 0.22);
      canvas.drawOval(
        corner,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.black.withValues(alpha: 0.04),
            Colors.black.withValues(alpha: 0),
          ]).createShader(corner),
      );
    }
  }

  @override
  bool shouldRepaint(_CurlPainter old) => false;
}

/// A round, glossy pushpin head with its shadow on the paper.
class Pushpin extends StatelessWidget {
  final Color color;
  final double size;
  const Pushpin({super.key, required this.color, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _PinPainter(color),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  final Color color;
  _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = Offset(r, r);
    // Its shadow falls down and to the right.
    canvas.drawCircle(
      c + Offset(r * 0.35, r * 0.5),
      r * 0.9,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
    );
    final head = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [
            Color.lerp(color, Colors.white, 0.45)!,
            color,
            Color.lerp(color, Colors.black, 0.28)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(head),
    );
    canvas.drawCircle(
      c + Offset(-r * 0.32, -r * 0.36),
      r * 0.24,
      Paint()..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}
