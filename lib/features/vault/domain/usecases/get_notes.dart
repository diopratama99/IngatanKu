import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_entity.dart';
import '../repositories/vault_repository.dart';

class GetNotes implements UseCase<List<NoteEntity>, NoParams> {
  final VaultRepository repo;
  GetNotes(this.repo);
  @override
  Future<Either<Failure, List<NoteEntity>>> call(NoParams params) => repo.getNotes();
}
