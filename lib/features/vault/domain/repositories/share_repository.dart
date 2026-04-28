import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/note_entity.dart';

abstract class ShareRepository {
  /// Enable sharing for [noteId]. Returns the share token.
  Future<Either<Failure, String>> enable(String noteId);

  /// Disable sharing.
  Future<Either<Failure, void>> disable(String noteId);

  /// Look up a note by its public share token (no auth required).
  Future<Either<Failure, NoteEntity>> getByToken(String token);
}
