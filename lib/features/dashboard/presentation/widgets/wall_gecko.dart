import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';

/// One stop on a gecko's way across the wall: where it goes, how long it
/// stays there, and whether it calls out while it does.
class GeckoStop {
  final Offset at;
  final Duration pause;
  final bool chirp;
  const GeckoStop(this.at, {this.pause = Duration.zero, this.chirp = false});
}

/// A little easter egg: now and then — not often — a gecko scuttles across
/// the wall along one of [routes], stopping to say "cek cek cek". Each
/// route starts and ends somewhere it can't be seen (off the edge, behind
/// the pegboard). Tap it and it bolts.
///
/// It only shows while [enabled], and never while the page is covered.
class WallGecko extends StatefulWidget {
  final bool enabled;

  /// Each a list of stops in scene pixels; one is picked per visit.
  final List<List<GeckoStop>> routes;

  /// Picks the route for a visit (say, the lamp at night).
  final int Function(math.Random rng)? pickRoute;

  /// Nose-to-tail length, in pixels.
  final double length;
  final String chirp;

  /// It came out (where), and went away again.
  final ValueChanged<Offset>? onAppear;
  final VoidCallback? onLeave;

  const WallGecko({
    super.key,
    required this.enabled,
    required this.routes,
    required this.length,
    required this.chirp,
    this.pickRoute,
    this.onAppear,
    this.onLeave,
  });

  /// For tests: show up after this long, every time, on this route.
  @visibleForTesting
  static Duration? debugEvery;
  @visibleForTesting
  static int? debugRoute;

  @override
  State<WallGecko> createState() => _WallGeckoState();
}

