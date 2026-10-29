part of 'pet_scene.dart';

// ════════════════════════════════════════════════════════════════════════
// Writing a link up
// ════════════════════════════════════════════════════════════════════════

/// The pet's notebook on the floor in front of it — pulled out from below,
/// written in — and then the finished page it holds up for you, with the
/// note's title and tags on it.
class _ScribePainter extends CustomPainter {
  final _Room room;
  final _RoomColors colors;

  /// The pet's sideways offset from the middle of the room, read per frame.
  final double Function() petX;
  final PetStage stage;
  final Color? hands;
  final Animation<double> intro;
  final Animation<double> write;
  final Animation<double> present;
  final String? title;
  final List<String> tags;
  final Color ink;
  final Color accent;

  _ScribePainter({
    required this.room,
    required this.colors,
    required this.petX,
    required this.stage,
    required this.hands,
    required this.intro,
    required this.write,
    required this.present,
    required this.title,
    required this.tags,
    required this.ink,
    required this.accent,
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final i = intro.value;
    final pr = present.value;
    if (i <= 0 && pr <= 0) return;
    final s = room.petS;
    final scale = stage == PetStage.egg ? PetStage.egg.scale : stage.scale;
    final cx = room.w / 2 + petX();
    final ground = room.groundY;
    final nearY = ground + s * 0.03;

    // The notebook slides up into view, and away once the page is up.
    final bookAlpha =
        (i / 0.25).clamp(0.0, 1.0) * (1 - pr * 1.6).clamp(0.0, 1.0);
    if (bookAlpha > 0) {
      final rise = Curves.easeOutBack.transform((i / 0.5).clamp(0.0, 1.0));
      canvas.saveLayer(
          null, Paint()..color = Colors.black.withValues(alpha: bookAlpha));
      canvas.translate(0, (1 - rise) * s * 0.25);
      paintLapNotebook(
        canvas,
        petX: cx,
        nearY: nearY,
        s: s,
        scale: scale,
        progress: i < 1 ? 0 : write.value,
        paper: colors.paper,
        line: colors.line,
        cover: colors.cover,
        hands: i > 0.35 ? hands : null,
      );
      canvas.restore();
    }
    if (pr > 0) _paintPage(canvas, s, scale, cx, nearY, pr);
  }

  /// The finished page, rising out of the notebook to just under its eyes
  /// (they peek over the top), held at the sides.
  void _paintPage(Canvas canvas, double s, double scale, double cx,
      double nearY, double pr) {
    final ground = room.groundY;
    final q = Curves.easeOutBack.transform(pr);
    final eyesBottom = stage == PetStage.egg
        ? ground - s * 0.3
        : ground - s * scale * (0.40 - 0.046 * stage.eyeBoost);
    final top = eyesBottom + s * 0.02;
    final bottom = ground + s * 0.3;
    final w = s * 0.92;
    final h = bottom - top;
    final nbW = lapNotebookWidth(s, scale);
    final from = Rect.fromCenter(
        center: Offset(cx + nbW * 0.2, nearY - 6), width: nbW * 0.4, height: 8);
    final to = Rect.fromLTWH(cx - w / 2, top, w, h);
    final r = Rect.lerp(from, to, q)!;
    final angle = (1 - q) * -0.35 + 0.03 * math.sin(pr * math.pi * 2);

    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(angle);
    final page = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height),
        const Radius.circular(6));
    canvas.drawRRect(
        page.shift(const Offset(0, 3)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawRRect(page, Paint()..color = colors.paper);
    canvas.drawRRect(
        page,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = colors.line);
    // A strip of tape at the top.
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(0, -r.height / 2 + 1),
            width: r.width * 0.28,
            height: 7),
        Paint()..color = colors.glow.withValues(alpha: 0.85));

    // What it wrote, once the page is big enough to read.
    final show = ((pr - 0.45) / 0.4).clamp(0.0, 1.0);
    if (show > 0) {
      final pad = r.width * 0.1;
      final textW = r.width - pad * 2;
      var y = -r.height / 2 + pad + 2;
      final fontSize = (r.width * 0.085).clamp(8.0, 12.0);
      final t = title?.trim();
      if (t != null && t.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: t,
            style: AppFonts.display(
              fontSize: fontSize,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: ink.withValues(alpha: show),
            ),
          ),
          maxLines: 2,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: textW);
        tp.paint(canvas, Offset(-textW / 2, y));
        y += tp.height + fontSize * 0.6;
      }
      final bar = Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = colors.line.withValues(alpha: show);
      final tagsY = r.height / 2 - pad - fontSize;
      for (final f in [0.92, 0.78, 0.6]) {
        if (y > tagsY - 4) break;
        canvas.drawLine(
            Offset(-textW / 2, y), Offset(-textW / 2 + textW * f, y), bar);
        y += fontSize * 0.75;
      }
      if (tags.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(
            text: tags.take(3).map((t) => '#$t').join(' '),
            style: AppFonts.body(
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.w600,
              color: accent.withValues(alpha: show),
            ),
          ),
          maxLines: 1,
          ellipsis: '…',
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: textW);
        tp.paint(canvas, Offset(-textW / 2, tagsY));
      }
    }

    // Its hands, holding the page at the sides.
    final hand = hands;
    if (hand != null) {
      for (final dir in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(dir * (r.width / 2 - 1), r.height * 0.08);
        canvas.rotate(dir * 0.35);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero,
                width: s * 0.15 * scale + 2,
                height: s * 0.1 * scale + 2),
            Paint()..color = hand);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScribePainter old) =>
      old.room.size != room.size ||
      old.colors != colors ||
      old.stage != stage ||
      old.hands != hands ||
      old.title != title ||
      old.tags != tags ||
      old.ink != ink;
}
