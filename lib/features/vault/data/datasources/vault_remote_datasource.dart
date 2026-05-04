import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/note_model.dart';

abstract class VaultRemoteDataSource {
  Future<NoteModel> addNote(Map<String, dynamic> insert);
  Future<NoteModel> updateNote(String id, Map<String, dynamic> updates);
  Future<List<NoteModel>> getNotes({int limit});
  Future<NoteModel> getNoteById(String id);
  Future<void> deleteNote(String id);
  Future<List<NoteModel>> searchByTag(String tag);
}

class VaultRemoteDataSourceImpl implements VaultRemoteDataSource {
  final SupabaseService service;
  VaultRemoteDataSourceImpl(this.service);

  String get _userId {
    final id = service.currentUserId;
    if (id == null) throw ServerException('Not authenticated');
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
  Future<NoteModel> addNote(Map<String, dynamic> insert) async {
    try {
      insert['user_id'] = _userId;
      final res = await service.db
          .from(AppConstants.tContentVault)
          .insert(insert)
          .select()
          .single();
      final note = NoteModel.fromMap(res);
      // Trigger embedding asynchronously — user-facing save is already done.
      // ignore: unawaited_futures
      _triggerEmbed(note);
      return note;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NoteModel>> getNotes({int limit = 50}) async {
    try {
      final res = await service.db
          .from(AppConstants.tContentVault)
          .select()
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List).map((e) => NoteModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<NoteModel> updateNote(String id, Map<String, dynamic> updates) async {
    try {
      final res = await service.db
          .from(AppConstants.tContentVault)
          .update(updates)
          .eq('id', id)
          .eq('user_id', _userId)
          .select()
          .single();
      final note = NoteModel.fromMap(res);
      // Re-embed only when the textual content changed; tag-only edits
      // and url-only edits don't affect retrieval.
      final touchesEmbeddingFields =
          updates.containsKey('manual_notes') || updates.containsKey('title');
      if (touchesEmbeddingFields) {
        // ignore: unawaited_futures
        _triggerEmbed(note);
      }
      return note;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<NoteModel> getNoteById(String id) async {
    try {
      final res = await service.db
          .from(AppConstants.tContentVault)
          .select()
          .eq('id', id)
          .single();
      return NoteModel.fromMap(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteNote(String id) async {
    try {
      await service.db
          .from(AppConstants.tContentVault)
          .delete()
          .eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NoteModel>> searchByTag(String tag) async {
    try {
      final res = await service.db
          .from(AppConstants.tContentVault)
          .select()
          .eq('user_id', _userId)
          .contains('tags', [tag]).order('created_at', ascending: false);
      return (res as List).map((e) => NoteModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
