import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.name,
    super.avatarId,
    super.hasPassword,
  });

  /// Builds a [UserModel] from the auth user. Display fields live in
  /// `user_metadata` (mirroring the web dashboard's contract); we
  /// optionally also accept a `profile` row for backwards compat with
  /// the legacy `ingatanku.profiles.username/avatar_url` schema.
  factory UserModel.fromSupabase(User user, {Map<String, dynamic>? profile}) {
    final meta = user.userMetadata ?? const {};
    // How the account signs in: 'email' (a password), 'google', or both.
    final providers = user.appMetadata['providers'];
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: profile?['username'] as String? ??
          meta['username'] as String?,
      name: meta['name'] as String?,
      avatarId: meta['avatar_id'] as String?,
      hasPassword: providers is! List || providers.contains('email'),
    );
  }
}
