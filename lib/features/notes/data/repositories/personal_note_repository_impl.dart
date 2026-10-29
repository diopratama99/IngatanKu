import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_first.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/personal_note.dart';
import '../../domain/repositories/personal_note_repository.dart';
import '../datasources/personal_note_image_store.dart';
import '../datasources/personal_note_local_datasource.dart';
import '../datasources/personal_note_remote_datasource.dart';
import '../models/personal_note_model.dart';

/// [PersonalNoteRepository] on the device first: notes are read from and
/// saved to [local] at once, and what's changed goes up to [remote] in
/// the background — right away when online, otherwise at the next
/// [sync]. Pictures stay on the device ([images]).
class PersonalNoteRepositoryImpl
    with LocalFirst
    implements PersonalNoteRepository {
  PersonalNoteRepositoryImpl({
    required this.remote,
    required this.local,
    required this.images,
    required String? Function() currentUser,
  }) : _currentUser = currentUser;

  final PersonalNoteRemoteDataSource remote;
  final PersonalNoteLocalDataSource local;
  final PersonalNoteImageStore images;
  final String? Function() _currentUser;

  @override
  String get label => 'notes';

  @override
  String? get userId => _currentUser();

  @override
  Future<Either<Failure, List<PersonalNote>>> list({int? limit}) =>
      read((userId) => local.live(userId, limit: limit));

  @override
  Future<Either<Failure, PersonalNote>> getById(String id) =>
      read((userId) async {
        final mine = await local.find(id);
        if (mine != null && mine.sync != SyncState.delete) return mine.item;
        // Not on this phone (yet): ask the server.
        final there = await remote.fetch(id);
        if (there == null) throw const CacheFailure('Note not found');
        return there;
      });

  @override
  Future<Either<Failure, PersonalNote>> create(PersonalNote draft) =>
      _save(draft);

  @override
  Future<Either<Failure, PersonalNote>> update(PersonalNote note) =>
      _save(note);

  Future<Either<Failure, PersonalNote>> _save(PersonalNote note) =>
      write((userId) async {
        final mine = await local.find(note.id);
        final saved = PersonalNoteModel.of(note, userId: userId);
        await local.save(
          saved,
          // New, or not on the server yet: still to be created there.
          sync: mine == null || mine.sync == SyncState.insert
              ? SyncState.insert
              : SyncState.update,
        );
        return saved;
      });

  @override
  Future<Either<Failure, void>> delete(String id) => write((_) async {
        await local.remove(id);
        // Best-effort image cleanup: orphan files are a small price vs.
        // a half-deleted note.
        try {
          await images.deleteAll(id);
        } catch (_) {}
      });

  @override
  Future<Either<Failure, String>> attachImage({
    required String noteId,
    required String sourcePath,
  }) async {
    try {
      final basename = await images.attach(
        noteId: noteId,
        sourcePath: sourcePath,
      );
      return Right(basename);
    } catch (e) {
      return Left(UnknownFailure('Gagal melampirkan gambar: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> detachImage({
    required String noteId,
    required String filename,
  }) async {
    try {
      await images.detach(noteId: noteId, filename: filename);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure('Gagal menghapus gambar: $e'));
    }
  }

  @override
  Future<String> imagePath({
    required String noteId,
    required String filename,
  }) {
    return images.pathFor(noteId: noteId, filename: filename);
  }

  @override
  @protected
  Future<void> exchange() async {
    final user = userId;
    if (user == null) return;
    await exchangeTable(
      local,
      user,
      push: (row) => remote.push(row.item),
      delete: remote.delete,
      fetchAll: remote.fetchAll,
    );
  }
}
