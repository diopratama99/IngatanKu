import 'dart:async';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/note_model.dart';

/// The user's link notes on the server (`ingatanku.content_vault`).
///
/// The app reads and writes them on the device first
/// ([VaultLocalDataSource]); this is how they get to and from the
/// account. Errors are thrown as they come, so the caller can tell a
/// missing connection from the server saying no.
abstract class VaultRemoteDataSource {
  /// All of the signed-in user's notes, newest first.
  Future<List<NoteModel>> fetchAll();

  Future<NoteModel?> fetch(String id);

  /// Creates or replaces [note] (its id is made on the device). With
  /// [reembed], its search embedding is made again from the new text.
  Future<void> push(NoteModel note, {required bool reembed});

  Future<void> delete(String id);
}

class VaultRemoteDataSourceImpl implements VaultRemoteDataSource {
  final SupabaseService service;
  VaultRemoteDataSourceImpl(this.service);

  /// What the app shows, without the (large) embedding vector.
  static const _columns = 'id,user_id,url,title,manual_notes,tags,'
      'source_type,created_at,thumbnail_url,in_quiz';

  static const _page = 1000;

  String get _userId {
    final id = service.currentUserId;
    if (id == null) throw StateError('Not authenticated');
    return id;
  }

  /// Fire-and-forget call to the `embed-note` edge function. We don't
  /// rely on the database webhook to fire because self-hosted Supabase
  /// instances often lack `pg_net`; calling the function inline gives
  /// us a deterministic embedding pipeline. Errors are swallowed so a
  /// missing key / network blip never blocks the user from saving the
  /// note — worst case the embedding can be backfilled via
  /// `reembed-missing` later.
  Future<void> _triggerEmbed(NoteModel note) async {
    try {
      await service.client.functions.invoke(
        AppConstants.fnEmbedNote,
        body: {
          'record': {
            'id': note.id,
            'title': note.title,
            'manual_notes': note.manualNotes,
          },
        },
      );
    } catch (e) {
      // Don't surface to caller — embedding is best-effort.
      // ignore: avoid_print
      print('[vault] embed-note invoke failed: $e');
    }
  }

  @override
  Future<List<NoteModel>> fetchAll() async {
    final userId = _userId;
    final notes = <NoteModel>[];
    // A page at a time: the API caps how many rows one request returns.
    while (true) {
      final res = await service.db
          .from(AppConstants.tContentVault)
          .select(_columns)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .order('id')
          .range(notes.length, notes.length + _page - 1);
      notes.addAll(res.map(NoteModel.fromMap));
      if (res.length < _page) return notes;
    }
  }

  @override
  Future<NoteModel?> fetch(String id) async {
    final res = await service.db
        .from(AppConstants.tContentVault)
        .select(_columns)
        .eq('id', id)
        .maybeSingle();
    return res == null ? null : NoteModel.fromMap(res);
  }

  @override
  Future<void> push(NoteModel note, {required bool reembed}) async {
    await service.db.from(AppConstants.tContentVault).upsert(
      {
        ...note.toRow(),
        'user_id': _userId,
        // Cleared so a stale one never answers for the new text.
        if (reembed) 'embedding': null,
      },
      onConflict: 'id',
    );
    // The embedding comes a moment later; saving doesn't wait for it.
    if (reembed) unawaited(_triggerEmbed(note));
  }

  @override
  Future<void> delete(String id) =>
      service.db.from(AppConstants.tContentVault).delete().eq('id', id);
}
