import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// A row of a [SyncedTable] with what it still owes the server.
class LocalRow<T> {
  final T item;
  final SyncState sync;

  /// Bumped by every change made here.
  final int rev;

  /// The row as stored, for table-specific columns.
  final Map<String, Object?> row;

  const LocalRow(this.item, this.sync, this.rev, this.row);
}

/// One table of the user's data in [AppDatabase], kept in step with the
/// server's copy.
///
/// Changes made here are saved at once and marked as owed ([save],
/// [remove]); the repository sends them up ([pending]) and marks them
/// sent ([settle], [forget]). What comes down from the server is
/// [merge]d in without overwriting anything still owed.
abstract class SyncedTable<T> {
  SyncedTable(this.database);
  final AppDatabase database;

  String get table;

  /// Default order of [live].
  String get order;

  /// The table's own columns for [item] (not `sync` or `rev`).
  Map<String, Object?> toRow(T item);
  T fromRow(Map<String, Object?> row);
  String idOf(T item);

  /// Columns reset once the server has a row (besides `sync`).
  Map<String, Object?> get settled => const {};

  /// The user's rows still in the app (not waiting to be deleted).
  static const liveWhere = "user_id = ? and sync != 'delete'";

  Future<List<T>> live(String userId, {int? limit}) async {
    final rows = await (await database.db).query(table,
        where: liveWhere, whereArgs: [userId], orderBy: order, limit: limit);
    return [for (final r in rows) fromRow(r)];
  }

  /// The row with [id], also when it's waiting to be deleted.
  Future<LocalRow<T>?> find(String id) async {
    final rows = await (await database.db)
        .query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : _local(rows.first);
  }

  /// Rows changed here that the server hasn't had yet, oldest first.
  Future<List<LocalRow<T>>> pending(String userId) async {
    final rows = await (await database.db).query(table,
        where: "user_id = ? and sync != 'synced'",
        whereArgs: [userId],
        orderBy: 'created_at');
    return [for (final r in rows) _local(r)];
  }

  /// Saves [item] as changed here, with any [extra] columns.
  Future<void> save(T item,
      {required SyncState sync, Map<String, Object?> extra = const {}}) async {
    final id = idOf(item);
    await (await database.db).transaction((tx) async {
      await tx.insert(
        table,
        {
          ...toRow(item),
          ...extra,
          'sync': sync.name,
          'rev': await _rev(tx, id) + 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// Takes the row out of the app; it stays until the server has deleted
  /// it too ([forget]).
  Future<void> remove(String id) async {
    await (await database.db).transaction((tx) async {
      await tx.update(
        table,
        {'sync': SyncState.delete.name, 'rev': await _rev(tx, id) + 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// The server has [rev] of the row: nothing owed, unless it changed
  /// again here meanwhile.
  Future<void> settle(String id, int rev) async {
    await (await database.db).update(
      table,
      {...settled, 'sync': SyncState.synced.name},
      where: 'id = ? and rev = ?',
      whereArgs: [id, rev],
    );
  }

  /// The server has deleted the row too.
  Future<void> forget(String id, int rev) async {
    await (await database.db)
        .delete(table, where: 'id = ? and rev = ?', whereArgs: [id, rev]);
  }

  /// Takes in the server's copy of the user's rows. Rows with changes
  /// here not sent yet keep those. With [complete] (it's every row the
  /// server has), rows no longer there are gone from here too. Returns
  /// whether anything changed.
  Future<bool> merge(String userId, List<T> remote,
      {required bool complete}) async {
    return (await database.db).transaction((tx) async {
      final local = {
        for (final r
            in await tx.query(table, where: 'user_id = ?', whereArgs: [userId]))
          r['id'] as String: r,
      };
      final batch = tx.batch();
      var changed = false;
      for (final item in remote) {
        final mine = local[idOf(item)];
        if (mine != null && _syncOf(mine) != SyncState.synced) continue;
        final row = toRow(item);
        if (mine != null && row.keys.every((k) => row[k] == mine[k])) continue;
        batch.insert(
          table,
          {...row, 'sync': SyncState.synced.name, 'rev': mine?['rev'] ?? 0},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        changed = true;
      }
      if (complete) {
        final there = {for (final item in remote) idOf(item)};
        for (final mine in local.values) {
          final id = mine['id'] as String;
          if (_syncOf(mine) == SyncState.synced && !there.contains(id)) {
            batch.delete(table, where: 'id = ?', whereArgs: [id]);
            changed = true;
          }
        }
      }
      await batch.commit(noResult: true);
      return changed;
    });
  }

  Future<int> _rev(DatabaseExecutor db, String id) async {
    final rows = await db.query(table,
        columns: ['rev'], where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? 0 : rows.first['rev'] as int;
  }

  LocalRow<T> _local(Map<String, Object?> r) =>
      LocalRow(fromRow(r), _syncOf(r), r['rev'] as int, r);

  static SyncState _syncOf(Map<String, Object?> r) =>
      SyncState.of(r['sync'] as String?);
}
