import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/database/app_database.dart';
import 'package:ingatanku/core/network/connectivity_service.dart';
import 'package:ingatanku/core/services/notification_service.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:ingatanku/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:ingatanku/features/vault/data/datasources/vault_local_datasource.dart';
import 'package:ingatanku/features/vault/data/datasources/vault_remote_datasource.dart';
import 'package:ingatanku/features/vault/data/models/note_model.dart';
import 'package:ingatanku/features/vault/data/repositories/vault_repository_impl.dart';
import 'package:ingatanku/features/vault/domain/usecases/add_note.dart';
import 'package:ingatanku/features/vault/domain/usecases/delete_note.dart';
import 'package:ingatanku/features/vault/domain/usecases/get_notes.dart';
import 'package:ingatanku/features/vault/domain/usecases/update_note.dart';
import 'package:ingatanku/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

class _NoReminders implements NotificationService {
  int scheduled = 0;

  @override
  Future<void> scheduleStreakReminder({
    required int currentStreak,
    int hour = 20,
    int minute = 0,
  }) async =>
      scheduled++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  final t0 = DateTime(2026, 10, 15, 9);

  late AppDatabase database;
  late _VaultServer server;
  late VaultRepositoryImpl vault;
  late VaultBloc bloc;

  NoteModel serverNote(String id, {int minutes = 0, List<String>? tags}) =>
      NoteModel(
        id: id,
        userId: 'ana',
        url: 'https://example.com/$id',
        title: 'Note $id',
        manualNotes: 'about $id',
        tags: tags ?? const ['cooking'],
        sourceType: 'article',
        createdAt: t0.add(Duration(minutes: minutes)),
      );

  setUp(() {
    ConnectivityService.instance.reportSuccess();
    database =
        AppDatabase(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    server = _VaultServer();
    vault = VaultRepositoryImpl(
      remote: server,
      local: VaultLocalDataSource(database),
      currentUser: () => 'ana',
      clock: () => t0,
    );
    bloc = VaultBloc(
      repo: vault,
      getNotes: GetNotes(vault),
      addNote: AddNote(vault),
      deleteNote: DeleteNote(vault),
      updateNote: UpdateNote(vault),
    );
  });

  tearDown(() async {
    await bloc.close();
    vault.dispose();
    await database.close();
  });

  test('a new phone waits for the account\'s notes once', () async {
    server.notes['a'] = serverNote('a');
    final states = <VaultState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const VaultLoadRequested());
    final loaded = await bloc.stream.firstWhere((s) => s is VaultLoaded);
    expect(states.first, isA<VaultLoading>());
    expect((loaded as VaultLoaded).notes.single.id, 'a');
    await sub.cancel();
  });

  test('notes fetched later show up without a loading screen', () async {
    bloc.add(const VaultLoadRequested());
    await bloc.stream.firstWhere((s) => s is VaultLoaded);
    final states = <VaultState>[];
    final sub = bloc.stream.listen(states.add);
    server.notes['b'] = serverNote('b');
    await vault.sync();
    final shown = await bloc.stream
        .firstWhere((s) => s is VaultLoaded && s.notes.isNotEmpty);
    expect(states, isNot(contains(isA<VaultLoading>())));
    expect((shown as VaultLoaded).notes.single.id, 'b');
    await sub.cancel();
  });

  test('saving offline works and comes back as a success', () async {
    server.offline = true;
    bloc.add(const VaultLoadRequested());
    await bloc.stream.firstWhere((s) => s is VaultLoaded);
    bloc.add(const VaultNoteAdded(AddNoteParams(
      url: 'https://example.com/x',
      title: 'Offline',
      manualNotes: '',
      tags: [],
      sourceType: 'article',
    )));
    final saved = await bloc.stream.firstWhere((s) => s is VaultNoteAddSuccess);
    expect((saved as VaultLoaded).notes.single.title, 'Offline');
    expect(server.notes, isEmpty);
  });

  test('Beranda\'s numbers come from the phone', () async {
    for (var i = 0; i < 35; i++) {
      server.notes['n$i'] = serverNote('n$i',
          minutes: i, tags: i.isEven ? const ['cooking', 'home'] : ['travel']);
    }
    await vault.sync();
    SharedPreferences.setMockInitialValues({});
    final pet = PetStore(await SharedPreferences.getInstance());
    final reminders = _NoReminders();
    final cubit = DashboardCubit(
      DashboardRepositoryImpl(
        notes: VaultLocalDataSource(database),
        pet: pet,
        currentUser: () => 'ana',
      ),
      reminders,
      changes: vault.changes,
    );
    await cubit.load();
    final data = (cubit.state as DashboardReady).data;
    expect(data.totalNotes, 35);
    expect(data.recentNotes, hasLength(30));
    expect(data.recentNotes.first.id, 'n34');
    expect(
        [for (final t in data.topTags) t.tag], ['cooking', 'home', 'travel']);
    expect(data.topTags.first.count, 18);

    // A note saved elsewhere arrives: Beranda counts it, without
    // scheduling the reminder again (the streak didn't change).
    server.notes['new'] = serverNote('new', minutes: 99);
    await vault.sync();
    final next = await cubit.stream
        .firstWhere((s) => s is DashboardReady && s.data.totalNotes == 36);
    expect((next as DashboardReady).data.recentNotes.first.id, 'new');
    expect(reminders.scheduled, 1);
    await cubit.close();
  });
}
