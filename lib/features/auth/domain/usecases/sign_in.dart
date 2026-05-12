import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignIn implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repo;
  SignIn(this.repo);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams p) =>
      repo.signIn(email: p.email, password: p.password);
}

class SignInParams extends Equatable {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}
