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

  Future<Either<Failure, void>> signOut();

  UserEntity? get currentUser;

  Stream<UserEntity?> authStateChanges();
}
