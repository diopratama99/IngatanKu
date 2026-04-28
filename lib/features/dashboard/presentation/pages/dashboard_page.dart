import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../vault/domain/entities/note_entity.dart';
import '../bloc/dashboard_cubit.dart';

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
        // Top meta — date + sign-out, both as quiet caption text.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatToday(), style: eyebrowStyle()),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.read<AuthBloc>().add(AuthSignOutRequested()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('KELUAR', style: eyebrowStyle()),
                  const SizedBox(width: 6),
                  const Icon(Icons.logout_rounded,
                      size: 13, color: AppColors.textTertiary),
                ],
              ),
            ),
          ],
        ),
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
            backgroundColor: AppColors.bgTertiary.withOpacity(0.4),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$remainingXp XP lagi → Level ${d.level + 1}',
          style: context.textStyles.bodySmall,
        ),
        const SizedBox(height: 48),

        // STATISTIK section — editorial rows, no card chrome.
        const SectionHeader(label: 'STATISTIK'),
        const SizedBox(height: 8),
        StatRow(
          value: '${d.totalNotes}',
          label: 'Catatan tersimpan',
          onTap: () => context.go(Routes.vault),
        ),
        const ThinDivider(),
        StatRow(
          value: '${d.badgesUnlocked}',
          label: 'Lencana terbuka',
          onTap: () => context.go(Routes.badges),
        ),
        const ThinDivider(),
        StatRow(
          value: d.topTags.isEmpty ? '—' : '#${d.topTags.first.tag}',
          label: 'Tag teratas',
          onTap: () => context.push(Routes.tags),
        ),
        const SizedBox(height: 48),

        // AKSI CEPAT section — one primary CTA, one secondary.
        const SectionHeader(label: 'AKSI CEPAT'),
        const SizedBox(height: 16),
        ActionRow(
          icon: Icons.add_rounded,
          label: 'Tulis catatan baru',
          primary: true,
          onTap: () => context.push(Routes.addNote),
        ),
        const SizedBox(height: 10),
        ActionRow(
          icon: Icons.psychology_alt_outlined,
          label: 'Tanya otak keduamu',
          onTap: () => context.go(Routes.chat),
        ),
        const SizedBox(height: 48),

        // PETA PENGETAHUAN — text-only chip-style row.
        if (d.topTags.isNotEmpty) ...[
          SectionHeader(
            label: 'PETA PENGETAHUAN',
            trailingLabel: 'KELOLA',
            onTrailing: () => context.push(Routes.tags),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 10,
            children: d.topTags.map((tc) {
              return GestureDetector(
                onTap: () => context.push(Routes.tags),
                child: Text(
                  '#${tc.tag}  ${tc.count}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ).copyWith(
                    decorationColor: AppColors.surfaceStroke,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
        ],

        // TERSIMPAN TERAKHIR — list rows with thin separators.
        SectionHeader(
          label: 'TERSIMPAN TERAKHIR',
          trailingLabel: 'SEMUA',
          onTrailing: () => context.go(Routes.vault),
        ),
        const SizedBox(height: 8),
        if (d.recentNotes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Belum ada catatan. Simpan tautan pertamamu dan dapatkan 10 XP.',
              style: context.textStyles.bodyMedium,
            ),
          )
        else
          ...List.generate(d.recentNotes.length, (i) {
            final n = d.recentNotes[i];
            return Column(
              children: [
                _NoteRow(
                  note: n,
                  onTap: () => context.push('/vault/${n.id}', extra: n),
                ),
                if (i != d.recentNotes.length - 1) const ThinDivider(),
              ],
            );
          }),
      ],
    );
  }

  // ─── helpers ──────────────────────────────────────────────────────────

  static const _hari = [
    'MINGGU', 'SENIN', 'SELASA', 'RABU', 'KAMIS', 'JUMAT', 'SABTU'
  ];
  static const _bulan = [
    'JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN',
    'JUL', 'AGT', 'SEP', 'OKT', 'NOV', 'DES'
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

/// Compact magazine-style note row: title + meta + outward arrow.
class _NoteRow extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  const _NoteRow({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : '(Tanpa judul)';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _meta(note),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(Icons.arrow_outward_rounded,
                  size: 16, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  String _meta(NoteEntity n) {
    final parts = <String>[
      _sourceLabel(n.sourceType),
      _relTime(n.createdAt),
      if (n.tags.isNotEmpty) '#${n.tags.first}',
    ];
    return parts.join('  ·  ');
  }

  String _sourceLabel(String s) {
    switch (s) {
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'instagram':
        return 'Instagram';
      case 'x':
        return 'X';
      case 'article':
        return 'Artikel';
      default:
        return 'Tautan';
    }
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
    if (diff.inHours < 24) return '${diff.inHours} jam';
    if (diff.inDays < 7) return '${diff.inDays} hari';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} minggu';
    return '${diff.inDays ~/ 30} bulan';
  }
}

