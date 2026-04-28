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

  @override
  Future<NoteModel> addNote(Map<String, dynamic> insert) async {
    try {
      insert['user_id'] = _userId;
      final res = await service.client
          .from(AppConstants.tContentVault)
          .insert(insert)
          .select()
          .single();
      return NoteModel.fromMap(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NoteModel>> getNotes({int limit = 50}) async {
    try {
      final res = await service.client
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
      final res = await service.client
          .from(AppConstants.tContentVault)
          .update(updates)
          .eq('id', id)
          .eq('user_id', _userId)
          .select()
          .single();
      return NoteModel.fromMap(res);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<NoteModel> getNoteById(String id) async {
    try {
      final res = await service.client
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
      await service.client.from(AppConstants.tContentVault).delete().eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<NoteModel>> searchByTag(String tag) async {
    try {
      final res = await service.client
          .from(AppConstants.tContentVault)
          .select()
          .eq('user_id', _userId)
          .contains('tags', [tag])
          .order('created_at', ascending: false);
      return (res as List).map((e) => NoteModel.fromMap(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
