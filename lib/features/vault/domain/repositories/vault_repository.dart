import 'package:dartz/dartz.dart';
import '../../../../core/database/local_first.dart';
import '../../../../core/error/failures.dart';
import '../entities/note_entity.dart';

/// The user's link notes. Kept on the device: reads and writes are
/// instant and work offline, and [sync] exchanges them with the account.
abstract class VaultRepository implements Syncable {
  Future<Either<Failure, NoteEntity>> addNote({
    required String url,
    required String? title,
    required String manualNotes,
    required List<String> tags,
    required String sourceType,
    String? thumbnailUrl,
    bool inQuiz = true,
  });

  Future<Either<Failure, NoteEntity>> updateNote({
    required String id,
    String? url,
    String? title,
    String? manualNotes,
    List<String>? tags,
    String? sourceType,
    String? thumbnailUrl,
    bool? inQuiz,
  });

  Future<Either<Failure, List<NoteEntity>>> getNotes({int? limit});

  Future<Either<Failure, NoteEntity>> getNoteById(String id);

  Future<Either<Failure, void>> deleteNote(String id);

  Future<Either<Failure, List<NoteEntity>>> searchByTag(String tag);
}
