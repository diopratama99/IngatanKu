import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/note_entity.dart';

abstract class VaultRepository {
  Future<Either<Failure, NoteEntity>> addNote({
    required String url,
    required String? title,
    required String manualNotes,
    required List<String> tags,
    required String sourceType,
  });

  Future<Either<Failure, NoteEntity>> updateNote({
    required String id,
    String? url,
    String? title,
    String? manualNotes,
    List<String>? tags,
    String? sourceType,
  });

  Future<Either<Failure, List<NoteEntity>>> getNotes({int limit = 50});

  Future<Either<Failure, NoteEntity>> getNoteById(String id);

  Future<Either<Failure, void>> deleteNote(String id);

  Future<Either<Failure, List<NoteEntity>>> searchByTag(String tag);
}
