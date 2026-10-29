part of 'pet_activities.dart';

// ════════════════════════════════════════════════════════════════════════
// Pustaka — reading in the library
// ════════════════════════════════════════════════════════════════════════

/// The pet's reading nook on Pustaka, like a corner of a library: the wall
/// lined with floating shelves full of books (illustrated pieces from
/// `assets/library/`, a few stacks, a box and little plants among them),
/// books on the floor, and the rug the pet sits on reading.
class PetReadingNook extends StatefulWidget {
  final List<String> lines;
  final double height;
  const PetReadingNook({super.key, required this.lines, this.height = 220});

  @override
  State<PetReadingNook> createState() => _PetReadingNookState();
}

class _PetReadingNookState extends State<PetReadingNook>
    with TickerProviderStateMixin, _Chatter {
  /// One loop = read a page, then flip it. Made up front (not lazily):
  /// an egg has no book, so the first use could otherwise be dispose().
  late final AnimationController _page;

  /// 0..1: how far the book's been lowered from its face (to tease you).
  late final AnimationController _lower;

  /// Has it teased you yet since the page opened?
  bool _teased = false;

  @override
  List<String> get lines => widget.lines;

  @override
  void initState() {
    super.initState();
    _page = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )
      ..addListener(_rustle)
      ..repeat();
    _lower = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    startChatter();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => pet.focus(const Offset(0, 0.95), scan: true));
  }

  @override
  void dispose() {
    stopChatter();
    _page.dispose();
    _lower.dispose();
    super.dispose();
  }

  double _lastPage = 0;

  /// A soft rustle as each page turns (the book's last stretch of a loop).
  void _rustle() {
    final v = _page.value;
    if (_lastPage < 0.82 &&
        v >= 0.82 &&
        sl<PetStore>().state.stage != PetStage.egg) {
      SoundService.instance.play(Sfx.pageFlip);
    }
    _lastPage = v;
  }

  /// Looks up from its book now and then — quietly, it's a library:
  /// nodding off over the page, scanning the shelves for the next one, a
  /// giggle at a funny bit, a sneeze from the dusty pages, a look around.
  @override
  Future<void> idleOnce(math.Random rng) async {
    final l10n = AppLocalizations.of(context)!;
    final roll = petLow ? (rng.nextBool() ? 10 : 30) : rng.nextInt(100);
    _page.stop();
    try {
      if (!_teased || rng.nextDouble() < 0.18) {
        // Lowers its book, looks down its nose at you and grins.
        _teased = true;
        await _lower.forward();
        if (!mounted) return;
        pet
          ..focus(const Offset(0, -0.05))
          ..express(BlobExpression.smirk,
              duration: const Duration(milliseconds: 3000));
        say(sl<PetInbox>().mealDoneOn(DateTime.now())
            ? l10n.libraryPetTeaseFed
            : l10n.libraryPetTease);
        if (!await pause(3100)) return;
        await _lower.reverse();
      } else if (roll < 25) {
        say(l10n.libraryIdleDoze);
        pet.idle(BlobIdle.doze);
        await pause(3700);
      } else if (roll < 50) {
        say(l10n.petIdleShelf);
        pet.focus(const Offset(-0.85, -0.75));
        if (!await pause(1500)) return;
        pet.focus(const Offset(0.85, -0.75));
        await pause(1500);
      } else if (roll < 72) {
        pet
          ..focus(const Offset(0, 0.95))
          ..beam(duration: const Duration(milliseconds: 1800));
        // Muffled — it's a library.
        SoundService.instance.play(Sfx.giggle, volume: 0.7);
        say(l10n.libraryIdleGiggle);
        await pause(2000);
      } else if (roll < 90) {
        pet.idle(BlobIdle.sneeze);
        say(l10n.libraryIdleSneeze);
        await pause(1800);
      } else {
        pet.idle(BlobIdle.lookAround);
        await pause(3100);
      }
    } finally {
      if (mounted) {
        pet.focus(const Offset(0, 0.95), scan: true);
        if (_lower.value > 0) _lower.reverse();
        _page.repeat();
      }
    }
  }

  final _pokes = <DateTime>[];

  void _onPoked(AppLocalizations l10n) {
    final now = DateTime.now();
    _pokes
      ..add(now)
      ..removeWhere((t) => now.difference(t) > const Duration(seconds: 5));
    final cross = _pokes.length >= 3;
    if (cross) SoundService.instance.play(Sfx.grumpy, volume: 0.9);
    say(cross ? l10n.libraryPetAngry : l10n.libraryPetShush);
  }

  @override
  Widget build(BuildContext context) {
    const props = _Props.room;
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, c) {
        final nook = _Nook(c.biggest);
        final s = nook.petS;
        final cx = nook.petX;
        final ground = nook.ground;
        final stage = sl<PetStore>().state.stage;
        final scale = stage == PetStage.egg ? PetStage.egg.scale : stage.scale;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _NookFloorPainter(nook: nook),
              ),
            ),
            // The wall of shelves: shadows first, then the shelves.
            for (final (rect, items) in nook.shelves)
              _WallShelf(
                  rect: rect,
                  items: items,
                  k: nook.k,
                  shadow: true),
            for (final (rect, items) in nook.shelves)
              _WallShelf(rect: rect, items: items, k: nook.k),
            _Prop.at(nook.rug, 'library/rug'),
            _Prop.at(nook.openBook, 'library/open_book'),
            _Prop.at(nook.books, 'library/books_stack'),
            // It's reading: taps get a glare and a "shh", and more of them
            // a proper telling-off.
            Positioned(
              left: cx - s * BlobMascot.widthFactor / 2,
              top: ground - s * BlobMascot.heightFactor + s * 0.05,
              child: _Actor(
                size: s,
                controller: pet,
                touchy: true,
                onPet: () => _onPoked(l10n),
              ),
            ),
            if (stage != PetStage.egg)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _lower,
                    builder: (_, __) => CustomPaint(
                      // Held low, its top just under the eyes, so the face
                      // shows above it — lowered further to tease you.
                      painter: _BookPainter(
                        props: props,
                        page: _page,
                        center: Offset(
                            cx,
                            ground -
                                s * 0.15 * scale +
                                Curves.easeInOut.transform(_lower.value) *
                                    s *
                                    0.17 *
                                    scale),
                        width: s * 0.92 * scale,
                        height: s * 0.26 * scale,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: cx - 130,
              width: 260,
              bottom: c.maxHeight - (ground - _bodyHeight(s) - s * 0.12),
              child: IgnorePointer(
                child: Center(child: PetSpeechBubble(text: currentLine)),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Where everything in the reading nook goes. Laid out in a 340 × 220
/// reference room: positions stretch with the scene, sizes scale evenly so
/// nothing gets squashed.
class _Nook {
  final Size size;
  _Nook(this.size);

  double get w => size.width;
  double get h => size.height;
  double get _sx => w / 340;
  double get _sy => h / 220;
  double get k => math.min(_sx, _sy);

  /// Where the wall meets the floor, and where the pet sits.
  double get floorY => 150 * _sy;
  double get ground => 186 * _sy;
  double get petX => w / 2;
  double get petS => (118 * k).clamp(80.0, 124.0);

  /// A piece [width] wide (reference px) with [aspect] (w / h) from its
  /// image, standing with its bottom centre at ([x], [y]).
  Rect _piece(double x, double y, double width, double aspect) {
    final pw = width * k;
    final ph = pw / aspect;
    return Rect.fromLTWH(x * _sx - pw / 2, y * _sy - ph, pw, ph);
  }

  /// How far the shelves (and the books on the floor) keep from each side
  /// — the same on the left and the right.
  double get _margin => 8 * _sx;

  /// The floating shelves on the wall — two on each side, the pet in
  /// between, mirrored about the middle — and what stands on each.
  List<(Rect, List<String>)> get shelves {
    final pw = 150 * k;
    Rect plank(bool left, double top) => Rect.fromLTWH(
        left ? _margin : w - _margin - pw, top * _sy, pw, pw * 46 / 378);
    return [
      (plank(true, 52), _shelfRows[0]),
      (plank(true, 112), _shelfRows[1]),
      (plank(false, 52), _shelfRows[2]),
      (plank(false, 112), _shelfRows[3]),
    ];
  }

  /// What's on each shelf, left to right ('|' is a little gap).
  static const _shelfRows = [
    [
      'book_1',
      'book_2',
      'book_3',
      '|',
      'stack_a',
      '|',
      'book_4',
      '|',
      'plant_small'
    ],
    ['book_group', 'book_6', 'book_1', '|', 'book_pair', 'book_3', 'book_2'],
    [
      'plant_small',
      '|',
      'book_5',
      'book_6',
      'book_pair',
      '|',
      'book_2',
      '|',
      'box'
    ],
    ['stack_b', '|', 'book_3', 'book_1', 'book_2', '|', 'book_group'],
  ];

  /// On the floor, as far in from the left and right edges.
  Rect get openBook {
    final pw = 62 * k;
    return _piece((_margin + 10 * _sx + pw / 2) / _sx, 198, 62, 293 / 106);
  }

  Rect get books {
    final pw = 50 * k;
    return _piece(
        (w - _margin - 10 * _sx - pw / 2) / _sx, 194, 50, 193 / 130);
  }
  Rect get rug {
    final rw = 178 * k;
    return Rect.fromCenter(
        center: Offset(petX, ground + 5 * _sy),
        width: rw,
        height: rw / (614 / 229));
  }

  /// Soft shadows where pieces meet the floor, with how dark each is.
  List<(Rect, double)> get onFloor {
    Rect at(Rect r, double width, double height, [double up = 2]) =>
        Rect.fromCenter(
            center: Offset(r.center.dx, r.bottom - up * k),
            width: r.width * width,
            height: height * k);
    return [
      (at(openBook, 0.9, 6, 2), 0.6),
      (at(books, 0.9, 8, 3), 0.8),
      (rug.shift(Offset(0, 3 * k)).inflate(2 * k), 0.4),
    ];
  }
}

/// The nook's floor: warm, deeper by the wall, lighter where the pet
/// sits, fading out at the sides and into the page below — plus the soft
/// shadows where things stand on it.
class _NookFloorPainter extends CustomPainter {
  final _Nook nook;
  _NookFloorPainter({required this.nook});

  @override
  void paint(Canvas canvas, Size size) {
    final w = nook.w;
    final floor = Rect.fromLTRB(0, nook.floorY, w, nook.h + 12);
    const back = Color(0xFFE7D9C5);
    const front = Color(0xFFF2E9DC);
    const light = Color(0xFFFCF8F2);
    const line = Color(0xFFDCD5C9);

    canvas.saveLayer(floor, Paint());
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [back, front],
          stops: [0, 0.65],
        ).createShader(floor),
    );
    final pool = Rect.fromCenter(
        center: Offset(nook.petX, nook.ground),
        width: w * 1.1,
        height: floor.height * 1.5);
    canvas.drawOval(
      pool,
      Paint()
        ..shader = RadialGradient(colors: [light, light.withValues(alpha: 0)])
            .createShader(pool),
    );
    // Fade into the page at the sides and below.
    for (final (begin, end, stops) in [
      (Alignment.topCenter, Alignment.bottomCenter, const [0.0, 0.65, 1.0]),
      (Alignment.centerLeft, Alignment.centerRight, const [0.0, 0.08, 0.92]),
    ]) {
      canvas.drawRect(
        floor,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: begin == Alignment.topCenter
                ? const [Colors.black, Colors.black, Colors.transparent]
                : const [Colors.transparent, Colors.black, Colors.black],
            stops: stops,
          ).createShader(floor),
      );
    }
    canvas.drawRect(
      floor,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Colors.transparent, Colors.black],
          stops: [0.0, 0.08],
        ).createShader(floor),
    );
    canvas.restore();
    canvas.drawLine(
        Offset(w * 0.04, nook.floorY),
        Offset(w * 0.96, nook.floorY),
        Paint()
          ..strokeWidth = 1
          ..color = line);

    for (final (oval, strength) in nook.onFloor) {
      canvas.drawOval(
        oval,
        Paint()
          ..color =
              Colors.black.withValues(alpha: (0.3) * strength)
          ..maskFilter =
              MaskFilter.blur(BlurStyle.normal, math.max(3, oval.height * 0.5)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NookFloorPainter old) =>
      old.nook.size != nook.size;
}

/// One floating shelf on the nook's wall with its [items] standing on it,
/// left to right ('|' is a little gap). With [shadow] it draws the whole
/// shelf's silhouette instead, blurred onto the wall a little down and to
/// the right.
class _WallShelf extends StatelessWidget {
  final Rect rect;
  final List<String> items;
  final double k;
  final bool shadow;
  const _WallShelf({
    required this.rect,
    required this.items,
    required this.k,
    this.shadow = false,
  });

  /// Image sizes, in pixels.
  static const _sizes = {
    'book_1': Size(76, 149),
    'book_2': Size(73, 147),
    'book_3': Size(75, 147),
    'book_4': Size(75, 147),
    'book_5': Size(80, 146),
    'book_6': Size(77, 138),
    'book_pair': Size(113, 141),
    'book_group': Size(206, 151),
    'stack_a': Size(184, 107),
    'stack_b': Size(177, 109),
    'box': Size(155, 112),
    'plant_small': Size(126, 145),
  };

  /// Reference px per image px: a standing book is about 30 tall.
  static const _scale = 30 / 147;

  @override
  Widget build(BuildContext context) {
    // Things stand on the plank's top face, about halfway back — all of
    // them on the board: if the row is too long for it, everything shrinks
    // a little, and the row sits in the middle of the plank.
    final surface = rect.top + rect.height * 0.5;
    double widthOf(String item) =>
        item == '|' ? 4 : _sizes[item]!.width * _scale + 0.8;
    final natural = items.fold<double>(0, (sum, i) => sum + widthOf(i)) * k;
    final room = rect.width - 16 * k;
    final fit = natural > room ? room / natural : 1.0;
    var x = rect.left + (rect.width - natural * fit) / 2;
    final placed = <Widget>[];
    for (final item in items) {
      if (item == '|') {
        x += 4 * k * fit;
        continue;
      }
      final px = _sizes[item]!;
      final w = px.width * _scale * k * fit;
      final h = px.height * _scale * k * fit;
      placed.add(Positioned(
        left: x,
        top: surface - h,
        width: w,
        height: h,
        child: _Prop('library/$item'),
      ));
      x += w + 0.8 * k * fit;
    }
    final shelf = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
            rect: rect, child: const _Prop('library/plank')),
        ...placed,
      ],
    );
    if (!shadow) return Positioned.fill(child: IgnorePointer(child: shelf));
    return Positioned.fill(
      child: IgnorePointer(
        child: Transform.translate(
          offset: Offset(5 * k, 3 * k),
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
                sigmaX: 5 * k, sigmaY: 5 * k, tileMode: TileMode.decal),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.2),
                  BlendMode.srcIn),
              child: shelf,
            ),
          ),
        ),
      ),
    );
  }
}

