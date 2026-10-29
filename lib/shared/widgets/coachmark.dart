import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/sound_service.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/theme/app_palette.dart';
import '../../l10n/generated/app_localizations.dart';

/// One stop on a [Coachmark] tour: what to light up and what to say
/// about it.
class CoachStep {
  /// What to light up. Without one (something that happens in another
  /// app, say) the card sits in the middle of the dimmed screen.
  final GlobalKey? target;
  final String text;

  /// A little picture over the text.
  final Widget? art;

  /// A round spotlight (an icon, the pet) rather than a rounded box.
  final bool circle;

  /// Room around the target inside the spotlight.
  final double padding;

  const CoachStep({
    required this.target,
    required this.text,
    this.art,
    this.circle = false,
    this.padding = 8,
  });
}

/// The first time somewhere new opens: the screen dims, one thing at a
/// time is lit up with a line about it, and a tap anywhere moves on.
/// Each tour shows once per device ([showOnce]); skipping it counts.
abstract final class Coachmark {
  /// A tour is on screen — the pet holds its impatience meanwhile.
  static final showing = ValueNotifier<bool>(false);

  static String _key(String id) => 'coach.$id';

  /// Whether the tour [id] has been seen on this device.
  static Future<bool> seen(String id) async =>
      (await SharedPreferences.getInstance()).getBool(_key(id)) ?? false;

  /// Shows the tour [id] unless it's been seen. Steps whose target isn't
  /// on screen are left out (it doesn't show for those alone). Returns
  /// whether it showed.
  static Future<bool> showOnce(
    BuildContext context, {
    required String id,
    required List<CoachStep> steps,
  }) async {
    if (showing.value) return false;
    showing.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if ((prefs.getBool(_key(id)) ?? false) || !context.mounted) {
        return false;
      }
      final present = [
        for (final s in steps)
          if (s.target == null || (s.target!.currentContext?.mounted ?? false))
            s,
      ];
      if (!present.any((s) => s.target != null)) return false;
      SoundService.instance.play(Sfx.sheetOpen);
      final shown = await Navigator.of(context, rootNavigator: true)
          .push(_CoachRoute(present));
      // Its page went away before it could start: next time, then.
      if (shown == false) return false;
      await prefs.setBool(_key(id), true);
      return true;
    } finally {
      showing.value = false;
    }
  }
}

/// Pops with false when the tour couldn't start (see [_CoachOverlayState._aim]).
class _CoachRoute extends PageRoute<bool> {
  final List<CoachStep> steps;
  _CoachRoute(this.steps);

  @override
  bool get opaque => false;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildPage(context, animation, secondaryAnimation) => Material(
        type: MaterialType.transparency,
        child: _CoachOverlay(steps: steps),
      );

  @override
  Widget buildTransitions(context, animation, secondaryAnimation, child) =>
      FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
}

