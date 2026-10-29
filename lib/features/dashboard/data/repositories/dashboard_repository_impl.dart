import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../companion/data/pet_store.dart';
import '../../../vault/data/datasources/vault_local_datasource.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

/// Beranda's numbers, all from what's on the phone: the notes in the
/// app's database ([VaultLocalDataSource]) and the pet ([PetStore]).
class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({
    required this.notes,
    required this.pet,
    required String? Function() currentUser,
    DateTime Function()? clock,
  })  : _currentUser = currentUser,
        _clock = clock ?? DateTime.now;

  final VaultLocalDataSource notes;
  final PetStore pet;
  final String? Function() _currentUser;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, DashboardData>> loadDashboard() async {
    final userId = _currentUser();
    if (userId == null) return const Left(AuthFailure('Not authenticated'));
    try {
      final (recent, total, tags) = await (
        // Also the pet's pantry (uneaten ones become dishes), so more
        // than a carousel's worth.
        notes.live(userId, limit: 30),
        notes.count(userId),
        notes.tagCounts(userId),
      ).wait;
      final topTags = [
        for (final e
            in tags.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
          TagCount(e.key, e.value),
      ].take(5).toList();
      return Right(DashboardData(
        streakDays: pet.state.careStreakAt(_clock()),
        totalNotes: total,
        recentNotes: recent,
        topTags: topTags,
      ));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
