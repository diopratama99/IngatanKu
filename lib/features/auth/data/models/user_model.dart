import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.avatarUrl,
  });

  factory UserModel.fromSupabase(User user, {Map<String, dynamic>? profile}) {
    return UserModel(
      id: user.id,
      email: user.email ?? '',
      username: profile?['username'] as String? ??
          user.userMetadata?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
