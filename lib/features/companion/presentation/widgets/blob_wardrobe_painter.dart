part of 'blob_mascot.dart';

// ════════════════════════════════════════════════════════════════════════
// Wardrobe: the outfits and the newer hats
// ════════════════════════════════════════════════════════════════════════
//
// Same space as the painter: origin at the bottom centre, y up is
// negative, the body [rx] wide either side and 2·[ry] tall, its face at
// about -1.08·ry. Clothes are painted inside the body's outline, from just
// under the mouth (where the scarf sits) down; a costume with its hood up
// is a puffier body with an opening for the face, like the parka.

extension _Wardrobe on _BlobPainter {
  /// Its arms take the outfit's sleeves (null: bare).
  Color? get _sleeve => switch (outfit) {
        BlobOutfit.none || BlobOutfit.overalls => null,
        BlobOutfit.hoodie => _hoodieBlue,
        BlobOutfit.stripedTee => _teeWhite,
        BlobOutfit.sweater => _knitCream,
        BlobOutfit.batik => _batikBrown,
        BlobOutfit.koko => _kokoCream,
        BlobOutfit.astronaut => _spaceWhite,
        BlobOutfit.raincoat => _rainYellow,
        BlobOutfit.dino => _dinoGreen,
        BlobOutfit.frog => _frogGreen,
        BlobOutfit.bee => _beeYellow,
        BlobOutfit.pumpkin => _pumpkinOrange,
      };

  static const _hoodieBlue = Color(0xFF7FA8D1);
  static const _teeWhite = Color(0xFFFBF7EF);
  static const _navy = Color(0xFF3E5C8A);
  static const _denim = Color(0xFF5B7FB0);
  static const _knitCream = Color(0xFFEADBC5);
  static const _knitRed = Color(0xFFC8584A);
  static const _batikBrown = Color(0xFF8B5A3C);
  static const _batikCream = Color(0xFFEBD3A6);
  static const _kokoCream = Color(0xFFF4EFE3);
  static const _gold = Color(0xFFC9A04A);
  static const _spaceWhite = Color(0xFFF1F3F6);
  static const _spaceGrey = Color(0xFFA7AFBA);
  static const _rainYellow = Color(0xFFF2C640);
  static const _dinoGreen = Color(0xFF7DB765);
  static const _frogGreen = Color(0xFF8FC46E);
  static const _beeYellow = Color(0xFFF5C842);
  static const _beeBlack = Color(0xFF2E2B2B);
  static const _pumpkinOrange = Color(0xFFEE8A3A);

  // ─── shared pieces ──────────────────────────────────────────────────

  static Color _darker(Color c, [double by = 0.18]) =>
      Color.lerp(c, Colors.black, by)!;

  static Color _lighter(Color c, [double by = 0.25]) =>
      Color.lerp(c, Colors.white, by)!;

