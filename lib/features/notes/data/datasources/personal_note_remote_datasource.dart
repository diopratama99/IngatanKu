import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/supabase_client.dart';
import '../models/personal_note_model.dart';

/// The user's personal notes on the server (`ingatanku.personal_notes`).
///
/// The app reads and writes them on the device first
/// ([PersonalNoteLocalDataSource]); this is how they get to and from the
/// account. Errors are thrown as they come, so the caller can tell a
/// missing connection from the server saying no.
abstract class PersonalNoteRemoteDataSource {
  /// All of the signed-in user's notes.
  Future<List<PersonalNoteModel>> fetchAll();

  Future<PersonalNoteModel?> fetch(String id);

  /// Creates or replaces [note] (its id is made on the device).
  Future<void> push(PersonalNoteModel note);

  Future<void> delete(String id);
}

class PersonalNoteRemoteDataSourceImpl implements PersonalNoteRemoteDataSource {
  final SupabaseService service;
  PersonalNoteRemoteDataSourceImpl(this.service);

  static const _page = 1000;

  String get _userId {
    final id = service.currentUserId;
    if (id == null) throw StateError('Not authenticated');
    return id;
  }

  @override
  Future<List<PersonalNoteModel>> fetchAll() async {
    final userId = _userId;
    final notes = <PersonalNoteModel>[];
    // A page at a time: the API caps how many rows one request returns.
    while (true) {
      final res = await service.db
          .from(AppConstants.tPersonalNotes)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .order('id')
          .range(notes.length, notes.length + _page - 1);
      notes.addAll(res.map(PersonalNoteModel.fromMap));
      if (res.length < _page) return notes;
    }
  }

  @override
  Future<PersonalNoteModel?> fetch(String id) async {
    final res = await service.db
        .from(AppConstants.tPersonalNotes)
        .select()
        .eq('id', id)
        .maybeSingle();
    return res == null ? null : PersonalNoteModel.fromMap(res);
  }

  /// RLS guarantees we can't upsert into someone else's note even if the
  /// id collides.
  @override
  Future<void> push(PersonalNoteModel note) => service.db
      .from(AppConstants.tPersonalNotes)
      .upsert(note.toUpsert(userId: _userId), onConflict: 'id');

  @override
  Future<void> delete(String id) =>
      service.db.from(AppConstants.tPersonalNotes).delete().eq('id', id);
}
