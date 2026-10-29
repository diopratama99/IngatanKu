import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/services/notification_service.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardReady extends DashboardState {
  final DashboardData data;
  const DashboardReady(this.data);
  @override
  List<Object?> get props => [data];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository repo;
  final NotificationService notifications;

  /// Loads again whenever this fires (the notes on the phone changed).
  DashboardCubit(this.repo, this.notifications, {Stream<void>? changes})
      : super(DashboardInitial()) {
    _changes = changes?.listen((_) => load());
  }

  StreamSubscription<void>? _changes;
  int? _remindedFor;

  Future<void> load() async {
    // Once it's up, the numbers stay while they're worked out again.
    if (state is! DashboardReady) emit(DashboardLoading());
    final res = await repo.loadDashboard();
    if (isClosed) return;
    res.fold(
      (f) => emit(DashboardError(f.message)),
      (d) {
        emit(DashboardReady(d));
        // Reschedule the daily streak reminder when the streak changed.
        // Fire-and-forget; failures (e.g. denied permission) shouldn't
        // break the dashboard.
        if (_remindedFor != d.streakDays) {
          _remindedFor = d.streakDays;
          notifications.scheduleStreakReminder(currentStreak: d.streakDays);
        }
      },
    );
  }

  @override
  Future<void> close() {
    _changes?.cancel();
    return super.close();
  }
}
