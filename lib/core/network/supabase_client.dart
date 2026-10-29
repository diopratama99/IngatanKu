import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class SupabaseService {
  SupabaseService._();
  static final instance = SupabaseService._();

  static Future<void> init() async {
    if (!Env.isConfigured) {
      throw StateError(
        'Supabase env not configured. Pass --dart-define=SUPABASE_URL=... and SUPABASE_ANON_KEY=...',
      );
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      debug: false,
    );
    // After cold start the persisted access token may already be
    // expired (default Supabase JWT TTL is 1h). Refresh it straight away
    // so the first requests don't 401 — without waiting for it: offline
    // that would hold up the start, and the notes on the phone don't
    // need it. Failure is non-fatal; [ensureFreshAccessToken] tries
    // again before edge-function calls.
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) {
      unawaited(auth.refreshSession().then<void>((_) {}, onError: (_) {}));
    }
  }

  SupabaseClient get client => Supabase.instance.client;

  /// Data accessor scoped to the dedicated `ingatanku` Postgres schema.
  /// Use this for every `.from(...)` / `.rpc(...)` call so multiple apps
  /// can safely coexist in the same Supabase project.
  SupabaseQuerySchema get db => client.schema('ingatanku');

  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  String? get currentUserId => auth.currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  /// Returns a fresh access token, transparently refreshing the
  /// persisted session if it's already expired (or about to expire
  /// within the next 30 seconds). All datasources hitting Edge
  /// Functions should call this instead of `auth.currentSession?.accessToken`
  /// directly so they never send a stale JWT.
  ///
  /// Returns null when there's no signed-in user — callers should
  /// surface "Belum login" in that case.
  Future<String?> ensureFreshAccessToken() async {
    final session = auth.currentSession;
    if (session == null) return null;

    final expiresAt = session.expiresAt; // unix seconds
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final needsRefresh =
        expiresAt == null || (expiresAt - now) <= 30; // 30s safety margin

    if (!needsRefresh) return session.accessToken;

    try {
      final res = await auth.refreshSession();
      return res.session?.accessToken ?? session.accessToken;
    } catch (_) {
      // Refresh failed — return whatever we still have; the caller
      // will see a 401 and can prompt the user to re-login.
      return session.accessToken;
    }
  }
}