class _CoachOverlay extends StatefulWidget {
  final List<CoachStep> steps;
  const _CoachOverlay({required this.steps});

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay>
    with TickerProviderStateMixin {
  int _i = 0;

  /// The spotlight slides from where it was to the next target.
  late final _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// A ring that breathes out of the spotlight, so the eye finds it.
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  RRect? _from;
  RRect? _to;

  /// The first step has been aimed at (the card can show).
  bool _aimed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _aim(jump: true));
  }

  @override
  void dispose() {
    _move.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// Where step [i]'s target is on this overlay, spotlight-shaped.
  RRect? _holeFor(int i) {
    final step = widget.steps[i];
    final box = step.target?.currentContext?.findRenderObject();
    final me = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || me is! RenderBox) return null;
    final topLeft = me.globalToLocal(box.localToGlobal(Offset.zero));
    // Only what's on screen gets lit.
    final rect = (topLeft & box.size).intersect(Offset.zero & me.size);
    if (rect.isEmpty) return null;
    if (step.circle) {
      final r = rect.longestSide / 2 + step.padding;
      return RRect.fromRectAndRadius(
        Rect.fromCircle(center: rect.center, radius: r),
        Radius.circular(r),
      );
    }
    return RRect.fromRectAndRadius(
      rect.inflate(step.padding),
      const Radius.circular(18),
    );
  }

  RRect? get _hole {
    final from = _from, to = _to;
    if (to == null) return null;
    if (from == null) return to;
    return RRect.lerp(from, to, Curves.easeInOutCubic.transform(_move.value));
  }

  void _aim({bool jump = false}) {
    if (!mounted) return;
    final next = _holeFor(_i);
    if (next == null && widget.steps[_i].target != null) {
      if (jump && _i == 0) {
        // Gone before the tour began (its page was left): not shown.
        Navigator.of(context).pop(false);
        return;
      }
      // The target went away meanwhile: on to the next one.
      _advance();
      return;
    }
    // Into or out of a step with nothing to light, the spotlight just
    // goes or comes; between two targets it slides.
    final slide = !jump && _to != null && next != null;
    setState(() {
      _aimed = true;
      _from = slide ? _hole : null;
      _to = next;
    });
    _move.forward(from: slide ? 0 : 1);
  }

  void _advance() {
    final next = _i + 1;
    if (next >= widget.steps.length) {
      Navigator.of(context).pop();
      return;
    }
    SoundService.instance.play(Sfx.tabTick);
    _i = next;
    _aim();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final step = widget.steps[_i];
    final last = _i == widget.steps.length - 1;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advance,
      child: AnimatedBuilder(
        animation: Listenable.merge([_move, _pulse]),
        builder: (context, _) {
          final hole = _hole;
          return LayoutBuilder(builder: (context, box) {
            final size = box.biggest;
            final pad = MediaQuery.paddingOf(context);
            // The card goes on whichever side of the spotlight has room
            // (or in the middle, with nothing lit).
            double? top, bottom;
            if (hole == null) {
              top = pad.top;
              bottom = pad.bottom;
            } else if (hole.center.dy < size.height / 2) {
              top = hole.bottom + 18;
            } else {
              bottom = size.height - hole.top + 18;
            }
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ScrimPainter(
                      hole: hole,
                      pulse: _pulse.value,
                    ),
                  ),
                ),
                if (_aimed)
                  Positioned(
                    left: 20,
                    right: 20,
                    top: top,
                    bottom: bottom,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: Offset(0, bottom == null ? -0.06 : 0.06),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _CoachCard(
                            key: ValueKey(_i),
                            text: step.text,
                            art: step.art,
                            index: _i,
                            count: widget.steps.length,
                            nextLabel: last ? l10n.coachDone : l10n.coachNext,
                            skipLabel: last ? null : l10n.coachSkip,
                            onNext: _advance,
                            onSkip: () => Navigator.of(context).pop(),
                            palette: palette,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          });
        },
      ),
    );
  }
}

/// What's said about the lit-up thing, with the way on (and out).
class _CoachCard extends StatelessWidget {
  final String text;
  final Widget? art;
  final int index;
  final int count;
  final String nextLabel;
  final String? skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final AppPalette palette;
  const _CoachCard({
    super.key,
    required this.text,
    this.art,
    required this.index,
    required this.count,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.surfaceStroke),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (art case final art?) ...[
              Center(child: art),
              const SizedBox(height: 14),
            ],
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                text,
                style: AppFonts.body(
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (count > 1)
                  for (var i = 0; i < count; i++)
                    Container(
                      width: i == index ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: i == index
                            ? palette.primary
                            : palette.surfaceStroke,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                const Spacer(),
                if (skipLabel case final skip?)
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textSecondary,
                    ),
                    child: Text(skip),
                  ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(nextLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The dimmed screen with the spotlight cut out of it.
class _ScrimPainter extends CustomPainter {
  final RRect? hole;
  final double pulse;
  _ScrimPainter({required this.hole, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole != null) scrim.addRRect(hole);
    canvas.drawPath(
        scrim, Paint()..color = Colors.black.withValues(alpha: 0.6));
    if (hole == null) return;
    canvas.drawRRect(
      hole.inflate(2 + 10 * pulse),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.7 * (1 - pulse)),
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.pulse != pulse;
}
