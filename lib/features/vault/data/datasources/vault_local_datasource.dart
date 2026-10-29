import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/synced_table.dart';
import '../models/note_model.dart';

/// The user's link notes (Pustaka) in the app's database (`vault_notes`,
/// see [AppDatabase]). Besides what [SyncedTable] keeps, a note whose
/// title or text changed here is marked `reembed`: its search embedding
/// has to be made again once it's up.
class VaultLocalDataSource extends SyncedTable<NoteModel> {
  VaultLocalDataSource(super.database);

  @override
  String get table => 'vault_notes';

  @override
  String get order => 'created_at desc, id';

  @override
  Map<String, Object?> get settled => const {'reembed': 0};

  Future<int> count(String userId) async {
    final db = await database.db;
    return Sqflite.firstIntValue(await db.rawQuery(
            'select count(*) from $table where ${SyncedTable.liveWhere}',
            [userId])) ??
        0;
  }

  /// Every tag the user's notes have, with how many have it.
  Future<Map<String, int>> tagCounts(String userId) async {
    final rows = await (await database.db).query(table,
        columns: ['tags'], where: SyncedTable.liveWhere, whereArgs: [userId]);
    final counts = <String, int>{};
    for (final r in rows) {
      for (final t in _list(r['tags'])) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  String idOf(NoteModel item) => item.id;

  @override
  Map<String, Object?> toRow(NoteModel n) => {
        'id': n.id,
        'user_id': n.userId,
        'url': n.url,
        'title': n.title,
        'manual_notes': n.manualNotes,
        'tags': jsonEncode(n.tags),
        'source_type': n.sourceType,
        'thumbnail_url': n.thumbnailUrl,
        'in_quiz': n.inQuiz ? 1 : 0,
        'created_at': n.createdAt.millisecondsSinceEpoch,
      };

  @override
  NoteModel fromRow(Map<String, Object?> r) => NoteModel(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        url: r['url'] as String,
        title: r['title'] as String?,
        manualNotes: r['manual_notes'] as String? ?? '',
        tags: _list(r['tags']),
        sourceType: r['source_type'] as String? ?? 'other',
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        thumbnailUrl: r['thumbnail_url'] as String?,
        inQuiz: r['in_quiz'] != 0,
      );

  static List<String> _list(Object? json) =>
      json is String ? (jsonDecode(json) as List).cast<String>() : const [];
}
