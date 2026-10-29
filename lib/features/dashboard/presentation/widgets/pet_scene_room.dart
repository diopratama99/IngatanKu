part of 'pet_scene.dart';

// ════════════════════════════════════════════════════════════════════════
// Layout — one place that knows where every piece of furniture goes, so
// the painter and the tappable widgets always line up.
// ════════════════════════════════════════════════════════════════════════

class _Room {
  final Size size;
  _Room(this.size);

  double get w => size.width;
  double get h => size.height;

  /// Where the back wall meets the floor.
  double get wall => h * 0.6;

  /// The pet's feet.
  double get groundY => h * 0.875;

  /// How far up the screen its feet go when it walks all the way back
  /// (depth 1): to just in front of the furniture along the wall.
  double get backLift => 74 * _sy;
  double get petS => (h * 0.29).clamp(56.0, 136.0);

  // Furniture is placed in a 320 × 400 reference room: positions stretch
  // with the scene, sizes scale evenly so no piece gets squashed (a short
  // scene, with the keyboard up, just gets smaller furniture).
  double get _sx => w / 320;
  double get _sy => h / 400;
  double get _k => math.min(_sx, _sy);

  /// A piece [width] wide in the reference room, with [aspect] (w / h)
  /// from its image, standing with its bottom centre at ([x], [y]).
  Rect _piece(double x, double y, double width, double aspect) {
    final pw = width * _k;
    final ph = pw / aspect;
    return Rect.fromLTWH(x * _sx - pw / 2, y * _sy - ph, pw, ph);
  }

  Rect get shelf => _piece(54, 252, 104, 325 / 471);

  /// Hung over the shelf, centred on its books (the vine hangs off the
  /// right).
  Rect get pegboard {
    final pw = 72 * _k;
    final ph = 54 * _k;
    return Rect.fromLTWH(shelf.left + shelf.width * 0.4 - pw / 2,
        shelf.top - 8 * _k - ph, pw, ph);
  }

  /// Centred in the gap between the shelf's body (its image ends with the
  /// vine, 80% across) and the console, on the same floor line.
  Rect get plant {
    final gapLeft = shelf.left + shelf.width * 0.8;
    final gapRight = console.left;
    final p = _piece(0, 252, 34, 161 / 278);
    return p.shift(Offset((gapLeft + gapRight) / 2 - p.center.dx, 0));
  }

  Rect get console => _piece(194, 252, 128, 434 / 188);

  /// On the console, its stand resting a little into the top.
  Rect get tv {
    final pw = 108 * _k;
    final ph = pw / (392 / 302);
    return Rect.fromLTWH(
        console.center.dx - pw / 2, console.top + 6 * _k - ph, pw, ph);
  }

  /// The TV image's screen.
  Rect get screen => Rect.fromLTWH(tv.left + tv.width * 0.033,
      tv.top + tv.height * 0.046, tv.width * 0.934, tv.height * 0.745);

  /// The wall clock on the right, between the calendar and the lamp and a
  /// little higher than the calendar.
  Rect get clock => Rect.fromCenter(
      center: Offset(234 * _sx, calendar.center.dy - 14 * _k),
      width: 44 * _k,
      height: 44 * _k);

  /// How far a wall piece's shadow falls (away from the lamp) for a piece
  /// standing [depth] reference px out from the wall.
  Offset shadowOn(Rect r, double depth) {
    final d = r.center - lampHead;
    return d / math.max(1, d.distance) * depth * 1.6 * _k;
  }

  /// The gecko's ways across the wall (reference px → scene px): out from
  /// behind the pegboard; in from the right to above the clock; and in
  /// from the right to hunt round the lamp. Each starts and ends out of
  /// sight.
  List<List<GeckoStop>> get geckoRoutes {
    Offset at(double x, double y) => Offset(x * _sx, y * _sy);
    const beat = Duration(milliseconds: 300);
    const look = Duration(milliseconds: 900);
    const chirp = Duration(milliseconds: 1900);
    return [
      [
        GeckoStop(at(44, 66)),
        GeckoStop(at(100, 58), pause: look),
        GeckoStop(at(128, 44), pause: chirp, chirp: true),
        GeckoStop(at(104, 60), pause: beat),
        GeckoStop(at(44, 68)),
      ],
      [
        GeckoStop(at(368, 24)),
        GeckoStop(at(290, 22), pause: beat),
        GeckoStop(at(262, 30), pause: chirp, chirp: true),
        GeckoStop(at(300, 18), pause: beat),
        GeckoStop(at(370, 14)),
      ],
      [
        GeckoStop(at(368, 44)),
        GeckoStop(at(318, 60), pause: beat),
        GeckoStop(at(296, 88),
            pause: const Duration(milliseconds: 2600), chirp: true),
        GeckoStop(at(322, 66), pause: beat),
        GeckoStop(at(370, 52)),
      ],
    ];
  }

