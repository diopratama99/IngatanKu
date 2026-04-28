import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../domain/entities/badge_entity.dart';
import '../bloc/badges_cubit.dart';

/// Analytics-style detail page for the dashboard "Lencana terbuka" stat.
/// Loads from [BadgesCubit] and surfaces breakdown by rarity, XP earned,
/// recently unlocked badges, and the locked roadmap so the user can see
/// exactly what's left to chase.
class BadgesStatsPage extends StatefulWidget {
  const BadgesStatsPage({super.key});

  @override
  State<BadgesStatsPage> createState() => _BadgesStatsPageState();
}

class _BadgesStatsPageState extends State<BadgesStatsPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<BadgesCubit>().state;
    if (state is! BadgesLoaded) {
      context.read<BadgesCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('LENCANA', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: BlocBuilder<BadgesCubit, BadgesState>(
          builder: (_, state) {
            if (state is BadgesLoading || state is BadgesInitial) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: ShimmerBox(height: 48, radius: 4),
                ),
              );
            }
            if (state is BadgesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              );
            }
            if (state is BadgesLoaded) {
              return _buildContent(context, state.badges);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<BadgeEntity> badges) {
    if (badges.isEmpty) return const _EmptyBadgesStats();

    final unlocked = badges.where((b) => b.unlocked).toList();
    final locked = badges.where((b) => !b.unlocked).toList();
    final total = badges.length;
    final progress = total == 0 ? 0.0 : unlocked.length / total;
    final xpEarned = unlocked.fold<int>(0, (acc, b) => acc + b.xpReward);

    final byRarity = _byRarity(badges);
    final recentUnlocked = ([...unlocked]..sort((a, b) =>
            (b.unlockedAt ?? DateTime(0))
                .compareTo(a.unlockedAt ?? DateTime(0))))
        .take(5)
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      children: [
        // ── HEADER ──────────────────────────────────────────────
        Text('Lencana.', style: pageTitleStyle(size: 36)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${unlocked.length}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                letterSpacing: -2,
                height: 0.95,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '/ $total',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          unlocked.isEmpty
              ? 'Belum ada lencana yang terbuka. Mulai catat tech-mu untuk milestone pertama.'
              : 'Setiap milestone unik, setiap rarity beda XP.',
          style: context.textStyles.bodyMedium,
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.bgTertiary.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 40),

        // ── BERDASARKAN RARITY ─────────────────────────────────
        const SectionHeader(label: 'BERDASARKAN RARITY'),
        const SizedBox(height: 8),
        ...byRarity.map((r) => Column(
              children: [
                _RarityRow(
                  label: r.label,
                  unlocked: r.unlocked,
                  total: r.total,
                  color: r.color,
                ),
                const ThinDivider(),
              ],
            )),
        const SizedBox(height: 40),

        // ── XP TERKUMPUL ───────────────────────────────────────
        const SectionHeader(label: 'XP TERKUMPUL'),
        const SizedBox(height: 8),
        StatRow(value: '$xpEarned', label: 'XP dari lencana'),
        const ThinDivider(),
        StatRow(
          value: '${locked.fold<int>(0, (acc, b) => acc + b.xpReward)}',
          label: 'Sisa XP yang menunggu',
        ),
        const SizedBox(height: 40),

        // ── DIBUKA TERBARU ─────────────────────────────────────
        if (recentUnlocked.isNotEmpty) ...[
          SectionHeader(
            label: 'DIBUKA TERBARU',
            trailingLabel: 'SEMUA',
            onTrailing: () => context.go(Routes.badges),
          ),
          const SizedBox(height: 8),
          ...List.generate(recentUnlocked.length, (i) {
            return Column(
              children: [
                _BadgeListRow(badge: recentUnlocked[i]),
                if (i != recentUnlocked.length - 1) const ThinDivider(),
              ],
            );
          }),
          const SizedBox(height: 40),
        ],

        // ── BELUM DIBUKA ───────────────────────────────────────
        if (locked.isNotEmpty) ...[
          const SectionHeader(label: 'BELUM DIBUKA'),
          const SizedBox(height: 8),
          ...List.generate(locked.length, (i) {
            return Column(
              children: [
                _BadgeListRow(badge: locked[i]),
                if (i != locked.length - 1) const ThinDivider(),
              ],
            );
          }),
        ],
      ],
    );
  }

  // ── Aggregations ──────────────────────────────────────────────

  List<_RarityBucket> _byRarity(List<BadgeEntity> all) {
    const order = ['common', 'rare', 'epic', 'legendary'];
    final groups = <String, List<BadgeEntity>>{};
    for (final b in all) {
      groups.putIfAbsent(b.rarity, () => []).add(b);
    }
    return order.where((r) => groups.containsKey(r)).map((r) {
      final bucket = groups[r]!;
      return _RarityBucket(
        label: _rarityLabel(r),
        unlocked: bucket.where((b) => b.unlocked).length,
        total: bucket.length,
        color: _rarityColor(r),
      );
    }).toList();
  }

  String _rarityLabel(String r) {
    switch (r) {
      case 'legendary':
        return 'Legendary';
      case 'epic':
        return 'Epic';
      case 'rare':
        return 'Rare';
      default:
        return 'Common';
    }
  }

  Color _rarityColor(String r) {
    switch (r) {
      case 'legendary':
        return AppColors.warning;
      case 'epic':
        return AppColors.primary;
      case 'rare':
        return AppColors.accent;
      default:
        return AppColors.textPrimary;
    }
  }
}

