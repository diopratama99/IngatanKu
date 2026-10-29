import 'package:equatable/equatable.dart';

/// Authenticated user. Display fields (`name`, `avatarId`) live in
/// Supabase's `auth.users.user_metadata` JSON — same source as the web
/// dashboard so changes from either client are immediately visible on
/// the other.
class UserEntity extends Equatable {
  final String id;
  final String email;

  /// Sign-up handle (legacy). Kept for back-compat with rows that
  /// stored only `username`. Display logic should prefer [name] when
  /// it's available, falling back to this and finally to email.
  final String? username;

  /// Display name as edited via Settings page on web/mobile. Source
  /// of truth: `user_metadata.name`.
  final String? name;

  /// Which blob friend the user picked as their avatar (see
  /// `UserAvatar`). Source of truth: `user_metadata.avatar_id`.
  final String? avatarId;

  /// Signs in with a password (and so can change it). False for an
  /// account that only ever signed in with Google.
  final bool hasPassword;

  const UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.name,
    this.avatarId,
    this.hasPassword = true,
  });

  /// What to render in the UI as the user's display name. Falls back
  /// gracefully so we never end up with a blank header.
  String get displayName {
    if (name != null && name!.trim().isNotEmpty) return name!.trim();
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    final emailHandle = email.split('@').first;
    return emailHandle.isEmpty ? 'Anonim' : emailHandle;
  }

  @override
  List<Object?> get props =>
      [id, email, username, name, avatarId, hasPassword];
}
