import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A round wall clock with a wooden rim, showing the real time. Its hands
/// move as the page rebuilds (Beranda does that every minute) — there's no
/// second hand, so it stays calm.
class WallClock extends StatelessWidget {
  /// Where its shadow falls (away from the lamp), in logical pixels.
  final Offset shadowOffset;
  final String semanticsLabel;
  const WallClock({
    super.key,
    required this.semanticsLabel,
    this.shadowOffset = const Offset(-2, 1),
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 7,
              offset: shadowOffset,
            ),
          ],
        ),
        child: CustomPaint(
          painter: _ClockPainter(time: DateTime.now()),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final DateTime time;
  _ClockPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rim = Rect.fromCircle(center: c, radius: r);

    // Wooden rim.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD9A06A), Color(0xFFA9713F)],
        ).createShader(rim),
    );
    // Face.
    final face = r * 0.8;
    canvas.drawCircle(
      c,
      face,
      Paint()..color = const Color(0xFFFBF6EC),
    );
    canvas.drawCircle(
      c,
      face,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.05
        ..color = Colors.black.withValues(alpha: 0.12),
    );

    // Hour marks, bolder at 12, 3, 6 and 9.
    const ink = Color(0xFF3A332B);
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * 2 * math.pi;
      final major = i % 3 == 0;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        c + dir * face * (major ? 0.72 : 0.8),
        c + dir * face * 0.9,
        Paint()
          ..strokeWidth = r * (major ? 0.07 : 0.035)
          ..strokeCap = StrokeCap.round
          ..color = ink.withValues(alpha: major ? 0.85 : 0.5),
      );
    }

    // Hands.
    final minutes = time.minute + time.second / 60;
    final hours = (time.hour % 12) + minutes / 60;
    void hand(double turns, double length, double width) {
      final a = turns * 2 * math.pi;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(
        c - dir * face * 0.12,
        c + dir * face * length,
        Paint()
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = ink,
      );
    }

    hand(hours / 12, 0.5, r * 0.1);
    hand(minutes / 60, 0.74, r * 0.065);
    canvas.drawCircle(c, r * 0.08, Paint()..color = const Color(0xFFE0584F));

    // A soft glare across the glass.
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: face)));
    canvas.drawOval(
      Rect.fromCenter(
        center: c + Offset(-face * 0.35, -face * 0.45),
        width: face * 1.1,
        height: face * 0.55,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) =>
      old.time.minute != time.minute || old.time.hour != time.hour;
}
