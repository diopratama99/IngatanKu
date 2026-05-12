import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../vault/data/models/note_model.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final SupabaseService service;
  DashboardRepositoryImpl(this.service);

  @override
  Future<Either<Failure, DashboardData>> loadDashboard() async {
    try {
      final userId = service.currentUserId;
      if (userId == null) return const Left(AuthFailure('Not authenticated'));

      // Profile
      final profile = await service.db
          .from(AppConstants.tProfiles)
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Recent notes
      final notesRes = await service.db
          .from(AppConstants.tContentVault)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);
      final notes =
          (notesRes as List).map((e) => NoteModel.fromMap(e)).toList();

      // Total notes count
      final countRes = await service.db
          .from(AppConstants.tContentVault)
          .count();

      // Badges count
      final badgesRes = await service.db
          .from(AppConstants.tUserBadges)
          .select('badge_id')
          .eq('user_id', userId);

      // Tag aggregation (client-side from recent 100)
      final tagsRes = await service.db
          .from(AppConstants.tContentVault)
          .select('tags')
          .eq('user_id', userId)
          .limit(100);
      final counter = <String, int>{};
      for (final row in (tagsRes as List)) {
        for (final t in ((row['tags'] as List?) ?? [])) {
          counter[t as String] = (counter[t] ?? 0) + 1;
        }
      }
      final topTags = (counter.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .map((e) => TagCount(e.key, e.value))
          .toList();

      return Right(DashboardData(
        username: (profile?['username'] as String?) ?? 'You',
        level: (profile?['level'] as int?) ?? 1,
        xp: (profile?['xp'] as int?) ?? 0,
        xpForNextLevel: AppConstants.xpPerLevel,
        streakDays: (profile?['streak_days'] as int?) ?? 0,
        totalNotes: countRes,
        badgesUnlocked: (badgesRes as List).length,
        recentNotes: notes,
        topTags: topTags,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
