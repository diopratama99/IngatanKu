import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/services/sound_service.dart';

/// The pet's pocket money, spilled on Beranda's floor when it's shaken
/// about while held ([BlobMascot.onShaken]): small change pops out, spins
/// down, bounces with a clink and rolls to a stop — and stays there until
/// the pet picks it back up ([pickUp]).
///
/// A handle to a [CoinFloor], like [BlobController] is to the pet.
class CoinController {
  _CoinFloorState? _state;

  /// Coins out of the pet's pocket: on the floor or still falling.
  int get count => _state?._loose ?? 0;

  /// Coins still in the air.
  int get falling => _state?._falling ?? 0;

  /// Spills one coin out at [at] (in the scene). False when the floor has
  /// plenty already.
  bool drop(Offset at) => _state?._drop(at) ?? false;

  /// Where the coin lying nearest to [walk] is (a walk value), or null
  /// when none is lying on the floor.
  double? nearest(double walk) => _state?._nearest(walk);

  /// Picks up the coins lying where the pet stands ([walk]); they hop up
  /// into it. How many it got.
  int pickUp(double walk) => _state?._pickUp(walk) ?? 0;
}

/// The coins on the floor, painted over the room. Needs the room's
/// geometry: its width, the floor line, the pet's size, and how a walk
/// value maps onto the floor ([walkScale] pixels from the middle).
class CoinFloor extends StatefulWidget {
  final CoinController controller;
  final double sceneWidth;
  final double groundY;
  final double petS;
  final double walkScale;

  /// How tall the pet's body is (a picked-up coin goes into it).
  final double bodyHeight;

  /// Where the pet is now, as a walk value.
  final Animation<double> walk;

  const CoinFloor({
    super.key,
    required this.controller,
    required this.sceneWidth,
    required this.groundY,
    required this.petS,
    required this.walkScale,
    required this.bodyHeight,
    required this.walk,
  });

  /// How many coins the floor holds at most.
  static const most = 16;

  @override
  State<CoinFloor> createState() => _CoinFloorState();
}

class _Coin {
  _Coin({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.restY,
    required this.silver,
  });

  double x, y, vx, vy;
  double spin;
  double angle = 0;
  final double restY;
  final bool silver;
  bool lying = false;
  int bounces = 0;

  /// Picked up: when, and from where.
  double? pickedAt;
  Offset pickedFrom = Offset.zero;
}

