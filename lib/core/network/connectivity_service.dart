import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether the app can reach the internet right now, as one thing the
/// whole app can listen to ([online]).
///
/// The phone's network state is the first word ([hasNetwork]: no WiFi or
/// data → offline at once). A request that fails for want of a connection
/// also counts ([reportFailure]): being on a WiFi network doesn't always
/// mean being online. The next network change, or a request that gets
/// through ([reportSuccess]), says otherwise.
class ConnectivityService {
  ConnectivityService._();
  static final instance = ConnectivityService._();

  final _online = ValueNotifier<bool>(true);
  StreamSubscription<List<ConnectivityResult>>? _changes;
  bool _network = true;
  bool _reachable = true;

  /// True while the app looks online.
  ValueListenable<bool> get online => _online;
  bool get isOnline => _online.value;

  /// Whether the phone is on WiFi or mobile data at all. Without it
  /// there's no point trying; with it a request may still fail.
  bool get hasNetwork => _network;

  Future<void> init() async {
    final connectivity = Connectivity();
    try {
      _setNetwork(await connectivity.checkConnectivity());
    } catch (_) {
      // Platform without the plugin (tests, desktop): assume online and
      // let failing requests say otherwise.
    }
    _changes =
        connectivity.onConnectivityChanged.listen(_setNetwork, onError: (_) {});
  }

  void dispose() => _changes?.cancel();

  /// A request failed because there was no connection.
  void reportFailure() {
    _reachable = false;
    _update();
  }

  /// A request got through.
  void reportSuccess() {
    _network = _reachable = true;
    _update();
  }

  /// Whether [error] looks like there was no connection (rather than the
  /// server saying no).
  static bool isNetworkError(Object error) {
    final s = error.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('connection closed') ||
        s.contains('clientexception') ||
        s.contains('timed out') ||
        s.contains('timeoutexception') ||
        s.contains('handshakeexception');
  }

  void _setNetwork(List<ConnectivityResult> results) {
    _network = results.any((c) => c != ConnectivityResult.none);
    // A new network: worth trying again.
    if (_network) _reachable = true;
    _update();
  }

  void _update() => _online.value = _network && _reachable;
}
