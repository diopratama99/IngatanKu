import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/repositories/badge_repository.dart';

class BadgeRepositoryImpl implements BadgeRepository {
  final SupabaseService service;
  BadgeRepositoryImpl(this.service);

  @override
  Future<Either<Failure, List<BadgeEntity>>> listAll() async {
    try {
      final userId = service.currentUserId;
      if (userId == null) return const Left(AuthFailure('Not authenticated'));

      final all = await service.db.from(AppConstants.tBadges).select();
      final unlockedRows = await service.db
          .from(AppConstants.tUserBadges)
          .select()
          .eq('user_id', userId);

      final unlockedMap = {
        for (final r in (unlockedRows as List))
          r['badge_id'] as String: DateTime.parse(r['unlocked_at'] as String),
      };

      final list = (all as List).map((r) {
        final id = r['id'] as String;
        return BadgeEntity(
          id: id,
          code: r['code'] as String,
          name: r['name'] as String,
          description: r['description'] as String,
          iconUrl: r['icon_url'] as String?,
          rarity: r['rarity'] as String? ?? 'common',
          xpReward: (r['xp_reward'] as int?) ?? 50,
          unlocked: unlockedMap.containsKey(id),
          unlockedAt: unlockedMap[id],
        );
      }).toList();

      // Sort: unlocked first, then by rarity weight
      const rarityWeight = {'legendary': 4, 'epic': 3, 'rare': 2, 'common': 1};
      list.sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
        return (rarityWeight[b.rarity] ?? 0).compareTo(rarityWeight[a.rarity] ?? 0);
      });

      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