/// The open book in the pet's arms. Every loop the right page lifts and
/// turns over to the left.
class _BookPainter extends CustomPainter {
  final _Props props;
  final Animation<double> page;
  final Offset center;
  final double width;
  final double height;
  _BookPainter({
    required this.props,
    required this.page,
    required this.center,
    required this.width,
    required this.height,
  }) : super(repaint: page);

  @override
  void paint(Canvas canvas, Size size) {
    final half = width / 2;
    final top = center.dy - height / 2;
    final bottom = center.dy + height / 2;
    // A blue book with cream pages.
    const cover = Color(0xFF8FA6E0);
    final paper = props.paper;
    final ink = props.line;
    // Cover peeking around the pages.
    props.rrect(
        canvas,
        Rect.fromCenter(
            center: center.translate(0, 2),
            width: width + 6,
            height: height + 4),
        3,
        Color.lerp(cover, Colors.black, 0.08)!);
    Path pageShape(double edgeX, double lift) => Path()
      ..moveTo(center.dx, top + 2)
      ..quadraticBezierTo((center.dx + edgeX) / 2, top - lift, edgeX, top)
      ..lineTo(edgeX, bottom)
      ..quadraticBezierTo(
          (center.dx + edgeX) / 2, bottom - lift, center.dx, bottom - 1)
      ..close();
    for (final edge in [center.dx - half, center.dx + half]) {
      final p = pageShape(edge, 4);
      canvas.drawPath(p, props.fill(paper));
      canvas.drawPath(p, props.stroke);
      // Text lines.
      final dir = edge < center.dx ? -1 : 1;
      for (var i = 0; i < 4; i++) {
        final y = top + height * (0.28 + i * 0.17);
        canvas.drawLine(
          Offset(center.dx + dir * 5, y),
          Offset(edge - dir * (6 + (i == 3 ? half * 0.3 : 0)), y),
          Paint()
            ..strokeWidth = 1
            ..color = ink.withValues(alpha: 0.8),
        );
      }
    }
    // Turning page during the last part of each loop.
    final v = page.value;
    if (v > 0.82) {
      final q = Curves.easeInOut.transform((v - 0.82) / 0.18);
      final edgeX = center.dx + math.cos(q * math.pi) * half;
      final lift = math.sin(q * math.pi) * height * 0.3;
      final p = pageShape(edgeX, lift + 4);
      canvas.drawPath(p, props.fill(Color.lerp(paper, ink, 0.08)!));
      canvas.drawPath(p, props.stroke);
    }
    canvas.drawLine(Offset(center.dx, top + 2), Offset(center.dx, bottom - 1),
        props.stroke);
  }

  @override
  bool shouldRepaint(covariant _BookPainter old) =>
      old.center != center || old.width != width || old.props != props;
}