class _RarityBucket {
  final String label;
  final int unlocked;
  final int total;
  final Color color;
  const _RarityBucket({
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
  });
}

/// Editorial-styled row for rarity breakdown — mirrors [StatRow] layout but
/// shows a "unlocked / total" fraction with a small accent dot.
class _RarityRow extends StatelessWidget {
  final String label;
  final int unlocked;
  final int total;
  final Color color;
  const _RarityRow({
    required this.label,
    required this.unlocked,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$unlocked',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '/ $total',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact list row for a badge — used in DIBUKA TERBARU and BELUM DIBUKA.
/// Editorial layout: rarity eyebrow + name + description, with status icon.
class _BadgeListRow extends StatelessWidget {
  final BadgeEntity badge;
  const _BadgeListRow({required this.badge});

  Color get _accent {
    if (!badge.unlocked) return AppColors.textTertiary;
    switch (badge.rarity) {
      case 'legendary':
        return AppColors.warning;
      case 'epic':
        return AppColors.primary;
      case 'rare':
        return AppColors.accent;
      default:
        return AppColors.textPrimary;
    }
  }

  IconData get _icon {
    switch (badge.code) {
      case 'BUG_HUNTER':
        return Icons.bug_report_outlined;
      case 'FRAMEWORK_MASTER':
        return Icons.architecture_rounded;
      case 'CONSISTENCY_KING':
        return Icons.local_fire_department_rounded;
      case 'MIDNIGHT_CODER':
        return Icons.bedtime_outlined;
      case 'THE_ORACLE':
        return Icons.psychology_alt_outlined;
      case 'POLYGLOT':
        return Icons.translate_rounded;
      case 'KNOWLEDGE_CARTOGRAPHER':
        return Icons.map_outlined;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Opacity(
        opacity: badge.unlocked ? 1 : 0.55,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 22, color: _accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.rarity.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.name,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.25,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.unlocked
                        ? '+${badge.xpReward} XP · Terbuka'
                        : '+${badge.xpReward} XP · Terkunci',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              badge.unlocked ? Icons.check_circle_rounded : Icons.lock_outline,
              size: 18,
              color:
                  badge.unlocked ? AppColors.success : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBadgesStats extends StatelessWidget {
  const _EmptyBadgesStats();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LENCANA KOSONG', style: eyebrowStyle()),
          const SizedBox(height: 12),
          Text('Belum\nada data.', style: pageTitleStyle(size: 38)),
          const SizedBox(height: 14),
          Text(
            'Lencana akan muncul di sini setelah definisi gamifikasi tersinkron.',
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
