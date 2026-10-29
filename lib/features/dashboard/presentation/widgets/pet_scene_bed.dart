part of 'pet_scene.dart';

// ════════════════════════════════════════════════════════════════════════
// Settled in for the night
// ════════════════════════════════════════════════════════════════════════

/// Where its floor cushion goes and how far it's out: on the pet's own
/// spot, [bed] 0 (not there) → 1 (sitting on it). The pet, in its padded
/// jacket ([BlobMascot.jacket]), dozes on it.
class _BedLayout {
  final _Room room;

  /// How tall the pet's body is (sets the cushion's size).
  final double bodyHeight;
  final double bed;

  const _BedLayout(this.room, this.bodyHeight, this.bed);

  /// The pet's size at its life stage.
  double get k => bodyHeight / 0.74;
  double get cx => room.w / 2;
  double get ground => room.groundY;

  /// How much the cushion lifts the pet off the floor.
  double get seat => k * 0.075 * Curves.easeOut.transform(bed);
}

/// A zabuton — a square Japanese floor cushion — under the pet: plump,
/// brick red, stitched round the edge, with a cream tassel at each
/// corner. Seen from a little above, so it's a flattened square.
class _ZabutonPainter extends CustomPainter {
  final _BedLayout Function() layout;
  _ZabutonPainter(this.layout, {required Listenable repaint})
      : super(repaint: repaint);

  static const _top = Color(0xFFC95B4C);
  static const _side = Color(0xFFA6453A);
  static const _stitch = Color(0xFFF3E2C3);
  static const _tassel = Color(0xFFF6E7CC);

  @override
  void paint(Canvas canvas, Size size) {
    final l = layout();
    final t = Curves.easeOutBack.transform(l.bed.clamp(0.0, 1.0));
    if (t <= 0) return;
    final k = l.k;
    final alpha = l.bed.clamp(0.0, 1.0);
    // Its top: a square seen from above, wider at the front.
    final halfBack = k * 0.5, halfFront = k * 0.6;
    final depth = k * 0.34, thick = k * 0.09;
    final topY = l.ground - depth * 0.45;
    canvas.save();
    canvas.translate(l.cx, 0);
    canvas.translate(0, l.ground);
    canvas.scale(0.75 + 0.25 * t);
    canvas.translate(0, -l.ground);

    Path top(double lift) {
      final back = topY - lift, front = topY + depth - lift;
      final r = k * 0.07;
      return Path()
        ..moveTo(-halfBack + r, back)
        // Puffed up in the middle of each edge.
        ..quadraticBezierTo(0, back - k * 0.025, halfBack - r, back)
        ..quadraticBezierTo(halfBack, back, halfBack + k * 0.02, back + r)
        ..quadraticBezierTo((halfBack + halfFront) / 2 + k * 0.03,
            (back + front) / 2, halfFront, front - r)
        ..quadraticBezierTo(halfFront, front, halfFront - r, front + k * 0.01)
        ..quadraticBezierTo(
            0, front + k * 0.035, -halfFront + r, front + k * 0.01)
        ..quadraticBezierTo(-halfFront, front, -halfFront, front - r)
        ..quadraticBezierTo((-halfBack - halfFront) / 2 - k * 0.03,
            (back + front) / 2, -halfBack - k * 0.02, back + r)
        ..quadraticBezierTo(-halfBack, back, -halfBack + r, back)
        ..close();
    }

    final base = top(0);
    final upper = top(thick);
    // Its thickness: the top, and the same shape lower down, joined.
    final sides = Path.combine(PathOperation.union, base, upper);
    canvas.drawShadow(
        sides, Colors.black.withValues(alpha: 0.6 * alpha), 3, false);
    canvas.drawPath(sides, Paint()..color = _side.withValues(alpha: alpha));
    canvas.drawPath(
      upper,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          radius: 1.0,
          colors: [
            Color.lerp(_top, Colors.white, 0.16)!.withValues(alpha: alpha),
            _top.withValues(alpha: alpha),
          ],
        ).createShader(upper.getBounds()),
    );
    // Stitching round the edge of the top.
    final stitch = Paint()
      ..color = _stitch.withValues(alpha: 0.85 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = k * 0.012
      ..strokeCap = StrokeCap.round;
    final inset = upper
        .transform(Matrix4.diagonal3Values(0.84, 0.8, 1).storage)
        .shift(Offset(0, (topY - thick + depth / 2) * 0.2));
    for (final metric in inset.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += k * 0.05) {
        canvas.drawPath(metric.extractPath(d, d + k * 0.025), stitch);
      }
    }
    // A tassel at each corner.
    final tassel = Paint()..color = _tassel.withValues(alpha: alpha);
    for (final (x, y) in [
      (-halfBack, topY - thick),
      (halfBack, topY - thick),
      (-halfFront, topY + depth - thick),
      (halfFront, topY + depth - thick),
    ]) {
      final at = Offset(x, y);
      canvas.drawCircle(at, k * 0.028, tassel);
      canvas.drawLine(
          at,
          at + Offset(x.sign * k * 0.035, k * 0.04),
          Paint()
            ..color = _tassel.withValues(alpha: alpha)
            ..strokeWidth = k * 0.022
            ..strokeCap = StrokeCap.round);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ZabutonPainter old) => false;
}