  /// The wall calendar hanging above the TV.
  Rect get calendar {
    final cw = math.max(28.0, 40 * _k);
    final ch = cw * 1.15;
    return Rect.fromCenter(
        // A little left of the TV's middle.
        center: Offset(tv.center.dx - 22 * _k, tv.top - h * 0.03 - ch / 2),
        width: cw,
        height: ch);
  }

  /// In the corner, standing on the same line as the TV console; its foot
  /// shows above the armchair's arm.
  Rect get lamp => _piece(302, 252, 54, 155 / 444);
  Offset get lampHead =>
      Offset(lamp.center.dx - lamp.width * 0.08, lamp.top + lamp.height * 0.1);
  Rect get chair => _piece(262, 332, 104, 470 / 445);
  Rect get sideTable => _piece(34, 340, 54, 208 / 341);

  // ── Shadows ────────────────────────────────────────────────────────
  // The floor lamp is the only light in the room: every shadow falls away
  // from it, and the further a piece is from the lamp the longer, softer
  // and fainter its shadow.

  /// The lamp's foot, where its light lands on the floor.
  Offset get _lampFoot => Offset(lamp.center.dx, lamp.bottom);

  /// 0 next to the lamp … 1 across the room.
  double _far(double dist) => (dist / (w * 0.9)).clamp(0.0, 1.0);

  /// A silhouette thrown on the wall behind a piece that stands [depth]
  /// (reference px) out from it.
  _Shadow _onWall(String name, Rect r, double depth) {
    final d = r.center - lampHead;
    final far = _far(d.distance);
    final u = d / math.max(1, d.distance);
    return _Shadow(
      name,
      r,
      offset: u * depth * (0.7 + 0.9 * far) * _k,
      blur: (4 + depth * 0.5 + 9 * far) * _k,
      strength: 1 - 0.3 * far,
    );
  }

  List<_Shadow> get wallShadows => [
        _onWall('bookshelf', shelf, 10),
        _onWall('tv_console', console, 9),
        _onWall('tv', tv, 12),
        _onWall('plant', plant, 8),
      ];

  /// A silhouette laid on the floor from a free-standing piece's feet,
  /// stretching away from the lamp.
  _Shadow _onFloor(String name, Rect r) {
    final d = Offset(r.center.dx, r.bottom) - _lampFoot;
    final far = _far(d.distance);
    final u = d / math.max(1, d.distance);
    final length = 0.3 + 0.5 * far; // × the piece's height
    final squash = (u.dy * length).clamp(0.14, 0.3);
    return _Shadow(
      name,
      r,
      squash: squash,
      // Kept from running off across the room (or off screen).
      lean: (u.dx * length / squash).clamp(-1.2, 1.2),
      blur: (5 + 6 * far) * _k,
      strength: 1 - 0.25 * far,
    );
  }

  List<_Shadow> get castShadows => [
        _onFloor('armchair', chair),
        _onFloor('side_table', sideTable),
      ];

  /// Soft dark ovals where each piece meets the floor (with how dark each
  /// is), nudged a little away from the lamp.
  List<(Rect, double)> get contactShadows {
    Rect at(Rect r, double cx, double width, double height, [double up = 2]) {
      final c = Offset(r.left + r.width * cx, r.bottom - up * _k);
      final d = c - _lampFoot;
      final away = d / math.max(1, d.distance) * 3 * _k;
      return Rect.fromCenter(
          center: c + Offset(away.dx, 0),
          width: r.width * width,
          height: height * _k);
    }

    return [
      (at(shelf, 0.4, 0.8, 11), 1),
      (at(console, 0.5, 0.96, 10), 1),
      (at(tv, 0.5, 0.42, 4, 1), 0.85),
      (at(plant, 0.5, 0.6, 7), 0.9),
      (at(lamp, 0.5, 0.5, 5), 0.7),
      (at(sideTable, 0.5, 1.0, 14, 6), 0.75),
      (at(chair, 0.5, 0.9, 12, 4), 0.6),
      (rug.shift(Offset(0, 3 * _k)).inflate(2 * _k), 0.4),
    ];
  }

  /// Where legs touch the floor (measured on the images), for the small
  /// dark spots right under each foot.
  List<Offset> get feet {
    Offset at(Rect r, double x, double y) =>
        Offset(r.left + r.width * x, r.top + r.height * y);
    return [
      at(sideTable, 0.11, 0.995),
      at(sideTable, 0.86, 0.965),
      at(sideTable, 0.43, 0.86),
      at(chair, 0.12, 0.945),
      at(chair, 0.73, 0.995),
      at(chair, 0.87, 0.905),
      at(console, 0.07, 0.99),
      at(console, 0.93, 0.99),
    ];
  }

