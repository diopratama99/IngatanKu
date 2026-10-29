part of 'pet_activities.dart';

// ════════════════════════════════════════════════════════════════════════
// Asisten — chatting over tea
// ════════════════════════════════════════════════════════════════════════

class PetChatCorner extends StatefulWidget {
  /// What the pet is saying right now.
  final String? speech;

  /// Show "thinking" dots instead of [speech].
  final bool thinking;

  /// Mouth moves while true (an answer is streaming in).
  final bool talking;

  /// Smaller version for when the keyboard is up.
  final bool compact;

  /// How many answers it has finished; when this goes up it reacts to the
  /// new one: pleased when it [found] notes for it, a little sad when not.
  final int answered;
  final bool found;

  const PetChatCorner({
    super.key,
    required this.speech,
    this.thinking = false,
    this.talking = false,
    this.compact = false,
    this.answered = 0,
    this.found = false,
  });

  @override
  State<PetChatCorner> createState() => _PetChatCornerState();
}

class _PetChatCornerState extends State<PetChatCorner>
    with _Chatter<PetChatCorner> {
  @override
  List<String> get lines => [if (widget.speech != null) widget.speech!];

  @override
  void didUpdateWidget(covariant PetChatCorner old) {
    super.didUpdateWidget(old);
    pet.talk(widget.talking);
    if (widget.thinking && !old.thinking) {
      // Looks up and to the side, serious, while it remembers.
      pet
        ..focus(const Offset(0.6, -0.7))
        ..express(BlobExpression.serious);
    } else if (!widget.thinking && old.thinking) {
      pet
        ..focus(null)
        ..express(null);
    }
    if (widget.answered > old.answered) {
      // Pleased to have remembered something, sorry when it hadn't.
      if (widget.found) {
        pet.beam(duration: const Duration(milliseconds: 1800));
      } else {
        pet.express(BlobExpression.sad,
            duration: const Duration(milliseconds: 1800));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    startChatter();
  }

  @override
  void dispose() {
    stopChatter();
    super.dispose();
  }

  /// Only while you're not chatting (no answer coming, keyboard down).
  @override
  bool get canIdle => !widget.thinking && !widget.talking && !widget.compact;

  /// Between questions: a sip of tea, a wave, a hum, a yawn, a look
  /// around, or nodding off for a second.
  @override
  Future<void> idleOnce(math.Random rng) async {
    final l10n = AppLocalizations.of(context)!;
    final roll = petLow ? 62 + rng.nextInt(38) : rng.nextInt(100);
    try {
      if (roll < 25) {
        // The tea table's to its right.
        pet.focus(const Offset(0.9, 0.35));
        if (!await pause(700)) return;
        pet.beam(duration: const Duration(milliseconds: 1500));
        SoundService.instance.play(Sfx.sip);
        say(l10n.chatIdleSip);
        await pause(1900);
      } else if (roll < 45) {
        pet.idle(BlobIdle.wave);
        say(l10n.petIdleWave);
        await pause(2100);
      } else if (roll < 62) {
        pet.idle(BlobIdle.hum);
        await pause(3300);
      } else if (roll < 77) {
        pet.idle(BlobIdle.stretch);
        say(l10n.petIdleYawn);
        await pause(2500);
      } else if (roll < 90) {
        pet.idle(BlobIdle.lookAround);
        await pause(3100);
      } else {
        pet.idle(BlobIdle.doze);
        await pause(3700);
      }
    } finally {
      // Unless it's started thinking about a question in the meantime.
      if (mounted && !widget.thinking) pet.focus(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Big enough to be the one you're talking to; smaller only while
    // the keyboard is up.
    final h = widget.compact ? 86.0 : 176.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: h,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        final hh = c.maxHeight;
        final s = (hh * (widget.compact ? 0.62 : 0.6)).clamp(48.0, 108.0);
        final cx = w * 0.2;
        final ground = hh * 0.86;
        final corner = _TeaCorner(Size(w, hh));
        final pieces = [
          (corner.flower, 'assistant/flower'),
          (corner.table, 'assistant/tea_table'),
          (corner.plant, 'assistant/vase_plant'),
          (corner.lamp, 'assistant/floor_lamp'),
        ];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // The tea corner (put away while the chat needs the room).
            if (!widget.compact) ...[
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoomFloorPainter(
                    floorY: corner.wallY,
                    pool: Offset(cx + s * 0.6, hh),
                    glow: (corner.lampLight, hh * 0.55),
                    shadows: [
                      for (final (r, _) in pieces) (corner.feet(r), 0.9),
                    ],
                    k: corner.k,
                  ),
                ),
              ),
              for (final (r, asset) in pieces) _Prop.at(r, asset),
            ],
            Positioned(
              left: cx - s * BlobMascot.widthFactor / 2,
              top: ground - s * BlobMascot.heightFactor + s * 0.05,
              child: _Actor(
                size: s,
                controller: pet,
                onPet: () => onPetted(l10n.chatPetPetted),
                onBonk: onBonked,
              ),
            ),
            // Bubble to the pet's upper right, its tail at the head. With
            // the table out it stays clear of the teapot.
            Positioned(
              left: cx + s * (widget.compact ? 0.55 : 0.62),
              right: 0,
              top: 0,
              bottom: widget.compact
                  ? hh - ground + _bodyHeight(s) * 0.55
                  : hh * 0.44,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: PetSpeechBubble(
                  text: currentLine,
                  thinking: widget.thinking && _reaction == null,
                  tailLeft: true,
                  maxWidth: w * 0.64,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Where everything in the tea corner goes, in a 340 × 150 reference room:
/// a floor lamp, the pet, the tea table beside it (a teapot and two cups —
/// one for the pet, one for you), then a potted plant and a little flower
/// (the right side stays clear for the pet's speech bubble).
class _TeaCorner {
  final Size size;
  _TeaCorner(this.size);

  double get _sx => size.width / 340;
  double get _sy => size.height / 150;
  double get k => math.min(_sx, _sy);

  /// Where the wall meets the floor.
  double get wallY => 112 * _sy;

  Rect _piece(double x, double y, double width, double aspect) {
    final pw = width * k;
    final ph = pw / aspect;
    return Rect.fromLTWH(x * _sx - pw / 2, y * _sy - ph, pw, ph);
  }

  Rect get table => _piece(150, 142, 80, 417 / 287);
  Rect get plant => _piece(232, 140, 28, 124 / 201);
  Rect get lamp => _piece(15, 138, 30, 185 / 439);
  Rect get flower => _piece(260, 141, 18, 111 / 125);

  /// The floor lamp's bulb, under its shade.
  Offset get lampLight =>
      Offset(lamp.left + lamp.width * 0.42, lamp.top + lamp.height * 0.16);

  /// The shadow where [r] stands on the floor.
  Rect feet(Rect r) => Rect.fromCenter(
      center: Offset(r.center.dx, r.bottom - 1.5 * k),
      width: r.width * 0.7,
      height: 6 * k);
}