  Paint _line(Color c, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  /// The neckline: just under its mouth in the middle, rising up either
  /// side of its face over its "shoulders", so the clothes wrap round it
  /// instead of sitting across the bottom like a band. [dy] moves it down.
  Path _neckline(double s, double rx, double ry, [double dy = 0]) => Path()
    ..moveTo(-rx * 1.3, -ry * 1.2 + dy)
    ..quadraticBezierTo(0, -ry * 0.2 + dy, rx * 1.3, -ry * 1.2 + dy);

  /// Everything below the neckline (to be clipped to the body).
  Path _garment(double s, double rx, double ry) => _neckline(s, rx, ry)
    ..lineTo(rx * 1.3, s * 0.05)
    ..lineTo(-rx * 1.3, s * 0.05)
    ..close();

  /// How far a row across the clothes at [y] dips in the middle: rows
  /// follow the body round, more near the neck, flatter near the floor.
  double _dip(double y, double s, double ry) {
    final top = -ry * 0.7;
    final t = ((y - top) / -top).clamp(0.0, 1.0);
    return s * 0.05 * (1 - t);
  }

  /// A row across the clothes at [y] (its centre dipping by [_dip]).
  Path _row(double y, double s, double rx, double ry) => Path()
    ..moveTo(-rx * 1.3, y - _dip(y, s, ry))
    ..quadraticBezierTo(0, y + _dip(y, s, ry), rx * 1.3, y - _dip(y, s, ry));

  /// Shades whatever's been painted in the current clip so it reads as
  /// cloth wrapped round a round body: deeper toward its [outline], lit
  /// from the top left like the body, a little deeper toward the floor.
  /// The shade is the cloth's own colour, darker (like the body's), so
  /// light cloth doesn't go grey.
  void _wrap(
      Canvas canvas, Path outline, double s, double rx, double ry, Color c) {
    final shade = Color.lerp(c, Colors.black, 0.45)!;
    canvas.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.16
        ..color = shade.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(-rx * 0.45, -ry * 0.75),
          width: s * 0.42,
          height: s * 0.26),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06),
    );
    final floor = Rect.fromLTRB(-rx * 1.5, -ry * 1.3, rx * 1.5, 0);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shade.withValues(alpha: 0), shade.withValues(alpha: 0.16)],
        ).createShader(floor),
    );
  }

  /// A garment of colour [c]: up to the neckline, [details] on it, the
  /// shading that wraps it round the body, and a rolled edge at the neck.
  void _wear(Canvas canvas, Path body, double s, double rx, double ry, Color c,
      [void Function()? details]) {
    final garment = _garment(s, rx, ry);
    canvas.save();
    canvas.clipPath(body);
    canvas.save();
    canvas.clipPath(garment);
    canvas.drawPaint(Paint()..color = c);
    details?.call();
    _wrap(canvas, body, s, rx, ry, c);
    canvas.restore();
    // Its edge: a soft shadow on the body above it, and a rolled hem.
    canvas.drawPath(
      _neckline(s, rx, ry, -s * 0.006),
      _line(Colors.black.withValues(alpha: 0.1), s * 0.014)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.008),
    );
    canvas.drawPath(
        _neckline(s, rx, ry, s * 0.008), _line(_lighter(c, 0.3), s * 0.016));
    canvas.restore();
  }

  /// The hood's opening round its face (same as the parka's).
  Rect _faceOpening(double s, double ry) => Rect.fromCenter(
      center: Offset(0, -ry * 1.06), width: s * 0.62, height: s * 0.42);

  /// A one-piece suit with its hood up: a little puffier than the body,
  /// with its face showing through. [details] are painted on the suit
  /// before it's shaded. Returns the suit's shape.
  Path _hoodSuit(
      Canvas canvas, Path body, double s, double rx, double ry, Color c,
      [void Function(Path suit)? details]) {
    final puff = body.transform(Matrix4.diagonal3Values(1.07, 1.04, 1).storage);
    final opening = _faceOpening(s, ry);
    final suit =
        Path.combine(PathOperation.difference, puff, Path()..addOval(opening));
    canvas.save();
    canvas.clipPath(suit);
    canvas.drawPaint(Paint()..color = c);
    details?.call(suit);
    _wrap(canvas, puff, s, rx, ry, c);
    canvas.restore();
    canvas.drawPath(puff, _line(_darker(c, 0.25).withValues(alpha: 0.5), 1));
    // The hood throws a little shadow on its forehead…
    canvas.save();
    canvas.clipPath(Path()..addOval(opening));
    canvas.drawRect(
      opening,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.16),
            Colors.black.withValues(alpha: 0),
          ],
          stops: const [0, 0.42],
        ).createShader(opening),
    );
    canvas.restore();
    // …and its edge rolls over round its face.
    canvas.drawOval(
        opening.inflate(s * 0.004), _line(_lighter(c, 0.28), s * 0.03));
    canvas.drawOval(opening.deflate(s * 0.012),
        _line(Colors.black.withValues(alpha: 0.1), s * 0.007));
    return suit;
  }

  /// The top of the hood at [x] (on the suit's outline, roughly).
  double _hoodTop(double x, double rx, double ry) {
    final a = rx * 1.07, b = ry * 1.04;
    final k = (1 - (x / a) * (x / a)).clamp(0.0, 1.0);
    return -b - b * math.sqrt(k);
  }

  // ─── behind the body ────────────────────────────────────────────────

  void _paintOutfitBehind(
      Canvas canvas, _Pose p, double s, double rx, double ry) {
    switch (outfit) {
      case BlobOutfit.dino:
        // A stubby tail out to one side, with two spikes on it.
        final tail = Path()
          ..moveTo(rx * 0.7, -ry * 0.55)
          ..quadraticBezierTo(rx * 1.35, -ry * 0.5, rx * 1.55, -ry * 0.08)
          ..quadraticBezierTo(rx * 1.2, -ry * 0.02, rx * 0.75, -ry * 0.05)
          ..close();
        for (final (x, y) in [(1.12, -0.5), (1.38, -0.32)]) {
          canvas.drawPath(
            Path()
              ..moveTo(rx * (x - 0.1), ry * (y + 0.02))
              ..lineTo(rx * (x + 0.02), ry * (y - 0.2))
              ..lineTo(rx * (x + 0.12), ry * (y + 0.06))
              ..close(),
            Paint()..color = const Color(0xFFF2A54A),
          );
        }
        canvas.drawPath(tail, Paint()..color = _dinoGreen);
        canvas.save();
        canvas.clipPath(tail);
        canvas.drawRect(
          tail.getBounds(),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_lighter(_dinoGreen, 0.12), _darker(_dinoGreen, 0.16)],
            ).createShader(tail.getBounds()),
        );
        canvas.restore();
      case BlobOutfit.bee:
        // Little see-through wings.
        for (final dir in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(dir * rx * 0.98, -ry * 1.32);
          canvas.rotate(dir * 0.55);
          final wing = Rect.fromCenter(
              center: Offset(dir * s * 0.06, 0),
              width: s * 0.22,
              height: s * 0.14);
          canvas.drawOval(
              wing, Paint()..color = Colors.white.withValues(alpha: 0.75));
          canvas.drawOval(wing, _line(const Color(0xFF9CC3E0), s * 0.01));
          canvas.restore();
        }
      default:
        return;
    }
  }

  // ─── over the body ──────────────────────────────────────────────────

  void _paintOutfit(
      Canvas canvas, _Pose p, Path body, double s, double rx, double ry) {
    switch (outfit) {
      case BlobOutfit.none:
        return;
      case BlobOutfit.hoodie:
        _paintHoodie(canvas, body, s, rx, ry);
      case BlobOutfit.stripedTee:
        _paintStripedTee(canvas, body, s, rx, ry);
      case BlobOutfit.overalls:
        _paintOveralls(canvas, body, s, rx, ry);
      case BlobOutfit.sweater:
        _paintSweater(canvas, body, s, rx, ry);
      case BlobOutfit.batik:
        _paintBatik(canvas, body, s, rx, ry);
      case BlobOutfit.koko:
        _paintKoko(canvas, body, s, rx, ry);
      case BlobOutfit.astronaut:
        _paintSpaceSuit(canvas, body, s, rx, ry);
      case BlobOutfit.raincoat:
        _paintRaincoat(canvas, body, s, rx, ry);
      case BlobOutfit.dino:
        _paintDino(canvas, body, s, rx, ry);
      case BlobOutfit.frog:
        _paintFrog(canvas, body, s, rx, ry);
      case BlobOutfit.bee:
        _paintBee(canvas, body, s, rx, ry);
      case BlobOutfit.pumpkin:
        _paintPumpkin(canvas, body, s, rx, ry);
    }
  }

  /// Its arms in the outfit's sleeves, in front at its sides — cuffs, and
  /// its little hands poking out — following the same poses as bare arms.
  void _paintSleeves(Canvas canvas, _Pose p, double s, double rx, double ry) {
    final sleeve = _sleeve;
    if (sleeve == null) return;
    final edge = _darker(sleeve, 0.22).withValues(alpha: 0.6);
    for (final dir in [-1.0, 1.0]) {
      // A waving hand is drawn on its own.
      if (dir > 0 && p.armRight > 0.3) continue;
      final raise = dir > 0 && p.armRight >= 0 ? p.armRight : p.arm;
      canvas.save();
      canvas.translate(dir * rx * 0.86, -ry * (0.8 + 0.45 * raise));
      canvas.rotate(dir * (0.5 - 1.3 * raise) + (dir > 0 ? p.armWave : 0));
      final arm = Rect.fromCenter(
          center: Offset(dir * s * 0.035, 0),
          width: s * 0.13,
          height: s * 0.095);
      canvas.drawOval(
        arm,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_lighter(sleeve, 0.12), _darker(sleeve, 0.12)],
          ).createShader(arm),
      );
      canvas.drawOval(arm, _line(edge, s * 0.007));
      // The cuff, and the hand.
      final cuff = dir * s * 0.085;
      canvas.drawLine(Offset(cuff, -s * 0.034), Offset(cuff, s * 0.034),
          _line(edge, s * 0.008));
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(dir * s * 0.108, 0),
            width: s * 0.052,
            height: s * 0.06),
        Paint()..color = color.shade,
      );
      canvas.restore();
    }
  }

  void _paintHoodie(Canvas canvas, Path body, double s, double rx, double ry) {
    final dark = _darker(_hoodieBlue);
    _wear(canvas, body, s, rx, ry, _hoodieBlue, () {
      // Ribbed hem and the front pocket.
      canvas.drawRect(Rect.fromLTRB(-rx * 1.3, -s * 0.035, rx * 1.3, 0),
          Paint()..color = dark);
      final pocket = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, -s * 0.1), width: s * 0.3, height: s * 0.09),
        Radius.circular(s * 0.03),
      );
      canvas.drawRRect(pocket, Paint()..color = dark.withValues(alpha: 0.3));
      canvas.drawRRect(pocket, _line(dark, s * 0.009));
    });
    // The hood, down, bunched round the back of its neck.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(_neckline(s, rx, ry, s * 0.02),
        _line(_lighter(_hoodieBlue, 0.1), s * 0.04));
    canvas.drawPath(_neckline(s, rx, ry, s * 0.042), _line(dark, s * 0.008));
    canvas.restore();
    // Drawstrings.
    final y = -ry * 0.7 + s * 0.05;
    final string = _line(const Color(0xFFF4F1EA), s * 0.011);
    for (final dir in [-1.0, 1.0]) {
      final x = dir * s * 0.045;
      canvas.drawLine(Offset(x, y), Offset(x * 1.1, y + s * 0.08), string);
      canvas.drawCircle(Offset(x * 1.1, y + s * 0.085), s * 0.012,
          Paint()..color = const Color(0xFFF4F1EA));
    }
  }

  void _paintStripedTee(
      Canvas canvas, Path body, double s, double rx, double ry) {
    _wear(canvas, body, s, rx, ry, _teeWhite, () {
      final stripe = _line(_navy, s * 0.026)..strokeCap = StrokeCap.butt;
      for (var y = -ry * 0.62; y < 0; y += s * 0.064) {
        canvas.drawPath(_row(y, s, rx, ry), stripe);
      }
    });
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(_neckline(s, rx, ry, s * 0.01), _line(_navy, s * 0.014));
    canvas.restore();
  }

  void _paintOveralls(
      Canvas canvas, Path body, double s, double rx, double ry) {
    final dark = _darker(_denim);
    const stitch = Color(0xFFB4CBE6);
    const button = Color(0xFFE2B65A);
    // Trousers up to the waist, the bib in front.
    final waist = -s * 0.13;
    final denim = Path()
      ..moveTo(-rx * 1.3, waist - _dip(waist, s, ry))
      ..quadraticBezierTo(0, waist + _dip(waist, s, ry) + s * 0.01, rx * 1.3,
          waist - _dip(waist, s, ry))
      ..lineTo(rx * 1.3, s * 0.05)
      ..lineTo(-rx * 1.3, s * 0.05)
      ..close()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTRB(-s * 0.13, -s * 0.255, s * 0.13, waist + s * 0.03),
        topLeft: Radius.circular(s * 0.025),
        topRight: Radius.circular(s * 0.025),
      ));
    canvas.save();
    canvas.clipPath(body);
    canvas.save();
    canvas.clipPath(denim);
    canvas.drawPaint(Paint()..color = _denim);
    // Stitching: the bib's pocket and the trousers' seam.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, -s * 0.185), width: s * 0.13, height: s * 0.06),
        Radius.circular(s * 0.012),
      ),
      _line(stitch, s * 0.008),
    );
    canvas.drawLine(
        Offset(0, waist + s * 0.05), Offset.zero, _line(dark, s * 0.01));
    _wrap(canvas, body, s, rx, ry, _denim);
    canvas.restore();
    // Straps over its shoulders, buttoned to the bib.
    for (final dir in [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(dir * s * 0.105, -s * 0.245)
          ..quadraticBezierTo(
              dir * s * 0.2, -s * 0.34, dir * rx * 1.05, -s * 0.37),
        _line(_denim, s * 0.045)..strokeCap = StrokeCap.butt,
      );
      canvas.drawCircle(Offset(dir * s * 0.1, -s * 0.235), s * 0.017,
          Paint()..color = button);
    }
    canvas.restore();
  }

  void _paintSweater(Canvas canvas, Path body, double s, double rx, double ry) {
    final rib = _darker(_knitCream, 0.1);
    _wear(canvas, body, s, rx, ry, _knitCream, () {
      // A zigzag band across its chest, dots either side, round with it.
      final y = -s * 0.15;
      final zig = Path();
      var up = true;
      for (var x = -rx * 1.3; x <= rx * 1.3; x += s * 0.05) {
        final dy = _dip(y, s, ry) * (2 * (1 - (x / (rx * 1.3)).abs()) - 1);
        final p = Offset(x, y + dy + (up ? -s * 0.022 : s * 0.022));
        x == -rx * 1.3 ? zig.moveTo(p.dx, p.dy) : zig.lineTo(p.dx, p.dy);
        up = !up;
      }
      canvas.drawPath(zig, _line(_knitRed, s * 0.018));
      final dot = Paint()..color = _knitRed;
      for (var x = -rx * 1.2; x <= rx * 1.2; x += s * 0.1) {
        final dy = _dip(y, s, ry) * (2 * (1 - (x / (rx * 1.3)).abs()) - 1);
        canvas.drawCircle(Offset(x, y + dy - s * 0.06), s * 0.01, dot);
        canvas.drawCircle(
            Offset(x + s * 0.05, y + dy + s * 0.06), s * 0.01, dot);
      }
      // Ribbed hem.
      canvas.drawRect(Rect.fromLTRB(-rx * 1.3, -s * 0.04, rx * 1.3, 0),
          Paint()..color = rib);
      final line = _line(_darker(_knitCream, 0.2), s * 0.006);
      for (var x = -rx * 1.3; x <= rx * 1.3; x += s * 0.025) {
        canvas.drawLine(Offset(x, -s * 0.035), Offset(x, -s * 0.005), line);
      }
    });
    // A snug ribbed collar.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(_neckline(s, rx, ry, s * 0.016), _line(rib, s * 0.038));
    canvas.restore();
  }

  void _paintBatik(Canvas canvas, Path body, double s, double rx, double ry) {
    final dark = _darker(_batikBrown, 0.25);
    _wear(canvas, body, s, rx, ry, _batikBrown, () {
      // Kawung: four petals round a dot, rows bending round with it.
      final petal = Paint()..color = _batikCream.withValues(alpha: 0.9);
      final dot = Paint()..color = dark;
      var row = 0;
      for (var y = -ry * 1.15; y < s * 0.02; y += s * 0.085) {
        final shift = row.isOdd ? s * 0.045 : 0.0;
        for (var x = -rx * 1.3 + shift; x <= rx * 1.3; x += s * 0.09) {
          final dy = _dip(y, s, ry) * (2 * (1 - (x / (rx * 1.3)).abs()) - 1);
          for (var k = 0; k < 4; k++) {
            canvas.save();
            canvas.translate(x, y + dy);
            canvas.rotate(math.pi / 4 + k * math.pi / 2);
            canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(s * 0.019, 0),
                  width: s * 0.03,
                  height: s * 0.017),
              petal,
            );
            canvas.restore();
          }
          canvas.drawCircle(Offset(x, y + dy), s * 0.006, dot);
        }
        row++;
      }
      // The placket and its buttons.
      canvas.drawLine(
          Offset(0, -ry * 0.7), Offset.zero, _line(dark, s * 0.012));
      for (var y = -ry * 0.7 + s * 0.05; y < -s * 0.02; y += s * 0.07) {
        canvas.drawCircle(
            Offset(s * 0.014, y), s * 0.011, Paint()..color = _batikCream);
      }
    });
    // Its collar, a point either side of the neck.
    final y = -ry * 0.7;
    canvas.save();
    canvas.clipPath(body);
    for (final dir in [-1.0, 1.0]) {
      final collar = Path()
        ..moveTo(dir * s * 0.01, y + s * 0.005)
        ..lineTo(dir * s * 0.14, y - s * 0.03)
        ..lineTo(dir * s * 0.07, y + s * 0.075)
        ..close();
      canvas.drawPath(collar, Paint()..color = dark);
      canvas.drawPath(collar, _line(_batikCream, s * 0.007));
    }
    canvas.restore();
  }

  void _paintKoko(Canvas canvas, Path body, double s, double rx, double ry) {
    _wear(canvas, body, s, rx, ry, _kokoCream, () {
      // The embroidered placket down the front.
      final y0 = -ry * 0.7;
      canvas.drawRect(Rect.fromLTRB(-s * 0.03, y0, s * 0.03, 0),
          Paint()..color = _darker(_kokoCream, 0.06));
      final thread = _line(_gold, s * 0.007);
      for (var y = y0 + s * 0.03; y < -s * 0.01; y += s * 0.04) {
        canvas.drawPath(
          Path()
            ..moveTo(0, y - s * 0.014)
            ..lineTo(s * 0.016, y)
            ..lineTo(0, y + s * 0.014)
            ..lineTo(-s * 0.016, y)
            ..close(),
          thread,
        );
      }
      canvas.drawLine(Offset(-s * 0.03, y0), Offset(-s * 0.03, 0), thread);
      canvas.drawLine(Offset(s * 0.03, y0), Offset(s * 0.03, 0), thread);
    });
    // A mandarin collar, edged in gold.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(_neckline(s, rx, ry, s * 0.016),
        _line(_darker(_kokoCream, 0.05), s * 0.032));
    canvas.drawPath(_neckline(s, rx, ry, s * 0.034), _line(_gold, s * 0.007));
    canvas.restore();
  }

  void _paintSpaceSuit(
      Canvas canvas, Path body, double s, double rx, double ry) {
    _wear(canvas, body, s, rx, ry, _spaceWhite, () {
      // A belt, and the control panel on its chest.
      canvas.drawPath(_row(-s * 0.055, s, rx, ry),
          _line(_spaceGrey, s * 0.026)..strokeCap = StrokeCap.butt);
      final panel = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(0, -s * 0.15), width: s * 0.2, height: s * 0.085),
        Radius.circular(s * 0.015),
      );
      canvas.drawRRect(panel, Paint()..color = const Color(0xFFDDE3EA));
      canvas.drawRRect(panel, _line(_spaceGrey, s * 0.008));
      for (final (i, c) in const [
        Color(0xFFE5606F),
        Color(0xFF6FA6D9),
        Color(0xFFF2C04E),
      ].indexed) {
        canvas.drawCircle(Offset((i - 1) * s * 0.055, -s * 0.15), s * 0.016,
            Paint()..color = c);
      }
    });
    // The collar ring the helmet locks onto.
    canvas.save();
    canvas.clipPath(body);
    canvas.drawPath(
        _neckline(s, rx, ry, s * 0.014), _line(_spaceGrey, s * 0.036));
    canvas.restore();
  }

  void _paintRaincoat(
      Canvas canvas, Path body, double s, double rx, double ry) {
    final dark = _darker(_rainYellow, 0.22);
    final opening = _faceOpening(s, ry);
    _hoodSuit(canvas, body, s, rx, ry, _rainYellow, (_) {
      // The hood's seam, and the front with its toggles.
      canvas.drawArc(opening.inflate(s * 0.1), math.pi * 1.1, math.pi * 0.8,
          false, _line(dark, s * 0.01));
      canvas.drawLine(
          Offset(0, opening.bottom), Offset.zero, _line(dark, s * 0.012));
      final toggle = Paint()..color = const Color(0xFF8B5A3C);
      for (var y = opening.bottom + s * 0.05; y < -s * 0.03; y += s * 0.075) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(0, y), width: s * 0.06, height: s * 0.022),
              Radius.circular(s * 0.011)),
          toggle,
        );
      }
    });
  }

  void _paintDino(Canvas canvas, Path body, double s, double rx, double ry) {
    // Spikes along the top of the hood, under its edge.
    for (final x in [-0.18, -0.09, 0.0, 0.09, 0.18]) {
      final at = s * x;
      final y = _hoodTop(at, rx, ry);
      canvas.drawPath(
        Path()
          ..moveTo(at - s * 0.042, y + s * 0.02)
          ..lineTo(at * 1.15, y - s * 0.07)
          ..lineTo(at + s * 0.042, y + s * 0.02)
          ..close(),
        Paint()..color = const Color(0xFFF2A54A),
      );
    }
    _hoodSuit(canvas, body, s, rx, ry, _dinoGreen,
        (_) => _belly(canvas, s, const Color(0xFFD8EBC4)));
  }

  void _paintFrog(Canvas canvas, Path body, double s, double rx, double ry) {
    _hoodSuit(canvas, body, s, rx, ry, _frogGreen,
        (_) => _belly(canvas, s, const Color(0xFFDCEFC8)));
    // Big round eyes on top of the hood.
    for (final dir in [-1.0, 1.0]) {
      final x = dir * s * 0.14;
      final c = Offset(x, _hoodTop(x, rx, ry) + s * 0.01);
      canvas.drawCircle(c, s * 0.068, Paint()..color = _frogGreen);
      canvas.drawCircle(c, s * 0.068,
          _line(_darker(_frogGreen, 0.2).withValues(alpha: 0.5), 1));
      canvas.drawCircle(c, s * 0.048, Paint()..color = Colors.white);
      canvas.drawCircle(c + Offset(0, s * 0.008), s * 0.024,
          Paint()..color = _BlobPainter._ink);
    }
  }

  void _paintBee(Canvas canvas, Path body, double s, double rx, double ry) {
    // Antennae, under the hood's edge.
    for (final dir in [-1.0, 1.0]) {
      final x = dir * s * 0.07;
      final y = _hoodTop(x, rx, ry);
      final tip = Offset(dir * s * 0.16, y - s * 0.12);
      canvas.drawPath(
        Path()
          ..moveTo(x, y + s * 0.02)
          ..quadraticBezierTo(x, y - s * 0.08, tip.dx, tip.dy),
        _line(_beeBlack, s * 0.014),
      );
      canvas.drawCircle(tip, s * 0.026, Paint()..color = _beeBlack);
    }
    _hoodSuit(canvas, body, s, rx, ry, _beeYellow, (_) {
      // Black bands, round with its tummy.
      final band = _line(_beeBlack, s * 0.055)..strokeCap = StrokeCap.butt;
      for (final y in [-0.175, -0.045]) {
        canvas.drawPath(_row(s * y, s, rx * 1.15, ry), band);
      }
    });
  }

  void _paintPumpkin(Canvas canvas, Path body, double s, double rx, double ry) {
    _hoodSuit(canvas, body, s, rx, ry, _pumpkinOrange, (_) {
      // Its ridges, bowing out.
      final ridge = _line(_darker(_pumpkinOrange, 0.2), s * 0.014);
      for (final x in [-0.3, -0.16, 0.16, 0.3]) {
        canvas.drawPath(
          Path()
            ..moveTo(s * x * 0.6, -ry * 2.1)
            ..quadraticBezierTo(s * x * 1.25, -ry, s * x * 0.7, 0),
          ridge,
        );
      }
    });
    // The stem, with a curl of vine.
    final top = _hoodTop(0, rx, ry);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(s * 0.01, top - s * 0.035),
            width: s * 0.05,
            height: s * 0.08),
        Radius.circular(s * 0.015),
      ),
      Paint()..color = const Color(0xFF6E8B3D),
    );
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.03, top - s * 0.02)
        ..quadraticBezierTo(s * 0.12, top - s * 0.07, s * 0.08, top - s * 0.01),
      _line(const Color(0xFF6E8B3D), s * 0.01),
    );
  }

  /// A lighter tummy on a costume (painted inside the suit).
  void _belly(Canvas canvas, double s, Color c) {
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(0, -s * 0.07), width: s * 0.36, height: s * 0.2),
      Paint()..color = c,
    );
  }

  // ─── in front of its face ───────────────────────────────────────────

  void _paintOutfitOver(
      Canvas canvas, _Pose p, double s, double rx, double ry) {
    if (outfit != BlobOutfit.astronaut) return;
    // A glass bubble over its head, with a little antenna on top.
    final c = Offset(0, -ry * 1.1);
    final r = s * 0.3;
    canvas.drawCircle(
        c, r, Paint()..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawCircle(c, r, _line(const Color(0xFFC9D0D9), s * 0.026));
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.8),
        math.pi * 1.1,
        math.pi * 0.35,
        false,
        _line(Colors.white.withValues(alpha: 0.8), s * 0.022));
    canvas.drawLine(Offset(c.dx + r * 0.5, c.dy - r * 0.86),
        Offset(c.dx + r * 0.62, c.dy - r * 1.18), _line(_spaceGrey, s * 0.012));
    canvas.drawCircle(Offset(c.dx + r * 0.62, c.dy - r * 1.2), s * 0.02,
        Paint()..color = const Color(0xFFE5606F));
  }

  // ─── the newer hats ─────────────────────────────────────────────────

  void _paintHat(Canvas canvas, _Pose p, double s, double rx, double ry) {
    final top = -2 * ry;
    switch (accessory) {
      case BlobAccessory.chefHat:
        const white = Color(0xFFFFFDF8);
        final outline = _line(const Color(0xFFDCD4C7), s * 0.009);
        final band = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, top + s * 0.03),
              width: s * 0.38,
              height: s * 0.085),
          Radius.circular(s * 0.03),
        );
        final puff = Path()
          ..addOval(Rect.fromCircle(
              center: Offset(-s * 0.11, top - s * 0.055), radius: s * 0.085))
          ..addOval(Rect.fromCircle(
              center: Offset(s * 0.11, top - s * 0.055), radius: s * 0.085))
          ..addOval(Rect.fromCircle(
              center: Offset(0, top - s * 0.1), radius: s * 0.105));
        final hat =
            Path.combine(PathOperation.union, puff, Path()..addRRect(band));
        canvas.drawPath(hat, Paint()..color = white);
        canvas.drawPath(hat, outline);
        for (final x in [-0.09, 0.0, 0.09]) {
          canvas.drawLine(Offset(s * x, top), Offset(s * x, top + s * 0.06),
              _line(const Color(0xFFE6E0D5), s * 0.008));
        }
      case BlobAccessory.partyHat:
        canvas.save();
        canvas.translate(s * 0.09, top + s * 0.035);
        canvas.rotate(0.28);
        canvas.scale(1.2);
        final cone = Path()
          ..moveTo(-s * 0.1, 0)
          ..lineTo(0, -s * 0.22)
          ..lineTo(s * 0.1, 0)
          ..close();
        canvas.drawPath(cone, Paint()..color = const Color(0xFF6FB7C9));
        canvas.save();
        canvas.clipPath(cone);
        final stripe = _line(const Color(0xFFF7D86B), s * 0.028);
        for (var y = -s * 0.2; y < s * 0.05; y += s * 0.06) {
          canvas.drawLine(Offset(-s * 0.12, y + s * 0.04),
              Offset(s * 0.12, y - s * 0.02), stripe);
        }
        canvas.restore();
        canvas.drawCircle(Offset(0, -s * 0.225), s * 0.035,
            Paint()..color = const Color(0xFFF28CA0));
        canvas.restore();
      case BlobAccessory.catEars:
        const fur = Color(0xFF3F3A45);
        const inner = Color(0xFFF2A7B5);
        for (final dir in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(dir * s * 0.2, top + s * 0.075);
          canvas.rotate(dir * 0.38);
          canvas.drawPath(
            Path()
              ..moveTo(-s * 0.07, s * 0.02)
              ..lineTo(0, -s * 0.13)
              ..lineTo(s * 0.07, s * 0.02)
              ..close(),
            Paint()..color = fur,
          );
          canvas.drawPath(
            Path()
              ..moveTo(-s * 0.035, 0)
              ..lineTo(0, -s * 0.08)
              ..lineTo(s * 0.035, 0)
              ..close(),
            Paint()..color = inner,
          );
          canvas.restore();
        }
        canvas.drawPath(
          Path()
            ..moveTo(-s * 0.34, top + s * 0.15)
            ..quadraticBezierTo(0, top - s * 0.12, s * 0.34, top + s * 0.15),
          _line(fur, s * 0.026),
        );
      case BlobAccessory.flower:
        canvas.save();
        canvas.translate(rx * 0.55, top + ry * 0.25);
        _leaf(canvas, Offset(s * 0.02, s * 0.01), s * 0.1, 0.5,
            const Color(0xFF7DB765));
        final petal = Paint()..color = const Color(0xFFF7B2C4);
        for (var k = 0; k < 5; k++) {
          final a = k * 2 * math.pi / 5 - math.pi / 2;
          canvas.drawCircle(
              Offset(math.cos(a), math.sin(a)) * (s * 0.045), s * 0.038, petal);
        }
        canvas.drawCircle(
            Offset.zero, s * 0.028, Paint()..color = const Color(0xFFF2C04E));
        canvas.restore();
      case BlobAccessory.peci:
        final cap = Path()
          ..moveTo(-s * 0.25, top + s * 0.085)
          ..quadraticBezierTo(0, top + s * 0.115, s * 0.25, top + s * 0.085)
          ..lineTo(s * 0.225, top - s * 0.06)
          ..quadraticBezierTo(0, top - s * 0.085, -s * 0.225, top - s * 0.06)
          ..close();
        canvas.drawPath(
          cap,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A4752), Color(0xFF2B2A30)],
            ).createShader(cap.getBounds()),
        );
        canvas.drawPath(
          Path()
            ..moveTo(-s * 0.18, top - s * 0.045)
            ..quadraticBezierTo(0, top - s * 0.068, s * 0.12, top - s * 0.05),
          _line(Colors.white.withValues(alpha: 0.18), s * 0.012),
        );
      case BlobAccessory.witchHat:
        canvas.save();
        canvas.translate(0, top + s * 0.035);
        canvas.rotate(-0.08);
        const purple = Color(0xFF6B4C9A);
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: s * 0.56, height: s * 0.1),
          Paint()..color = _darker(purple, 0.12),
        );
        final cone = Path()
          ..moveTo(-s * 0.14, -s * 0.015)
          ..cubicTo(
              -s * 0.09, -s * 0.15, -s * 0.06, -s * 0.27, s * 0.08, -s * 0.33)
          ..cubicTo(
              s * 0.03, -s * 0.24, s * 0.1, -s * 0.12, s * 0.14, -s * 0.015)
          ..close();
        canvas.drawPath(cone, Paint()..color = purple);
        canvas.save();
        canvas.clipPath(cone);
        canvas.drawRect(
            Rect.fromLTRB(-s * 0.2, -s * 0.065, s * 0.2, -s * 0.025),
            Paint()..color = const Color(0xFFF2C04E));
        canvas.restore();
        canvas.restore();
      case BlobAccessory.santaHat:
        const red = Color(0xFFD9473F);
        const fur = Color(0xFFFBF8F3);
        // White fur on pale paper needs an edge to show.
        final furEdge = _line(const Color(0xFFDCD4C7), s * 0.008);
        // Its tip flops down over one side, the pompom on its head.
        final tip = Offset(s * 0.3, top + s * 0.1);
        final cap = Path()
          ..moveTo(-s * 0.21, top + s * 0.07)
          ..cubicTo(-s * 0.2, top - s * 0.14, s * 0.2, top - s * 0.17,
              tip.dx + s * 0.02, tip.dy - s * 0.02)
          ..lineTo(tip.dx - s * 0.04, tip.dy - s * 0.01)
          ..quadraticBezierTo(s * 0.2, top - s * 0.02, s * 0.21, top + s * 0.07)
          ..close();
        canvas.drawPath(cap, Paint()..color = red);
        final band = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(0, top + s * 0.07),
              width: s * 0.48,
              height: s * 0.08),
          Radius.circular(s * 0.04),
        );
        canvas.drawRRect(band, Paint()..color = fur);
        canvas.drawRRect(band, furEdge);
        canvas.drawCircle(tip, s * 0.045, Paint()..color = fur);
        canvas.drawCircle(tip, s * 0.045, furEdge);
      default:
        return;
    }
  }
}
