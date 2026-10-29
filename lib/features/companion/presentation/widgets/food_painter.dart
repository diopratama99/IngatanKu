import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/companion_style.dart';

/// Hand-drawn art for some dishes (`assets/food/`), used instead of the
/// painted version once it's loaded — call [load] at start-up.
class FoodArt {
  FoodArt._();

  static ui.Image? onigiri;

  static Future<void> load() async {
    try {
      final data = await rootBundle.load('assets/food/onigiri.png');
      onigiri = await decodeImageFromList(data.buffer.asUint8List());
    } catch (_) {
      // Missing or undecodable: the painted onigiri stays.
    }
  }
}

/// A single dish, drawn in the pet's chunky rounded style.
class FoodIcon extends StatelessWidget {
  final FoodKind kind;
  final double size;
  const FoodIcon({super.key, required this.kind, this.size = 48});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _FoodPainter(kind),
      );
}

class _FoodPainter extends CustomPainter {
  final FoodKind kind;
  _FoodPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) =>
      paintFood(canvas, kind, size.center(Offset.zero), size.width);

  @override
  bool shouldRepaint(covariant _FoodPainter old) => old.kind != kind;
}

/// Paints [kind] centred on [c], fitting a [s]×[s] box. Shared by the
/// pantry icons and the pet's eating animation.
void paintFood(Canvas canvas, FoodKind kind, Offset c, double s) {
  canvas.save();
  canvas.translate(c.dx, c.dy);
  switch (kind) {
    case FoodKind.bento:
      _bento(canvas, s);
    case FoodKind.sandwich:
      _sandwich(canvas, s);
    case FoodKind.onigiri:
      _onigiri(canvas, s);
    case FoodKind.donut:
      _donut(canvas, s);
    case FoodKind.cookie:
      _cookie(canvas, s);
    case FoodKind.chips:
      _chips(canvas, s);
  }
  canvas.restore();
}

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = c;

void _bento(Canvas canvas, double s) {
  final box = RRect.fromRectAndRadius(
    Rect.fromCenter(
        center: Offset(0, s * 0.06), width: s * 0.86, height: s * 0.62),
    Radius.circular(s * 0.12),
  );
  canvas.drawRRect(box, _fill(const Color(0xFFC0503F)));
  final inner = box.deflate(s * 0.05);
  canvas.drawRRect(inner, _fill(const Color(0xFFFFF6E8)));
  // Divider, rice with sesame, salmon and greens.
  canvas.drawLine(Offset(s * 0.02, inner.top), Offset(s * 0.02, inner.bottom),
      _line(const Color(0xFFC0503F), s * 0.035));
  canvas.drawOval(
    Rect.fromCenter(
        center: Offset(-s * 0.18, s * 0.06), width: s * 0.3, height: s * 0.36),
    _fill(Colors.white),
  );
  for (final d in [
    Offset(-s * 0.22, 0),
    Offset(-s * 0.13, s * 0.08),
    Offset(-s * 0.2, s * 0.14)
  ]) {
    canvas.drawCircle(d, s * 0.014, _fill(const Color(0xFF3A332B)));
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(s * 0.2, -s * 0.03),
          width: s * 0.26,
          height: s * 0.14),
      Radius.circular(s * 0.06),
    ),
    _fill(const Color(0xFFF28C6A)),
  );
  canvas.drawCircle(
      Offset(s * 0.14, s * 0.13), s * 0.06, _fill(const Color(0xFF7DB765)));
  canvas.drawCircle(
      Offset(s * 0.26, s * 0.14), s * 0.05, _fill(const Color(0xFFE5534B)));
}

void _sandwich(Canvas canvas, double s) {
  Path tri(double inset, double dy) => Path()
    ..moveTo(-s * 0.4 + inset, s * 0.28 + dy)
    ..lineTo(s * 0.4 - inset, s * 0.28 + dy)
    ..quadraticBezierTo(
        s * 0.06, -s * 0.38 + inset + dy, 0, -s * 0.38 + inset + dy)
    ..quadraticBezierTo(
        -s * 0.06, -s * 0.38 + inset + dy, -s * 0.4 + inset, s * 0.28 + dy)
    ..close();
  canvas.drawPath(tri(0, 0), _fill(const Color(0xFFD9A25F)));
  canvas.drawPath(tri(s * 0.05, s * 0.01), _fill(const Color(0xFFF6DDB0)));
  // Fillings peeking out of the bottom edge.
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(0, s * 0.3), width: s * 0.84, height: s * 0.08),
      Radius.circular(s * 0.04),
    ),
    _fill(const Color(0xFF7DB765)),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(0, s * 0.36), width: s * 0.76, height: s * 0.06),
      Radius.circular(s * 0.03),
    ),
    _fill(const Color(0xFFE5534B)),
  );
}

