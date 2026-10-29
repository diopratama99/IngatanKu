import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/note_entity.dart';
import '../repositories/vault_repository.dart';

class UpdateNote implements UseCase<NoteEntity, UpdateNoteParams> {
  final VaultRepository repo;
  UpdateNote(this.repo);

  @override
  Future<Either<Failure, NoteEntity>> call(UpdateNoteParams p) =>
      repo.updateNote(
        id: p.id,
        url: p.url,
        title: p.title,
        manualNotes: p.manualNotes,
        tags: p.tags,
        sourceType: p.sourceType,
        thumbnailUrl: p.thumbnailUrl,
        inQuiz: p.inQuiz,
      );
}

class UpdateNoteParams extends Equatable {
  final String id;
  final String? url;
  final String? title;
  final String? manualNotes;
  final List<String>? tags;
  final String? sourceType;
  final String? thumbnailUrl;

  /// Whether the quizzes may ask about it (see [NoteEntity.inQuiz]).
  final bool? inQuiz;
  const UpdateNoteParams({
    required this.id,
    this.url,
    this.title,
    this.manualNotes,
    this.tags,
    this.sourceType,
    this.thumbnailUrl,
    this.inQuiz,
  });
  @override
  List<Object?> get props =>
      [id, url, title, manualNotes, tags, sourceType, thumbnailUrl, inQuiz];
}