class _CoinFloorState extends State<CoinFloor>
    with SingleTickerProviderStateMixin {
  // Made when the first coin falls. A floor that never had one has no
  // ticker to dispose — making one then would look up the deactivated
  // context, throw, and leave the rest of the page half taken down.
  Ticker? _tickerOrNull;
  Ticker get _ticker => _tickerOrNull ??= createTicker(_tick);
  final _frame = ValueNotifier<int>(0);
  final _coins = <_Coin>[];
  final _rng = math.Random();

  /// Seconds on this floor's own clock (it keeps counting across the
  /// ticker's stops and starts).
  double _t = 0;
  double _lastT = 0;
  double _base = 0;

  static const _pickLength = 0.4;

  double get _r => widget.petS * 0.075;
  double get _g => widget.petS * 15;

  int get _loose => _coins.where((c) => c.pickedAt == null).length;
  int get _falling =>
      _coins.where((c) => c.pickedAt == null && !c.lying).length;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(CoinFloor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      if (old.controller._state == this) old.controller._state = null;
      widget.controller._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller._state == this) widget.controller._state = null;
    _tickerOrNull?.dispose();
    _frame.dispose();
    super.dispose();
  }

  /// The floor's edges, so coins stay where the pet can reach them.
  (double, double) get _bounds {
    final reach = widget.sceneWidth / 2 - widget.petS * 0.45;
    return (widget.sceneWidth / 2 - reach, widget.sceneWidth / 2 + reach);
  }

  bool _drop(Offset at) {
    if (_loose >= CoinFloor.most) return false;
    final s = widget.petS;
    _coins.add(_Coin(
      x: at.dx + (_rng.nextDouble() - 0.5) * s * 0.3,
      y: at.dy,
      vx: (_rng.nextDouble() * 2 - 1) * s * 1.6,
      // A little hop out of the bottom of it (not up past its face).
      vy: -(0.3 + _rng.nextDouble() * 0.6) * s * 2,
      spin: (_rng.nextBool() ? 1 : -1) * (10 + _rng.nextDouble() * 8),
      restY: widget.groundY + (0.01 + _rng.nextDouble() * 0.07) * s,
      // Mostly brass, now and then a silver one.
      silver: _rng.nextDouble() < 0.3,
    ));
    _wake();
    return true;
  }

  double _walkOf(_Coin c) => (c.x - widget.sceneWidth / 2) / widget.walkScale;

  double? _nearest(double walk) {
    double? best;
    for (final c in _coins) {
      if (c.pickedAt != null || !c.lying) continue;
      final w = _walkOf(c);
      if (best == null || (w - walk).abs() < (best - walk).abs()) best = w;
    }
    return best;
  }

  int _pickUp(double walk) {
    final reach = widget.petS * 0.4;
    var got = 0;
    for (final c in _coins) {
      if (c.pickedAt != null || !c.lying) continue;
      if ((_walkOf(c) - walk).abs() * widget.walkScale > reach) continue;
      c
        ..pickedAt = _t
        ..pickedFrom = Offset(c.x, c.y);
      got++;
    }
    if (got > 0) {
      SoundService.instance.play(Sfx.coinPick);
      _wake();
    }
    return got;
  }

  void _wake() {
    if (_ticker.isActive) return;
    _base = _lastT = _t;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    _lastT = _t;
    _t = _base + elapsed.inMicroseconds / 1e6;
    final dt = (_t - _lastT).clamp(0.0, 0.05);
    final (left, right) = _bounds;
    var moving = false;
    for (final c in _coins) {
      if (c.pickedAt != null) {
        moving = true;
        continue;
      }
      if (!c.lying) {
        moving = true;
        c
          ..vy += _g * dt
          ..x += c.vx * dt
          ..y += c.vy * dt
          ..angle += c.spin * dt;
        if (c.x < left || c.x > right) {
          c
            ..x = c.x.clamp(left, right)
            ..vx = -c.vx * 0.5;
        }
        if (c.y >= c.restY && c.vy > 0) {
          c.y = c.restY;
          // Clink, and a smaller one for each bounce after.
          SoundService.instance
              .play(Sfx.coinDrop, volume: c.bounces == 0 ? 1 : 0.45);
          c.bounces++;
          if (c.vy > widget.petS * 1.4 && c.bounces < 3) {
            c
              ..vy = -c.vy * 0.36
              ..vx *= 0.6
              ..spin *= 0.6;
          } else {
            c
              ..lying = true
              ..vy = 0
              ..vx *= 0.5;
          }
        }
      } else if (c.vx.abs() > 2) {
        // Rolls on a little and stops.
        moving = true;
        c
          ..x = (c.x + c.vx * dt).clamp(left, right)
          ..vx *= math.exp(-7 * dt);
      }
    }
    _coins.removeWhere(
        (c) => c.pickedAt != null && _t - c.pickedAt! > _pickLength);
    _frame.value++;
    if (!moving) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CoinPainter(this,
            repaint: Listenable.merge([_frame, widget.walk])),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter(this.floor, {super.repaint});
  final _CoinFloorState floor;

  static const _brass = (
    face: Color(0xFFF2C14E),
    rim: Color(0xFFC08A26),
    shine: Color(0xFFFFF1B8),
    mark: Color(0xFFD9A23A),
  );
  static const _silver = (
    face: Color(0xFFDCDFE4),
    rim: Color(0xFF9FA6B0),
    shine: Color(0xFFFFFFFF),
    mark: Color(0xFFB9BFC8),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final r = floor._r;
    final w = floor.widget;
    // Where a picked-up coin goes: into the pet's middle.
    final pocket = Offset(w.sceneWidth / 2 + w.walk.value * w.walkScale,
        w.groundY - w.bodyHeight * 0.45);
    for (final c in floor._coins) {
      final colors = c.silver ? _silver : _brass;
      final picked = c.pickedAt;
      if (picked != null) {
        final k =
            ((floor._t - picked) / _CoinFloorState._pickLength).clamp(0.0, 1.0);
        // A hop up, then into the pet, shrinking away.
        final at =
            Offset.lerp(c.pickedFrom, pocket, Curves.easeIn.transform(k))! +
                Offset(0, -math.sin(k * math.pi) * w.petS * 0.35);
        _coin(canvas, at, r * (1 - 0.6 * k), 1, colors,
            alpha: 1 - Curves.easeIn.transform(k));
        if (k < 0.5) _sparkle(canvas, c.pickedFrom, r, k / 0.5);
        continue;
      }
      if (c.lying) {
        // Flat on the floor: a squashed oval with a soft shadow.
        canvas.drawOval(
          Rect.fromCenter(
              center: Offset(c.x + r * 0.15, c.y + r * 0.25),
              width: r * 2.1,
              height: r * 0.9),
          Paint()..color = Colors.black.withValues(alpha: 0.12),
        );
        _coin(canvas, Offset(c.x, c.y), r, 0.48, colors);
      } else {
        // Flipping over and over as it falls.
        final turn = math.cos(c.angle).abs().clamp(0.12, 1.0);
        _coin(canvas, Offset(c.x, c.y), r, 1, colors,
            widthScale: turn, tilt: c.angle * 0.15);
      }
    }
  }

  /// One coin centred on [at]: [flat] squashes it top to bottom (lying
  /// down), [widthScale] side to side (turning edge-on).
  void _coin(
    Canvas canvas,
    Offset at,
    double r,
    double flat,
    ({Color face, Color rim, Color shine, Color mark}) colors, {
    double widthScale = 1,
    double tilt = 0,
    double alpha = 1,
  }) {
    if (alpha <= 0) return;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(tilt);
    canvas.scale(widthScale, flat);
    Color a(Color c) => c.withValues(alpha: c.a * alpha);
    canvas.drawCircle(Offset.zero, r, Paint()..color = a(colors.rim));
    canvas.drawCircle(Offset.zero, r * 0.8, Paint()..color = a(colors.face));
    // The stamped number: a ring and a little bar.
    final mark = Paint()
      ..color = a(colors.mark)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12;
    canvas.drawCircle(Offset.zero, r * 0.5, mark);
    canvas.drawLine(Offset(0, -r * 0.22), Offset(0, r * 0.22), mark);
    // Shine on the top left.
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: r * 0.66),
      math.pi * 1.05,
      math.pi * 0.45,
      false,
      Paint()
        ..color = a(colors.shine)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  /// A little twinkle where a coin was picked up ([k] 0 → 1).
  void _sparkle(Canvas canvas, Offset at, double r, double k) {
    final paint = Paint()
      ..color = const Color(0xFFFFE08A).withValues(alpha: 1 - k)
      ..strokeWidth = r * 0.22
      ..strokeCap = StrokeCap.round;
    final reach = r * (1.2 + 1.4 * k);
    for (var i = 0; i < 4; i++) {
      final dir = Offset.fromDirection(i * math.pi / 2 + math.pi / 4);
      canvas.drawLine(at + dir * reach * 0.55, at + dir * reach, paint);
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.floor != floor;
}
