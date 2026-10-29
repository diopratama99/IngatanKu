import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/database/app_database.dart';
import 'package:ingatanku/core/network/connectivity_service.dart';
import 'package:ingatanku/features/notes/data/datasources/personal_note_image_store.dart';
import 'package:ingatanku/features/notes/data/datasources/personal_note_local_datasource.dart';
import 'package:ingatanku/features/notes/data/datasources/personal_note_remote_datasource.dart';
import 'package:ingatanku/features/notes/data/models/personal_note_model.dart';
import 'package:ingatanku/features/notes/data/repositories/personal_note_repository_impl.dart';
import 'package:ingatanku/features/notes/domain/entities/personal_note.dart';
import 'package:ingatanku/features/vault/data/datasources/vault_local_datasource.dart';
import 'package:ingatanku/features/vault/data/datasources/vault_remote_datasource.dart';
import 'package:ingatanku/features/vault/data/models/note_model.dart';
import 'package:ingatanku/features/vault/data/repositories/vault_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _offline = SocketException('Failed host lookup');

/// The account's link notes, in memory.
class _VaultServer implements VaultRemoteDataSource {
  final notes = <String, NoteModel>{};
  bool offline = false;

  /// (id, reembed) of every push.
  final pushes = <(String, bool)>[];

  /// Runs during a push, before it lands.
  Future<void> Function(NoteModel note)? duringPush;

  void _reach() {
    if (offline) throw _offline;
  }

  @override
  Future<List<NoteModel>> fetchAll() async {
    _reach();
    return notes.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<NoteModel?> fetch(String id) async {
    _reach();
    return notes[id];
  }

  @override
  Future<void> push(NoteModel note, {required bool reembed}) async {
    _reach();
    await duringPush?.call(note);
    notes[note.id] = note;
    pushes.add((note.id, reembed));
  }

  @override
  Future<void> delete(String id) async {
    _reach();
    notes.remove(id);
  }
}

/// The account's personal notes, in memory.
class _NotesServer implements PersonalNoteRemoteDataSource {
  final notes = <String, PersonalNoteModel>{};
  bool offline = false;

  void _reach() {
    if (offline) throw _offline;
  }

  @override
  Future<List<PersonalNoteModel>> fetchAll() async {
    _reach();
    return notes.values.toList();
  }

  @override
  Future<PersonalNoteModel?> fetch(String id) async {
    _reach();
    return notes[id];
  }

  @override
  Future<void> push(PersonalNoteModel note) async {
    _reach();
    notes[note.id] = note;
  }

