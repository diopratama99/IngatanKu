import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../features/quiz/presentation/widgets/weekly_quiz_card.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../bloc/dashboard_cubit.dart';
import '../widgets/recent_notes_carousel.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<DashboardCubit>().load(),
          child: BlocBuilder<DashboardCubit, DashboardState>(
            builder: (_, state) {
              if (state is DashboardLoading || state is DashboardInitial) {
                return _buildSkeleton();
              }
              if (state is DashboardError) {
                return Center(child: Text(state.message));
              }
              if (state is DashboardReady) {
                return _buildContent(context, state);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() => ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
        children: const [
          ShimmerBox(height: 14, radius: 4),
          SizedBox(height: 32),
          ShimmerBox(height: 56, radius: 6),
          SizedBox(height: 12),
          ShimmerBox(height: 56, radius: 6),
          SizedBox(height: 48),
          ShimmerBox(height: 1, radius: 0),
          SizedBox(height: 16),
          ShimmerBox(height: 80, radius: 6),
          SizedBox(height: 32),
          ShimmerBox(height: 1, radius: 0),
          SizedBox(height: 16),
          ShimmerBox(height: 64, radius: 6),
        ],
      );

  Widget _buildContent(BuildContext context, DashboardReady state) {
    final d = state.data;
    final remainingXp = d.xpForNextLevel - (d.xp % d.xpForNextLevel);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
      children: [
        // Top meta — date as quiet caption text.
        Text(_formatToday(), style: eyebrowStyle()),
        const SizedBox(height: 36),

        // Editorial greeting — large display type, two lines.
        Text(
          '${_greeting()},',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 38,
            fontWeight: FontWeight.w400,
            letterSpacing: -1,
            height: 1.1,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${d.username}.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
            height: 1.1,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 48),

        // PROGRES section — two big stats side by side, then xp bar.
        const SectionHeader(label: 'PROGRES'),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BigStat(
                value: '${d.level}',
                label: 'Level · ${d.xp} XP',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: BigStat(
                value: '${d.streakDays}',
                label: d.streakDays == 0
                    ? 'Mulai streak hari ini'
                    : 'Hari beruntun',
                accent: d.streakDays > 0 ? AppColors.warning : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: d.xpProgress,
            backgroundColor: AppColors.bgTertiary.withValues(alpha: 0.4),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$remainingXp XP lagi → Level ${d.level + 1}',
          style: context.textStyles.bodySmall,
        ),
        const SizedBox(height: 40),

        // CATATAN KAMU — auto-rotating single-card carousel of recent notes.
        if (d.recentNotes.isNotEmpty) ...[
          const SectionHeader(label: 'CATATAN KAMU'),
          const SizedBox(height: 16),
          RecentNotesCarousel(notes: d.recentNotes),
          const SizedBox(height: 40),
        ],

        // QUIZ MINGGUAN — entry point card; the page itself decides
        // whether to generate, resume, or show the completed review.
        const WeeklyQuizCard(),
        const SizedBox(height: 40),

        // STATISTIK section — editorial rows, no card chrome.
        const SectionHeader(label: 'STATISTIK'),
        const SizedBox(height: 8),
        StatRow(
          value: '${d.totalNotes}',
          label: 'Catatan tersimpan',
          onTap: () => context.push(Routes.notesStats),
        ),
        const ThinDivider(),
        StatRow(
          value: '${d.badgesUnlocked}',
          label: 'Lencana terbuka',
          onTap: () => context.push(Routes.badgesStats),
        ),
        const ThinDivider(),
        StatRow(
          value: d.topTags.isEmpty ? '—' : '#${d.topTags.first.tag}',
          label: 'Tag teratas',
          onTap: d.topTags.isEmpty
              ? null
              : () => context.push(
                    Routes.tagDetail,
                    extra: d.topTags.first.tag,
                  ),
        ),
        const SizedBox(height: 48),

        // PETA PENGETAHUAN — text-only chip-style row.
        if (d.topTags.isNotEmpty) ...[
          SectionHeader(
            label: 'PETA PENGETAHUAN',
            trailingLabel: 'DETAIL',
            onTrailing: () => context.push(Routes.knowledgeMap),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 22,
            runSpacing: 14,
            children: d.topTags.map((tc) {
              // Two-tier styling: hashtag in primary color/weight, count
              // smaller and tertiary so the eye reads tag-first, count-second
              // instead of the previous flat "#docker  2" run-on.
              return GestureDetector(
                onTap: () => context.push(Routes.tagDetail, extra: tc.tag),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '#${tc.tag}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: '  ${tc.count}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
        ],
      ],
    );
  }

  // ─── helpers ──────────────────────────────────────────────────────────

  static const _hari = [
    'MINGGU',
    'SENIN',
    'SELASA',
    'RABU',
    'KAMIS',
    'JUMAT',
    'SABTU'
  ];
  static const _bulan = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MEI',
    'JUN',
    'JUL',
    'AGT',
    'SEP',
    'OKT',
    'NOV',
    'DES'
  ];

  String _formatToday() {
    final now = DateTime.now();
    return '${_hari[now.weekday % 7]}, ${now.day} ${_bulan[now.month - 1]}';
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }
}
