import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// What a local row still owes the server.
enum SyncState {
  /// Same as the server's copy.
  synced,

  /// Made here; the server hasn't seen it yet.
  insert,

  /// Changed here since the server last saw it.
  update,

  /// Deleted here; gone from the app, waiting to go from the server too.
  delete;

  static SyncState of(String? raw) =>
      SyncState.values.asNameMap()[raw] ?? SyncState.synced;
}

/// The app's own SQLite database: the user's notes on the device, so the
/// app opens instantly and works offline. The server stays the shared
/// copy; repositories keep the two in step (see the `sync` columns).
///
/// Tables, one row per note, all with the owner's `user_id` (the device
/// may have had more than one account), a `sync` column ([SyncState])
/// and `rev`, bumped by every change made here (so a row changed again
/// while it was on its way up isn't marked as sent):
///  * `vault_notes`    — Pustaka (saved links), like `ingatanku.content_vault`
///  * `personal_notes` — Catatan, like `ingatanku.personal_notes`
///
/// Lists (tags, links, image files) are stored as JSON text; times as
/// milliseconds since the epoch; yes/no as 1/0.
///
/// Versions: 1 — the two tables; 2 — `vault_notes.in_quiz` (a note kept
/// out of the quizzes).
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? path})
      : _factory = factory ?? databaseFactory,
        _path = path;

  static const _version = 2;

  final DatabaseFactory _factory;
  final String? _path;
  Future<Database>? _db;

  Future<Database> get db => _db ??= _open();

  Future<Database> _open() async {
    final path = _path ?? p.join(await getDatabasesPath(), 'ingatanku.db');
    return _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: (db, version) async {
          final batch = db.batch();
          _createV1(batch);
          _toV2(batch);
          await batch.commit(noResult: true);
        },
        onUpgrade: (db, from, to) async {
          final batch = db.batch();
          if (from < 2) _toV2(batch);
          await batch.commit(noResult: true);
        },
      ),
    );
  }

  static void _createV1(Batch b) {
    b.execute('''
      create table vault_notes (
        id            text primary key,
        user_id       text not null,
        url           text not null,
        title         text,
        manual_notes  text not null default '',
        tags          text not null default '[]',
        source_type   text not null default 'other',
        thumbnail_url text,
        created_at    integer not null,
        sync          text not null default 'synced',
        rev           integer not null default 0,
        reembed       integer not null default 0
      )''');
    b.execute('create index vault_notes_user_created '
        'on vault_notes (user_id, created_at desc)');
    b.execute('''
      create table personal_notes (
        id          text primary key,
        user_id     text not null,
        title       text,
        body        text not null default '',
        image_files text not null default '[]',
        links       text not null default '[]',
        tags        text not null default '[]',
        pinned      integer not null default 0,
        color       text not null default 'default',
        created_at  integer not null,
        updated_at  integer not null,
        sync        text not null default 'synced',
        rev         integer not null default 0
      )''');
    b.execute('create index personal_notes_user_updated '
        'on personal_notes (user_id, updated_at desc)');
    b.execute('create table meta (key text primary key, value text)');
  }

  /// Notes can be kept out of the quizzes; every note so far stays in.
  static void _toV2(Batch b) {
    b.execute('alter table vault_notes '
        'add column in_quiz integer not null default 1');
  }

  /// A small value kept with the data (e.g. when a table was last
  /// fetched for a user), so it goes when the database does.
  Future<String?> meta(String key) async {
    final rows = await (await db)
        .query('meta', columns: ['value'], where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async =>
      (await db).insert('meta', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> close() async {
    final db = _db;
    _db = null;
    if (db != null) await (await db).close();
  }
}
