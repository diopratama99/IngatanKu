import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Draws a little cartoon mosquito (the easter egg on Beranda) centred on
/// [at]: a round striped body, a big eye, a long nose, glassy wings beating
/// fast and thin dangling legs. [size] is its length nose to tail; it
/// faces right, or left with a negative [facing]. [t] (seconds) beats the
/// wings; [spin] turns it (tumbling into the pet's mouth).
void paintMosquito(
  Canvas canvas,
  Offset at,
  double size,
  double t, {
  double facing = 1,
  double spin = 0,
  double alpha = 1,
}) {
  if (size <= 0 || alpha <= 0) return;
  final l = size;
  Color c(int argb) => Color(argb).withValues(alpha: alpha);
  canvas.save();
  canvas.translate(at.dx, at.dy);
  canvas.rotate(spin);
  canvas.scale(facing < 0 ? -1 : 1, 1);

  // Legs, dangling under it.
  final leg = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = l * 0.025
    ..color = c(0xFF4D4856);
  for (var i = 0; i < 3; i++) {
    final from = Offset(l * (0.12 - i * 0.07), l * 0.08);
    final knee = from + Offset(-l * 0.05, l * 0.16);
    final foot = knee + Offset(-l * (0.02 + i * 0.03), l * 0.14);
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy),
      leg,
    );
  }

  // Its tail end: a striped oval, tipped down a little.
  canvas.save();
  canvas.translate(-l * 0.2, l * 0.04);
  canvas.rotate(0.25);
  final belly =
      Rect.fromCenter(center: Offset.zero, width: l * 0.52, height: l * 0.3);
  canvas.drawOval(belly, Paint()..color = c(0xFF6B6577));
  canvas.save();
  canvas.clipPath(Path()..addOval(belly));
  final band = Paint()..color = c(0xFFD9D3E2);
  for (final x in [-0.12, 0.0, 0.12]) {
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(l * x, 0), width: l * 0.045, height: l * 0.4),
        band);
  }
  canvas.restore();
  canvas.restore();

  // Body and head.
  canvas.drawCircle(
      Offset(l * 0.06, -l * 0.02), l * 0.15, Paint()..color = c(0xFF57525F));
  final head = Offset(l * 0.25, -l * 0.06);
  canvas.drawCircle(head, l * 0.11, Paint()..color = c(0xFF625C6C));
  // The long nose.
  canvas.drawLine(
    head + Offset(l * 0.09, l * 0.03),
    head + Offset(l * 0.42, l * 0.2),
    Paint()
      ..strokeWidth = l * 0.035
      ..strokeCap = StrokeCap.round
      ..color = c(0xFF3F3B46),
  );
  // A big, slightly worried eye.
  final eye = head + Offset(l * 0.03, -l * 0.02);
  canvas.drawCircle(eye, l * 0.065, Paint()..color = c(0xFFFFFFFF));
  canvas.drawCircle(eye + Offset(l * 0.015, l * 0.005), l * 0.035,
      Paint()..color = c(0xFF1F1B24));

  // Wings, a blur of beats: the far one, then the near one.
  final beat = math.sin(t * 2 * math.pi * 22);
  for (final (dx, phase, shade) in [(-0.03, 0.6, 0.35), (0.04, 0.0, 0.6)]) {
    canvas.save();
    canvas.translate(l * dx, -l * 0.13);
    canvas.rotate(
        -2.2 + 0.55 * math.sin(t * 2 * math.pi * 22 + phase) + 0.1 * beat);
    final wing = Rect.fromLTWH(0, -l * 0.1, l * 0.48, l * 0.2);
    canvas.drawOval(
        wing, Paint()..color = Colors.white.withValues(alpha: shade * alpha));
    canvas.drawOval(
      wing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = l * 0.02
        ..color = c(0xFF9AA6BA).withValues(alpha: 0.8 * alpha),
    );
    canvas.restore();
  }
  canvas.restore();
}
