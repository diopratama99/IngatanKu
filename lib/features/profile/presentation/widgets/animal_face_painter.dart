import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/user_avatar.dart';

/// A little animal face for an avatar, drawn in the pet's style: soft
/// shaded shapes, round shiny eyes, rosy cheeks and a small "ω" mouth.
/// Laid out on a 100 × 100 grid, scaled to the canvas.
class AnimalFacePainter extends CustomPainter {
  final AvatarAnimal animal;
  const AnimalFacePainter(this.animal);

  static const _ink = Color(0xFF3B2F2A);
  static const _white = Color(0xFFFFFFFF);
  static const _cream = Color(0xFFFFF7EC);
  static const _beak = Color(0xFFF2A541);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    switch (animal) {
      case AvatarAnimal.cat:
        _cat(canvas);
      case AvatarAnimal.dog:
        _dog(canvas);
      case AvatarAnimal.bear:
        _bear(canvas);
      case AvatarAnimal.bunny:
        _bunny(canvas);
      case AvatarAnimal.panda:
        _panda(canvas);
      case AvatarAnimal.fox:
        _fox(canvas);
      case AvatarAnimal.frog:
        _frog(canvas);
      case AvatarAnimal.owl:
        _owl(canvas);
      case AvatarAnimal.koala:
        _koala(canvas);
      case AvatarAnimal.pig:
        _pig(canvas);
      case AvatarAnimal.penguin:
        _penguin(canvas);
      case AvatarAnimal.lion:
        _lion(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AnimalFacePainter old) => old.animal != animal;

  // ─── the animals ────────────────────────────────────────────────────

  void _cat(Canvas c) {
    const base = Color(0xFFF2B56B);
    const stripe = Color(0xFFD9893F);
    for (final sx in [-1.0, 1.0]) {
      _ear(c, sx, base, const Color(0xFFF6C3B8),
          tip: const Offset(27, 17), root: (23, 46), inner: 0.55);
    }
    final head =
        Rect.fromCenter(center: const Offset(50, 58), width: 66, height: 56);
    _shaded(c, head, base);
    // Tabby stripes on the forehead.
    final s = _stroke(stripe, 2.6);
    for (final x in [43.0, 50.0, 57.0]) {
      c.drawLine(Offset(x, 33), Offset(x, x == 50 ? 41 : 38.5), s);
    }
    _eyes(c, y: 56, dx: 12.5);
    _blush(c, y: 64, dx: 21);
    _nose(c, const Offset(50, 62.5), 5.5, const Color(0xFFF08C8C));
    _mouth(c, const Offset(50, 66), w: 3.6);
    // Whiskers.
    final w = _stroke(_ink.withValues(alpha: 0.32), 1);
    for (final sx in [-1.0, 1.0]) {
      c
        ..drawLine(Offset(50 + sx * 19, 63.5), Offset(50 + sx * 30, 61.5), w)
        ..drawLine(Offset(50 + sx * 19, 67), Offset(50 + sx * 30, 68.5), w);
    }
  }

  void _dog(Canvas c) {
    const base = Color(0xFFE3B07E);
    const ear = Color(0xFFA9744E);
    final head =
        Rect.fromCenter(center: const Offset(50, 56), width: 62, height: 58);
    _shaded(c, head, base);
    // A patch round one eye.
    c.drawOval(
        Rect.fromCenter(center: const Offset(62.5, 50), width: 15, height: 16),
        Paint()..color = const Color(0xFFC98F5E));
    // Floppy ears over the sides of the head.
    for (final sx in [-1.0, 1.0]) {
      c.save();
      c.translate(50 + sx * 27, 50);
      c.rotate(sx * -0.32);
      _shaded(
          c, Rect.fromCenter(center: Offset.zero, width: 17, height: 34), ear);
      c.restore();
    }
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 66), width: 30, height: 21),
        Paint()..color = _cream);
    _eyes(c, y: 52, dx: 12.5);
    _blush(c, y: 61, dx: 21);
    // A big shiny nose, and a tongue out.
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: const Offset(50, 72.5), width: 6.5, height: 6.5),
            const Radius.circular(3.2)),
        Paint()..color = const Color(0xFFF08A8A));
    _mouth(c, const Offset(50, 68.5), w: 3.6);
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 62), width: 10, height: 7),
        Paint()..color = _ink);
    c.drawCircle(const Offset(48, 60.6), 1.4, Paint()..color = _white);
  }

  void _bear(Canvas c) {
    const base = Color(0xFFB5835A);
    const light = Color(0xFFE6C29B);
    for (final sx in [-1.0, 1.0]) {
      final at = Offset(50 + sx * 23, 32);
      _shaded(c, Rect.fromCircle(center: at, radius: 11), base);
      c.drawCircle(at, 6, Paint()..color = light);
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 58), width: 64, height: 58),
        base);
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 67), width: 27, height: 20),
        Paint()..color = const Color(0xFFEDD0AC));
    _eyes(c, y: 55, dx: 12.5);
    _blush(c, y: 63, dx: 21);
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 63.5), width: 9.5, height: 7),
        Paint()..color = _ink);
    c.drawCircle(const Offset(48.3, 62.4), 1.3, Paint()..color = _white);
    _mouth(c, const Offset(50, 69), w: 3.4);
  }

  void _bunny(Canvas c) {
    const base = Color(0xFFF8F1E8);
    const pink = Color(0xFFF5B4C2);
    for (final sx in [-1.0, 1.0]) {
      c.save();
      c.translate(50 + sx * 12, 23);
      c.rotate(sx * 0.16);
      final ear = Rect.fromCenter(center: Offset.zero, width: 14, height: 40);
      _shaded(c, ear, base);
      _rim(c, ear, base);
      c.drawOval(
          Rect.fromCenter(center: const Offset(0, 2), width: 6.5, height: 29),
          Paint()..color = pink);
      c.restore();
    }
    final head =
        Rect.fromCenter(center: const Offset(50, 61), width: 62, height: 54);
    _shaded(c, head, base);
    _rim(c, head, base);
    _eyes(c, y: 59, dx: 11.5);
    _blush(c, y: 66.5, dx: 19, color: const Color(0xFFF59AAE));
    _nose(c, const Offset(50, 65.5), 4.6, const Color(0xFFF08FA4));
    _mouth(c, const Offset(50, 68.5), w: 3.2);
    // Two buck teeth.
    final teeth = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(50, 73), width: 6, height: 5),
        const Radius.circular(1.2));
    c
      ..drawRRect(teeth, Paint()..color = _white)
      ..drawRRect(teeth, _stroke(_ink.withValues(alpha: 0.35), 0.8))
      ..drawLine(const Offset(50, 70.6), const Offset(50, 75.4),
          _stroke(_ink.withValues(alpha: 0.35), 0.8));
  }

  void _panda(Canvas c) {
    const black = Color(0xFF34302F);
    const white = Color(0xFFFBFAF7);
    for (final sx in [-1.0, 1.0]) {
      _shaded(
          c,
          Rect.fromCircle(center: Offset(50 + sx * 22, 32), radius: 10.5),
          black);
    }
    final head =
        Rect.fromCenter(center: const Offset(50, 58), width: 66, height: 58);
    _shaded(c, head, white);
    _rim(c, head, const Color(0xFFD9D6D0));
    // Eye patches, and eyes that shine through them.
    for (final sx in [-1.0, 1.0]) {
      c.save();
      c.translate(50 + sx * 12, 56);
      c.rotate(sx * 0.55);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 14, height: 19),
          Paint()..color = black);
      c.restore();
      final eye = Offset(50 + sx * 12, 55.5);
      c.drawCircle(eye, 3.6, Paint()..color = _white);
      c.drawCircle(eye + const Offset(0.3, 0.4), 2.5, Paint()..color = _ink);
      c.drawCircle(
          eye + const Offset(-0.6, -0.8), 0.9, Paint()..color = _white);
    }
    _blush(c, y: 66, dx: 21);
    _nose(c, const Offset(50, 64), 6, black);
    _mouth(c, const Offset(50, 67.5), w: 3.4);
  }

  void _fox(Canvas c) {
    const base = Color(0xFFEE8D4A);
    const tip = Color(0xFF5A3A2A);
    for (final sx in [-1.0, 1.0]) {
      _ear(c, sx, base, const Color(0xFFF8D7BE),
          tip: const Offset(26, 13), root: (21, 47), inner: 0.5, tipColor: tip);
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 57), width: 68, height: 56),
        base);
    // White cheeks round a pointed chin.
    final cheeks = Paint()..color = _cream;
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(50 + sx * 13, 66), width: 27, height: 19),
          cheeks);
    }
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 71), width: 18, height: 14),
        cheeks);
    _eyes(c, y: 54.5, dx: 12.5);
    _blush(c, y: 63, dx: 22);
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 64.5), width: 7, height: 5),
        Paint()..color = _ink);
    _mouth(c, const Offset(50, 68), w: 3.2);
  }

  void _frog(Canvas c) {
    const base = Color(0xFF9CCB7E);
    // The bumps the eyes sit in, then the wide face.
    for (final sx in [-1.0, 1.0]) {
      _shaded(
          c,
          Rect.fromCircle(center: Offset(50 + sx * 16, 41), radius: 12.5),
          base);
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 62), width: 74, height: 50),
        base);
    for (final sx in [-1.0, 1.0]) {
      final eye = Offset(50 + sx * 16, 41);
      c.drawCircle(eye, 8.4, Paint()..color = _white);
      c.drawCircle(eye + const Offset(0, 0.8), 5, Paint()..color = _ink);
      c.drawCircle(
          eye + const Offset(-1.6, -1.2), 1.8, Paint()..color = _white);
    }
    _blush(c, y: 64, dx: 25);
    final nostril = Paint()..color = const Color(0xFF5E8A47);
    c
      ..drawCircle(const Offset(46.5, 57), 1.1, nostril)
      ..drawCircle(const Offset(53.5, 57), 1.1, nostril);
    final smile = Path()
      ..moveTo(36, 64.5)
      ..quadraticBezierTo(50, 75, 64, 64.5);
    c.drawPath(smile, _stroke(_ink, 1.7));
  }

  void _owl(Canvas c) {
    const base = Color(0xFFB08562);
    // Ear tufts.
    for (final sx in [-1.0, 1.0]) {
      final tuft = Path()
        ..moveTo(50 + sx * 26, 40)
        ..lineTo(50 + sx * 23, 15)
        ..lineTo(50 + sx * 8, 31)
        ..close();
      c.drawPath(tuft, Paint()..color = base);
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 58), width: 66, height: 60),
        base);
    // The two pale discs round its eyes.
    final disc = Paint()..color = const Color(0xFFF3E0C8);
    for (final sx in [-1.0, 1.0]) {
      c.drawCircle(Offset(50 + sx * 11.5, 54), 13, disc);
    }
    for (final sx in [-1.0, 1.0]) {
      final eye = Offset(50 + sx * 11.5, 54);
      c.drawCircle(eye, 6, Paint()..color = _ink);
      c.drawCircle(eye + const Offset(-1.9, -2), 2.1, Paint()..color = _white);
      c.drawCircle(eye + const Offset(1.8, 2), 0.9, Paint()..color = _white);
    }
    final beak = Path()
      ..moveTo(45.5, 62)
      ..lineTo(54.5, 62)
      ..lineTo(50, 69.5)
      ..close();
    c
      ..drawPath(beak, Paint()..color = _beak)
      ..drawPath(
          beak,
          Paint()
            ..color = _beak
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round);
    _blush(c, y: 68, dx: 21);
    // A few feathers on its front.
    final feather = _stroke(const Color(0xFF8F6A4C), 1.3);
    for (final x in [42.0, 50.0, 58.0]) {
      c.drawArc(Rect.fromCenter(center: Offset(x, 77), width: 6, height: 4), 0,
          math.pi, false, feather);
    }
  }

  void _koala(Canvas c) {
    const base = Color(0xFFA9AFB8);
    for (final sx in [-1.0, 1.0]) {
      final at = Offset(50 + sx * 27, 38);
      _shaded(c, Rect.fromCircle(center: at, radius: 15), base);
      c.drawCircle(at + Offset(sx * 1.5, 1), 9.5,
          Paint()..color = const Color(0xFFE7E9ED));
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 59), width: 62, height: 56),
        base);
    _eyes(c, y: 55, dx: 14.5, r: 3.9);
    _blush(c, y: 65, dx: 21);
    final nose = Rect.fromCenter(
        center: const Offset(50, 62), width: 12.5, height: 15.5);
    _shaded(c, nose, const Color(0xFF4A4246));
    c.drawOval(
        Rect.fromCenter(
            center: const Offset(47.5, 58), width: 3.4, height: 4.4),
        Paint()..color = _white.withValues(alpha: 0.55));
    _mouth(c, const Offset(50, 72.5), w: 3);
  }

  void _pig(Canvas c) {
    const base = Color(0xFFF7BDBD);
    for (final sx in [-1.0, 1.0]) {
      _ear(c, sx, const Color(0xFFF5AFB1), const Color(0xFFEC95A0),
          tip: const Offset(26, 22), root: (22, 44), inner: 0.5);
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 58), width: 66, height: 58),
        base);
    _eyes(c, y: 52.5, dx: 13);
    _blush(c, y: 61, dx: 23, color: const Color(0xFFF0868F));
    final snout =
        Rect.fromCenter(center: const Offset(50, 64), width: 21, height: 14.5);
    _shaded(c, snout, const Color(0xFFF29CA4));
    _rim(c, snout, const Color(0xFFF29CA4));
    final nostril = Paint()..color = const Color(0xFFB45C68);
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(50 + sx * 3.8, 64), width: 3, height: 4.6),
          nostril);
    }
    _mouth(c, const Offset(50, 73.5), w: 3);
  }

  void _penguin(Canvas c) {
    const navy = Color(0xFF3E4A5E);
    const white = Color(0xFFFBFAF7);
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 57), width: 66, height: 62),
        navy);
    // A tuft on top.
    final tuft = _stroke(navy, 2.4);
    c
      ..drawLine(const Offset(50, 28), const Offset(48, 21), tuft)
      ..drawLine(const Offset(50, 28), const Offset(54, 22), tuft);
    // Its white face, heart-shaped.
    final face = Paint()..color = white;
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(50 + sx * 10, 59), width: 27, height: 32),
          face);
    }
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 69), width: 30, height: 18),
        face);
    _eyes(c, y: 57, dx: 10.5, r: 3.9);
    _blush(c, y: 65, dx: 17);
    final beak = Path()
      ..moveTo(45.5, 63)
      ..lineTo(54.5, 63)
      ..lineTo(50, 69)
      ..close();
    c
      ..drawPath(beak, Paint()..color = _beak)
      ..drawPath(
          beak,
          Paint()
            ..color = _beak
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeJoin = StrokeJoin.round);
  }

  void _lion(Canvas c) {
    const mane = Color(0xFFD98744);
    const face = Color(0xFFF5C46E);
    // The mane: a ring of round tufts.
    final maneShade = Paint()..color = Color.lerp(mane, Colors.black, 0.08)!;
    c.drawCircle(const Offset(50, 57), 32, maneShade);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawCircle(Offset(50 + math.cos(a) * 30, 57 + math.sin(a) * 30), 10.5,
          Paint()..color = mane);
    }
    for (final sx in [-1.0, 1.0]) {
      final at = Offset(50 + sx * 17, 37);
      c.drawCircle(at, 7, Paint()..color = face);
      c.drawCircle(at, 3.8, Paint()..color = const Color(0xFFE6A25A));
    }
    _shaded(
        c,
        Rect.fromCenter(center: const Offset(50, 59), width: 50, height: 46),
        face);
    c.drawOval(
        Rect.fromCenter(center: const Offset(50, 67), width: 23, height: 15),
        Paint()..color = const Color(0xFFFBE3B6));
    _eyes(c, y: 56.5, dx: 10.5, r: 3.9);
    _blush(c, y: 64, dx: 17);
    _nose(c, const Offset(50, 63.5), 6, const Color(0xFF7A4B2E));
    _mouth(c, const Offset(50, 67.5), w: 3.2);
  }

  // ─── the bits they share ────────────────────────────────────────────

  /// A shape filled with [base], lit softly from the top left.
  void _shaded(Canvas c, Rect r, Color base) {
    c.drawOval(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [
            Color.lerp(base, _white, 0.2)!,
            base,
            Color.lerp(base, Colors.black, 0.07)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(r),
    );
  }

  /// A faint edge, for pale shapes on pale paper.
  void _rim(Canvas c, Rect r, Color base) => c.drawOval(
      r,
      _stroke(
          Color.lerp(base, Colors.black, 0.25)!.withValues(alpha: 0.5), 1.1));

  /// A pointed ear on side [sx] (-1 left, 1 right), laid out for the
  /// left and mirrored: [tip] its point, [root] the outer corner of its
  /// base (its inner corner is towards the middle of the head), [inner]
  /// how big the inside of it is, and the point coloured [tipColor].
  void _ear(Canvas c, double sx, Color base, Color innerColor,
      {required Offset tip,
      required (double, double) root,
      required double inner,
      Color? tipColor}) {
    Offset m(Offset p) => Offset(50 - sx * (p.dx - 50), p.dy);
    Path tri(Offset p, Offset q, Offset r) => Path()
      ..moveTo(m(p).dx, m(p).dy)
      ..lineTo(m(q).dx, m(q).dy)
      ..lineTo(m(r).dx, m(r).dy)
      ..close();
    void fill(Path path, Color color) => c
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeJoin = StrokeJoin.round);
    final a = Offset(root.$1, root.$2);
    final b = tip;
    const d = Offset(46, 33);
    fill(tri(a, b, d), base);
    if (tipColor != null) {
      fill(
          tri(b, Offset.lerp(b, a, 0.36)!, Offset.lerp(b, d, 0.36)!), tipColor);
    }
    // The inside, smaller and a little lower.
    final mid = Offset((a.dx + b.dx + d.dx) / 3, (a.dy + b.dy + d.dy) / 3);
    Offset shrink(Offset p) => mid + (p - mid) * inner + const Offset(0, 2);
    c.drawPath(
        tri(shrink(a), shrink(b), shrink(d)), Paint()..color = innerColor);
  }

  /// Round, dark, shiny eyes, [dx] either side of the middle at [y].
  void _eyes(Canvas c,
      {required double y, required double dx, double r = 4.2}) {
    for (final sx in [-1.0, 1.0]) {
      final at = Offset(50 + sx * dx, y);
      c.drawOval(Rect.fromCenter(center: at, width: r * 2, height: r * 2.3),
          Paint()..color = _ink);
      c.drawCircle(
          at + Offset(-r * 0.32, -r * 0.48), r * 0.4, Paint()..color = _white);
      c.drawCircle(at + Offset(r * 0.38, r * 0.45), r * 0.17,
          Paint()..color = _white.withValues(alpha: 0.85));
    }
  }

  void _blush(Canvas c, {required double y, required double dx, Color? color}) {
    final paint = Paint()
      ..color = (color ?? const Color(0xFFF49A9A)).withValues(alpha: 0.5);
    for (final sx in [-1.0, 1.0]) {
      c.drawOval(
          Rect.fromCenter(
              center: Offset(50 + sx * dx, y), width: 8, height: 4.6),
          paint);
    }
  }

  /// A small rounded triangle nose, point down.
  void _nose(Canvas c, Offset at, double w, Color color) {
    final p = Path()
      ..moveTo(at.dx - w / 2, at.dy - w * 0.3)
      ..lineTo(at.dx + w / 2, at.dy - w * 0.3)
      ..lineTo(at.dx, at.dy + w * 0.35)
      ..close();
    c
      ..drawPath(p, Paint()..color = color)
      ..drawPath(
          p,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = w * 0.3
            ..strokeJoin = StrokeJoin.round);
  }

  /// The little "ω" mouth.
  void _mouth(Canvas c, Offset at, {double w = 3.5}) {
    final p = Path()
      ..moveTo(at.dx - w, at.dy)
      ..quadraticBezierTo(at.dx - w / 2, at.dy + w * 0.95, at.dx, at.dy)
      ..quadraticBezierTo(at.dx + w / 2, at.dy + w * 0.95, at.dx + w, at.dy);
    c.drawPath(p, _stroke(_ink, 1.5));
  }

  static Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
}
