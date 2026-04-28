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
  }

  SupabaseClient get client => Supabase.instance.client;
  GoTrueClient get auth => client.auth;
  User? get currentUser => auth.currentUser;
  String? get currentUserId => auth.currentUser?.id;
  bool get isLoggedIn => currentUser != null;
}