  /// Under the pet, its blue middle where the pet sits.
  Rect get rug {
    final rw = 236 * _k;
    return Rect.fromCenter(
        center: Offset(w / 2, groundY + 6 * _sy),
        width: rw,
        height: rw / (468 / 171));
  }
}

class _RoomColors {
  final Color line;
  final Color glow;

  /// The floor: by the wall, towards us, the light pooling in the middle,
  /// and the shade at its sides.
  final Color floorBack;
  final Color floorFront;
  final Color floorLight;
  final Color floorEdge;

  /// The notebook the pet writes in: its pages and cover.
  final Color paper;
  final Color cover;

  const _RoomColors({
    required this.line,
    required this.glow,
    required this.floorBack,
    required this.floorFront,
    required this.floorLight,
    required this.floorEdge,
    required this.paper,
    required this.cover,
  });

  static const room = _RoomColors(
    line: Color(0xFFDCD5C9),
    glow: Color(0xFFFFE6B0),
    floorBack: Color(0xFFE7D9C5),
    floorFront: Color(0xFFF2E9DC),
    floorLight: Color(0xFFFCF8F2),
    floorEdge: Color(0x1A7A5A36),
    paper: Color(0xFFFBFAF7),
    cover: Color(0xFFD9DCEF),
  );
}

/// A piece's silhouette as a shadow: which image and where the piece is,
/// how soft and how dark (0..1) the shadow is, and either how far it
/// falls on the wall ([offset]) or how it lies on the floor — squashed to
/// [squash] of the piece's height and leaning by [lean] (dx per dy).
class _Shadow {
  final String name;
  final Rect rect;
  final Offset offset;
  final double blur;
  final double strength;
  final double squash;
  final double lean;
  const _Shadow(
    this.name,
    this.rect, {
    this.offset = Offset.zero,
    required this.blur,
    this.strength = 1,
    this.squash = 0.3,
    this.lean = 0,
  });
}

