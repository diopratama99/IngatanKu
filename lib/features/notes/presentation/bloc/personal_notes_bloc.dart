import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/personal_note.dart';
import '../../domain/repositories/personal_note_repository.dart';

// ── Events ────────────────────────────────────────────────────

abstract class PersonalNotesEvent extends Equatable {
  const PersonalNotesEvent();
  @override
  List<Object?> get props => [];
}

/// Shows the notes on the phone, and checks the account for news. With
/// [fetch] (pull to refresh) it always checks; otherwise not more than
/// every [PersonalNotesBloc.fetchEvery].
class PersonalNotesLoadRequested extends PersonalNotesEvent {
  final bool fetch;
  const PersonalNotesLoadRequested({this.fetch = false});
  @override
  List<Object?> get props => [fetch];
}

/// The notes on the phone changed (saved here or fetched).
class _PersonalNotesChanged extends PersonalNotesEvent {
  const _PersonalNotesChanged();
}

class PersonalNotesNoteUpserted extends PersonalNotesEvent {
  final PersonalNote note;
  const PersonalNotesNoteUpserted(this.note);
  @override
  List<Object?> get props => [note];
}

class PersonalNotesNoteDeleted extends PersonalNotesEvent {
  final String id;
  const PersonalNotesNoteDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class PersonalNotesNotePinToggled extends PersonalNotesEvent {
  final PersonalNote note;
  const PersonalNotesNotePinToggled(this.note);
  @override
  List<Object?> get props => [note];
}

// ── States ───────────────────────────────────────────────────

abstract class PersonalNotesState extends Equatable {
  const PersonalNotesState();
  @override
  List<Object?> get props => [];
}

class PersonalNotesInitial extends PersonalNotesState {}

class PersonalNotesLoading extends PersonalNotesState {}

class PersonalNotesLoaded extends PersonalNotesState {
  final List<PersonalNote> notes;
  const PersonalNotesLoaded(this.notes);

  /// Pinned-first split — convenient for the list UI.
  List<PersonalNote> get pinned => notes.where((n) => n.pinned).toList();
  List<PersonalNote> get others => notes.where((n) => !n.pinned).toList();

  @override
  List<Object?> get props => [notes];
}

class PersonalNotesError extends PersonalNotesState {
  final String message;
  const PersonalNotesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Bloc ─────────────────────────────────────────────────────

class PersonalNotesBloc extends Bloc<PersonalNotesEvent, PersonalNotesState> {
  final PersonalNoteRepository repo;

  PersonalNotesBloc({required this.repo}) : super(PersonalNotesInitial()) {
    on<PersonalNotesLoadRequested>(_onLoad);
    on<PersonalNotesNoteUpserted>(_onUpserted);
    on<PersonalNotesNoteDeleted>(_onDeleted);
    on<PersonalNotesNotePinToggled>(_onPinToggled);
    on<_PersonalNotesChanged>(_onChanged);
    _changes = repo.changes.listen((_) => add(const _PersonalNotesChanged()));
  }

  static const fetchEvery = Duration(seconds: 30);

  late final StreamSubscription<void> _changes;
  DateTime? _fetchedAt;

  Future<void> _onLoad(
    PersonalNotesLoadRequested e,
    Emitter<PersonalNotesState> emit,
  ) async {
    // Once there's a list, it stays up while this runs.
    final first = state is! PersonalNotesLoaded;
    if (first) emit(PersonalNotesLoading());
    final now = DateTime.now();
    final last = _fetchedAt;
    Future<void>? fetched;
    if (e.fetch || last == null || now.difference(last) > fetchEvery) {
      _fetchedAt = now;
      fetched = repo.sync();
    }
    var res = await repo.list();
    // Nothing on this phone yet (a new phone, or the first run with this
    // version): wait for the account's notes.
    if (first && fetched != null && res.fold((_) => false, (n) => n.isEmpty)) {
      await fetched;
      res = await repo.list();
    }
    res.fold(
      (f) => emit(PersonalNotesError(f.message)),
      (notes) => emit(PersonalNotesLoaded(notes)),
    );
  }

  Future<void> _onChanged(
    _PersonalNotesChanged e,
    Emitter<PersonalNotesState> emit,
  ) async {
    if (state is PersonalNotesInitial || state is PersonalNotesLoading) return;
    final res = await repo.list();
    res.fold((_) {}, (notes) => emit(PersonalNotesLoaded(notes)));
  }

  /// Optimistically upsert into the in-memory list. The note has
  /// already been persisted by the caller (Add/Edit page) — we just
  /// merge it into our state so the list rebuilds without a full
  /// refetch.
  void _onUpserted(
    PersonalNotesNoteUpserted e,
    Emitter<PersonalNotesState> emit,
  ) {
    if (state is! PersonalNotesLoaded) {
      // Bloc isn't loaded yet — kick a load instead. Cheap.
      add(const PersonalNotesLoadRequested());
      return;
    }
    final current = (state as PersonalNotesLoaded).notes;
    final next = [...current];
    final idx = next.indexWhere((n) => n.id == e.note.id);
    if (idx == -1) {
      next.insert(0, e.note);
    } else {
      next[idx] = e.note;
    }
    next.sort(_compareForList);
    emit(PersonalNotesLoaded(next));
  }

  Future<void> _onDeleted(
    PersonalNotesNoteDeleted e,
    Emitter<PersonalNotesState> emit,
  ) async {
    if (state is PersonalNotesLoaded) {
      final current = (state as PersonalNotesLoaded).notes;
      final optimistic = current.where((n) => n.id != e.id).toList();
      emit(PersonalNotesLoaded(optimistic));
    }
    final res = await repo.delete(e.id);
    res.fold(
      (f) => emit(PersonalNotesError(f.message)),
      (_) {},
    );
  }

  /// Pin toggle is fast enough that we don't need an optimistic state
  /// — we just persist and re-emit. UI reflects the change in <100ms.
  Future<void> _onPinToggled(
    PersonalNotesNotePinToggled e,
    Emitter<PersonalNotesState> emit,
  ) async {
    final updated = e.note.copyWith(pinned: !e.note.pinned);
    final res = await repo.update(updated);
    res.fold(
      (f) => emit(PersonalNotesError(f.message)),
      (saved) {
        if (state is PersonalNotesLoaded) {
          final current = (state as PersonalNotesLoaded).notes;
          final next = [
            for (final n in current) n.id == saved.id ? saved : n,
          ];
          next.sort(_compareForList);
          emit(PersonalNotesLoaded(next));
        }
      },
    );
  }

  /// Pinned first, then most recently updated — same ordering the
  /// server uses. Re-sorting client-side keeps the UI consistent
  /// after pin toggles without a refetch.
  static int _compareForList(PersonalNote a, PersonalNote b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  }

  @override
  Future<void> close() {
    _changes.cancel();
    return super.close();
  }
}
