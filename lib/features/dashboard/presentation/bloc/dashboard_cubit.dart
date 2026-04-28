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
  DashboardCubit(this.repo, this.notifications) : super(DashboardInitial());

  Future<void> load() async {
    emit(DashboardLoading());
    final res = await repo.loadDashboard();
    res.fold(
      (f) => emit(DashboardError(f.message)),
      (d) {
        emit(DashboardReady(d));
        // Reschedule daily streak reminder based on current streak.
        // Fire-and-forget; failures (e.g. denied permission) shouldn't break the dashboard.
        notifications.scheduleStreakReminder(currentStreak: d.streakDays);
      },
    );
  }
}
