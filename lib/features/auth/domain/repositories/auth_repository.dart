import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Outcome of a sign-up. The user may be fully authenticated immediately,
/// or they may need to verify an email OTP first.
class SignUpOutcome {
  final UserEntity user;
  final bool needsVerification;
  const SignUpOutcome({required this.user, required this.needsVerification});
}

/// Outcome of signing in with Google: [isNew] when the account was made
/// by this sign-in (it goes through the welcome story first).
class GoogleSignInOutcome {
  final UserEntity user;
  final bool isNew;
  const GoogleSignInOutcome({required this.user, required this.isNew});
}

/// The failure message for a Google sign-in that didn't work; the pages
/// say it in the app's language.
const kGoogleSignInFailed = 'google_sign_in_failed';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Either<Failure, SignUpOutcome>> signUp({
    required String email,
    required String password,
    required String username,
  });

  Future<Either<Failure, UserEntity>> verifyOtp({
    required String email,
    required String token,
  });

  Future<Either<Failure, void>> resendOtp({required String email});

  /// Send a 6-digit OTP for password reset.
  Future<Either<Failure, void>> sendPasswordResetOtp({required String email});

  /// Verify the password-reset OTP. Successful verification produces a
  /// (recovery) session that allows [updatePassword] to be called.
  Future<Either<Failure, UserEntity>> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Update the password for the currently-authenticated user.
  Future<Either<Failure, void>> updatePassword({required String newPassword});

  /// Re-authenticates the current user against [currentPassword] and,
  /// on success, updates the password to [newPassword]. Used by the
  /// Settings page where the user must prove they know the existing
  /// password before changing it (Supabase has no native re-auth, so
  /// we sign-in with the same credentials as a verify step).
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Updates the display name in `user_metadata.name`. Returns the
  /// refreshed [UserEntity] so the UI can rebind without waiting for
  /// the auth-state stream to emit.
  Future<Either<Failure, UserEntity>> updateDisplayName({
    required String name,
  });

  /// Saves the picked avatar ([avatarId], one of `UserAvatar.all`) to
  /// `user_metadata.avatar_id`. Returns the refreshed [UserEntity].
  Future<Either<Failure, UserEntity>> updateAvatar({required String avatarId});

  /// Null when the account picker was dismissed.
  Future<Either<Failure, GoogleSignInOutcome?>> signInWithGoogle();

  Future<Either<Failure, void>> signOut();

  UserEntity? get currentUser;

  Stream<UserEntity?> authStateChanges();
}
