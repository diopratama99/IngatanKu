import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/services/app_pause.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/widgets/mosquito_painter.dart';

/// A mosquito buzzing in, as Beranda asks for it.
class MosquitoPlan {
  /// Comes in from the left, or from the right.
  final bool fromLeft;
  const MosquitoPlan({required this.fromLeft});
}

/// The mosquito easter egg on Beranda. It buzzes in from one side and
/// does a lap round the pet's head (the pet spots it and follows it with
/// its eyes); darts off and the pet hops after it, twice; then hovers
/// right over its head — and the pet jumps up and slurps it in, Kirby
/// style ([BlobController.hap]). It doesn't fill the pet up.
///
/// The pet's walking is Beranda's ([onChase] walks it to a walk value);
/// its lines go through [onSay]. When the pet gets busy ([interrupted])
/// the mosquito flies off.
class MosquitoHunt extends StatefulWidget {
  final MosquitoPlan plan;
  final double sceneWidth;

  /// The floor line the pet stands on, and its reference size.
  final double groundY;
  final double petS;

  /// Where the pet is: [walk] × [walkScale] pixels from the middle.
  final Animation<double> walk;
  final double walkScale;

  final BlobController host;
  final bool interrupted;
  final Future<void> Function(double walk) onChase;
  final void Function(String line, Duration hold) onSay;
  final VoidCallback onDone;

  const MosquitoHunt({
    super.key,
    required this.plan,
    required this.sceneWidth,
    required this.groundY,
    required this.petS,
    required this.walk,
    required this.walkScale,
    required this.host,
    required this.interrupted,
    required this.onChase,
    required this.onSay,
    required this.onDone,
  });

  @override
  State<MosquitoHunt> createState() => _MosquitoHuntState();
}

