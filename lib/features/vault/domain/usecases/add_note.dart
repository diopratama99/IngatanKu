import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_entity.dart';
import '../repositories/vault_repository.dart';

class AddNote implements UseCase<NoteEntity, AddNoteParams> {
  final VaultRepository repo;
  AddNote(this.repo);

  @override
  Future<Either<Failure, NoteEntity>> call(AddNoteParams p) => repo.addNote(
        url: p.url,
        title: p.title,
        manualNotes: p.manualNotes,
        tags: p.tags,
        sourceType: p.sourceType,
      );
}

class AddNoteParams extends Equatable {
  final String url;
  final String? title;
  final String manualNotes;
  final List<String> tags;
  final String sourceType;
  const AddNoteParams({
    required this.url,
    required this.title,
    required this.manualNotes,
    required this.tags,
    required this.sourceType,
  });
  @override
  List<Object?> get props => [url, title, manualNotes, tags, sourceType];
}
