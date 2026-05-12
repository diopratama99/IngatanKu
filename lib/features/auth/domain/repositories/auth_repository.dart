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

  Future<Either<Failure, void>> signOut();

  UserEntity? get currentUser;

  Stream<UserEntity?> authStateChanges();
}
