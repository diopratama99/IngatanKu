part of 'blob_mascot.dart';

// ════════════════════════════════════════════════════════════════════════
// Painter
// ════════════════════════════════════════════════════════════════════════

class _BlobPainter extends CustomPainter {
  final _BlobMascotState state;
  final BlobColor color;
  final BlobAccessory accessory;
  final BlobOutfit outfit;
  final PetStage stage;
  final CompanionMood mood;

  _BlobPainter({
    required this.state,
    required this.color,
    required this.accessory,
    required this.outfit,
    required this.stage,
    required this.mood,
    required Listenable repaint,
  }) : super(repaint: repaint);

  static const _ink = Color(0xFF2A2520);
  static const _blush = Color(0xFFF08A8A);

  @override
  void paint(Canvas canvas, Size size) {
    final p = state._pose;
    final s = state._s;
    final cx = size.width / 2;
    final ground = state._groundY;
    final scale = state._scale;
    final rx = s * 0.42;
    final ry = s * 0.37;

    final air = (p.jump / (s * 0.5)).clamp(0.0, 1.0);
    final footprint = (p.egg ? 0.62 : 1.0) * scale;
    // Carried around, the parent draws the shadow on the floor instead.
    if (!p.held) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, ground),
          width: rx * 1.9 * footprint * (1 - air * 0.45),
          height: s * 0.09 * footprint * (1 - air * 0.45),
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.13 * (1 - air * 0.6)),
      );
    }

    canvas.save();
    canvas.translate(cx + p.shakeX, ground - p.jump);
    canvas.rotate(p.tilt);
    // Rolling: turned about the middle of its (now round) body.
    if (p.roll != 0) {
      final mid = -ry * scale * (1 - p.squash);
      canvas.translate(0, mid);
      canvas.rotate(p.roll);
      canvas.translate(0, -mid);
    }
    // Twirling: squeezed side to side, mirrored while it shows its back.
    final turn = p.turn.abs() < 0.06 ? 0.06 * p.turn.sign : p.turn;
    canvas.scale(scale * (1 + p.squash) * turn, scale * (1 - p.squash));

    if (p.egg) {
      _paintEgg(canvas, p, s);
    } else {
      // Curled up into a ball, its arms and feet are tucked in.
      final tucked = p.ball > 0.5;
      // Its sleeping parka covers whatever it's wearing.
      final dressed = p.jacket == 0;
      // In sleeves, its arms come in front (below); bare, they peek out
      // from behind.
      final sleeved = dressed && _sleeve != null;
      final arms = state.widget.showArms && !tucked;
      if (arms && !sleeved) _paintArms(canvas, p, s, rx, ry);
      if (!tucked) _paintFeet(canvas, p, s, rx);
      // A tail or wings stick out from behind.
      if (dressed) _paintOutfitBehind(canvas, p, s, rx, ry);
      final body = _bodyPath(p.t, rx, ry,
          wobble: state.widget.animate, ball: p.ball);
      _paintBody(canvas, body, rx, ry);
      if (p.bruise > 0) _paintBump(canvas, p, s, rx, ry);
      if (p.jacket > 0) {
        _paintJacket(canvas, body, s, rx, ry, p.jacket);
      } else {
        _paintOutfit(canvas, p, body, s, rx, ry);
        if (accessory == BlobAccessory.scarf) {
          _paintScarf(canvas, body, s, rx, ry);
        }
        if (arms && sleeved) _paintSleeves(canvas, p, s, rx, ry);
      }
      if (state.widget.showArms && p.armRight > 0.3) {
        _paintWavingHand(canvas, p, s, rx, ry);
      }
      // Its face only shows from the front.
      if (p.turn > 0) _paintFace(canvas, p, s, ry);
      // A hood or helmet takes the place of a hat.
      if (!dressed || !outfit.coversHead) _paintAccessory(canvas, p, s, rx, ry);
      if (dressed) _paintOutfitOver(canvas, p, s, rx, ry);
      if (p.turn > 0) _paintExpressionExtras(canvas, p, s, rx, ry);
    }

    canvas.restore();

    if (p.food != null) _paintFlyingFood(canvas, p, s, cx, ground);
    if (p.slurp != null) _paintSlurp(canvas, p, s, cx, ground);
    for (final part in state._particles) {
      _paintParticle(canvas, part, state._t, s);
    }
  }

  // ─── egg ────────────────────────────────────────────────────────────

  void _paintEgg(Canvas canvas, _Pose p, double s) {
    final ex = s * 0.32;
    final ey = s * 0.42;
    final path = Path();
    const n = 72;
    for (var i = 0; i <= n; i++) {
      final th = i / n * 2 * math.pi;
      final sn = math.sin(th);
      // Narrower toward the top (sin < 0 is up).
      final x = ex * math.cos(th) * (sn < 0 ? 1 + 0.2 * sn : 1);
      final y = ey * sn - ey;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    final bounds = Rect.fromLTRB(-ex, -2 * ey, ex, 0);
    final shell = Color.lerp(color.base, Colors.white, 0.62)!;
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [Colors.white, shell, Color.lerp(shell, color.shade, 0.35)!],
          stops: const [0, 0.55, 1],
        ).createShader(bounds),
    );
    canvas.save();
    canvas.clipPath(path);
    final spot = Paint()..color = color.base.withValues(alpha: 0.75);
    for (final o in [
      Offset(-ex * 0.4, -ey * 1.45),
      Offset(ex * 0.45, -ey * 1.1),
      Offset(-ex * 0.2, -ey * 0.55),
      Offset(ex * 0.15, -ey * 1.7),
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: o, width: s * 0.1, height: s * 0.075), spot);
    }
    canvas.restore();
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = color.shade.withValues(alpha: 0.45),
    );
    // Glossy highlight.
    canvas.save();
    canvas.translate(-ex * 0.42, -ey * 1.5);
    canvas.rotate(-0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: ex * 0.42, height: ey * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    canvas.restore();

    if (p.crack > 0) {
      // Zigzag crack that spreads from the left as hatching progresses.
      final pts = <Offset>[];
      const steps = 8;
      for (var i = 0; i <= steps; i++) {
        final x = -ex * 0.95 + (ex * 1.9) * i / steps;
        final y = -ey * 1.05 + (i.isEven ? -s * 0.03 : s * 0.03);
        pts.add(Offset(x, y));
      }
      final shown = (p.crack * steps).ceil().clamp(1, steps);
      final crack = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i <= shown; i++) {
        crack.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(
        crack,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.016
          ..strokeJoin = StrokeJoin.round
          ..color = _ink.withValues(alpha: 0.7),
      );
    }
  }

  // ─── body ───────────────────────────────────────────────────────────

  /// Superellipse with a rounder top (n≈2.1) and a flatter, sitting
  /// bottom (n≈3.2) — or, curled up into a [ball], an ellipse all round.
  /// Origin is bottom-centre, y grows downward.
  Path _bodyPath(double t, double rx, double ry,
      {required bool wobble, double ball = 0}) {
    const n = 96;
    final path = Path();
    for (var i = 0; i <= n; i++) {
      final th = i / n * 2 * math.pi;
      final c = math.cos(th);
      final sn = math.sin(th);
      final e = (sn > 0 ? 2 / 3.2 : 2 / 2.1) * (1 - ball) + ball;
      var x = rx * c.sign * math.pow(c.abs(), e);
      var y = ry * sn.sign * math.pow(sn.abs(), e);
      if (wobble) {
        final w = 1 +
            0.012 * math.sin(3 * th + 2.1 * t) +
            0.007 * math.sin(5 * th - 1.3 * t);
        x *= w;
        y *= w;
      }
      final pt = Offset(x, y - ry);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  void _paintBody(Canvas canvas, Path body, double rx, double ry) {
    final bounds = Rect.fromLTRB(-rx, -2 * ry, rx, 0);
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          radius: 1.05,
          colors: [
            Color.lerp(color.base, Colors.white, 0.28)!,
            color.base,
            color.shade,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(bounds),
    );
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.028
        ..color = color.shade.withValues(alpha: 0.55),
    );
    canvas.save();
    canvas.translate(-rx * 0.42, -ry * 1.58);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 0.42, height: ry * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.42),
    );
    canvas.restore();
  }

  /// A sore bump swelling up on top of its head.
  void _paintBump(Canvas canvas, _Pose p, double s, double rx, double ry) {
    final b = p.bruise;
    final r = s * 0.055 * (0.6 + 0.4 * b);
    final c = Offset(-rx * 0.3, -2 * ry + s * 0.035 - r * 0.3);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = Color.lerp(color.base, const Color(0xFFEF7F86), 0.6)!
            .withValues(alpha: b),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = rx * 0.028
        ..color = color.shade.withValues(alpha: 0.55 * b),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: c + Offset(-r * 0.3, -r * 0.35),
          width: r * 0.55,
          height: r * 0.3),
      Paint()..color = Colors.white.withValues(alpha: 0.5 * b),
    );
  }

  void _paintFeet(Canvas canvas, _Pose p, double s, double rx) {
    final paint = Paint()..color = color.shade;
    for (final dir in [-1.0, 1.0]) {
      // Dangling (and kicking a little) while it's held up.
      final dangle = p.held
          ? Offset(math.sin(p.t * 9 + dir) * s * 0.015, s * 0.035)
          : Offset.zero;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dir * rx * 0.42, -s * 0.012) + dangle,
          width: s * 0.17,
          height: s * 0.075,
        ),
        paint,
      );
    }
  }

  void _paintArms(Canvas canvas, _Pose p, double s, double rx, double ry) {
    // In its jacket, its arms are in the sleeves.
    final paint = Paint()
      ..color = Color.lerp(_sleeve ?? color.shade, _jacketSleeve, p.jacket)!;
    for (final dir in [-1.0, 1.0]) {
      // A waving hand is drawn in front of the body instead.
      if (dir > 0 && p.armRight > 0.3) continue;
      final raise = dir > 0 && p.armRight >= 0 ? p.armRight : p.arm;
      canvas.save();
      canvas.translate(dir * rx * 0.9, -ry * (0.8 + 0.45 * raise));
      canvas.rotate(dir * (0.5 - 1.3 * raise) + (dir > 0 ? p.armWave : 0));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dir * s * 0.03, 0),
          width: s * 0.13,
          height: s * 0.085,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  /// A hand raised up by the side of its head, swinging hello.
  void _paintWavingHand(
      Canvas canvas, _Pose p, double s, double rx, double ry) {
    final up = (p.armRight / 1.3).clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(rx * (0.8 + 0.12 * up), -ry * (0.95 + 0.7 * up));
    canvas.rotate(-0.35 * up + p.armWave);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, -s * 0.03 * up),
        width: s * 0.11,
        height: s * 0.155,
      ),
      Paint()..color = _sleeve ?? color.shade,
    );
    // Out of a sleeve, its hand shows at the end.
    if (_sleeve != null && p.jacket == 0) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -s * 0.03 * up - s * 0.075),
          width: s * 0.06,
          height: s * 0.055,
        ),
        Paint()..color = color.shade,
      );
    }
    canvas.restore();
  }

  // ─── face ───────────────────────────────────────────────────────────

  void _paintFace(Canvas canvas, _Pose p, double s, double ry) {
    final look = p.look;
    final face = Offset(look.dx * s * 0.03, -ry * 1.08 + look.dy * s * 0.02);
    final eyeShift = Offset(look.dx * s * 0.016, look.dy * s * 0.012);

    final expr = p.eyes == _Eyes.open ? p.expr : null;
    final glow = mood == CompanionMood.happy || p.eyes == _Eyes.happy;
    final puff = 1 + 0.35 * p.cheekPuff;
    final blush = Paint()
      ..color = switch (expr) {
        BlobExpression.angry => const Color(0xFFE8605A).withValues(alpha: 0.6),
        BlobExpression.scared => _blush.withValues(alpha: 0.16),
        BlobExpression.yuck => _blush.withValues(alpha: 0.12),
        _ => _blush.withValues(alpha: glow ? 0.5 : 0.34),
      };
    for (final dir in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: face + Offset(dir * s * 0.2, s * 0.07),
          width: s * 0.09 * puff,
          height: s * 0.052 * puff,
        ),
        blush,
      );
    }

    final boost = stage.eyeBoost;
    final ew = s * 0.068 * boost;
    final eh = s * 0.092 * boost;
    final glasses = accessory == BlobAccessory.glasses || state.widget.glasses;
    if (p.bruise > 0) _paintBruises(canvas, p, s, face, eyeShift, ew, eh);
    // Brows sit above the rims when it wears glasses.
    final browUp = Offset(0, glasses ? -s * 0.03 : 0);
    for (final dir in [-1.0, 1.0]) {
      final c = face + Offset(dir * s * 0.12, 0) + eyeShift;
      _paintEye(canvas, p, expr, c, dir, ew, eh, s);
      final brow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round
        ..color = _ink;
      switch (expr) {
        case BlobExpression.angry:
          // Pulled down hard towards the middle.
          canvas.drawLine(
            c + Offset(dir * ew * 0.95, -eh * 0.98) + browUp,
            c + Offset(-dir * ew * 0.55, -eh * 0.5) + browUp,
            brow..strokeWidth = s * 0.022,
          );
        case BlobExpression.serious:
          canvas.drawLine(
            c + Offset(dir * ew * 0.85, -eh * 0.8) + browUp,
            c + Offset(-dir * ew * 0.55, -eh * 0.68) + browUp,
            brow,
          );
        case BlobExpression.surprised:
          canvas.drawPath(
            Path()
              ..moveTo(c.dx - ew * 0.6, c.dy - eh * 1.0 + browUp.dy)
              ..quadraticBezierTo(c.dx, c.dy - eh * 1.35 + browUp.dy,
                  c.dx + ew * 0.6, c.dy - eh * 1.0 + browUp.dy),
            brow,
          );
        case BlobExpression.smirk:
          if (dir > 0) {
            // One brow cocked high…
            canvas.drawPath(
              Path()
                ..moveTo(c.dx - ew * 0.6, c.dy - eh * 1.05 + browUp.dy)
                ..quadraticBezierTo(c.dx, c.dy - eh * 1.5 + browUp.dy,
                    c.dx + ew * 0.7, c.dy - eh * 1.15 + browUp.dy),
              brow,
            );
          } else {
            // …the other low and flat.
            canvas.drawLine(
              c + Offset(-ew * 0.65, -eh * 0.72) + browUp,
              c + Offset(ew * 0.6, -eh * 0.62) + browUp,
              brow,
            );
          }
        default:
          if (p.sadBrows) {
            // Inner end raised — the classic worried look.
            canvas.drawLine(
              c + Offset(dir * ew * 0.75, -eh * 0.95) + browUp,
              c + Offset(-dir * ew * 0.45, -eh * 1.2) + browUp,
              brow,
            );
          }
      }
    }

    if (p.expr == BlobExpression.crying) {
      _paintTearStreams(canvas, p, s, face, eyeShift, eh);
    }

    // A tear rolling down from the outer corner of the left eye.
    if (expr == BlobExpression.sad) {
      final q = (p.t % 2.2) / 2.2;
      final start = face + Offset(-s * 0.12 - ew * 0.5, eh * 0.3) + eyeShift;
      _drop(canvas, start + Offset(-s * 0.01 * q, s * 0.1 * q),
          s * 0.02 * (0.6 + 0.4 * math.min(q * 4, 1)), _tear, 1 - q * q);
    }

    if (glasses) {
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.014
        ..color = const Color(0xFF3B332B);
      final lens = Paint()..color = Colors.white.withValues(alpha: 0.16);
      final l = face + Offset(-s * 0.12, 0) + eyeShift;
      final r = face + Offset(s * 0.12, 0) + eyeShift;
      for (final c in [l, r]) {
        canvas.drawCircle(c, s * 0.078, lens);
        canvas.drawCircle(c, s * 0.078, rim);
      }
      canvas.drawPath(
        Path()
          ..moveTo(l.dx + s * 0.078, l.dy - s * 0.01)
          ..quadraticBezierTo(face.dx + eyeShift.dx, l.dy - s * 0.04,
              r.dx - s * 0.078, r.dy - s * 0.01),
        rim,
      );
    }

    final m = face + Offset(0, s * 0.085);
    _paintMouth(canvas, p, s, m);
    // Drool gathering at the corner of a hungry mouth.
    if (expr == BlobExpression.hungry && p.mouth == _Mouth.open) {
      final q = (p.t % 2.6) / 2.6;
      _drop(canvas, m + Offset(s * 0.028, s * 0.03 + s * 0.035 * q),
          s * 0.012 * (0.6 + 0.6 * q), _drool, q > 0.85 ? (1 - q) / 0.15 : 1);
    }
  }

  static const _tear = Color(0xFF9FD3F2);
  static const _drool = Color(0xFFCFE6F5);

  /// Beaten up: a purple shiner round its right eye and a plaster stuck
  /// on its left cheek.
  void _paintBruises(Canvas canvas, _Pose p, double s, Offset face,
      Offset eyeShift, double ew, double eh) {
    final b = p.bruise;
    const purple = Color(0xFF7B5EA7);
    final eye = face + Offset(s * 0.12, 0) + eyeShift;
    final shiner =
        Rect.fromCenter(center: eye, width: ew * 2.4, height: eh * 1.8);
    canvas.drawOval(
      shiner,
      Paint()
        ..shader = RadialGradient(
          colors: [
            purple.withValues(alpha: 0.7 * b),
            purple.withValues(alpha: 0.5 * b),
            purple.withValues(alpha: 0),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(shiner),
    );
    canvas.save();
    canvas.translate(face.dx - s * 0.19, face.dy + s * 0.075);
    canvas.rotate(-0.45);
    final strip = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: s * 0.12, height: s * 0.042),
      Radius.circular(s * 0.02),
    );
    canvas.drawRRect(
        strip, Paint()..color = const Color(0xFFF2D1A2).withValues(alpha: b));
    canvas.drawRRect(
      strip,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.006
        ..color = const Color(0xFFD5A86F).withValues(alpha: b),
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: s * 0.038, height: s * 0.03),
      Paint()..color = const Color(0xFFE3B67E).withValues(alpha: b),
    );
    final dot = Paint()..color = const Color(0xFFC99A60).withValues(alpha: b);
    for (final x in [-0.04, 0.04]) {
      canvas.drawCircle(Offset(s * x, 0), s * 0.004, dot);
    }
    canvas.restore();
  }

  /// Two streams of tears running down its cheeks, wavering.
  void _paintTearStreams(Canvas canvas, _Pose p, double s, Offset face,
      Offset eyeShift, double eh) {
    final width = s * (p.squint ? 0.026 : 0.018);
    for (final dir in [-1.0, 1.0]) {
      final top = face + Offset(dir * s * 0.13, eh * 0.45) + eyeShift;
      final bottom = s * 0.24;
      final path = Path();
      const n = 12;
      for (var i = 0; i <= n; i++) {
        final y = bottom * i / n;
        final x = math.sin(p.t * 9 + y / s * 18 + dir) * s * 0.006;
        final pt = top + Offset(x - width / 2, y);
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      for (var i = n; i >= 0; i--) {
        final y = bottom * i / n;
        final x = math.sin(p.t * 9 + y / s * 18 + dir) * s * 0.006;
        final pt = top + Offset(x + width / 2, y);
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = _tear.withValues(alpha: 0.75));
      canvas.drawLine(
        top + Offset(-width * 0.15, s * 0.01),
        top + Offset(-width * 0.15, bottom * 0.7),
        Paint()
          ..strokeWidth = width * 0.25
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.45),
      );
    }
  }

  void _paintEye(Canvas canvas, _Pose p, BlobExpression? expr, Offset c,
      double dir, double ew, double eh, double s) {
    final ink = Paint()..color = _ink;
    final white = Paint()..color = Colors.white;
    final closedByBlink =
        p.eyeOpen < 0.2 &&
            p.eyes == _Eyes.open &&
            expr != BlobExpression.dizzy &&
            expr != BlobExpression.yuck &&
            expr != BlobExpression.crying;
    if (p.squint) {
      _paintSquint(canvas, c, dir, ew, eh, s);
      return;
    }
    if (p.eyes == _Eyes.happy) {
      _strokeCurve(canvas, c, ew, eh, up: true, width: s * 0.022);
      return;
    }
    if (p.eyes == _Eyes.closed || closedByBlink) {
      _strokeCurve(canvas, c, ew, eh, up: false, width: s * 0.02);
      return;
    }
    final h = eh * p.eyeOpen;
    switch (expr) {
      case BlobExpression.dizzy:
        // Spinning spirals.
        final spiral = Path();
        const n = 36;
        final rot = p.t * 7 * dir;
        for (var i = 0; i <= n; i++) {
          final q = i / n;
          final a = rot + q * 2.4 * 2 * math.pi;
          final r = ew * 0.8 * q;
          final pt = c + Offset(math.cos(a) * r, math.sin(a) * r * 1.15);
          i == 0 ? spiral.moveTo(pt.dx, pt.dy) : spiral.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(
            spiral,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.014
              ..strokeCap = StrokeCap.round
              ..color = _ink);
      case BlobExpression.scared:
        // Wide whites with tiny, jittery pupils.
        final ball = Rect.fromCenter(
            center: c, width: ew * 1.4, height: eh * 1.2 * p.eyeOpen);
        canvas.drawOval(ball, white);
        canvas.drawOval(
            ball,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.012
              ..color = _ink);
        canvas.drawCircle(
            c + Offset(math.sin(p.t * 40 + dir) * ew * 0.06, eh * 0.14),
            ew * 0.27,
            ink);
      case BlobExpression.angry:
        // A slanted lid cuts off the inner top of each eye.
        final inner = c + Offset(-dir * ew * 0.75, -eh * 0.05);
        final outer = c + Offset(dir * ew * 0.75, -eh * 0.42);
        final a = inner + (inner - outer) * 0.6;
        final b = outer + (outer - inner) * 0.6;
        canvas.save();
        canvas.clipPath(Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b.dx, c.dy + eh)
          ..lineTo(a.dx, c.dy + eh)
          ..close());
        canvas.drawOval(Rect.fromCenter(center: c, width: ew, height: h), ink);
        canvas.restore();
        canvas.drawCircle(
            c + Offset(dir * ew * 0.1, h * 0.12), ew * 0.13, white);
      case BlobExpression.serious:
        // Narrowed, focused.
        final hh = h * 0.55;
        canvas.drawOval(
            Rect.fromCenter(
                center: c + Offset(0, eh * 0.1), width: ew, height: hh),
            ink);
        canvas.drawCircle(c + Offset(-ew * 0.16, eh * 0.04), ew * 0.13, white);
      case BlobExpression.smirk:
        // Half-lidded: the top of each eye cut off by a flat lid.
        final lid = c.dy - h * 0.05;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(c.dx - ew, lid, c.dx + ew, c.dy + eh));
        canvas.drawOval(Rect.fromCenter(center: c, width: ew, height: h), ink);
        canvas.restore();
        canvas.drawLine(
          Offset(c.dx - ew * 0.62, lid),
          Offset(c.dx + ew * 0.62, lid),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = s * 0.018
            ..color = _ink,
        );
        canvas.drawCircle(c + Offset(ew * 0.12, h * 0.2), ew * 0.12, white);
      case BlobExpression.yuck:
        _paintSquint(canvas, c, dir, ew, eh, s);
      case BlobExpression.crying:
        // Swimming with tears: big wet shines, a pool along the lid.
        canvas.drawOval(Rect.fromCenter(center: c, width: ew, height: h), ink);
        canvas.drawCircle(
            c + Offset(-ew * 0.18, -h * 0.22), ew * 0.3, white);
        canvas.drawCircle(c + Offset(ew * 0.16, h * 0.18), ew * 0.13, white);
        canvas.drawOval(
          Rect.fromCenter(
              center: c + Offset(0, h * 0.42),
              width: ew * 1.3,
              height: eh * 0.32),
          Paint()..color = _tear.withValues(alpha: 0.85),
        );
      case BlobExpression.surprised:
        final big =
            Rect.fromCenter(center: c, width: ew * 1.2, height: h * 1.15);
        canvas.drawOval(big, ink);
        if (p.eyeOpen > 0.6) {
          canvas.drawCircle(c + Offset(-ew * 0.2, -h * 0.25), ew * 0.26, white);
          canvas.drawCircle(c + Offset(ew * 0.18, h * 0.22), ew * 0.1, white);
        }
      default:
        canvas.drawOval(Rect.fromCenter(center: c, width: ew, height: h), ink);
        if (p.eyeOpen > 0.6) {
          // Sad eyes are glassier: bigger shine.
          final wet = expr == BlobExpression.sad ? 1.35 : 1.0;
          canvas.drawCircle(
              c + Offset(-ew * 0.18, -h * 0.22), ew * 0.22 * wet, white);
          canvas.drawCircle(
              c + Offset(ew * 0.16, h * 0.2), ew * 0.09 * wet, white);
        }
    }
  }

  /// "> <": screwed up tight, pointing in.
  void _paintSquint(
      Canvas canvas, Offset c, double dir, double ew, double eh, double s) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx + dir * ew * 0.5, c.dy - eh * 0.36)
        ..lineTo(c.dx - dir * ew * 0.4, c.dy)
        ..lineTo(c.dx + dir * ew * 0.5, c.dy + eh * 0.36),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = s * 0.02
        ..color = _ink,
    );
  }

  /// A drop (tear, sweat, drool) with its point up.
  void _drop(Canvas canvas, Offset c, double r, Color color, double alpha) {
    if (alpha <= 0) return;
    final paint = Paint()..color = color.withValues(alpha: alpha);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r * 2)
        ..quadraticBezierTo(c.dx + r * 0.35, c.dy - r * 1.1, c.dx + r, c.dy)
        ..arcToPoint(Offset(c.dx - r, c.dy),
            radius: Radius.circular(r), clockwise: true)
        ..quadraticBezierTo(c.dx - r * 0.35, c.dy - r * 1.1, c.dx, c.dy - r * 2)
        ..close(),
      paint,
    );
    canvas.drawCircle(c + Offset(-r * 0.35, -r * 0.2), r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.8 * alpha));
  }

  /// Things around the head that go with a face: the anger mark, a sweat
  /// drop, stars circling a dizzy pet.
  void _paintExpressionExtras(
      Canvas canvas, _Pose p, double s, double rx, double ry) {
    final top = -2 * ry;
    switch (p.eyes == _Eyes.open ? p.expr : null) {
      case BlobExpression.angry:
        // The throbbing "cross vein" mark.
        final c = Offset(rx * 0.78, top + ry * 0.12);
        final r = s * 0.06 * (0.88 + 0.12 * math.sin(p.t * 10));
        final g = r * 0.28;
        final vein = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.02
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFE0574F);
        for (final sx in [-1.0, 1.0]) {
          for (final sy in [-1.0, 1.0]) {
            canvas.drawPath(
              Path()
                ..moveTo(c.dx + sx * g, c.dy + sy * r)
                ..quadraticBezierTo(
                    c.dx + sx * g, c.dy + sy * g, c.dx + sx * r, c.dy + sy * g),
              vein,
            );
          }
        }
      case BlobExpression.scared:
        final q = (p.t * 0.8) % 1.0;
        _drop(canvas, Offset(-rx * 0.86, -ry * 1.45 + s * 0.05 * q), s * 0.024,
            _tear, 1 - q * q);
      case BlobExpression.dizzy:
        final c = Offset(0, top - s * 0.02);
        for (var i = 0; i < 3; i++) {
          final a = p.t * 3.2 + i * 2 * math.pi / 3;
          final depth = 0.75 + 0.25 * math.sin(a);
          canvas.save();
          canvas.translate(
              c.dx + math.cos(a) * rx * 0.85, c.dy + math.sin(a) * s * 0.05);
          canvas.rotate(p.t * 4);
          _sparkle(canvas, s * 0.04 * depth,
              const Color(0xFFF2B93B).withValues(alpha: 0.6 + 0.4 * depth));
          canvas.restore();
        }
      default:
        break;
    }
  }

  /// "^" (happy, [up]) or "u" (closed) eye stroke.
  void _strokeCurve(Canvas canvas, Offset c, double w, double h,
      {required bool up, required double width}) {
    final path = Path();
    if (up) {
      path
        ..moveTo(c.dx - w * 0.65, c.dy + h * 0.12)
        ..quadraticBezierTo(
            c.dx, c.dy - h * 0.55, c.dx + w * 0.65, c.dy + h * 0.12);
    } else {
      path
        ..moveTo(c.dx - w * 0.65, c.dy - h * 0.02)
        ..quadraticBezierTo(
            c.dx, c.dy + h * 0.42, c.dx + w * 0.65, c.dy - h * 0.02);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = _ink,
    );
  }

  void _paintMouth(Canvas canvas, _Pose p, double s, Offset m) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.016
      ..color = _ink;
    switch (p.mouth) {
      case _Mouth.smile:
        canvas.drawPath(
          Path()
            ..moveTo(m.dx - s * 0.032, m.dy)
            ..quadraticBezierTo(m.dx, m.dy + s * 0.03, m.dx + s * 0.032, m.dy),
          stroke,
        );
      case _Mouth.frown:
        canvas.drawPath(
          Path()
            ..moveTo(m.dx - s * 0.03, m.dy + s * 0.022)
            ..quadraticBezierTo(
                m.dx, m.dy - s * 0.008, m.dx + s * 0.03, m.dy + s * 0.022),
          stroke,
        );
      case _Mouth.flat:
        canvas.drawPath(
          Path()
            ..moveTo(m.dx - s * 0.028, m.dy + s * 0.008)
            ..quadraticBezierTo(
                m.dx, m.dy - s * 0.004, m.dx + s * 0.028, m.dy + s * 0.008),
          stroke,
        );
      case _Mouth.wavy:
        // Trembly zigzag.
        final w = s * 0.075;
        final path = Path()..moveTo(m.dx - w / 2, m.dy + s * 0.012);
        for (var i = 1; i <= 4; i++) {
          path.lineTo(m.dx - w / 2 + w * i / 4,
              m.dy + s * 0.012 + (i.isOdd ? -1 : 1) * s * 0.009);
        }
        canvas.drawPath(path, stroke..strokeJoin = StrokeJoin.round);
      case _Mouth.grin:
        // Lopsided: the right corner hitched up, a row of teeth showing.
        final w = s * 0.14;
        final left = Offset(m.dx - w * 0.46, m.dy + s * 0.004);
        final right = Offset(m.dx + w * 0.54, m.dy - s * 0.03);
        final grin = Path()
          ..moveTo(left.dx, left.dy)
          ..quadraticBezierTo(m.dx, m.dy - s * 0.004, right.dx, right.dy)
          ..quadraticBezierTo(
              m.dx + w * 0.22, m.dy + s * 0.072, left.dx, left.dy)
          ..close();
        canvas.drawPath(grin, Paint()..color = _ink);
        canvas.save();
        canvas.clipPath(grin);
        final teeth = Path()
          ..moveTo(left.dx, left.dy)
          ..quadraticBezierTo(m.dx, m.dy - s * 0.004, right.dx, right.dy)
          ..lineTo(right.dx, right.dy + s * 0.034)
          ..quadraticBezierTo(
              m.dx, m.dy + s * 0.032, left.dx, left.dy + s * 0.02)
          ..close();
        canvas.drawPath(teeth, Paint()..color = Colors.white);
        final gap = Paint()
          ..strokeWidth = s * 0.007
          ..color = _ink.withValues(alpha: 0.6);
        for (final x in [-0.1, 0.12, 0.33]) {
          canvas.drawLine(Offset(m.dx + w * x, m.dy - s * 0.024),
              Offset(m.dx + w * x, m.dy + s * 0.03), gap);
        }
        canvas.restore();
        canvas.drawPath(
          Path()
            ..moveTo(left.dx, left.dy)
            ..quadraticBezierTo(m.dx, m.dy - s * 0.004, right.dx, right.dy)
            ..quadraticBezierTo(
                m.dx + w * 0.22, m.dy + s * 0.072, left.dx, left.dy),
          stroke..strokeJoin = StrokeJoin.round,
        );
      case _Mouth.wail:
        // Bawling: wide, corners pulled down, the top lip arched up.
        final w = s * 0.13;
        final h = s * 0.03 + s * 0.065 * p.mouthOpen;
        final left = Offset(m.dx - w / 2, m.dy + h * 0.55);
        final right = Offset(m.dx + w / 2, m.dy + h * 0.55);
        final wail = Path()
          ..moveTo(left.dx, left.dy)
          ..quadraticBezierTo(m.dx, m.dy - h * 0.45, right.dx, right.dy)
          ..quadraticBezierTo(m.dx + w * 0.4, m.dy + h * 1.15, m.dx,
              m.dy + h * 1.15)
          ..quadraticBezierTo(
              m.dx - w * 0.4, m.dy + h * 1.15, left.dx, left.dy)
          ..close();
        canvas.drawPath(wail, Paint()..color = _ink);
        canvas.save();
        canvas.clipPath(wail);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(m.dx, m.dy + h * 1.1),
              width: w * 0.6,
              height: h * 0.7),
          Paint()..color = const Color(0xFFE8737A),
        );
        canvas.restore();
      case _Mouth.gape:
        // Kirby-wide, slurping everything in.
        final k = p.mouthOpen;
        final mouth = Rect.fromCenter(
          center: m + Offset(0, s * 0.04 * k),
          width: s * (0.05 + 0.17 * k),
          height: s * (0.03 + 0.16 * k),
        );
        canvas.drawOval(mouth, Paint()..color = _ink);
        canvas.drawOval(
          mouth.deflate(mouth.shortestSide * 0.12),
          Paint()
            ..shader = const RadialGradient(colors: [
              Color(0xFF4A1420),
              Color(0xFF8E2E3E),
            ]).createShader(mouth),
        );
        canvas.save();
        canvas.clipRRect(RRect.fromRectAndRadius(
            mouth, Radius.circular(mouth.shortestSide)));
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(mouth.center.dx, mouth.bottom - mouth.height * 0.1),
              width: mouth.width * 0.62,
              height: mouth.height * 0.42),
          Paint()..color = const Color(0xFFE8737A),
        );
        canvas.restore();
      case _Mouth.small:
        canvas.drawOval(
          Rect.fromCenter(
              center: m + Offset(0, s * 0.008),
              width: s * 0.022,
              height: s * 0.016),
          stroke..strokeWidth = s * 0.012,
        );
      case _Mouth.open:
        final w = s * 0.075;
        final h = s * 0.018 + s * 0.06 * p.mouthOpen;
        final mouth = Path()
          ..moveTo(m.dx - w / 2, m.dy)
          ..quadraticBezierTo(m.dx, m.dy - s * 0.008, m.dx + w / 2, m.dy)
          ..quadraticBezierTo(m.dx + w * 0.45, m.dy + h, m.dx, m.dy + h)
          ..quadraticBezierTo(m.dx - w * 0.45, m.dy + h, m.dx - w / 2, m.dy)
          ..close();
        canvas.drawPath(mouth, Paint()..color = _ink);
        if (p.mouthOpen > 0.3) {
          canvas.save();
          canvas.clipPath(mouth);
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(m.dx, m.dy + h * 0.95),
              width: w * 0.62,
              height: h * 0.7,
            ),
            Paint()..color = const Color(0xFFE8737A),
          );
          canvas.restore();
        }
    }
  }

  // ─── accessories ────────────────────────────────────────────────────

  void _paintAccessory(Canvas canvas, _Pose p, double s, double rx, double ry) {
    final top = -2 * ry;
    switch (accessory) {
      case BlobAccessory.none:
      case BlobAccessory.glasses: // painted with the face
      case BlobAccessory.scarf: // painted before the face, clipped to body
        return;
      case BlobAccessory.sprout:
        canvas.save();
        canvas.translate(s * 0.02, top + s * 0.015);
        canvas.rotate(math.sin(p.t * 1.8) * 0.12);
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..quadraticBezierTo(-s * 0.01, -s * 0.06, s * 0.005, -s * 0.11),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = s * 0.02
            ..color = const Color(0xFF5E8C4A),
        );
        _leaf(canvas, Offset(s * 0.005, -s * 0.11), s * 0.1, -0.6,
            const Color(0xFF7DB765));
        _leaf(canvas, Offset(s * 0.005, -s * 0.11), s * 0.085, math.pi + 0.5,
            const Color(0xFF94C97C));
        canvas.restore();
      case BlobAccessory.bow:
        canvas.save();
        canvas.translate(rx * 0.5, top + ry * 0.2);
        canvas.rotate(0.35);
        final bow = Paint()..color = const Color(0xFFE5798C);
        for (final dir in [-1.0, 1.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(0, 0)
              ..quadraticBezierTo(dir * s * 0.1, -s * 0.09, dir * s * 0.11, 0)
              ..quadraticBezierTo(dir * s * 0.1, s * 0.09, 0, 0)
              ..close(),
            bow,
          );
        }
        canvas.drawCircle(
            Offset.zero, s * 0.03, Paint()..color = const Color(0xFFC95A70));
        canvas.restore();
      case BlobAccessory.beanie:
        final y = -ry * 1.62;
        final dome = Rect.fromCenter(
            center: Offset(0, y), width: rx * 1.72, height: ry * 1.0);
        canvas.drawArc(dome, math.pi, math.pi, true,
            Paint()..color = const Color(0xFFD9A441));
        final rib = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.008
          ..color = const Color(0xFFB9852A).withValues(alpha: 0.6);
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(Offset(i * rx * 0.16, y - ry * 0.02),
              Offset(i * rx * 0.12, y - ry * 0.4), rib);
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(0, y), width: rx * 1.8, height: s * 0.075),
            Radius.circular(s * 0.04),
          ),
          Paint()..color = const Color(0xFFC08A2E),
        );
        canvas.drawCircle(Offset(0, y - ry * 0.52), s * 0.05,
            Paint()..color = const Color(0xFFF6EBD8));
      case BlobAccessory.headphones:
        canvas.drawPath(
          Path()
            ..moveTo(-rx * 0.96, -ry * 1.05)
            ..cubicTo(-rx * 0.9, top - s * 0.1, rx * 0.9, top - s * 0.1,
                rx * 0.96, -ry * 1.05),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = s * 0.035
            ..color = const Color(0xFF4A4752),
        );
        for (final dir in [-1.0, 1.0]) {
          final cup = RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(dir * rx * 0.98, -ry * 1.0),
                width: s * 0.1,
                height: s * 0.17),
            Radius.circular(s * 0.05),
          );
          canvas.drawRRect(cup, Paint()..color = const Color(0xFFE5735B));
          canvas.drawRRect(
              cup.deflate(s * 0.022), Paint()..color = const Color(0xFFC4563F));
        }
      case BlobAccessory.chefHat:
      case BlobAccessory.partyHat:
      case BlobAccessory.catEars:
      case BlobAccessory.flower:
      case BlobAccessory.peci:
      case BlobAccessory.witchHat:
      case BlobAccessory.santaHat:
        _paintHat(canvas, p, s, rx, ry);
      case BlobAccessory.crown:
        canvas.save();
        canvas.translate(-s * 0.02, top + s * 0.025);
        canvas.rotate(-0.12);
        final w = s * 0.24;
        final h = s * 0.13;
        final crown = Path()
          ..moveTo(-w / 2, 0)
          ..lineTo(-w / 2, -h * 0.8)
          ..lineTo(-w / 4, -h * 0.35)
          ..lineTo(0, -h)
          ..lineTo(w / 4, -h * 0.35)
          ..lineTo(w / 2, -h * 0.8)
          ..lineTo(w / 2, 0)
          ..close();
        canvas.drawPath(crown, Paint()..color = const Color(0xFFF2C04E));
        canvas.drawPath(
          crown,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.round
            ..strokeWidth = s * 0.012
            ..color = const Color(0xFFC9952A),
        );
        canvas.drawCircle(Offset(0, -h * 0.3), s * 0.02,
            Paint()..color = const Color(0xFFE5606F));
        canvas.restore();
    }
  }

  void _leaf(Canvas canvas, Offset at, double len, double angle, Color c) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(len * 0.5, -len * 0.42, len, 0)
        ..quadraticBezierTo(len * 0.5, len * 0.42, 0, 0)
        ..close(),
      Paint()..color = c,
    );
    canvas.restore();
  }

  static const _jacketCloth = Color(0xFF4D5566);
  static const _jacketSleeve = Color(0xFF444B5A);
  static const _jacketDark = Color(0xFF383E4B);
  static const _jacketSnap = Color(0xFFC9CED6);
  static const _fur = Color(0xFFD2A770);
  static const _furLight = Color(0xFFE8CB9E);
  static const _furDark = Color(0xFFB98C58);

  /// Its thick winter parka, [amount] of the way on: a puffy charcoal
  /// coat over all of it, its hood up — only its face shows, ringed with
  /// fluffy fur — zipped up the front with snaps, and a flap pocket either
  /// side.
  void _paintJacket(
    Canvas canvas,
    Path body,
    double s,
    double rx,
    double ry,
    double amount,
  ) {
    final bounds = Rect.fromLTRB(-rx * 1.5, -ry * 2.4, rx * 1.5, ry * 0.2);
    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.black.withValues(alpha: amount),
    );
    // Puffier than the body under it, hood and all.
    final puff = body.transform(Matrix4.diagonal3Values(1.09, 1.05, 1).storage);
    // The hood's opening, round its face.
    final opening = Rect.fromCenter(
      center: Offset(0, -ry * 1.06),
      width: s * 0.62,
      height: s * 0.42,
    );
    final coat = Path.combine(
      PathOperation.difference,
      puff,
      Path()..addOval(opening),
    );
    canvas.drawPath(
      coat,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [
            Color.lerp(_jacketCloth, Colors.white, 0.16)!,
            _jacketCloth,
            Color.lerp(_jacketCloth, Colors.black, 0.18)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(bounds),
    );
    // The face sits back inside the hood.
    canvas.drawOval(
      opening.deflate(s * 0.012),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03,
    );

    canvas.save();
    canvas.clipPath(coat);
    final seam = Paint()
      ..color = _jacketDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.012
      ..strokeCap = StrokeCap.round;
    // The hood's seam, and the yoke across its chest.
    canvas.drawArc(
      opening.inflate(s * 0.11),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      seam,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-rx * 1.2, -ry * 0.5)
        ..quadraticBezierTo(0, -ry * 0.38, rx * 1.2, -ry * 0.5),
      seam,
    );
    // Zipped up the front: a placket with its snaps.
    final top = opening.bottom + s * 0.03;
    canvas.drawRect(
      Rect.fromLTRB(-s * 0.03, top, s * 0.03, 0),
      Paint()..color = _jacketDark,
    );
    canvas.drawLine(
      Offset(0, top),
      const Offset(0, 0),
      seam..color = Colors.black.withValues(alpha: 0.35),
    );
    final snap = Paint()..color = _jacketSnap;
    for (var y = top + s * 0.05; y < -s * 0.03; y += s * 0.1) {
      canvas.drawCircle(Offset(s * 0.012, y), s * 0.014, snap);
    }
    // A flap pocket either side.
    for (final dir in [-1.0, 1.0]) {
      final pocket = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(dir * rx * 0.55, -ry * 0.26),
          width: s * 0.2,
          height: s * 0.13,
        ),
        Radius.circular(s * 0.02),
      );
      canvas.drawRRect(
        pocket,
        Paint()
          ..color = _jacketDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.012,
      );
      final flap = Rect.fromLTWH(
        pocket.left,
        pocket.top,
        pocket.width,
        s * 0.05,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(flap, Radius.circular(s * 0.015)),
        Paint()..color = _jacketDark,
      );
      canvas.drawCircle(
        Offset(flap.center.dx, flap.bottom - s * 0.012),
        s * 0.011,
        snap,
      );
    }
    canvas.restore();

    // The fur trim round the hood: a soft ring, then two rows of small
    // overlapping tufts on it — fluffy, not beady.
    final ring = opening.inflate(s * 0.045);
    canvas.drawOval(
      ring,
      Paint()
        ..color = _fur
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07,
    );
    for (final (rows, out, size, colors) in [
      (44, s * 0.02, s * 0.03, const [_furDark, _fur]),
      (52, -s * 0.012, s * 0.026, const [_fur, _furLight]),
    ]) {
      final around = ring.inflate(out);
      for (var i = 0; i < rows; i++) {
        final a = (i + (out < 0 ? 0.5 : 0)) / rows * 2 * math.pi;
        final at = Offset(
          around.center.dx + around.width / 2 * math.cos(a),
          around.center.dy + around.height / 2 * math.sin(a),
        );
        canvas.drawCircle(
          at,
          size * (0.85 + 0.3 * ((i * 5) % 4) / 3),
          Paint()..color = colors[i % 2],
        );
      }
    }
    // A little shine on the top of the fur.
    canvas.drawArc(
      ring.inflate(s * 0.012),
      math.pi * 1.2,
      math.pi * 0.35,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.016
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }
  void _paintScarf(Canvas canvas, Path body, double s, double rx, double ry) {
    const red = Color(0xFFD9604C);
    // Just under the mouth so it reads as a scarf, not a belt.
    final y = -ry * 0.66;
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
      Path()
        ..moveTo(-rx * 1.1, y - s * 0.04)
        ..quadraticBezierTo(0, y + s * 0.02, rx * 1.1, y - s * 0.04)
        ..lineTo(rx * 1.1, y + s * 0.04)
        ..quadraticBezierTo(0, y + s * 0.1, -rx * 1.1, y + s * 0.04)
        ..close(),
      Paint()..color = red,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-rx * 1.1, y)
        ..quadraticBezierTo(0, y + s * 0.06, rx * 1.1, y),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012
        ..color = const Color(0xFFF2D4A0),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(rx * 0.55, y + s * 0.05);
    canvas.rotate(-0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-s * 0.035, 0, s * 0.07, s * 0.13),
        Radius.circular(s * 0.02),
      ),
      Paint()..color = red,
    );
    canvas.restore();
  }

  // ─── extras ─────────────────────────────────────────────────────────

  /// Food arcs from where it was dropped (or from below, where the
  /// pantry is) into the mouth — or into the egg while hatching.
  void _paintFlyingFood(
      Canvas canvas, _Pose p, double s, double cx, double ground) {
    final q = Curves.easeInCubic.transform(p.food!.clamp(0.0, 1.0));
    final from = state._foodFrom ?? Offset(cx + s * 0.1, ground + s * 0.15);
    final to = p.egg
        ? Offset(cx, ground - state._ry)
        : Offset(cx, ground - p.jump - state._ry * 0.85);
    final pos =
        Offset.lerp(from, to, q)! - Offset(0, math.sin(q * math.pi) * s * 0.12);
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(-0.3 + q * 0.9);
    paintFood(canvas, state._food, Offset.zero, s * 0.3 * (1 - q * 0.75));
    canvas.restore();
  }

  /// The mosquito sucked in towards the gaping mouth, wind rushing in
  /// with it.
  void _paintSlurp(
      Canvas canvas, _Pose p, double s, double cx, double ground) {
    final q = Curves.easeIn.transform(p.slurp!.clamp(0.0, 1.0));
    final from = state._hapFrom ?? Offset(cx + s * 0.4, ground - s * 1.4);
    final to = Offset(cx, ground - p.jump - state._ry * 0.85);
    if (p.mouth == _Mouth.gape) {
      final away = from - to;
      final len = math.max(1.0, away.distance);
      final n = away / len;
      final side = Offset(-n.dy, n.dx);
      for (var i = 0; i < 4; i++) {
        // Each streak runs in from further out and narrows into the mouth.
        final along = 1 - (p.t * 2.6 + i / 4) % 1.0;
        final spread = (i.isEven ? 1 : -1) * s * (0.03 + 0.12 * along);
        final a = to + n * (s * 0.08 + len * 0.9 * along) + side * spread;
        canvas.drawLine(
          a,
          a - n * s * 0.12 - side * spread * 0.2,
          Paint()
            ..strokeWidth = s * 0.02
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFF8FB3D6)
                .withValues(alpha: 0.85 * math.sin(math.pi * along)),
        );
      }
    }
    paintMosquito(
      canvas,
      Offset.lerp(from, to, q)!,
      s * 0.24 * (1 - q * 0.65),
      p.t,
      facing: from.dx > to.dx ? -1 : 1,
      spin: q * 3,
    );
  }

  void _paintParticle(Canvas canvas, _Particle part, double now, double s) {
    final a = now - part.born;
    final q = (a / part.life).clamp(0.0, 1.0);
    final fade = 1 - q * q;
    final pop = (a / 0.15).clamp(0.0, 1.0);
    switch (part.kind) {
      case _PKind.heart:
        final pos =
            part.origin + part.velocity * a + Offset(math.sin(a * 6) * 5, 0);
        _heart(canvas, pos, s * 0.07 * part.scale * pop,
            const Color(0xFFEF7A8A).withValues(alpha: fade));
      case _PKind.star:
        final drag = (1 - math.exp(-a * 3)) / 3;
        final pos = part.origin + part.velocity * drag;
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(part.spin * a);
        _sparkle(canvas, s * 0.055 * part.scale * pop,
            const Color(0xFFF2B93B).withValues(alpha: fade));
        canvas.restore();
      case _PKind.shell:
        final pos = part.origin + part.velocity * a + Offset(0, 260 * a * a);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(part.spin * a);
        final r = s * 0.05 * part.scale;
        canvas.drawPath(
          Path()
            ..moveTo(-r, r * 0.4)
            ..lineTo(-r * 0.4, -r * 0.6)
            ..lineTo(0, 0)
            ..lineTo(r * 0.5, -r * 0.7)
            ..lineTo(r, r * 0.4)
            ..close(),
          Paint()
            ..color = Color.lerp(color.base, Colors.white, 0.62)!
                .withValues(alpha: fade),
        );
        canvas.restore();
      case _PKind.puff:
        final pos = part.origin + part.velocity * a;
        final r = s * 0.05 * part.scale * (0.7 + 0.9 * q);
        canvas.drawCircle(
            pos, r, Paint()..color = Colors.white.withValues(alpha: 0.9 * fade));
        canvas.drawCircle(
          pos,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.008
            ..color = const Color(0xFFC9C2B6).withValues(alpha: 0.8 * fade),
        );
      case _PKind.dust:
        canvas.drawCircle(
          part.origin + part.velocity * a,
          s * (0.03 + 0.05 * q),
          Paint()
            ..color = const Color(0xFFBFB29C).withValues(alpha: 0.5 * fade),
        );
      case _PKind.note:
        // A little ♪ drifting up and swaying.
        final pos =
            part.origin + part.velocity * a + Offset(math.sin(a * 5) * 4, 0);
        final r = s * 0.028 * part.scale * pop;
        final ink = const Color(0xFF8A8FB5).withValues(alpha: fade);
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(-0.35);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: r * 2.2, height: r * 1.6),
            Paint()..color = ink);
        canvas.restore();
        final stem = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.45
          ..strokeCap = StrokeCap.round
          ..color = ink;
        final top = pos + Offset(r * 0.95, -r * 3.4);
        canvas.drawLine(pos + Offset(r * 0.95, -r * 0.2), top, stem);
        canvas.drawPath(
            Path()
              ..moveTo(top.dx, top.dy)
              ..quadraticBezierTo(top.dx + r * 1.5, top.dy + r * 0.6,
                  top.dx + r * 1.1, top.dy + r * 1.8),
            stem);
      case _PKind.tear:
        final pos = part.origin + part.velocity * a + Offset(0, 320 * a * a);
        _drop(canvas, pos, s * 0.018 * part.scale, _tear, fade);
      case _PKind.zzz:
        final pos = part.origin + part.velocity * a;
        final z = s * (0.025 + 0.025 * q);
        canvas.drawPath(
          Path()
            ..moveTo(pos.dx - z, pos.dy - z)
            ..lineTo(pos.dx + z, pos.dy - z)
            ..lineTo(pos.dx - z, pos.dy + z)
            ..lineTo(pos.dx + z, pos.dy + z),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.014
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF8A8FB5).withValues(alpha: fade),
        );
    }
  }

  void _heart(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy + r * 0.9)
        ..cubicTo(c.dx - r * 1.4, c.dy - r * 0.1, c.dx - r * 0.6,
            c.dy - r * 1.2, c.dx, c.dy - r * 0.45)
        ..cubicTo(c.dx + r * 0.6, c.dy - r * 1.2, c.dx + r * 1.4,
            c.dy - r * 0.1, c.dx, c.dy + r * 0.9)
        ..close(),
      Paint()..color = color,
    );
  }

  void _sparkle(Canvas canvas, double r, Color color) {
    canvas.drawPath(
      Path()
        ..moveTo(0, -r)
        ..quadraticBezierTo(r * 0.15, -r * 0.15, r, 0)
        ..quadraticBezierTo(r * 0.15, r * 0.15, 0, r)
        ..quadraticBezierTo(-r * 0.15, r * 0.15, -r, 0)
        ..quadraticBezierTo(-r * 0.15, -r * 0.15, 0, -r)
        ..close(),
      Paint()..color = color,
    );
  }

  /// Only the body (plus a forgiving margin) takes touches, so the
  /// empty headroom doesn't swallow taps meant for things behind it.
  @override
  bool hitTest(Offset position) {
    // Rolling past or mid-hap: touches go to whatever's behind it.
    if (state._busyMoving) return false;
    final p = state._pose;
    final c = Offset(state._w / 2, state._groundY - p.jump - state._ry);
    final dx = (position.dx - c.dx) / (state._rx * 1.25);
    final dy = (position.dy - c.dy) / (state._ry * 1.35);
    return dx * dx + dy * dy <= 1;
  }

  @override
  bool shouldRepaint(covariant _BlobPainter old) =>
      old.color != color ||
      old.accessory != accessory ||
      old.outfit != outfit ||
      old.stage != stage ||
      old.mood != mood;
}
