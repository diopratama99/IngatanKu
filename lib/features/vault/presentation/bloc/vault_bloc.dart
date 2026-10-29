import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/vault_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/delete_note.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/update_note.dart';

// EVENTS
abstract class VaultEvent extends Equatable {
  const VaultEvent();
  @override
  List<Object?> get props => [];
}

/// Shows the notes on the phone, and checks the account for news. With
/// [fetch] (pull to refresh) it always checks; otherwise not more than
/// every [VaultBloc.fetchEvery].
class VaultLoadRequested extends VaultEvent {
  final bool fetch;
  const VaultLoadRequested({this.fetch = false});
  @override
  List<Object?> get props => [fetch];
}

/// The notes on the phone changed (saved here or fetched).
class _VaultChanged extends VaultEvent {
  const _VaultChanged();
}

class VaultNoteAdded extends VaultEvent {
  final AddNoteParams params;
  const VaultNoteAdded(this.params);
  @override
  List<Object?> get props => [params];
}

class VaultNoteDeleted extends VaultEvent {
  final String id;
  const VaultNoteDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

class VaultNoteUpdated extends VaultEvent {
  final UpdateNoteParams params;
  const VaultNoteUpdated(this.params);
  @override
  List<Object?> get props => [params];
}

// STATES
abstract class VaultState extends Equatable {
  const VaultState();
  @override
  List<Object?> get props => [];
}

class VaultInitial extends VaultState {}

class VaultLoading extends VaultState {}

class VaultLoaded extends VaultState {
  final List<NoteEntity> notes;
  const VaultLoaded(this.notes);
  @override
  List<Object?> get props => [notes];
}

class VaultActionLoading extends VaultLoaded {
  const VaultActionLoading(super.notes);
}

class VaultError extends VaultState {
  final String message;
  const VaultError(this.message);
  @override
  List<Object?> get props => [message];
}

class VaultNoteAddSuccess extends VaultLoaded {
  final NoteEntity newNote;
  const VaultNoteAddSuccess(super.notes, this.newNote);
  @override
  List<Object?> get props => [notes, newNote];
}

class VaultNoteUpdateSuccess extends VaultLoaded {
  final NoteEntity updatedNote;
  const VaultNoteUpdateSuccess(super.notes, this.updatedNote);
  @override
  List<Object?> get props => [notes, updatedNote];
}

// BLOC
class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final VaultRepository _repo;
  final GetNotes _getNotes;
  final AddNote _addNote;
  final DeleteNote _deleteNote;
  final UpdateNote _updateNote;

  VaultBloc({
    required VaultRepository repo,
    required GetNotes getNotes,
    required AddNote addNote,
    required DeleteNote deleteNote,
    required UpdateNote updateNote,
  })  : _repo = repo,
        _getNotes = getNotes,
        _addNote = addNote,
        _deleteNote = deleteNote,
        _updateNote = updateNote,
        super(VaultInitial()) {
    on<VaultLoadRequested>(_onLoad);
    on<VaultNoteAdded>(_onAdd);
    on<VaultNoteDeleted>(_onDelete);
    on<VaultNoteUpdated>(_onUpdate);
    on<_VaultChanged>(_onChanged);
    _changes = repo.changes.listen((_) => add(const _VaultChanged()));
  }

  static const fetchEvery = Duration(seconds: 30);

  late final StreamSubscription<void> _changes;
  DateTime? _fetchedAt;

  Future<void> _onLoad(VaultLoadRequested e, Emitter<VaultState> emit) async {
    // Once there's a list, it stays up while this runs.
    final first = state is! VaultLoaded;
    if (first) emit(VaultLoading());
    final now = DateTime.now();
    final last = _fetchedAt;
    Future<void>? fetched;
    if (e.fetch || last == null || now.difference(last) > fetchEvery) {
      _fetchedAt = now;
      fetched = _repo.sync();
    }
    var res = await _getNotes(const NoParams());
    // Nothing on this phone yet (a new phone, or the first run with this
    // version): wait for the account's notes.
    if (first && fetched != null && res.fold((_) => false, (n) => n.isEmpty)) {
      await fetched;
      res = await _getNotes(const NoParams());
    }
    res.fold(
      (f) => emit(VaultError(f.message)),
      (notes) => emit(VaultLoaded(notes)),
    );
  }

  Future<void> _onChanged(_VaultChanged e, Emitter<VaultState> emit) async {
    if (state is VaultInitial || state is VaultLoading) return;
    final res = await _getNotes(const NoParams());
    res.fold((_) {}, (notes) => emit(VaultLoaded(notes)));
  }

  Future<void> _onAdd(VaultNoteAdded e, Emitter<VaultState> emit) async {
    final current =
        state is VaultLoaded ? (state as VaultLoaded).notes : <NoteEntity>[];
    emit(VaultActionLoading(current));
    final res = await _addNote(e.params);
    res.fold(
      (f) => emit(VaultError(f.message)),
      (note) => emit(VaultNoteAddSuccess([note, ...current], note)),
    );
  }

  Future<void> _onDelete(VaultNoteDeleted e, Emitter<VaultState> emit) async {
    if (state is! VaultLoaded) return;
    final current = (state as VaultLoaded).notes;
    final optimistic = current.where((n) => n.id != e.id).toList();
    emit(VaultLoaded(optimistic));
    final res = await _deleteNote(e.id);
    res.fold(
      (f) => emit(VaultError(f.message)),
      (_) {},
    );
  }

  Future<void> _onUpdate(VaultNoteUpdated e, Emitter<VaultState> emit) async {
    final current =
        state is VaultLoaded ? (state as VaultLoaded).notes : <NoteEntity>[];
    emit(VaultActionLoading(current));
    final res = await _updateNote(e.params);
    res.fold(
      (f) => emit(VaultError(f.message)),
      (note) {
        final next = current.map((n) => n.id == note.id ? note : n).toList();
        emit(VaultNoteUpdateSuccess(next, note));
      },
    );
  }

  @override
  Future<void> close() {
    _changes.cancel();
    return super.close();
  }
}
