import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/note_entity.dart';
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

class VaultLoadRequested extends VaultEvent {}

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
  final GetNotes _getNotes;
  final AddNote _addNote;
  final DeleteNote _deleteNote;
  final UpdateNote _updateNote;

  VaultBloc({
    required GetNotes getNotes,
    required AddNote addNote,
    required DeleteNote deleteNote,
    required UpdateNote updateNote,
  })  : _getNotes = getNotes,
        _addNote = addNote,
        _deleteNote = deleteNote,
        _updateNote = updateNote,
        super(VaultInitial()) {
    on<VaultLoadRequested>(_onLoad);
    on<VaultNoteAdded>(_onAdd);
    on<VaultNoteDeleted>(_onDelete);
    on<VaultNoteUpdated>(_onUpdate);
  }

  Future<void> _onLoad(VaultLoadRequested e, Emitter<VaultState> emit) async {
    emit(VaultLoading());
    final res = await _getNotes(const NoParams());
    res.fold(
      (f) => emit(VaultError(f.message)),
      (notes) => emit(VaultLoaded(notes)),
    );
  }

  Future<void> _onAdd(VaultNoteAdded e, Emitter<VaultState> emit) async {
    final current = state is VaultLoaded ? (state as VaultLoaded).notes : <NoteEntity>[];
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
    final current = state is VaultLoaded ? (state as VaultLoaded).notes : <NoteEntity>[];
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
}
