part of 'pet_activities.dart';

// ════════════════════════════════════════════════════════════════════════
// Butik — trying things on
// ════════════════════════════════════════════════════════════════════════

/// The boutique's fitting corner: a clothes rack on the left, the pet on a
/// rug in the middle wearing what you've picked, a standing mirror and a
/// plant on the right. Each new thing it tries on, it twirls to show it
/// off; between times it checks itself in the mirror.
class PetFittingRoom extends StatefulWidget {
  /// Being tried on. Null: what it's wearing anyway.
  final BlobAccessory? accessory;
  final BlobOutfit? outfit;

  const PetFittingRoom({super.key, this.accessory, this.outfit});

  @override
  State<PetFittingRoom> createState() => _PetFittingRoomState();
}

class _PetFittingRoomState extends State<PetFittingRoom>
    with _Chatter<PetFittingRoom> {
  @override
  List<String> get lines {
    final l10n = AppLocalizations.of(context)!;
    return [l10n.shopPetLine1, l10n.shopPetLine2];
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

  @override
  void didUpdateWidget(covariant PetFittingRoom old) {
    super.didUpdateWidget(old);
    final newHat =
        widget.accessory != null && widget.accessory != old.accessory;
    final newOutfit = widget.outfit != null && widget.outfit != old.outfit;
    if (newHat || newOutfit) _showOff();
  }

  /// A twirl and a word for each new thing.
  void _showOff() {
    final l10n = AppLocalizations.of(context)!;
    final said = [l10n.shopPetReact1, l10n.shopPetReact2, l10n.shopPetReact3];
    pet.idle(BlobIdle.spin);
    say(said[_rng.nextInt(said.length)]);
  }

  /// A look in the mirror, a wave or a hum.
  @override
  Future<void> idleOnce(math.Random rng) async {
    final l10n = AppLocalizations.of(context)!;
    final roll = petLow ? 70 + rng.nextInt(30) : rng.nextInt(100);
    try {
      if (roll < 40) {
        // The mirror's to its right.
        pet.focus(const Offset(1, -0.1));
        if (!await pause(800)) return;
        pet.beam(duration: const Duration(milliseconds: 1400));
        say(l10n.shopPetMirror);
        await pause(2000);
      } else if (roll < 70) {
        pet.idle(BlobIdle.wave);
        say(l10n.petIdleWave);
        await pause(2100);
      } else {
        pet.idle(BlobIdle.hum);
        await pause(3300);
      }
    } finally {
      if (mounted) pet.focus(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 176,
      child: LayoutBuilder(builder: (context, c) {
        final room = _Boutique(c.biggest);
        final s = room.petS;
        final ground = room.ground;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _RoomFloorPainter(
                  floorY: room.floorY,
                  pool: Offset(room.petX, c.maxHeight),
                  glow: (room.light, c.maxHeight * 0.6),
                  shadows: [
                    for (final r in room.standing) (r, 0.9),
                  ],
                  k: room.k,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _BoutiquePainter(room)),
              ),
            ),
            _Prop.at(room.rug, 'home/rug'),
            _Prop.at(room.plant, 'home/plant'),
            Positioned(
              left: room.petX - s * BlobMascot.widthFactor / 2,
              top: ground - s * BlobMascot.heightFactor + s * 0.05,
              child: _Actor(
                size: s,
                controller: pet,
                accessory: widget.accessory,
                outfit: widget.outfit,
                onPet: () => onPetted(l10n.shopPetPetted),
                onBonk: onBonked,
              ),
            ),
            Positioned(
              left: room.petX - 130,
              width: 260,
              bottom: c.maxHeight - (ground - _bodyHeight(s) - s * 0.14),
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

/// Where everything in the fitting corner goes, in a 340 × 176 reference
/// room: positions stretch with the scene, sizes scale evenly.
class _Boutique {
  final Size size;
  _Boutique(this.size);

  double get w => size.width;
  double get h => size.height;
  double get _sx => w / 340;
  double get _sy => h / 176;
  double get k => math.min(_sx, _sy);

  double get floorY => 118 * _sy;
  double get ground => 156 * _sy;
  double get petX => w / 2;
  double get petS => (104 * k).clamp(72.0, 112.0);

  Rect _piece(double x, double y, double width, double aspect) {
    final pw = width * k;
    final ph = pw / aspect;
    return Rect.fromLTWH(x * _sx - pw / 2, y * _sy - ph, pw, ph);
  }

  Rect get rug {
    final rw = 176 * k;
    return Rect.fromCenter(
        center: Offset(petX, ground + 4 * _sy),
        width: rw,
        height: rw / (468 / 171));
  }

  Rect get plant => _piece(318, 146, 30, 161 / 278);

  /// The rack: its rail along the top, its posts down to the floor.
  Rect get rack => Rect.fromLTRB(12 * _sx, 30 * _sy, 98 * _sx, 140 * _sy);

  /// Folded sweaters on the floor under the rack.
  Rect get folded => Rect.fromCenter(
      center: Offset(55 * _sx, 132 * _sy), width: 38 * k, height: 18 * k);

  /// The standing mirror (its arched glass and its little stand).
  Rect get mirror {
    final mw = 44 * k;
    final mh = 100 * k;
    return Rect.fromLTWH(262 * _sx - mw / 2, 142 * _sy - mh, mw, mh);
  }

  /// Daylight on the wall behind the mirror.
  Offset get light =>
      Offset(mirror.center.dx, mirror.top + mirror.height * 0.2);

  /// Where things stand on the floor, for their shadows.
  List<Rect> get standing => [
        for (final x in [rack.left, rack.right])
          Rect.fromCenter(
              center: Offset(x, rack.bottom), width: 16 * k, height: 4 * k),
        Rect.fromCenter(
            center: Offset(folded.center.dx, folded.bottom),
            width: folded.width * 0.9,
            height: 5 * k),
        Rect.fromCenter(
            center: Offset(mirror.center.dx, mirror.bottom),
            width: mirror.width * 0.9,
            height: 5 * k),
        Rect.fromCenter(
            center: Offset(plant.center.dx, plant.bottom - 1.5 * k),
            width: plant.width * 0.7,
            height: 6 * k),
      ];
}

/// The rack with its hanging clothes, the folded pile and the mirror —
/// drawn in the rooms' quiet way: soft fills, hairline outlines.
class _BoutiquePainter extends CustomPainter {
  final _Boutique room;
  _BoutiquePainter(this.room);

  static const _wood = Color(0xFFE2D3BC);
  static const _woodLine = Color(0xFFCDBDA4);

  /// Soft cloth colours, each with its outline.
  static const _cloth = [
    (Color(0xFFEBC4BC), Color(0xFFD9A79D)), // rose
    (Color(0xFFC5D8EA), Color(0xFFA5BFD8)), // sky
    (Color(0xFFEFDFB2), Color(0xFFD9C690)), // butter
    (Color(0xFFC9DDC2), Color(0xFFA9C4A0)), // sage
    (Color(0xFFDCCDEA), Color(0xFFC1AFD6)), // lilac
  ];

  Paint _line(Color c, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c;

  @override
  void paint(Canvas canvas, Size size) {
    final k = room.k;
    _paintRack(canvas, k);
    _paintFolded(canvas, k);
    _paintMirror(canvas, k);
  }

  void _paintRack(Canvas canvas, double k) {
    final r = room.rack;
    final post = _line(_woodLine, 2.4 * k);
    // Posts and their feet.
    for (final x in [r.left, r.right]) {
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), post);
      canvas.drawLine(Offset(x - 7 * k, r.bottom), Offset(x + 7 * k, r.bottom),
          _line(_woodLine, 2 * k));
    }
    // The rail, a little past each post.
    final rail = RRect.fromRectAndRadius(
      Rect.fromLTRB(
          r.left - 4 * k, r.top - 1.6 * k, r.right + 4 * k, r.top + 1.6 * k),
      Radius.circular(1.6 * k),
    );
    canvas.drawRRect(rail, Paint()..color = _wood);
    canvas.drawRRect(rail, _line(_woodLine, 1));

    // Five things hanging: tee, dress, sweater, tee, dress.
    const kinds = [0, 1, 2, 0, 1];
    const lengths = [1.0, 1.25, 1.1, 0.95, 1.2];
    final gap = (r.width - 16 * k) / (kinds.length - 1);
    for (var i = 0; i < kinds.length; i++) {
      final x = r.left + 8 * k + gap * i;
      final (fill, edge) = _cloth[i % _cloth.length];
      _paintHanging(canvas, Offset(x, r.top), kinds[i], 21 * k * lengths[i],
          18 * k, fill, edge, k);
    }
  }

  /// A hanger on the rail at [at] with a garment ([kind]: 0 tee, 1 dress,
  /// 2 sweater) [length] long and [width] wide.
  void _paintHanging(Canvas canvas, Offset at, int kind, double length,
      double width, Color fill, Color edge, double k) {
    final hanger = _line(const Color(0xFFBFB3A2), 1);
    final shoulders = at.dy + 7 * k;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(at.dx, at.dy + 0.5 * k), radius: 2.2 * k),
      math.pi,
      math.pi * 1.1,
      false,
      hanger,
    );
    canvas.drawLine(Offset(at.dx, at.dy + 2.6 * k),
        Offset(at.dx, shoulders - 2 * k), hanger);

    final hw = width / 2;
    final top = shoulders;
    final path = Path();
    switch (kind) {
      case 1: // dress: thin straps, a flared skirt
        path
          ..moveTo(at.dx - hw * 0.35, top)
          ..lineTo(at.dx - hw * 0.55, top + length * 0.45)
          ..lineTo(at.dx - hw * 1.05, top + length * 1.4)
          ..quadraticBezierTo(
              at.dx, top + length * 1.48, at.dx + hw * 1.05, top + length * 1.4)
          ..lineTo(at.dx + hw * 0.55, top + length * 0.45)
          ..lineTo(at.dx + hw * 0.35, top)
          ..quadraticBezierTo(
              at.dx, top + length * 0.22, at.dx - hw * 0.35, top)
          ..close();
      default: // tee or sweater: sleeves out, short or long
        final sleeve = kind == 2 ? length * 0.95 : length * 0.42;
        final reach = kind == 2 ? hw * 1.18 : hw * 1.35;
        path
          ..moveTo(at.dx - hw * 0.32, top)
          ..lineTo(at.dx - hw, top + length * 0.08)
          ..lineTo(at.dx - reach, top + sleeve)
          ..lineTo(at.dx - hw * 0.82, top + sleeve + length * 0.06)
          ..lineTo(at.dx - hw * 0.8, top + length * 1.15)
          ..lineTo(at.dx + hw * 0.8, top + length * 1.15)
          ..lineTo(at.dx + hw * 0.82, top + sleeve + length * 0.06)
          ..lineTo(at.dx + reach, top + sleeve)
          ..lineTo(at.dx + hw, top + length * 0.08)
          ..lineTo(at.dx + hw * 0.32, top)
          ..quadraticBezierTo(
              at.dx, top + length * 0.16, at.dx - hw * 0.32, top)
          ..close();
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, _line(edge, 1));
    // The hanger's shoulders show over the top.
    canvas.drawPath(
      Path()
        ..moveTo(at.dx - hw * 0.95, top + 2.2 * k)
        ..lineTo(at.dx, top - 2 * k)
        ..lineTo(at.dx + hw * 0.95, top + 2.2 * k),
      hanger,
    );
  }

  void _paintFolded(Canvas canvas, double k) {
    final f = room.folded;
    final layer = f.height / 3;
    for (var i = 0; i < 3; i++) {
      final (fill, edge) = _cloth[(i + 1) % _cloth.length];
      final inset = i * 1.5 * k;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(f.left + inset, f.bottom - layer * (i + 1),
            f.width - inset * 2, layer),
        Radius.circular(2.2 * k),
      );
      canvas.drawRRect(rr, Paint()..color = fill);
      canvas.drawRRect(rr, _line(edge, 1));
    }
  }

  void _paintMirror(Canvas canvas, double k) {
    final m = room.mirror;
    final stand = _line(_woodLine, 2 * k);
    // Its little stand.
    canvas.drawLine(Offset(m.center.dx - m.width * 0.12, m.bottom - 8 * k),
        Offset(m.center.dx - m.width * 0.38, m.bottom), stand);
    canvas.drawLine(Offset(m.center.dx + m.width * 0.12, m.bottom - 8 * k),
        Offset(m.center.dx + m.width * 0.38, m.bottom), stand);
    // The frame, arched at the top, and the glass.
    final frameRect = Rect.fromLTRB(m.left, m.top, m.right, m.bottom - 6 * k);
    final frame = RRect.fromRectAndCorners(
      frameRect,
      topLeft: Radius.circular(m.width / 2),
      topRight: Radius.circular(m.width / 2),
      bottomLeft: Radius.circular(3 * k),
      bottomRight: Radius.circular(3 * k),
    );
    canvas.drawRRect(frame, Paint()..color = _wood);
    canvas.drawRRect(frame, _line(_woodLine, 1));
    final glass = frame.deflate(3.5 * k);
    canvas.drawRRect(
      glass,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7F9FA), Color(0xFFE5ECEF)],
        ).createShader(glass.outerRect),
    );
    canvas.drawRRect(glass, _line(_woodLine.withValues(alpha: 0.6), 1));
    final shine = _line(Colors.white.withValues(alpha: 0.9), 1.6 * k);
    final g = glass.outerRect;
    canvas.drawLine(Offset(g.left + g.width * 0.25, g.top + g.height * 0.32),
        Offset(g.left + g.width * 0.55, g.top + g.height * 0.18), shine);
    canvas.drawLine(Offset(g.left + g.width * 0.25, g.top + g.height * 0.44),
        Offset(g.left + g.width * 0.42, g.top + g.height * 0.36), shine);
  }

  @override
  bool shouldRepaint(covariant _BoutiquePainter old) =>
      old.room.size != room.size;
}
