import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/badge_entity.dart';

class BadgeCard extends StatelessWidget {
  final BadgeEntity badge;
  const BadgeCard({super.key, required this.badge});

  Color get _accentColor {
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
    final faded = !badge.unlocked;
    final accent = _accentColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFill,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: faded
              ? AppColors.surfaceStroke
              : accent.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Opacity(
        opacity: faded ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_icon, size: 28, color: accent),
            const SizedBox(height: 12),
            Text(
              badge.rarity.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              badge.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(
                  badge.unlocked ? Icons.check_circle_rounded : Icons.lock_outline,
                  size: 14,
                  color: badge.unlocked
                      ? AppColors.success
                      : AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  badge.unlocked ? 'Terbuka' : 'Terkunci',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: badge.unlocked
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