  @override
  Future<void> delete(String id) async {
    _reach();
    notes.remove(id);
  }
}

class _NoImages extends PersonalNoteImageStore {
  @override
  Future<void> deleteAll(String noteId) async {}
}

void main() {
  sqfliteFfiInit();
  final t0 = DateTime(2026, 10, 15, 9);

  late AppDatabase database;
  late VaultLocalDataSource local;
  late _VaultServer server;
  late VaultRepositoryImpl vault;
  String? user = 'ana';

  NoteModel serverNote(String id, {int minutes = 0, String user = 'ana'}) =>
      NoteModel(
        id: id,
        userId: user,
        url: 'https://example.com/$id',
        title: 'Note $id',
        manualNotes: 'about $id',
        tags: const ['cooking'],
        sourceType: 'article',
        createdAt: t0.add(Duration(minutes: minutes)),
      );

  setUp(() {
    ConnectivityService.instance.reportSuccess();
    database =
        AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    local = VaultLocalDataSource(database);
    server = _VaultServer();
    user = 'ana';
    vault = VaultRepositoryImpl(
      remote: server,
      local: local,
      currentUser: () => user,
      clock: () => t0,
    );
  });

  tearDown(() async {
    vault.dispose();
    await database.close();
  });

  Future<List<String>> titles() async => [
        for (final n in (await vault.getNotes()).getOrElse(() => []))
          n.title ?? '',
      ];

  group('link notes', () {
    test('saved offline: there at once, sent once back online', () async {
      server.offline = true;
      final res = await vault.addNote(
        url: 'https://example.com/a',
        title: 'Offline',
        manualNotes: 'written on the train',
        tags: const ['travel'],
        sourceType: 'article',
      );
      expect(res.isRight(), isTrue);
      expect(await titles(), ['Offline']);
      await vault.sync();
      expect(server.notes, isEmpty);
      expect(ConnectivityService.instance.isOnline, isFalse);

      server.offline = false;
      await vault.sync();
      final sent = server.notes.values.single;
      expect(sent.title, 'Offline');
      expect(sent.createdAt, t0);
      // New notes get their embedding made.
      expect(server.pushes.single.$2, isTrue);
      expect(await local.pending('ana'), isEmpty);
      expect(ConnectivityService.instance.isOnline, isTrue);
    });

    test('fetches the account\'s notes; ones deleted there go here too',
        () async {
      server.notes['a'] = serverNote('a');
      server.notes['b'] = serverNote('b', minutes: 1);
      await vault.sync();
      expect(await titles(), ['Note b', 'Note a']);

      server.notes.remove('a');
      await vault.sync();
      expect(await titles(), ['Note b']);
    });

    test('a change not sent yet survives a fetch', () async {
      server.notes['a'] = serverNote('a');
      await vault.sync();
      server.offline = true;
      await vault.updateNote(id: 'a', title: 'Mine');
      // The server's copy changed meanwhile; this one isn't sent yet.
      server.notes['a'] = serverNote('a').copyWith(title: 'Theirs');
      server.offline = false;
      await vault.sync();
      expect(await titles(), ['Mine']);
      expect(server.notes['a']!.title, 'Mine');
    });

    test('only text edits make the embedding again', () async {
      server.notes['a'] = serverNote('a');
      await vault.sync();
      await vault.updateNote(id: 'a', tags: const ['baking']);
      await vault.sync();
      expect(server.pushes.last, ('a', false));
      await vault.updateNote(id: 'a', manualNotes: 'new text');
      await vault.sync();
      expect(server.pushes.last, ('a', true));
    });

    test('edited while on its way up: the edit goes up too', () async {
      final added = (await vault.addNote(
        url: 'https://example.com/a',
        title: 'First',
        manualNotes: '',
        tags: const [],
        sourceType: 'article',
      ))
          .getOrElse(() => throw StateError('not saved'));
      await vault.sync();
      server.duringPush = (note) async {
        server.duringPush = null;
        await vault.updateNote(id: added.id, title: 'Second');
      };
      await vault.updateNote(id: added.id, title: 'Between');
      await vault.sync();
      await vault.sync();
      expect(server.notes[added.id]!.title, 'Second');
      expect(await local.pending('ana'), isEmpty);
    });

    test('deleted offline: gone here at once, there once back online',
        () async {
      server.notes['a'] = serverNote('a');
      await vault.sync();
      server.offline = true;
      await vault.deleteNote('a');
      expect(await titles(), isEmpty);
      await vault.sync();
      expect(server.notes, contains('a'));

      server.offline = false;
      await vault.sync();
      expect(server.notes, isEmpty);
      expect(await local.find('a'), isNull);
    });

    test('each account sees its own notes only', () async {
      server.notes['a'] = serverNote('a');
      await vault.sync();
      user = 'budi';
      expect(await titles(), isEmpty);
      user = null;
      expect((await vault.getNotes()).isLeft(), isTrue);
    });

    test('a note kept out of the quizzes stays out, here and there',
        () async {
      final added = (await vault.addNote(
        url: 'https://example.com/comic',
        title: 'A comic to read',
        manualNotes: 'volume 1 first',
        tags: const [],
        sourceType: 'article',
        inQuiz: false,
      ))
          .getOrElse(() => throw StateError('not saved'));
      expect(added.inQuiz, isFalse);
      await vault.sync();
      expect(server.notes[added.id]!.inQuiz, isFalse);
      expect(server.notes[added.id]!.toRow()['in_quiz'], isFalse);

      // Switched back on: not a text edit, so the embedding stays.
      await vault.updateNote(id: added.id, inQuiz: true);
      await vault.sync();
      expect(server.notes[added.id]!.inQuiz, isTrue);
      expect(server.pushes.last, (added.id, false));
      // Other edits leave it as it is.
      await vault.updateNote(id: added.id, tags: const ['comics']);
      expect((await local.find(added.id))!.item.inQuiz, isTrue);

      // Switched off on another device: it comes down too.
      server.notes['b'] = serverNote('b').copyWith(inQuiz: false);
      await vault.sync();
      expect((await local.find('b'))!.item.inQuiz, isFalse);
    });

    test('tells the screens when something changed', () async {
      var heard = 0;
      final sub = vault.changes.listen((_) => heard++);
      server.notes['a'] = serverNote('a');
      await vault.sync();
      await pumpEventQueue();
      expect(heard, 1);
      // Nothing new: nothing to tell.
      await vault.sync();
      await pumpEventQueue();
      expect(heard, 1);
      await sub.cancel();
    });
  });

  group('database', () {
    test('notes saved before the quiz switch existed stay in the quizzes',
        () async {
      final dir = await Directory.systemTemp.createTemp('ingatanku_db');
      final path = '${dir.path}/ingatanku.db';
      // A version 1 database, as the app made it before.
      final old = await databaseFactoryFfi.openDatabase(path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, _) async {
              await db.execute('''
                create table vault_notes (
                  id text primary key, user_id text not null,
                  url text not null, title text,
                  manual_notes text not null default '',
                  tags text not null default '[]',
                  source_type text not null default 'other',
                  thumbnail_url text, created_at integer not null,
                  sync text not null default 'synced',
                  rev integer not null default 0,
                  reembed integer not null default 0)''');
              await db.execute('create table personal_notes (id text primary '
                  'key, user_id text not null, title text, body text not '
                  "null default '', image_files text not null default '[]', "
                  "links text not null default '[]', tags text not null "
                  "default '[]', pinned integer not null default 0, color "
                  "text not null default 'default', created_at integer not "
                  'null, updated_at integer not null, sync text not null '
                  "default 'synced', rev integer not null default 0)");
              await db.execute(
                  'create table meta (key text primary key, value text)');
            },
          ));
      await old.insert('vault_notes', {
        'id': 'a',
        'user_id': 'ana',
        'url': 'https://example.com/a',
        'title': 'Before',
        'created_at': t0.millisecondsSinceEpoch,
      });
      await old.close();

      final upgraded = AppDatabase(factory: databaseFactoryFfi, path: path);
      final table = VaultLocalDataSource(upgraded);
      final before = (await table.live('ana')).single;
      expect(before.title, 'Before');
      expect(before.inQuiz, isTrue);
      // The new column is really there: a note can be switched off.
      await table.save(before.copyWith(inQuiz: false),
          sync: SyncState.update);
      expect((await table.find('a'))!.row['in_quiz'], 0);
      await upgraded.close();
      await dir.delete(recursive: true);
    });
  });

  group('personal notes', () {
    late _NotesServer notesServer;
    late PersonalNoteRepositoryImpl notes;

    PersonalNote draft(String id, {bool pinned = false, int minutes = 0}) =>
        PersonalNote(
          id: id,
          userId: '',
          title: 'Note $id',
          body: 'body $id',
          links: const [NoteLink(url: 'https://example.com', label: 'ex')],
          tags: const ['home'],
          pinned: pinned,
          color: NoteColor.yellow,
          createdAt: t0,
          updatedAt: t0.add(Duration(minutes: minutes)),
        );

    setUp(() {
      notesServer = _NotesServer();
      notes = PersonalNoteRepositoryImpl(
        remote: notesServer,
        local: PersonalNoteLocalDataSource(database),
        images: _NoImages(),
        currentUser: () => user,
      );
    });

    tearDown(() => notes.dispose());

    test('kept on the phone in list order, sent once online', () async {
      notesServer.offline = true;
      await notes.create(draft('a', minutes: 2));
      await notes.create(draft('b', pinned: true));
      await notes.create(draft('c', minutes: 1));
      final listed = (await notes.list()).getOrElse(() => []);
      expect([for (final n in listed) n.id], ['b', 'a', 'c']);
      expect(listed.first.userId, 'ana');
      expect(listed.first.links.single.label, 'ex');
      expect(listed.first.color, NoteColor.yellow);
      await notes.sync();
      expect(notesServer.notes, isEmpty);

      notesServer.offline = false;
      await notes.sync();
      expect(notesServer.notes.keys, unorderedEquals(['a', 'b', 'c']));
      expect(notesServer.notes['b']!.pinned, isTrue);
    });

    test('a cleared title stays cleared', () async {
      await notes.create(draft('a'));
      await notes.sync();
      await notes.update(PersonalNote(
        id: 'a',
        userId: 'ana',
        body: 'body a',
        createdAt: t0,
        updatedAt: t0.add(const Duration(minutes: 5)),
      ));
      await notes.sync();
      expect(notesServer.notes['a']!.title, isNull);
      expect(notesServer.notes['a']!.toUpsert(userId: 'ana'),
          containsPair('title', null));
      final listed = (await notes.list()).getOrElse(() => []);
      expect(listed.single.title, isNull);
    });
  });
}