class _MosquitoHuntState extends State<MosquitoHunt>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = ValueNotifier<int>(0);

  double _t = 0;

  /// Where it's flying (before its wobble), and the leg it's on.
  Offset _pos = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  double _legAt = 0;
  double _legLength = 1;
  Curve _curve = Curves.easeInOut;
  Completer<void>? _arrived;
  double _facing = 1;

  /// The pet's eyes follow it.
  bool _watched = false;

  /// Eaten: the pet draws it from here on.
  bool _gone = false;
  bool _leaving = false;
  bool _done = false;

  bool _buzzing = false;
  ValueListenable<bool>? _visible;

  double get _s => widget.petS;
  double get _side => widget.plan.fromLeft ? -1 : 1;
  double get _petX =>
      widget.sceneWidth / 2 + widget.walk.value * widget.walkScale;

  /// [up] pet sizes above the floor.
  double _above(double up) => widget.groundY - _s * up;

  /// Where it shows: drifting about where it's flying, as mosquitoes do.
  Offset get _shown =>
      _pos +
      Offset(math.sin(_t * 6.3) * _s * 0.05, math.sin(_t * 9.1) * _s * 0.04);

  bool get _going => mounted && !_leaving && !widget.interrupted;

  @override
  void initState() {
    super.initState();
    _pos = Offset(widget.sceneWidth / 2 + _side * (widget.sceneWidth / 2 + _s),
        _above(1.7));
    _ticker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quiet while Beranda is covered by another page.
    final visible = TickerMode.getNotifier(context);
    if (visible != _visible) {
      _visible?.removeListener(_syncBuzz);
      _visible = visible..addListener(_syncBuzz);
    }
  }

  @override
  void didUpdateWidget(MosquitoHunt old) {
    super.didUpdateWidget(old);
    if (widget.interrupted && !old.interrupted) _leave();
  }

  @override
  void dispose() {
    _visible?.removeListener(_syncBuzz);
    if (_buzzing) SoundService.instance.setLoop(SfxLoop.buzz, false);
    if (_watched) widget.host.focus(null);
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _syncBuzz() {
    final on = !_gone && !_done && (_visible?.value ?? true);
    if (on == _buzzing) return;
    _buzzing = on;
    SoundService.instance.setLoop(SfxLoop.buzz, on);
  }

  void _tick(Duration elapsed) {
    _t = elapsed.inMicroseconds / 1e6;
    final arrived = _arrived;
    if (arrived != null) {
      final q = ((_t - _legAt) / _legLength).clamp(0.0, 1.0);
      _pos = Offset.lerp(_from, _to, _curve.transform(q))!;
      if (q >= 1) {
        _arrived = null;
        arrived.complete();
      }
    }
    if (_watched && !_gone) widget.host.focus(_lookAt(_shown));
    _frame.value++;
  }

  /// The pet's gaze (-1..1 each way) towards [at].
  Offset _lookAt(Offset at) {
    final v = (at - Offset(_petX, _above(0.37))) / (_s * 0.6);
    return Offset(v.dx.clamp(-1.0, 1.0), v.dy.clamp(-1.0, 1.0));
  }

  /// Flies to [to] over [ms]; false if it should be off by then.
  Future<bool> _flyTo(Offset to, int ms, {Curve curve = Curves.easeInOut}) {
    _arrived?.complete();
    _from = _pos;
    _to = to;
    _legAt = _t;
    _legLength = ms / 1000;
    _curve = curve;
    if ((to.dx - _pos.dx).abs() > 2) _facing = (to.dx - _pos.dx).sign;
    final arrived = _arrived = Completer<void>();
    return arrived.future.then((_) => _going);
  }

  Future<bool> _wait(int ms) async {
    await AppPause.delay(Duration(milliseconds: ms));
    return _going;
  }

  /// Stays inside the room.
  double _inRoom(double x) =>
      x.clamp(_s * 0.6, math.max(_s * 0.6, widget.sceneWidth - _s * 0.6));

  Future<void> _run() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    _syncBuzz();
    // In it comes, wandering over to the pet.
    if (!await _flyTo(
        Offset(_inRoom(_petX + _side * _s * 0.8), _above(1.3)), 2400)) {
      return _leave();
    }
    // Spotted.
    _watched = true;
    widget.host.express(BlobExpression.surprised,
        duration: const Duration(milliseconds: 900));
    widget.onSay(l10n.petStatusMosquito, const Duration(milliseconds: 2400));
    // A lap round its head, teasing.
    for (final (dx, up) in [(-0.75, 1.45), (0.0, 1.05), (0.75, 1.4)]) {
      if (!await _flyTo(
          Offset(_inRoom(_petX + _side * dx * _s), _above(up)), 600)) {
        return _leave();
      }
    }
    // The chase: it darts off and the pet hops after it — then back.
    var dir = _petX > widget.sceneWidth / 2 ? -1.0 : 1.0;
    for (var i = 0; i < 2; i++) {
      if (i == 0) {
        widget.onSay(
            l10n.petStatusMosquitoChase, const Duration(milliseconds: 2000));
      }
      final x = _inRoom(_petX + dir * _s * 1.4);
      final walk =
          (x - dir * _s * 0.3 - widget.sceneWidth / 2) / widget.walkScale;
      final flying =
          _flyTo(Offset(x, _above(1.25)), 800, curve: Curves.easeOutCubic);
      await Future.wait([flying, widget.onChase(walk.clamp(-1.1, 1.1))]);
      if (!_going) return _leave();
      dir = -dir;
    }
    // Right above its head…
    if (!await _flyTo(Offset(_petX, _above(1.5)), 500) || !await _wait(200)) {
      return _leave();
    }
    // …hap!
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final at = box != null && box.hasSize ? box.localToGlobal(_shown) : null;
    _watched = false;
    setState(() => _gone = true);
    _syncBuzz();
    widget.host.hap(fromGlobal: at);
    widget.onSay(
        l10n.petStatusMosquitoCaught, const Duration(milliseconds: 2000));
    await AppPause.delay(BlobController.hapLength);
    if (mounted) {
      widget.onSay(
          l10n.petStatusMosquitoAfter, const Duration(milliseconds: 2600));
    }
    _finish();
  }

  /// Off it goes, out of the room the nearer way.
  Future<void> _leave() async {
    if (_leaving || _done || _gone || !mounted) return;
    _leaving = true;
    if (_watched) {
      _watched = false;
      widget.host.focus(null);
    }
    final out = _pos.dx < widget.sceneWidth / 2 ? -1.0 : 1.0;
    _from = _pos;
    _to = Offset(widget.sceneWidth / 2 + out * (widget.sceneWidth / 2 + _s),
        _above(2.0));
    _legAt = _t;
    _legLength = 1.0;
    _curve = Curves.easeIn;
    _facing = out;
    // Whatever leg it was on is over (the script sees it's leaving).
    _arrived?.complete();
    final arrived = _arrived = Completer<void>();
    await arrived.future;
    _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _syncBuzz();
    if (_watched) widget.host.focus(null);
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        painter: _MosquitoPainter(this),
        size: Size.infinite,
      ),
    );
  }
}

class _MosquitoPainter extends CustomPainter {
  final _MosquitoHuntState hunt;
  _MosquitoPainter(this.hunt) : super(repaint: hunt._frame);

  @override
  void paint(Canvas canvas, Size size) {
    paintMosquito(canvas, hunt._shown, hunt._s * 0.24, hunt._t,
        facing: hunt._facing);
  }

  @override
  bool shouldRepaint(_MosquitoPainter old) => false;
}
