import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/vault_remote_datasource.dart';

class VaultRepositoryImpl implements VaultRepository {
  final VaultRemoteDataSource remote;
  VaultRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, NoteEntity>> addNote({
    required String url,
    required String? title,
    required String manualNotes,
    required List<String> tags,
    required String sourceType,
  }) async {
    try {
      final note = await remote.addNote({
        'url': url,
        'title': title,
        'manual_notes': manualNotes,
        'tags': tags,
        'source_type': sourceType,
      });
      return Right(note);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> updateNote({
    required String id,
    String? url,
    String? title,
    String? manualNotes,
    List<String>? tags,
    String? sourceType,
  }) async {
    try {
      // Build a partial update — only include fields the caller provided.
      final updates = <String, dynamic>{};
      if (url != null) updates['url'] = url;
      if (title != null) updates['title'] = title;
      if (manualNotes != null) updates['manual_notes'] = manualNotes;
      if (tags != null) updates['tags'] = tags;
      if (sourceType != null) updates['source_type'] = sourceType;
      // Reset embedding so the webhook regenerates it from the new content.
      if (manualNotes != null || title != null) {
        updates['embedding'] = null;
      }
      final note = await remote.updateNote(id, updates);
      return Right(note);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> getNotes({int limit = 50}) async {
    try {
      return Right(await remote.getNotes(limit: limit));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(String id) async {
    try {
      return Right(await remote.getNoteById(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(String id) async {
    try {
      await remote.deleteNote(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<NoteEntity>>> searchByTag(String tag) async {
    try {
      return Right(await remote.searchByTag(tag));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
