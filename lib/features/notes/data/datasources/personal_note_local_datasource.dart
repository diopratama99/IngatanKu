import 'dart:convert';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/synced_table.dart';
import '../../domain/entities/personal_note.dart';
import '../models/personal_note_model.dart';

/// The user's personal notes (Catatan) in the app's database
/// (`personal_notes`, see [AppDatabase]). Pinned first, then the most
/// recently changed — the list's order.
class PersonalNoteLocalDataSource extends SyncedTable<PersonalNoteModel> {
  PersonalNoteLocalDataSource(super.database);

  @override
  String get table => 'personal_notes';

  @override
  String get order => 'pinned desc, updated_at desc, id';

  @override
  String idOf(PersonalNoteModel item) => item.id;

  @override
  Map<String, Object?> toRow(PersonalNoteModel n) => {
        'id': n.id,
        'user_id': n.userId,
        'title': n.title,
        'body': n.body,
        'image_files': jsonEncode(n.imageFiles),
        'links': jsonEncode([for (final l in n.links) l.toJson()]),
        'tags': jsonEncode(n.tags),
        'pinned': n.pinned ? 1 : 0,
        'color': n.color.wireValue,
        'created_at': n.createdAt.millisecondsSinceEpoch,
        'updated_at': n.updatedAt.millisecondsSinceEpoch,
      };

  @override
  PersonalNoteModel fromRow(Map<String, Object?> r) => PersonalNoteModel(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        title: r['title'] as String?,
        body: r['body'] as String? ?? '',
        imageFiles: _list(r['image_files']).cast<String>(),
        links: [
          for (final l in _list(r['links']).whereType<Map>())
            NoteLink.fromJson(Map<String, dynamic>.from(l)),
        ],
        tags: _list(r['tags']).cast<String>(),
        pinned: r['pinned'] == 1,
        color: NoteColor.parse(r['color'] as String?),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
      );

  static List<Object?> _list(Object? json) =>
      json is String ? jsonDecode(json) as List : const [];
}
