import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignUp implements UseCase<SignUpOutcome, SignUpParams> {
  final AuthRepository repo;
  SignUp(this.repo);

  @override
  Future<Either<Failure, SignUpOutcome>> call(SignUpParams p) =>
      repo.signUp(email: p.email, password: p.password, username: p.username);
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String username;
  const SignUpParams({required this.email, required this.password, required this.username});
  @override
  List<Object?> get props => [email, password, username];
}
