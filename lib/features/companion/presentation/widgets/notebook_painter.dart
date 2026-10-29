import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Lines on a page of the pet's notebook.
const _rows = 4;

/// Where the pencil is at [progress] (0..1) through a page: the line it's
/// on and how far along that line (0..1). It rests at the end of the page
/// for a moment before the next one.
(int, double) notebookPenAt(double progress) {
  final local = progress * (_rows + 0.6);
  final row = math.min(local.floor(), _rows - 1);
  return (row, (local - row).clamp(0.0, 1.0));
}

/// Width of the notebook [paintLapNotebook] draws for a pet of size [s].
double lapNotebookWidth(double s, double scale) => s * 0.85 * scale + 14;

/// The pet's open notebook lying in front of it, turned to face it, drawn
/// with a little perspective (the edge by the pet is narrower than the one
/// by us). Used at the Catatan desk and when it writes up a link on
/// Beranda.
///
/// It's written line by line from the pet's side of the book, so the lines
/// grow from the outer edge towards the spine; [progress] is how far
/// through the page it is. With [hands] one hand steadies the book and the
/// other writes with a pencil, scribbling as [progress] moves.
///
/// [petX] is the pet's centre line, [nearY] the book's edge nearest to us,
/// [s] and [scale] the pet's size and life-stage scale.
void paintLapNotebook(
  Canvas canvas, {
  required double petX,
  required double nearY,
  required double s,
  required double scale,
  required double progress,
  required Color paper,
  required Color line,
  required Color cover,
  Color? hands,
}) {
  final stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeJoin = StrokeJoin.round
    ..color = line;
  final nbW = lapNotebookWidth(s, scale);
  final depth = nbW * 0.16;
  final farY = nearY - depth;
  final hn = nbW / 2;
  final hf = hn * 0.86;
  double halfAt(double t) => hf + (hn - hf) * t; // t: 0 far → 1 near
  double yAt(double t) => farY + depth * t;

  final back = Path()
    ..moveTo(petX - hf - 2, farY + 1)
    ..lineTo(petX + hf + 2, farY + 1)
    ..lineTo(petX + hn + 3, nearY + 1.5)
    ..lineTo(petX - hn - 3, nearY + 1.5)
    ..close();
  canvas.drawPath(back, Paint()..color = cover);
  canvas.drawPath(back, stroke);
  for (final dir in [-1.0, 1.0]) {
    final page = Path()
      ..moveTo(petX, farY + 1)
      ..quadraticBezierTo(
          petX + dir * hf * 0.5, farY - 2, petX + dir * hf, farY)
      ..lineTo(petX + dir * hn, nearY)
      ..quadraticBezierTo(petX + dir * hn * 0.5, nearY - 2, petX, nearY)
      ..close();
    canvas.drawPath(page, Paint()..color = paper);
    canvas.drawPath(page, stroke);
  }
  canvas.drawLine(Offset(petX, farY + 1), Offset(petX, nearY), stroke);

  final ink = Paint()
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..color = line;
  final ruled = Paint()
    ..strokeWidth = 1
    ..color = line.withValues(alpha: 0.35);
  // Pet's first page (our right) fills up; its other page waits, ruled.
  final (row, along) = notebookPenAt(progress);
  Offset tip = Offset.zero;
  for (var i = 0; i < _rows; i++) {
    final t = 0.24 + i * 0.19;
    final y = yAt(t);
    final outer = petX + halfAt(t) * 0.84;
    final inner = petX + 4;
    final f = i < row ? 1.0 : (i == row ? along : 0.0);
    if (f > 0) {
      canvas.drawLine(
          Offset(outer, y), Offset(outer - (outer - inner) * f, y), ink);
    }
    if (i == row) tip = Offset(outer - (outer - inner) * f, y);
    canvas.drawLine(
        Offset(petX - 4, y), Offset(petX - halfAt(t) * 0.84, y), ruled);
  }

  if (hands == null) return;
  // Free hand holding the book open on its far side.
  canvas.save();
  canvas.translate(petX - hn * 0.58, yAt(0.5));
  canvas.rotate(-0.25);
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: s * 0.15 * scale + 2,
          height: s * 0.1 * scale + 2),
      Paint()..color = hands);
  canvas.restore();
  _paintPencilInHand(canvas, tip, hands, s, scale, progress);
}

/// A short pencil, its point on the page at [tip], held in a little hand
/// partway up, scribbling.
void _paintPencilInHand(Canvas canvas, Offset tip, Color hand, double s,
    double scale, double progress) {
  final wiggle = progress * 2 * math.pi * 36;
  final point =
      tip + Offset(math.sin(wiggle) * 0.8, -0.5 + math.cos(wiggle) * 0.5);
  // Leaning back towards the pet's shoulder, low enough to pass under its
  // cheek.
  const u = Offset(0.88, -0.48);
  final len = s * 0.34 * math.max(scale, 0.75) + 6;
  final width = math.max(2.6, s * 0.035 * scale + 1);
  final end = point + u * len;
  final wood = point + u * (width * 1.1);
  canvas.drawLine(
      wood,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFF2C46B));
  canvas.drawLine(
      end - u * 3,
      end,
      Paint()
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFEA9A9A));
  // Sharpened wood and the lead.
  canvas.drawLine(
      point,
      wood,
      Paint()
        ..strokeWidth = width * 0.7
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFE9D3B0));
  canvas.drawCircle(point, 1.2, Paint()..color = const Color(0xFF4A4743));
  // The hand wrapped around it, near the point.
  final grip = point + u * (len * 0.3);
  canvas.save();
  canvas.translate(grip.dx, grip.dy);
  canvas.rotate(-0.45);
  canvas.drawOval(
      Rect.fromCenter(
          center: Offset.zero,
          width: s * 0.12 * scale + 3,
          height: s * 0.08 * scale + 2),
      Paint()..color = hand);
  canvas.restore();
}
