part of 'note_detail_page.dart';

/// How far apart the ruled lines are. Everything written on a page — the
/// header, the title, the notes — sits on them.
const _line = 26.0;

/// The red margin line, and where the writing starts (past the spiral
/// holes and the margin).
const _marginX = 44.0;
const _textX = 58.0;

/// Where the writing starts from the top of the page, and the first
/// ruled line under it.
const _topPad = 14.0;
const _firstRule = _topPad + _line - 4;

const _pageRadius = BorderRadius.only(
  topLeft: Radius.circular(5),
  bottomLeft: Radius.circular(5),
  topRight: Radius.circular(16),
  bottomRight: Radius.circular(16),
);

// ════════════════════════════════════════════════════════════════
//                  THE NOTEBOOK: TURNING PAGES
// ════════════════════════════════════════════════════════════════

/// A spiral-bound notebook, one note to a page. Swipe sideways to turn
/// the page over (it swings round the spiral and the next one is under
/// it), or [turn] it from outside.
class _Journal extends StatefulWidget {
  final int count;
  final int index;
  final String Function(int i) idOf;
  final ValueChanged<int> onTurned;

  /// Page [i]; [active] while it's the page you're reading.
  final Widget Function(BuildContext context, int i, bool active) page;

  /// The way back: a divider tab sticking up behind the pages, top left.
  final Widget back;

  /// The menu: a ribbon bookmark hanging over the page, top right.
  final Widget ribbon;

  /// Room above the pages for [back] to stick up into.
  static const tabRoom = 34.0;

  const _Journal({
    super.key,
    required this.count,
    required this.index,
    required this.idOf,
    required this.onTurned,
    required this.page,
    required this.back,
    required this.ribbon,
  });

  @override
  State<_Journal> createState() => _JournalState();
}

class _JournalState extends State<_Journal>
    with SingleTickerProviderStateMixin {
  /// How far a page is turned: towards the next page (0 → 1) or back to
  /// the previous one (0 → -1).
  late final _turn =
      AnimationController(vsync: this, lowerBound: -1, upperBound: 1, value: 0);
  double _width = 1;
  bool _busy = false;

  bool get _hasNext => widget.index < widget.count - 1;
  bool get _hasPrev => widget.index > 0;

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  /// Turns one page forward ([dir] 1) or back (-1).
  void turn(int dir) {
    if (_busy || (dir > 0 ? !_hasNext : !_hasPrev)) return;
    _commit(dir);
  }

  void _drag(DragUpdateDetails d) {
    if (_busy) return;
    var p = _turn.value - (d.primaryDelta ?? 0) / _width;
    if (!_hasNext) p = math.min(p, 0);
    if (!_hasPrev) p = math.max(p, 0);
    _turn.value = p.clamp(-1.0, 1.0);
  }

  void _release(DragEndDetails d) {
    if (_busy) return;
    final v = d.primaryVelocity ?? 0;
    final p = _turn.value;
    if (p > 0 && (p > 0.25 || v < -400)) {
      _commit(1);
    } else if (p < 0 && (p < -0.25 || v > 400)) {
      _commit(-1);
    } else {
      _turn.animateTo(0,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
    }
  }

  Future<void> _commit(int dir) async {
    _busy = true;
    SoundService.instance.play(Sfx.pageFlip);
    final left = (dir - _turn.value).abs();
    await _turn.animateTo(dir.toDouble(),
        duration: Duration(milliseconds: (520 * left).round().clamp(180, 520)),
        curve: Curves.easeInOut);
    if (!mounted) return;
    widget.onTurned(widget.index + dir);
    _turn.value = 0;
    _busy = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      _width = c.maxWidth;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragUpdate: _drag,
        onHorizontalDragEnd: _release,
        onHorizontalDragCancel: () => _release(DragEndDetails()),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Behind the pages, sticking up over their top edge.
            Positioned(left: 30, top: 0, child: widget.back),
            // The pages further down the pile: their edges peek out.
            for (final off in const [8.0, 4.0])
              Positioned.fill(
                left: off * 0.5,
                top: _Journal.tabRoom + off * 0.5,
                right: -off,
                bottom: -off,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                        NoteColorPalette.background(NoteColor.defaultColor),
                        Colors.black,
                        0.02 * off / 4),
                    borderRadius: _pageRadius,
                    border: Border.all(
                        color: NoteColorPalette.border(NoteColor.defaultColor)),
                  ),
                ),
              ),
            Positioned.fill(
              top: _Journal.tabRoom,
              child: AnimatedBuilder(
                animation: _turn,
                builder: (context, _) {
                  final p = _turn.value;
                  final i = widget.index;
                  // The page lying flat, and the one swinging over it.
                  final (int flat, int? turning, double lift) = p > 0
                      ? (i + 1, i, p)
                      : p < 0
                          ? (i, i - 1, 1 + p)
                          : (i, null, 0.0);
                  Widget slot(int n, double lift, double shade) => _PageSlot(
                        key: ValueKey(widget.idOf(n)),
                        lift: lift,
                        shade: shade,
                        child: widget.page(context, n, n == i && !_busy),
                      );
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // In the turning page's shadow until it's well up.
                      slot(flat, 0, turning == null ? 0 : 0.14 * (1 - lift)),
                      if (turning != null) slot(turning, lift, 0),
                    ],
                  );
                },
              ),
            ),
            // The spiral, through the holes down every page.
            const Positioned(
              left: -12,
              top: _Journal.tabRoom,
              bottom: 0,
              width: 40,
              child: IgnorePointer(
                child: CustomPaint(painter: _SpiralPainter()),
              ),
            ),
            // Tucked in at the top of the book, hanging over the page.
            Positioned(
              right: 26,
              top: _Journal.tabRoom - 5,
              child: widget.ribbon,
            ),
          ],
        ),
      );
    });
  }
}

