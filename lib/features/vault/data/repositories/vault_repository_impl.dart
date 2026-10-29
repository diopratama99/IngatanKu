import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/local_first.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../datasources/vault_local_datasource.dart';
import '../datasources/vault_remote_datasource.dart';
import '../models/note_model.dart';

/// [VaultRepository] on the device first: notes are read from and saved
/// to [local] at once (ids and times made here), and what's changed goes
/// up to [remote] in the background — right away when online, otherwise
/// at the next [sync].
class VaultRepositoryImpl with LocalFirst implements VaultRepository {
  VaultRepositoryImpl({
    required this.remote,
    required this.local,
    required String? Function() currentUser,
    DateTime Function()? clock,
  })  : _currentUser = currentUser,
        _clock = clock ?? DateTime.now;

  final VaultRemoteDataSource remote;
  final VaultLocalDataSource local;
  final String? Function() _currentUser;
  final DateTime Function() _clock;

  static const _ids = Uuid();

  /// The note's search embedding has to be made again.
  static const _reembed = {'reembed': 1};

  @override
  String get label => 'vault';

  @override
  String? get userId => _currentUser();

  @override
  Future<Either<Failure, NoteEntity>> addNote({
    required String url,
    required String? title,
    required String manualNotes,
    required List<String> tags,
    required String sourceType,
    String? thumbnailUrl,
    bool inQuiz = true,
  }) =>
      write((userId) async {
        final note = NoteModel(
          id: _ids.v4(),
          userId: userId,
          url: url,
          title: title,
          manualNotes: manualNotes,
          tags: tags,
          sourceType: sourceType,
          createdAt: _clock(),
          thumbnailUrl: (thumbnailUrl == null || thumbnailUrl.isEmpty)
              ? null
              : thumbnailUrl,
          inQuiz: inQuiz,
        );
        await local.save(note, sync: SyncState.insert, extra: _reembed);
        return note;
      });

  @override
  Future<Either<Failure, NoteEntity>> updateNote({
    required String id,
    String? url,
    String? title,
    String? manualNotes,
    List<String>? tags,
    String? sourceType,
    String? thumbnailUrl,
    bool? inQuiz,
  }) =>
      write((userId) async {
        final mine = await local.find(id);
        if (mine == null || mine.sync == SyncState.delete) {
          throw const CacheFailure('Note not found');
        }
        final before = mine.item;
        final note = before.copyWith(
          url: url,
          title: title,
          manualNotes: manualNotes,
          tags: tags,
          sourceType: sourceType,
          thumbnailUrl: thumbnailUrl,
          inQuiz: inQuiz,
        );
        // Only the text is searched: tag or link edits keep the embedding.
        final reembed = mine.row['reembed'] == 1 ||
            note.title != before.title ||
            note.manualNotes != before.manualNotes;
        await local.save(
          note,
          // Not on the server yet: still to be created there.
          sync: mine.sync == SyncState.insert
              ? SyncState.insert
              : SyncState.update,
          extra: reembed ? _reembed : const {},
        );
        return note;
      });

  @override
  Future<Either<Failure, void>> deleteNote(String id) =>
      write((_) => local.remove(id));

  @override
  Future<Either<Failure, List<NoteEntity>>> getNotes({int? limit}) =>
      read((userId) => local.live(userId, limit: limit));

  @override
  Future<Either<Failure, NoteEntity>> getNoteById(String id) =>
      read((userId) async {
        final mine = await local.find(id);
        if (mine != null && mine.sync != SyncState.delete) return mine.item;
        // Not on this phone (yet): ask the server.
        final there = await remote.fetch(id);
        if (there == null) throw const CacheFailure('Note not found');
        return there;
      });

  @override
  Future<Either<Failure, List<NoteEntity>>> searchByTag(String tag) =>
      read((userId) async => [
            for (final n in await local.live(userId))
              if (n.tags.contains(tag)) n,
          ]);

  @override
  @protected
  Future<void> exchange() async {
    final user = userId;
    if (user == null) return;
    await exchangeTable(
      local,
      user,
      // A new note gets its embedding too.
      push: (row) => remote.push(row.item,
          reembed: row.sync == SyncState.insert || row.row['reembed'] == 1),
      delete: remote.delete,
      fetchAll: remote.fetchAll,
    );
  }
}
