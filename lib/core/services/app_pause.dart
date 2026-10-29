import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Whether the app is out of sight — minimised, behind another app, or the
/// screen is off. Meanwhile the pet, its room and its sounds hold still,
/// and they carry on from the same moment when the app is back:
///
///  * animations: no frames are drawn while it's hidden, and when it's
///    back the frame clock picks up from the last frame (rather than
///    jumping ahead by the time away, which would finish half-played
///    moves at once);
///  * timers made with [AppTimer] (and [delay]) stop with the time they
///    had left;
///  * listeners hear of both ([paused], with [lastGap] once it's back).
///
/// Real-world time (the pet getting hungry, the wall clock) goes on as
/// usual.
class AppPause extends ChangeNotifier {
  AppPause._();
  static final instance = AppPause._();

  AppLifecycleListener? _lifecycle;
  bool _paused = false;
  Stopwatch? _away;
  Duration _lastGap = Duration.zero;
  final _timers = <AppTimer>{};

  /// True while the app is out of sight.
  bool get paused => _paused;

  /// How long the app was away the last time.
  Duration get lastGap => _lastGap;

  /// Starts following the app's lifecycle (once, at start-up).
  void init() {
    _lifecycle ??= AppLifecycleListener(onHide: _hide, onShow: _show);
  }

  /// Completes after [duration] of the app being in sight.
  static Future<void> delay(Duration duration) {
    final done = Completer<void>();
    AppTimer(duration, done.complete);
    return done.future;
  }

  @visibleForTesting
  void debugSetPaused(bool paused) => paused ? _hide() : _show();

  void _hide() {
    if (_paused) return;
    _paused = true;
    _away = clock.stopwatch()..start();
    for (final t in _timers.toList()) {
      t._hold();
    }
    notifyListeners();
  }

  void _show() {
    if (!_paused) return;
    _paused = false;
    _lastGap = _away?.elapsed ?? Duration.zero;
    // The next frame follows on from the last one drawn.
    SchedulerBinding.instance.resetEpoch();
    for (final t in _timers.toList()) {
      t._go();
    }
    notifyListeners();
  }
}

/// A [Timer] that stops while the app is out of sight ([AppPause]) and,
/// when it's back, carries on with the time it had left.
class AppTimer implements Timer {
  /// Calls [callback] after [duration] of the app being in sight.
  AppTimer(Duration duration, void Function() callback)
      : this._(duration, (_) => callback(), periodic: false);

  /// Calls [callback] every [period] of the app being in sight.
  AppTimer.periodic(Duration period, void Function(Timer timer) callback)
      : this._(period, callback, periodic: true);

  AppTimer._(this._period, this._callback, {required bool periodic})
      : _periodic = periodic,
        _left = _period {
    AppPause.instance._timers.add(this);
    if (!AppPause.instance.paused) _go();
  }

  final Duration _period;
  final void Function(Timer timer) _callback;
  final bool _periodic;

  /// Time still to wait (as of the last start).
  Duration _left;
  final _running = clock.stopwatch();
  Timer? _timer;
  bool _active = true;
  int _tick = 0;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  @override
  void cancel() {
    _active = false;
    _timer?.cancel();
    _timer = null;
    AppPause.instance._timers.remove(this);
  }

  void _go() {
    if (!_active || _timer != null) return;
    _running
      ..reset()
      ..start();
    _timer = Timer(_left, _fire);
  }

  void _hold() {
    final timer = _timer;
    if (timer == null) return;
    timer.cancel();
    _timer = null;
    _running.stop();
    final left = _left - _running.elapsed;
    _left = left.isNegative ? Duration.zero : left;
  }

  void _fire() {
    _timer = null;
    _tick++;
    if (_periodic) {
      _left = _period;
      _go();
    } else {
      _active = false;
      AppPause.instance._timers.remove(this);
    }
    _callback(this);
  }
}