void _onigiri(Canvas canvas, double s) {
  final art = FoodArt.onigiri;
  if (art != null) {
    // The illustrated one, fitted to the same box (centred on 0, 0).
    final w = s * 0.9;
    final h = w * art.height / art.width;
    canvas.drawImageRect(
      art,
      Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
      Rect.fromCenter(center: Offset(0, s * 0.02), width: w, height: h),
      Paint()..filterQuality = FilterQuality.medium,
    );
    return;
  }
  final rice = Path()
    ..moveTo(0, -s * 0.38)
    ..cubicTo(s * 0.12, -s * 0.38, s * 0.42, s * 0.12, s * 0.38, s * 0.26)
    ..cubicTo(s * 0.34, s * 0.38, -s * 0.34, s * 0.38, -s * 0.38, s * 0.26)
    ..cubicTo(-s * 0.42, s * 0.12, -s * 0.12, -s * 0.38, 0, -s * 0.38)
    ..close();
  canvas.drawPath(rice, _fill(Colors.white));
  canvas.drawPath(rice, _line(const Color(0xFFE2DED6), s * 0.025));
  canvas.save();
  canvas.clipPath(rice);
  canvas.drawRect(
    Rect.fromCenter(
        center: Offset(0, s * 0.24), width: s * 0.34, height: s * 0.32),
    _fill(const Color(0xFF2F3A33)),
  );
  canvas.restore();
}

void _donut(Canvas canvas, double s) {
  canvas.drawCircle(Offset.zero, s * 0.38, _fill(const Color(0xFFD9A25F)));
  final icing = Path()
    ..addOval(Rect.fromCircle(center: Offset(0, -s * 0.02), radius: s * 0.33));
  canvas.drawPath(icing, _fill(const Color(0xFFF29BB0)));
  canvas.drawCircle(Offset.zero, s * 0.11, _fill(const Color(0xFFD9A25F)));
  canvas.drawCircle(Offset.zero, s * 0.075, _fill(const Color(0xFFFFF6E8)));
  const sprinkle = [
    Color(0xFFFFFFFF),
    Color(0xFF8EC5E8),
    Color(0xFFF2C04E),
    Color(0xFF7DB765),
  ];
  for (var i = 0; i < 9; i++) {
    final a = i / 9 * 2 * math.pi + 0.3;
    final r = s * (i.isEven ? 0.22 : 0.27);
    final p = Offset(math.cos(a) * r, math.sin(a) * r - s * 0.02);
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(a * 1.7);
    canvas.drawLine(Offset(-s * 0.025, 0), Offset(s * 0.025, 0),
        _line(sprinkle[i % sprinkle.length], s * 0.025));
    canvas.restore();
  }
}

void _cookie(Canvas canvas, double s) {
  canvas.drawCircle(Offset.zero, s * 0.37, _fill(const Color(0xFFD9A36A)));
  canvas.drawCircle(
      Offset.zero, s * 0.37, _line(const Color(0xFFBF8650), s * 0.03));
  for (final d in [
    Offset(-s * 0.15, -s * 0.12),
    Offset(s * 0.12, -s * 0.16),
    Offset(s * 0.17, s * 0.1),
    Offset(-s * 0.06, s * 0.17),
    Offset(-s * 0.2, s * 0.06),
    Offset(s * 0.02, -s * 0.01),
  ]) {
    canvas.drawCircle(d, s * 0.045, _fill(const Color(0xFF5A3A2A)));
  }
}

void _chips(Canvas canvas, double s) {
  void chip(Offset at, double angle, double scale) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final w = s * 0.36 * scale;
    final path = Path()
      ..moveTo(-w, 0)
      ..quadraticBezierTo(-w * 0.5, -w * 0.9, 0, -w * 0.75)
      ..quadraticBezierTo(w * 0.7, -w * 0.6, w, 0)
      ..quadraticBezierTo(w * 0.4, w * 0.75, 0, w * 0.6)
      ..quadraticBezierTo(-w * 0.6, w * 0.7, -w, 0)
      ..close();
    canvas.drawPath(path, _fill(const Color(0xFFF2C46B)));
    canvas.drawPath(path, _line(const Color(0xFFD9A441), s * 0.025));
    canvas.drawCircle(
        Offset(-w * 0.2, -w * 0.15), s * 0.018, _fill(const Color(0xFFD9A441)));
    canvas.drawCircle(
        Offset(w * 0.3, w * 0.1), s * 0.015, _fill(const Color(0xFFD9A441)));
    canvas.restore();
  }

  chip(Offset(-s * 0.12, s * 0.1), -0.3, 0.9);
  chip(Offset(s * 0.14, s * 0.08), 0.4, 0.85);
  chip(Offset(0, -s * 0.1), 0.05, 1);
}
