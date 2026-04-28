import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/glass_container.dart';

class StatGlassCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const StatGlassCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withOpacity(0.4)),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 2),
          Text(label,
              style: context.textStyles.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