/// A page in the notebook, turned over by [lift] (0 lying flat, 1 turned
/// right over): like a real page it comes up towards you, round the
/// spiral, and over to the left — showing its back past halfway — and it's
/// in [shade] by that much.
class _PageSlot extends StatelessWidget {
  final double lift;
  final double shade;
  final Widget child;
  const _PageSlot({
    super.key,
    required this.lift,
    required this.shade,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final angle = lift * math.pi;
    final front = angle <= math.pi / 2;
    // Darker as it stands up off the page (the lamp's behind you).
    final dark = (shade + math.sin(angle) * 0.14).clamp(0.0, 1.0);
    // Always the same widgets round the page, so it keeps its state
    // (scroll, video) as it goes from turning to lying flat.
    return Transform(
      alignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0005)
        ..rotateY(angle),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Only the side you can see takes touches (a see-through back
          // over the page would swallow every scroll and tap).
          IgnorePointer(
            ignoring: !front,
            child: Opacity(opacity: front ? 1 : 0, child: child),
          ),
          IgnorePointer(
            child: Opacity(opacity: front ? 0 : 1, child: const _PageBack()),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _pageRadius,
                color: Colors.black.withValues(alpha: dark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The back of a page, seen as it's turned over: the same paper, its
/// lines showing through faintly, and the spiral holes.
class _PageBack extends StatelessWidget {
  const _PageBack();

  @override
  Widget build(BuildContext context) {
    final paper = Color.lerp(
        NoteColorPalette.background(NoteColor.defaultColor),
        Colors.black,
        0.03)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: _pageRadius,
        border:
            Border.all(color: NoteColorPalette.border(NoteColor.defaultColor)),
      ),
      child: ClipRRect(
        borderRadius: _pageRadius,
        child: CustomPaint(
          painter: const _RulingPainter(faint: true),
          foregroundPainter: _PageMarginPainter(
              holeColor: context.palette.bgPrimary, margin: false),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// The wire rings of the spiral, one through each hole.
class _SpiralPainter extends CustomPainter {
  const _SpiralPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final wire = Paint()
      ..color = const Color(0xFF8C8F96)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final shine = Paint()
      ..color = const Color(0xFFE3E5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    // The holes are 28 px into the page; this sits 12 px left of it.
    const holeX = 12 + _JournalPage.holeX;
    for (final y in _JournalPage.holes(size.height)) {
      final ring = Rect.fromLTRB(3, y - 9, holeX + 2, y + 3);
      canvas.drawArc(ring, math.pi * 0.95, math.pi * 1.1, false, wire);
      canvas.drawArc(
          ring.deflate(1.2), math.pi * 1.15, math.pi * 0.5, false, shine);
    }
  }

  @override
  bool shouldRepaint(_SpiralPainter old) => false;
}

// ════════════════════════════════════════════════════════════════
//                          ONE PAGE
// ════════════════════════════════════════════════════════════════

/// One note on a ruled page: the date and where it's from, the title,
/// its video or picture taped on like a photo, the whole note written
/// out, its tags on strips of tape, and the page number.
class _JournalPage extends StatelessWidget {
  final NoteEntity note;
  final int number;
  final int mediaRev;
  final bool active;
  const _JournalPage({
    required this.note,
    required this.number,
    required this.mediaRev,
    required this.active,
  });

  /// The spiral holes: how far in, and where down the page.
  static const holeX = 16.0;
  static Iterable<double> holes(double height) sync* {
    for (var y = 26.0; y < height - 14; y += 30) {
      yield y;
    }
  }

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(note.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final paper = NoteColorPalette.background(NoteColor.defaultColor);
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : l10n.noteDetailUntitled;
    final hasMedia = SourceMeta.supportsCobaltResolve(note.sourceType) ||
        (note.thumbnailUrl?.isNotEmpty ?? false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: _pageRadius,
        border:
            Border.all(color: NoteColorPalette.border(NoteColor.defaultColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: _pageRadius,
        child: CustomPaint(
          foregroundPainter: _PageMarginPainter(holeColor: palette.bgPrimary),
          child: LayoutBuilder(
            builder: (context, c) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: c.maxHeight),
                child: CustomPaint(
                  painter: const _RulingPainter(),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(_textX, _topPad, 18, _line),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Where it's from (tap to open it) and when.
                        SizedBox(
                          height: _line,
                          child: Row(
                            children: [
                              Flexible(
                                child: _SourceChip(note: note, onTap: _openUrl),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                note.createdAt.prettyDateLocalized(context),
                                style: AppFonts.body(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Clear of the ribbon bookmark on the right.
                        Padding(
                          padding: const EdgeInsets.only(right: 40),
                          child: Text(
                            title,
                            strutStyle: const StrutStyle(
                                fontSize: 20,
                                height: _line / 20,
                                forceStrutHeight: true),
                            style: AppFonts.display(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                        if (hasMedia)
                          _Polaroid(
                            note: note,
                            mediaRev: mediaRev,
                            active: active,
                            maxHeight: c.maxHeight * 0.52,
                          )
                        else
                          const SizedBox(height: _line),
                        _NoteText(note: note),
                        if (note.tags.isNotEmpty) ...[
                          const SizedBox(height: _line),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              for (final t in note.tags)
                                TapeLabel(
                                  text: '#$t',
                                  color: BookColor.of(t).chip,
                                  angle: (t.hashCode % 5 - 2) * 0.012,
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: _line),
                        Center(
                          child: Text(
                            '— $number —',
                            style: AppFonts.body(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                              color: palette.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The ruled lines, scrolling with the writing ([faint] on the back of
/// a page, showing through).
class _RulingPainter extends CustomPainter {
  final bool faint;
  const _RulingPainter({this.faint = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = const Color(0xFFCFDCE8).withValues(alpha: faint ? 0.35 : 1)
      ..strokeWidth = 1;
    for (var y = _firstRule; y < size.height; y += _line) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }
  }

  @override
  bool shouldRepaint(_RulingPainter old) => old.faint != faint;
}

/// What doesn't scroll: the red margin line ([margin]) and the spiral
/// holes.
class _PageMarginPainter extends CustomPainter {
  final Color holeColor;
  final bool margin;
  const _PageMarginPainter({required this.holeColor, this.margin = true});

  @override
  void paint(Canvas canvas, Size size) {
    if (margin) {
      canvas.drawLine(
        const Offset(_marginX, 0),
        Offset(_marginX, size.height),
        Paint()
          ..color = const Color(0xFFF0BAB4)
          ..strokeWidth = 1.2,
      );
    }
    final hole = Paint()..color = holeColor;
    final rim = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final y in _JournalPage.holes(size.height)) {
      const x = _JournalPage.holeX;
      canvas
        ..drawCircle(Offset(x, y), 4.6, hole)
        ..drawCircle(Offset(x, y), 4.6, rim);
    }
  }

  @override
  bool shouldRepaint(_PageMarginPainter old) =>
      old.holeColor != holeColor || old.margin != margin;
}

/// The note itself, written out on the ruled lines.
class _NoteText extends StatelessWidget {
  final NoteEntity note;
  const _NoteText({required this.note});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final empty = note.manualNotes.trim().isEmpty;
    TextStyle on(double size, TextStyle style) =>
        style.copyWith(fontSize: size, height: _line / size);
    final body = on(
        15,
        AppFonts.body(
            color: empty ? palette.textTertiary : palette.textPrimary));
    return MarkdownBody(
      data: empty ? l10n.noteDetailEmptyMarkdown : note.manualNotes,
      // Not selectable: a sideways swipe over the writing turns the page.
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        // A blank line between paragraphs, so the writing stays on the
        // lines.
        blockSpacing: 0,
        pPadding: const EdgeInsets.only(bottom: _line),
        p: body,
        listBullet: body,
        h1: on(
            19,
            AppFonts.display(
                fontWeight: FontWeight.w700, color: palette.textPrimary)),
        h2: on(
            17,
            AppFonts.display(
                fontWeight: FontWeight.w700, color: palette.textPrimary)),
        h3: on(
            15.5,
            AppFonts.display(
                fontWeight: FontWeight.w700, color: palette.textPrimary)),
        strong: const TextStyle(fontWeight: FontWeight.w700),
        blockquote: on(
            14,
            AppFonts.body(
                fontStyle: FontStyle.italic, color: palette.textSecondary)),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: palette.surfaceStroke, width: 3),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        code: GoogleFonts.jetBrainsMono(
          fontSize: 12.5,
          color: palette.textPrimary,
          backgroundColor: palette.bgTertiary,
        ),
        codeblockDecoration: BoxDecoration(
          color: palette.bgTertiary.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// The video or picture, taped on the page like a photo: a white border,
/// a strip of tape over each top corner, and where it's from written
/// along the bottom. Takes whole ruled lines, so the writing under it
/// stays on them.
class _Polaroid extends StatelessWidget {
  final NoteEntity note;
  final int mediaRev;
  final bool active;
  final double maxHeight;
  const _Polaroid({
    required this.note,
    required this.mediaRev,
    required this.active,
    required this.maxHeight,
  });

  /// Tall for the vertical-video apps, wide for the rest.
  bool get _portrait => const {'tiktok', 'instagram', 'threads', 'facebook'}
      .contains(note.sourceType);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = NoteColorPalette.swatch(_tint(note));
    final host = Uri.tryParse(note.url)?.host.replaceFirst('www.', '') ?? '';
    // Leans one way or the other, the same each time for this note.
    final lean = (note.id.hashCode.isEven ? 1 : -1) * 0.018;
    return LayoutBuilder(builder: (context, c) {
      final aspect = _portrait ? 4 / 5 : 16 / 10;
      var w = math.min(c.maxWidth * 0.92, 320.0) - 16;
      var h = w / aspect;
      final maxPhoto = maxHeight - 46;
      if (h > maxPhoto) {
        h = maxPhoto;
        w = h * aspect;
      }
      const frameTop = 8.0, frameBottom = 30.0;
      final frameH = h + frameTop + frameBottom;
      // Room above and below for the tape and a little air, rounded up to
      // whole lines.
      final block = ((frameH + 24) / _line).ceil() * _line;
      return SizedBox(
        height: block,
        child: Center(
          child: Transform.rotate(
            angle: lean,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: w + 16,
                  padding:
                      const EdgeInsets.fromLTRB(8, frameTop, 8, frameBottom),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFA),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(1, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: w,
                        height: h,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: ColoredBox(
                            color: palette.bgTertiary,
                            child: InlineMediaPlayer(
                              key: ValueKey('${note.id}#$mediaRev'),
                              noteId: note.id,
                              sourceUrl: note.url,
                              sourceType: note.sourceType,
                              thumbnailUrl: note.thumbnailUrl,
                              autoPause: !active,
                              fullBleed: true,
                              loop: true,
                            ),
                          ),
                        ),
                      ),
                      if (host.isNotEmpty)
                        Positioned(
                          left: 2,
                          right: 2,
                          bottom: -frameBottom + 6,
                          child: Text(
                            host,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.body(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: palette.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: -9,
                  left: -14,
                  child: WashiTape(color: tint, width: 58, angle: -0.6),
                ),
                Positioned(
                  top: -9,
                  right: -14,
                  child: WashiTape(color: tint, width: 58, angle: 0.6),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════
//              THE WAY BACK, AND THE MENU, ON THE BOOK
// ════════════════════════════════════════════════════════════════

/// "‹ Library" on a divider tab sticking up from behind the pages, like
/// the tabs of a ring binder: tap it to close the book.
class _BackTab extends StatelessWidget {
  final VoidCallback onTap;
  const _BackTab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ink = Color.lerp(
        NoteColorPalette.swatch(NoteColor.yellow), Colors.black, 0.55)!;
    return Semantics(
      button: true,
      label: l10n.noteDetailBackTooltip,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          // Taller than it shows: the rest is tucked behind the pages.
          height: _Journal.tabRoom + 14,
          padding: const EdgeInsets.fromLTRB(10, 7, 14, 0),
          alignment: Alignment.topLeft,
          decoration: BoxDecoration(
            color: NoteColorPalette.background(NoteColor.yellow),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border:
                Border.all(color: NoteColorPalette.border(NoteColor.yellow)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left_rounded, size: 20, color: ink),
              const SizedBox(width: 2),
              Text(
                l10n.navLibrary,
                style: AppFonts.body(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The book's ribbon bookmark, hanging down over the top of the page from
/// the binding, three little dots stitched near its end — it opens the
/// menu.
class _Ribbon extends StatelessWidget {
  const _Ribbon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 30,
      height: 66,
      child: CustomPaint(painter: _RibbonPainter()),
    );
  }
}

class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  static const _cloth = Color(0xFFC9655A);
  static const _thread = Color(0xFFF6E7D8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // A swallowtail end.
    final ribbon = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h - 9)
      ..lineTo(0, h)
      ..close();
    canvas.drawShadow(ribbon, Colors.black, 3, false);
    canvas.drawPath(ribbon, Paint()..color = _cloth);
    // The weave: a lighter stripe down each side.
    final edge = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.4;
    canvas
      ..drawLine(const Offset(3.5, 0), Offset(3.5, h - 3), edge)
      ..drawLine(Offset(w - 3.5, 0), Offset(w - 3.5, h - 3), edge);
    // Where it comes out from under the top edge of the book.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 5),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );
    // Three stitched dots.
    final dot = Paint()..color = _thread;
    for (var i = -1; i <= 1; i++) {
      canvas.drawCircle(Offset(w / 2 + i * 7.0, h - 24), 2.2, dot);
    }
  }

  @override
  bool shouldRepaint(_RibbonPainter old) => false;
}

// ════════════════════════════════════════════════════════════════
//                 UNDER THE NOTEBOOK: THE PET & PAGES
// ════════════════════════════════════════════════════════════════

/// Along the bottom: the pet in its reading glasses, which page this is
/// (or how to turn them, the first time), and arrows to turn them.
class _JournalFooter extends StatelessWidget {
  final BlobController pet;
  final int position;
  final int count;
  final bool hint;
  final double bottomInset;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  /// How tall it is, above the bottom inset.
  static const height = 74.0;

  const _JournalFooter({
    required this.pet,
    required this.position,
    required this.count,
    required this.hint,
    required this.bottomInset,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    Widget arrow(IconData icon, VoidCallback? onTap, String tooltip) =>
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onTap == null ? 0.35 : 1,
          child: IgnorePointer(
            ignoring: onTap == null,
            child: _PaperCircleButton(
                icon: icon, onTap: onTap ?? () {}, tooltip: tooltip),
          ),
        );
    return Container(
      height: height + bottomInset,
      padding: EdgeInsets.fromLTRB(10, 4, 14, 8 + bottomInset),
      child: Row(
        children: [
          PetHost(height: 62, glasses: true, calm: true, controller: pet),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (count > 1)
                  Text(
                    l10n.noteDetailPageOf(position, count),
                    style: AppFonts.body(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                if (hint)
                  Text(
                    l10n.noteDetailSwipeHint,
                    style: AppFonts.body(
                      fontSize: 11.5,
                      color: palette.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          if (count > 1) ...[
            arrow(Icons.chevron_left_rounded, onPrev, l10n.noteDetailPrevPage),
            const SizedBox(width: 10),
            arrow(Icons.chevron_right_rounded, onNext, l10n.noteDetailNextPage),
          ],
        ],
      ),
    );
  }
}
