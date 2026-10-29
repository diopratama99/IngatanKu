part of 'pet_activities.dart';

// ════════════════════════════════════════════════════════════════════════
// Catatan — writing at the desk
// ════════════════════════════════════════════════════════════════════════

/// The pet's study on Catatan, furnished with illustrated pieces
/// (`assets/notes/`): a pinboard on the wall, and the pet behind its desk
/// writing in a notebook, glasses on — a plant and a mug of tea on one
/// side, books, a pencil cup and a desk lamp on the other.
class PetWritingDesk extends StatefulWidget {
  final List<String> lines;
  final double height;
  const PetWritingDesk({super.key, required this.lines, this.height = 232});

  @override
  State<PetWritingDesk> createState() => _PetWritingDeskState();
}

class _PetWritingDeskState extends State<PetWritingDesk>
    with SingleTickerProviderStateMixin, _Chatter {
  late final AnimationController _write;

  @override
  List<String> get lines => widget.lines;

  @override
  void initState() {
    super.initState();
    // Eyes follow the pencil along each line: it starts out by the book's
    // edge (to the pet's right) and works in towards the spine.
    _write = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )
      ..addListener(() {
        final (_, along) = notebookPenAt(_write.value);
        pet.focus(Offset(0.1 + 0.4 * (1 - along), 1));
      })
      ..repeat();
    startChatter();
  }

  @override
  void dispose() {
    stopChatter();
    _write.dispose();
    super.dispose();
  }

  /// Puts the pencil down for a moment: a sip of tea, a think (and the
  /// idea that follows), a look at the pinboard, nodding off at the desk,
  /// a yawn or a sneeze — then back to writing.
  @override
  Future<void> idleOnce(math.Random rng) async {
    final l10n = AppLocalizations.of(context)!;
    // Quiet ones only when it's hungry or lonely.
    final roll = petLow ? 44 + rng.nextInt(46) : rng.nextInt(100);
    _write.stop();
    try {
      if (roll < 22) {
        // The mug's to its right, on the desk.
        pet.focus(const Offset(0.85, 0.45));
        if (!await pause(700)) return;
        pet.beam(duration: const Duration(milliseconds: 1500));
        SoundService.instance.play(Sfx.sip);
        say(l10n.notesIdleSip);
        await pause(1900);
      } else if (roll < 44) {
        pet.focus(const Offset(-0.55, -0.85));
        say(l10n.notesIdleThink);
        if (!await pause(2400)) return;
        pet
          ..focus(const Offset(0.1, 1))
          ..beam(duration: const Duration(milliseconds: 1300));
        SoundService.instance.play(Sfx.idea);
        say(l10n.notesIdleIdea);
        await pause(1300);
      } else if (roll < 60) {
        // The pinboard's up on the wall to its right.
        pet.focus(const Offset(0.9, -0.75));
        say(l10n.notesIdleBoard);
        await pause(2600);
      } else if (roll < 76) {
        pet.idle(BlobIdle.doze);
        if (!await pause(2500)) return;
        say(l10n.notesIdleDoze);
        await pause(1300);
      } else if (roll < 90) {
        pet.idle(BlobIdle.stretch);
        say(l10n.petIdleYawn);
        await pause(2500);
      } else {
        pet.idle(BlobIdle.sneeze);
        say(l10n.petIdleSneeze);
        await pause(1800);
      }
    } finally {
      if (mounted && !pet.crying.value) _write.repeat();
    }
  }

  @override
  void onCrying(bool crying) => crying ? _write.stop() : _write.repeat();

  @override
  Widget build(BuildContext context) {
    const props = _Props.room;
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(builder: (context, c) {
        final room = _Study(c.biggest);
        final s = room.petS;
        final cx = room.petX;
        final ground = room.ground;
        final store = sl<PetStore>();
        final stage = store.state.stage;
        final scale = stage == PetStage.egg ? PetStage.egg.scale : stage.scale;
        final onDesk = [
          (room.plant, 'notes/plant'),
          (room.mug, 'notes/mug'),
          (room.books, 'notes/books'),
          (room.pencilCup, 'notes/pencil_cup'),
          (room.lamp, 'notes/desk_lamp'),
        ];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Wall and floor, the lamp's glow, shadows on the floor.
            Positioned.fill(
              child: CustomPaint(
                painter: _RoomFloorPainter(
                  floorY: room.wallY,
                  pool: Offset(room.desk.center.dx, room.h),
                  glow: (room.lampLight, room.h * 0.5),
                  shadows: [(room.deskFeet, 1.0)],
                  k: room.k,
                ),
              ),
            ),
            _PropShadow(
                asset: 'notes/corkboard',
                rect: room.corkboard,
                offset: Offset(-5 * room.k, 3 * room.k),
                k: room.k),
            _Prop.at(room.corkboard, 'notes/corkboard'),
            Positioned(
              left: cx - s * BlobMascot.widthFactor / 2,
              top: ground - s * BlobMascot.heightFactor + s * 0.05,
              // Glasses on and a serious face for writing; its hands are
              // drawn on the notebook instead of at its sides.
              child: _Actor(
                size: s,
                controller: pet,
                onPet: () => onPetted(l10n.notesPetPetted),
                onBonk: onBonked,
                glasses: true,
                showArms: false,
                expression: BlobExpression.serious,
              ),
            ),
            // The desk, in front of the pet's lower half.
            _Prop.at(room.desk, 'notes/desk'),
            // What stands on the desk, each with a little shadow, then the
            // notebook it's writing in.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ContactShadows(
                    [
                      for (final (r, _) in onDesk)
                        Rect.fromCenter(
                            center: Offset(r.center.dx - 2 * room.k, r.bottom),
                            width: r.width * 0.9,
                            height: 5 * room.k),
                    ],
                  ),
                ),
              ),
            ),
            for (final (r, asset) in onDesk) _Prop.at(r, asset),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NotebookPainter(
                    props: props,
                    write: _write,
                    nearY: room.deskFront,
                    petX: cx,
                    s: s,
                    scale: scale,
                    // An egg has no hands to write with.
                    hands: stage == PetStage.egg ? null : store.color.shade,
                  ),
                ),
              ),
            ),
            Positioned(
              left: cx - 118,
              width: 236,
              bottom: room.h - (ground - _bodyHeight(s) - s * 0.12),
              child: IgnorePointer(
                child: Center(
                  child: PetSpeechBubble(text: currentLine, maxWidth: 216),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Where everything in the study goes, laid out in a 340 × 232 reference
/// room: positions stretch with the scene, sizes scale evenly so nothing
/// gets squashed.
class _Study {
  final Size size;
  _Study(this.size);

  double get w => size.width;
  double get h => size.height;
  double get _sx => w / 340;
  double get _sy => h / 232;
  double get k => math.min(_sx, _sy);

  /// Where the wall meets the floor (seen between the desk's legs).
  double get wallY => 206 * _sy;

  /// The pet sits left of centre, so its speech bubble (above it) stays
  /// clear of the lamp and the pinboard on the right.
  double get petX => desk.left + desk.width * 0.30;
  double get petS => (h * 0.44).clamp(76.0, 104.0);

  /// The pet's feet: just behind the desk's top, so only its head and
  /// shoulders show over the desk.
  double get ground => deskBack + petS * 0.12;

  /// A piece [width] wide with [aspect] (w / h), its bottom centre at
  /// ([x], [y]) in reference px.
  Rect _piece(double x, double y, double width, double aspect) {
    final pw = width * k;
    final ph = pw / aspect;
    return Rect.fromLTWH(x * _sx - pw / 2, y * _sy - ph, pw, ph);
  }

  Rect get desk => _piece(170, 226, 284, 838 / 302);

  /// The desk's top: its back edge, its front edge (where the notebook
  /// lies) and where things stand on it (towards the back).
  double get deskBack => desk.top + desk.height * 0.01;
  double get deskFront => desk.top + desk.height * 0.15;
  double get _onDesk => desk.top + desk.height * 0.09;

  /// Under the desk's legs.
  Rect get deskFeet => Rect.fromCenter(
      center: Offset(desk.center.dx, desk.bottom - 2 * k),
      width: desk.width * 0.92,
      height: 8 * k);

  /// A piece standing on the desk, centred [along] its width (0–1) — so
  /// it stays on the desk however wide the screen is.
  Rect _onTop(double along, double width, double aspect) {
    final pw = width * k;
    final ph = pw / aspect;
    final x = desk.left + desk.width * along;
    return Rect.fromLTWH(x - pw / 2, _onDesk - ph, pw, ph);
  }

  // Left of the notebook a plant; right of it a mug, books, a pencil cup
  // and the lamp at the end.
  Rect get plant => _onTop(0.085, 24, 123 / 145);
  Rect get mug => _onTop(0.535, 19, 165 / 254);
  Rect get books => _onTop(0.655, 44, 281 / 105);
  Rect get pencilCup => _onTop(0.765, 14, 96 / 174);
  Rect get lamp => _onTop(0.855, 40, 185 / 326);

  /// The lamp's bulb, under its shade.
  Offset get lampLight =>
      Offset(lamp.left + lamp.width * 0.3, lamp.top + lamp.height * 0.2);

  /// On the wall right above the lamp.
  Rect get corkboard {
    final pw = 66 * k;
    final ph = pw / (363 / 266);
    return Rect.fromLTWH(desk.left + desk.width * 0.866 - pw / 2,
        lamp.top - 5 * k - ph, pw, ph);
  }
}

/// The open notebook in front of the pet at its desk, its hands writing in
/// it (see [paintLapNotebook]). Without [hands] (an egg) the page just
/// sits there, half written.
class _NotebookPainter extends CustomPainter {
  final _Props props;
  final Animation<double> write;
  final double nearY;
  final double petX;
  final double s;
  final double scale;
  final Color? hands;
  _NotebookPainter({
    required this.props,
    required this.write,
    required this.nearY,
    required this.petX,
    required this.s,
    required this.scale,
    required this.hands,
  }) : super(repaint: write);

  @override
  void paint(Canvas canvas, Size size) {
    // Cream pages and a lavender cover, like the books in the pictures.
    paintLapNotebook(
      canvas,
      petX: petX,
      nearY: nearY,
      s: s,
      scale: scale,
      progress: hands == null ? 0.55 : write.value,
      paper: const Color(0xFFFFFDF8),
      line: props.line,
      cover: const Color(0xFFC9C3EA),
      hands: hands,
    );
  }

  @override
  bool shouldRepaint(covariant _NotebookPainter old) =>
      old.props != props ||
      old.nearY != nearY ||
      old.petX != petX ||
      old.s != s ||
      old.scale != scale ||
      old.hands != hands;
}
