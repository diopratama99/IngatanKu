import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class SignOut implements UseCase<void, NoParams> {
  final AuthRepository repo;
  SignOut(this.repo);
  @override
  Future<Either<Failure, void>> call(NoParams params) => repo.signOut();
}
