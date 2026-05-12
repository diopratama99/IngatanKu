import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/vault_repository.dart';

class DeleteNote implements UseCase<void, String> {
  final VaultRepository repo;
  DeleteNote(this.repo);
  @override
  Future<Either<Failure, void>> call(String id) => repo.deleteNote(id);
}
