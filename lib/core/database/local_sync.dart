import 'dart:async';

import 'package:flutter/widgets.dart';

import '../network/connectivity_service.dart';
import 'local_first.dart';

/// Keeps the data on the phone in step with the account, beyond what the
/// screens ask for: every [Syncable] is exchanged when someone signs in,
/// when the phone is back online, and when the app comes back to the
/// front (not more than every [resumeEvery]).
class LocalSync with WidgetsBindingObserver {
  LocalSync(this.parts, {ConnectivityService? connectivity})
      : _net = connectivity ?? ConnectivityService.instance;

  final List<Syncable> parts;
  final ConnectivityService _net;

  static const resumeEvery = Duration(minutes: 1);

  StreamSubscription<String?>? _users;
  String? _user;
  bool _wasOnline = true;
  DateTime? _resumedAt;

  /// Follows [users] (who's signed in), starting with [current].
  void start(String? current, Stream<String?> users) {
    _user = current;
    _wasOnline = _net.isOnline;
    _net.online.addListener(_onNetwork);
    _users = users.listen(_onUser, onError: (_) {});
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> syncAll() => Future.wait([for (final p in parts) p.sync()]);

  void _onUser(String? id) {
    if (id == _user) return;
    _user = id;
    // The screens show this user's notes now (or nobody's).
    for (final p in parts) {
      p.reload();
    }
    if (id != null) unawaited(syncAll());
  }

  void _onNetwork() {
    final online = _net.isOnline;
    if (online && !_wasOnline && _user != null) unawaited(syncAll());
    _wasOnline = online;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _user == null) return;
    final now = DateTime.now();
    final last = _resumedAt;
    if (last != null && now.difference(last) < resumeEvery) return;
    _resumedAt = now;
    unawaited(syncAll());
  }

  void dispose() {
    _users?.cancel();
    _net.online.removeListener(_onNetwork);
    WidgetsBinding.instance.removeObserver(this);
  }
}
