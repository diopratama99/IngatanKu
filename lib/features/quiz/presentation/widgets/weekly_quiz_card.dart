import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editorial.dart';

/// Dashboard entry point to the weekly quiz feature. Renders as a quiet
/// editorial section (header + tap row) so it sits naturally between the
/// other dashboard sections without card chrome. Opening the page is
/// what triggers `generate-weekly-quiz` — we don't pre-fetch here so
/// dashboard refreshes stay snappy and we avoid a redundant LLM hit on
/// every Beranda load.
class WeeklyQuizCard extends StatelessWidget {
  const WeeklyQuizCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(label: 'QUIZ MINGGUAN'),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.push(Routes.weeklyQuiz),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test ingatanmu dari catatan minggu ini.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '5 pertanyaan · hingga +35 XP',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
