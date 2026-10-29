part of 'pet_scene.dart';

// ════════════════════════════════════════════════════════════════════════
// The pegboard over the shelf, and today's notes fanned out from it
// ════════════════════════════════════════════════════════════════════════

/// A pegboard on the wall with sticky notes pinned to it. The big yellow
/// note says how many links were saved today; tap the board to fan them
/// out over the room.
class _Pegboard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _Pegboard({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.homeBoardSemantics(count),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The board, its shadow falling away from the lamp.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8D4B4),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFFD2B990),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.13),
                        blurRadius: 9,
                        offset: const Offset(-4, 2),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _PegHoles(const Color(0xFFCDB28A)),
                  ),
                ),
              ),
              // Two smaller notes behind the main one.
              Positioned(
                right: w * 0.07,
                top: h * 0.12,
                width: w * 0.3,
                height: w * 0.3,
                child: const _Sticky(
                  color: Color(0xFFF6C7D0),
                  angle: 0.1,
                  lines: 2,
                ),
              ),
              Positioned(
                right: w * 0.1,
                bottom: h * 0.09,
                width: w * 0.27,
                height: w * 0.22,
                child: const _Sticky(
                  color: Color(0xFFC6E6D0),
                  angle: -0.06,
                  lines: 1,
                ),
              ),
              // Today's count on the big yellow note.
              Positioned(
                left: w * 0.08,
                top: h * 0.1,
                width: w * 0.52,
                height: h * 0.8,
                child: _Sticky(
                  color: const Color(0xFFFBE38A),
                  angle: -0.05,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(3, h * 0.12, 3, 3),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: AppFonts.display(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              color: const Color(0xFF4A3B1F),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.homeTvCaption,
                            style: AppFonts.body(
                              fontSize: 7.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B5A35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// The pegboard's grid of holes.
class _PegHoles extends CustomPainter {
  final Color color;
  _PegHoles(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final gap = (size.shortestSide / 6).clamp(6.0, 11.0);
    final r = gap * 0.13;
    for (var y = gap * 0.7; y < size.height - gap * 0.4; y += gap) {
      for (var x = gap * 0.7; x < size.width - gap * 0.4; x += gap) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PegHoles old) => old.color != color;
}

/// A sticky note pinned to the board: slightly turned, with a pushpin at
/// the top and either [child] on it or a few scribbled [lines].
class _Sticky extends StatelessWidget {
  final Color color;
  final double angle;
  final int lines;
  final Widget? child;
  const _Sticky({
    required this.color,
    required this.angle,
    this.lines = 0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final paper = color;
    return Transform.rotate(
      angle: angle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 3,
                    offset: const Offset(-1.5, 1.5),
                  ),
                ],
              ),
              child: child ??
                  LayoutBuilder(
                    builder: (context, c) => Padding(
                      padding: EdgeInsets.fromLTRB(c.maxWidth * 0.16,
                          c.maxHeight * 0.38, c.maxWidth * 0.16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < lines; i++) ...[
                            FractionallySizedBox(
                              widthFactor: i.isEven ? 1 : 0.65,
                              child: Container(
                                height: 1.4,
                                color: Colors.black.withValues(alpha: 0.18),
                              ),
                            ),
                            SizedBox(height: c.maxHeight * 0.14),
                          ],
                        ],
                      ),
                    ),
                  ),
            ),
          ),
          // The pushpin.
          Positioned(
            top: -2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE0584F),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 1.5,
                      offset: const Offset(-0.5, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's saves, taken off the pegboard and fanned out over the room as
/// sticky notes: they fly out from the board one after another and
/// settle like a hand of cards. Tap one to open it.
class _Fan extends StatefulWidget {
  final List<NoteEntity> notes;

  /// Where they come from: the pegboard's centre.
  final Offset from;
  final double centerY;
  final ValueChanged<NoteEntity> onTap;
  const _Fan({
    super.key,
    required this.notes,
    required this.from,
    required this.centerY,
    required this.onTap,
  });

  @override
  State<_Fan> createState() => _FanState();
}

class _FanState extends State<_Fan> with SingleTickerProviderStateMixin {
  static const _w = 116.0;
  static const _h = 128.0;
  static const _flyMs = 420;
  static const _staggerMs = 110;

  /// The same pastels as the notes on the board, one after another so
  /// neighbours differ.
  static const _papers = [
    Color(0xFFFBE38A),
    Color(0xFFF6C7D0),
    Color(0xFFC6E6D0),
    Color(0xFFD8D2F3),
  ];

  late final AnimationController _out = AnimationController(
    vsync: this,
    duration:
        Duration(milliseconds: _flyMs + _staggerMs * (widget.notes.length - 1)),
  )..forward();

  @override
  void dispose() {
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cx = c.maxWidth / 2;
      final n = widget.notes.length;
      final total = _out.duration!.inMilliseconds;
      return AnimatedBuilder(
        animation: _out,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < n; i++) _note(context, i, n, cx, total),
          ],
        ),
      );
    });
  }

  Widget _note(BuildContext context, int i, int n, double cx, int total) {
    final note = widget.notes[i];
    final k = i - (n - 1) / 2;
    final p = ((_out.value * total - _staggerMs * i) / _flyMs).clamp(0.0, 1.0);
    final t = Curves.easeOutBack.transform(p);
    final to =
        Offset(cx - _w / 2 + k * 104, widget.centerY - 70 + k.abs() * 10);
    final at = Offset.lerp(widget.from - const Offset(_w / 2, _h / 2), to, t)!;
    final paper = _papers[i % _papers.length];
    const ink = Color(0xFF3F3424);
    final title =
        (note.title?.trim().isNotEmpty ?? false) ? note.title! : note.url;
    final host = Uri.tryParse(note.url)?.host.replaceFirst('www.', '') ?? '';
    return Positioned(
      left: at.dx,
      top: at.dy,
      width: _w,
      child: Opacity(
        opacity: (p * 3).clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.3 + 0.7 * t,
          child: StickyNote(
            paper: paper,
            angle: k * 0.12 * t + StickyNote.tiltFor(note.id, max: 0.02),
            accent: StickyNote.pick(note.id, StickyNote.pins, salt: 1),
            minHeight: _h,
            padding: const EdgeInsets.fromLTRB(11, 16, 11, 11),
            onTap: () => widget.onTap(note),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(SourceMeta.icon(note.sourceType),
                        size: 12, color: ink.withValues(alpha: 0.55)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        host.isNotEmpty
                            ? host
                            : SourceMeta.labelLocalized(
                                context, note.sourceType),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ink.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