class _WallShadow extends StatelessWidget {
  final _Shadow shadow;
  const _WallShadow({required this.shadow});

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: shadow.rect.shift(shadow.offset),
      child: IgnorePointer(
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: shadow.blur,
            sigmaY: shadow.blur,
            tileMode: TileMode.decal,
          ),
          child: Image.asset(
            'assets/home/${shadow.name}.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            color: Colors.black.withValues(alpha: (0.3) * shadow.strength),
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

/// A piece's silhouette laid flat on the floor from its feet, stretching
/// away from the lamp.
class _CastShadow extends StatelessWidget {
  final _Shadow shadow;
  const _CastShadow({required this.shadow});

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: shadow.rect,
      child: IgnorePointer(
        child: Transform(
          alignment: Alignment.bottomCenter,
          // Flipped down onto the floor, squashed and leaning away.
          transform: Matrix4.skewX(math.atan(shadow.lean))
            ..scaleByDouble(1.0, -shadow.squash, 1.0, 1.0),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: shadow.blur,
              sigmaY: shadow.blur / math.max(0.3, shadow.squash),
              tileMode: TileMode.decal,
            ),
            child: Image.asset(
              'assets/home/${shadow.name}.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              excludeFromSemantics: true,
              color: Colors.black.withValues(alpha: (0.22) * shadow.strength),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

/// One illustrated piece of furniture from `assets/home/`, laid out at
/// [rect].
class _Furniture extends StatelessWidget {
  final String name;
  final String? semanticsLabel;
  final VoidCallback? onTap;
  const _Furniture(this.name, {this.semanticsLabel, this.onTap});

  static Widget at(Rect rect, String name,
          {String? semanticsLabel, VoidCallback? onTap}) =>
      Positioned.fromRect(
        rect: rect,
        child: _Furniture(name, semanticsLabel: semanticsLabel, onTap: onTap),
      );

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/home/$name.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    if (onTap == null) return IgnorePointer(child: image);
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: image,
      ),
    );
  }
}

/// A little wall calendar: the month ("OCT") on a red band, today's date
/// under it.
class _WallCalendar extends StatelessWidget {
  final VoidCallback? onTap;
  const _WallCalendar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    const band = Color(0xFFE5675A);
    final now = DateTime.now();
    // "OCT", "JAN", "OKT"… in the app's language.
    final month = DateFormat.MMM(Localizations.localeOf(context).toString())
        .format(now)
        .replaceAll('.', '')
        .toUpperCase();
    return Semantics(
      button: onTap != null,
      label: MaterialLocalizations.of(context).formatFullDate(now),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFDCD5C9)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 7,
                          offset: const Offset(-4, 1),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Container(
                          height: h * 0.32,
                          width: double.infinity,
                          color: band,
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              month,
                              style: AppFonts.display(
                                fontSize: h * 0.17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                height: 1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${now.day}',
                              style: AppFonts.display(
                                fontSize: h * 0.4,
                                fontWeight: FontWeight.w700,
                                height: 1,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Two rings where the pages are bound.
                for (final x in [0.3, 0.7])
                  Positioned(
                    left: w * x - 2,
                    top: -2,
                    child: Container(
                      width: 4,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B675E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════
// The room behind the furniture: floor, lamp glow, the calendar's nail
// ════════════════════════════════════════════════════════════════════════

class _LivingRoomPainter extends CustomPainter {
  final _Room room;
  final _RoomColors colors;
  _LivingRoomPainter({required this.room, required this.colors});

  Paint get _stroke => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeJoin = StrokeJoin.round
    ..color = colors.line;

  @override
  void paint(Canvas canvas, Size size) {
    final w = room.w;
    final h = room.h;

    // The floor runs past the scene's side padding to the screen edges.
    // Painted in layers on its own, then faded into the page at the bottom.
    final floor = Rect.fromLTRB(-40, room.wall, w + 40, h + 8);
    final depth = floor.height;
    canvas.saveLayer(floor, Paint());
    // Warm tone, deeper by the wall and lighter towards us.
    canvas.drawRect(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.floorBack, colors.floorFront],
          stops: const [0, 0.6],
        ).createShader(floor),
    );
    // Light pooling in the middle of the room, where the pet sits.
    final pool = Rect.fromCenter(
        center: Offset(w / 2, room.groundY - depth * 0.05),
        width: w * 1.25,
        height: depth * 1.5);
    canvas.drawOval(
      pool,
      Paint()
        ..shader = RadialGradient(colors: [
          colors.floorLight,
          colors.floorLight.withValues(alpha: 0),
        ]).createShader(pool),
    );
    // Warm spill from the floor lamp.
    final spill = Rect.fromCenter(
        center: Offset(room.lamp.center.dx, room.wall + depth * 0.2),
        width: w * 0.8,
        height: depth * 0.9);
    canvas.drawOval(
      spill,
      Paint()
        ..shader = RadialGradient(colors: [
          colors.glow.withValues(alpha: 0.28),
          colors.glow.withValues(alpha: 0),
        ]).createShader(spill),
    );
    // A touch of shade towards the sides.
    canvas.drawRect(
      floor,
      Paint()
        ..shader = LinearGradient(
          colors: [
            colors.floorEdge,
            colors.floorEdge.withValues(alpha: 0),
            colors.floorEdge.withValues(alpha: 0),
            colors.floorEdge,
          ],
          stops: const [0.02, 0.3, 0.7, 0.98],
        ).createShader(floor),
    );
    // Melt into the page below the room.
    canvas.drawRect(
      floor,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.6, 1],
        ).createShader(floor),
    );
    canvas.restore();
    canvas.drawLine(Offset(-40, room.wall), Offset(w + 40, room.wall), _stroke);

    // A little shade where the wall meets the floor, so the room has depth.
    final k = room.petS / 116;
    final shade = Colors.black.withValues(alpha: 0.07);
    final above = Rect.fromLTRB(-40, room.wall - 14 * k, w + 40, room.wall);
    canvas.drawRect(
        above,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [shade.withValues(alpha: 0), shade],
          ).createShader(above));
    final below = Rect.fromLTRB(-40, room.wall, w + 40, room.wall + 22 * k);
    canvas.drawRect(
        below,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [shade, shade.withValues(alpha: 0)],
          ).createShader(below));

    // Contact shadows where each piece stands on the floor.
    // A tight dark spot right under each foot.
    for (final foot in room.feet) {
      canvas.drawOval(
        Rect.fromCenter(center: foot, width: 9 * k, height: 3.5 * k),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.6 * k),
      );
    }
    for (final (oval, strength) in room.contactShadows) {
      canvas.drawOval(
        oval,
        Paint()
          ..color = Colors.black.withValues(alpha: (0.42) * strength)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, math.max(3, oval.height * 0.5)),
      );
    }

    // Warm glow from the floor lamp, behind everything else.
    final head = room.lampHead;
    final r = h * 0.22;
    canvas.drawCircle(
      head,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          colors.glow.withValues(alpha: 0.45),
          colors.glow.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: head, radius: r)),
    );

    // The nail and string the quiz calendar hangs from.
    final c = room.calendar;
    final nail = Offset(c.center.dx, c.top - h * 0.03);
    for (final dx in [-0.25, 0.25]) {
      canvas.drawLine(
          nail, Offset(c.center.dx + c.width * dx, c.top + 2), _stroke);
    }
    canvas.drawCircle(nail, 2.2, Paint()..color = colors.line);
  }

  @override
  bool shouldRepaint(covariant _LivingRoomPainter old) =>
      old.room.size != room.size || old.colors != colors;
}