class _WallGeckoState extends State<WallGecko>
    with SingleTickerProviderStateMixin {
  final _rng = math.Random();

  /// Made up front, not lazily: if the gecko never showed, dispose()
  /// would otherwise create it while the page is going away.
  late final AnimationController _run;

  // What it was doing last frame, to hear when it starts a dash or a call.
  bool _wasMoving = false;
  bool _wasChirping = false;

  /// A patter of tiny feet as each dash starts, and its "cek cek cek".
  void _sounds() {
    final trip = _trip;
    if (trip == null) return;
    final p = trip.at(trip.total * _run.value);
    if (p.moving && !_wasMoving) {
      SoundService.instance.play(Sfx.geckoScurry);
    }
    if (p.chirping && !_wasChirping) {
      SoundService.instance.play(Sfx.geckoChirp);
    }
    _wasMoving = p.moving;
    _wasChirping = p.chirping;
  }

  Timer? _timer;
  _Trip? _trip;

  @override
  void initState() {
    super.initState();
    _run = AnimationController(vsync: this)
      ..addListener(_sounds)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _gone();
      });
    _schedule(first: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _run.dispose();
    super.dispose();
  }

  /// Rarely: the first visit a couple of minutes in, then a coin toss
  /// every 4–9 minutes.
  void _schedule({bool first = false}) {
    _timer?.cancel();
    final wait = WallGecko.debugEvery ??
        (first
            ? Duration(seconds: 120 + _rng.nextInt(60))
            : Duration(seconds: 240 + _rng.nextInt(300)));
    _timer = AppTimer(wait, () {
      if (!mounted) return;
      final visible = TickerMode.of(context);
      final lucky = WallGecko.debugEvery != null || _rng.nextBool();
      if (!widget.enabled || !visible || !lucky || widget.routes.isEmpty) {
        _schedule();
        return;
      }
      _go();
    });
  }

  void _go() {
    final pick = WallGecko.debugRoute ??
        widget.pickRoute?.call(_rng) ??
        _rng.nextInt(widget.routes.length);
    final trip = _Trip(widget.routes[pick % widget.routes.length],
        speed: widget.length * 2.6);
    setState(() => _trip = trip);
    _wasMoving = false;
    _wasChirping = false;
    _run
      ..duration = trip.total
      ..value = 0
      ..forward();
    widget.onAppear?.call(trip.routeStops[1].at);
  }

  void _gone() {
    if (!mounted) return;
    setState(() => _trip = null);
    widget.onLeave?.call();
    _schedule();
  }

  /// Tapped: it bolts the rest of the way.
  void _scare() {
    final trip = _trip;
    if (trip == null) return;
    final left = (1 - _run.value) * trip.total.inMilliseconds;
    _run.animateTo(1,
        duration:
            Duration(milliseconds: (left * 0.15).round().clamp(150, 700)));
  }

  @override
  void didUpdateWidget(covariant WallGecko old) {
    super.didUpdateWidget(old);
    // Something else is going on: it slips away.
    if (!widget.enabled && _trip != null && _run.isAnimating) _scare();
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    if (trip == null) return const SizedBox.shrink();
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _run,
      builder: (context, _) {
        final now = trip.total * _run.value;
        final p = trip.at(now);
        final box = widget.length * 1.3;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: p.position.dx - box / 2,
              top: p.position.dy - box / 2,
              width: box,
              height: box,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _scare,
                child: CustomPaint(
                  painter: _GeckoPainter(
                    heading: p.heading,
                    step: p.walked / (widget.length * 0.35),
                    moving: p.moving,
                  ),
                ),
              ),
            ),
            if (p.chirping)
              Positioned(
                left: p.position.dx - 40,
                width: 80,
                top: p.position.dy - box * 0.85,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: p.chirpFade,
                    child: Text(
                      widget.chirp,
                      textAlign: TextAlign.center,
                      style: AppFonts.body(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: palette.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Where the gecko is at a moment of its trip.
class _Pose {
  final Offset position;
  final double heading;
  final double walked;
  final bool moving;
  final bool chirping;
  final double chirpFade;
  const _Pose(this.position, this.heading, this.walked, this.moving,
      this.chirping, this.chirpFade);
}

/// A route turned into timed legs: a dash to each stop (eased, like a
/// gecko's stop-start scurry), then the stop's pause.
class _Trip {
  final List<GeckoStop> routeStops;
  final List<(Offset, Offset, Duration, Duration, GeckoStop)> _legs = [];
  late final Duration total;

  _Trip(this.routeStops, {required double speed}) {
    var t = Duration.zero;
    for (var i = 1; i < routeStops.length; i++) {
      final from = routeStops[i - 1].at;
      final to = routeStops[i].at;
      final move =
          Duration(milliseconds: ((to - from).distance / speed * 1000).round());
      _legs.add((from, to, t, move, routeStops[i]));
      t += move + routeStops[i].pause;
    }
    total = t;
  }

  _Pose at(Duration now) {
    var walked = 0.0;
    var heading = 0.0;
    for (final (from, to, start, move, stop) in _legs) {
      final d = to - from;
      heading = math.atan2(d.dy, d.dx);
      final end = start + move;
      if (now < start) break;
      if (now < end) {
        final q = Curves.easeInOut
            .transform((now - start).inMicroseconds / move.inMicroseconds);
        return _Pose(
            from + d * q, heading, walked + d.distance * q, true, false, 0);
      }
      walked += d.distance;
      if (now < end + stop.pause) {
        final q =
            (now - end).inMicroseconds / math.max(1, stop.pause.inMicroseconds);
        final fade = math.min(1.0, math.min(q, 1 - q) * 5);
        return _Pose(to, heading, walked, false, stop.chirp, fade);
      }
    }
    final last = _legs.last;
    return _Pose(last.$2, heading, walked, false, false, 0);
  }
}

/// A house gecko seen from the front, nose along [heading]: pale and
/// speckled, legs splayed, tail swinging. Its legs step while it [moving].
class _GeckoPainter extends CustomPainter {
  final double heading;
  final double step;
  final bool moving;
  _GeckoPainter({
    required this.heading,
    required this.step,
    required this.moving,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final l = size.shortestSide / 1.3;
    const skin = Color(0xFFD3C29C);
    const shade = Color(0xFFB9A57D);
    final body = Paint()..color = skin;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(heading);

    // A soft shadow on the wall, away from the lamp.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(-l * 0.02, l * 0.05),
          width: l * 0.62,
          height: l * 0.2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, l * 0.05),
    );

    // Tail, swinging as it goes.
    final swing = math.sin(step * math.pi) * (moving ? 0.6 : 0.2);
    final tail = Path()..moveTo(-l * 0.14, 0);
    const n = 10;
    final top = <Offset>[];
    final bottom = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final q = i / n;
      final x = -l * 0.14 - l * 0.46 * q;
      final y = math.sin(q * math.pi * 0.9) * l * 0.12 * swing;
      final w = l * 0.055 * (1 - q * 0.9);
      top.add(Offset(x, y - w));
      bottom.add(Offset(x, y + w));
    }
    for (final pt in top) {
      tail.lineTo(pt.dx, pt.dy);
    }
    for (final pt in bottom.reversed) {
      tail.lineTo(pt.dx, pt.dy);
    }
    tail.close();
    canvas.drawPath(tail, body);

    // Legs: diagonal pairs step together.
    final gait = moving ? math.sin(step * math.pi) : 0.0;
    void leg(double x, double side, double phase) {
      final swingLeg = gait * phase * 0.45;
      final reach = x.sign;
      final hip = Offset(x, side * l * 0.05);
      final knee =
          hip + Offset(reach * l * 0.05 + l * 0.04 * swingLeg, side * l * 0.1);
      final foot = knee +
          Offset(reach * l * 0.04 + l * 0.03 * swingLeg, side * l * 0.035);
      final limb = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = l * 0.04
        ..strokeCap = StrokeCap.round
        ..color = skin;
      canvas.drawPath(
          Path()
            ..moveTo(hip.dx, hip.dy)
            ..lineTo(knee.dx, knee.dy)
            ..lineTo(foot.dx, foot.dy),
          limb);
      for (final a in [-0.6, 0.0, 0.6]) {
        canvas.drawCircle(
            foot +
                Offset(math.cos(a) * l * 0.025,
                    side * math.sin(a.abs() + 0.3) * l * 0.02),
            l * 0.016,
            body);
      }
    }

    leg(l * 0.1, -1, 1);
    leg(l * 0.1, 1, -1);
    leg(-l * 0.1, -1, -1);
    leg(-l * 0.1, 1, 1);

    // Body and head.
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: l * 0.36, height: l * 0.13),
        body);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(l * 0.22, 0), width: l * 0.16, height: l * 0.12),
        body);
    // Speckles.
    final spot = Paint()..color = shade;
    for (final o in [
      Offset(-l * 0.08, -l * 0.02),
      Offset(l * 0.02, l * 0.02),
      Offset(l * 0.1, -l * 0.015),
      Offset(-l * 0.22, 0),
    ]) {
      canvas.drawCircle(o, l * 0.014, spot);
    }
    // Eyes.
    final eye = Paint()..color = const Color(0xFF2A2520);
    canvas.drawCircle(Offset(l * 0.25, -l * 0.04), l * 0.016, eye);
    canvas.drawCircle(Offset(l * 0.25, l * 0.04), l * 0.016, eye);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GeckoPainter old) =>
      old.heading != heading || old.step != step || old.moving != moving;
}
