import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/repositories/badge_repository.dart';

abstract class BadgesState extends Equatable {
  const BadgesState();
  @override
  List<Object?> get props => [];
}

class BadgesInitial extends BadgesState {}

class BadgesLoading extends BadgesState {}

class BadgesLoaded extends BadgesState {
  final List<BadgeEntity> badges;
  const BadgesLoaded(this.badges);
  @override
  List<Object?> get props => [badges];
}

class BadgesError extends BadgesState {
  final String message;
  const BadgesError(this.message);
}

class BadgesCubit extends Cubit<BadgesState> {
  final BadgeRepository repo;
  BadgesCubit(this.repo) : super(BadgesInitial());

  Future<void> load() async {
    emit(BadgesLoading());
    final res = await repo.listAll();
    res.fold(
      (f) => emit(BadgesError(f.message)),
      (b) => emit(BadgesLoaded(b)),
    );
  }
}
