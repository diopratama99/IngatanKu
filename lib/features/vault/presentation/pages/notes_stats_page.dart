import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/vault_note_row.dart';

/// Analytics-style detail page for the dashboard "Catatan tersimpan" stat.
/// Reuses the [VaultBloc] data and shows three editorial breakdowns
/// (sumber, periode, tag) plus a quick-access list of the latest notes.
class NotesStatsPage extends StatefulWidget {
  const NotesStatsPage({super.key});

  @override
  State<NotesStatsPage> createState() => _NotesStatsPageState();
}

class _NotesStatsPageState extends State<NotesStatsPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<VaultBloc>().state;
    if (state is! VaultLoaded) {
      context.read<VaultBloc>().add(VaultLoadRequested());
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
        title: Text('CATATAN', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: BlocBuilder<VaultBloc, VaultState>(
          builder: (_, state) {
            if (state is VaultLoading || state is VaultInitial) {
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 6,
                itemBuilder: (_, __) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: ShimmerBox(height: 48, radius: 4),
                ),
              );
            }
            if (state is VaultError) {
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
            if (state is VaultLoaded) {
              return _buildContent(context, state.notes);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<NoteEntity> notes) {
    if (notes.isEmpty) return const _EmptyNotesStats();

    final bySource = _bySource(notes);
    final byPeriod = _byPeriod(notes);
    final topTags = _topTags(notes);
    final recent = ([...notes]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)))
        .take(5)
        .toList();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async =>
          context.read<VaultBloc>().add(VaultLoadRequested()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
        children: [
          // ── HEADER ────────────────────────────────────────────────
          Text('Catatan.', style: pageTitleStyle(size: 36)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${notes.length}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -2,
                  height: 0.95,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'tersimpan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ringkasan koleksi catatanmu — dari mana, kapan, dan tentang apa.',
            style: context.textStyles.bodyMedium,
          ),
          const SizedBox(height: 40),

          // ── BERDASARKAN SUMBER ───────────────────────────────────
          const SectionHeader(label: 'BERDASARKAN SUMBER'),
          const SizedBox(height: 8),
          ...bySource.map((e) => Column(
                children: [
                  StatRow(value: '${e.count}', label: e.label),
                  const ThinDivider(),
                ],
              )),
          const SizedBox(height: 40),

          // ── PER PERIODE ──────────────────────────────────────────
          const SectionHeader(label: 'PER PERIODE'),
          const SizedBox(height: 8),
          StatRow(value: '${byPeriod.thisWeek}', label: 'Minggu ini'),
          const ThinDivider(),
          StatRow(value: '${byPeriod.thisMonth}', label: 'Bulan ini'),
          const ThinDivider(),
          StatRow(value: '${byPeriod.older}', label: 'Lebih lama'),
          const SizedBox(height: 40),

          // ── TAG TERATAS ──────────────────────────────────────────
          if (topTags.isNotEmpty) ...[
            const SectionHeader(label: 'TAG TERATAS'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: topTags.map((t) {
                return GestureDetector(
                  onTap: () => context.push(Routes.tagDetail, extra: t.tag),
                  child: Text(
                    '#${t.tag}  ${t.count}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
          ],

          // ── TERSIMPAN TERAKHIR ───────────────────────────────────
          SectionHeader(
            label: 'TERSIMPAN TERAKHIR',
            trailingLabel: 'SEMUA',
            onTrailing: () => context.go(Routes.vault),
          ),
          const SizedBox(height: 8),
          ...List.generate(recent.length, (i) {
            return Column(
              children: [
                VaultNoteRow(
                  note: recent[i],
                  onTap: () => context
                      .push('/vault/${recent[i].id}', extra: recent[i]),
                ),
                if (i != recent.length - 1) const ThinDivider(),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Aggregations ────────────────────────────────────────────────

  List<_SourceCount> _bySource(List<NoteEntity> notes) {
    final counter = <String, int>{};
    for (final n in notes) {
      counter[n.sourceType] = (counter[n.sourceType] ?? 0) + 1;
    }
    final entries = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => _SourceCount(label: _sourceLabel(e.key), count: e.value))
        .toList();
  }

  _PeriodBuckets _byPeriod(List<NoteEntity> notes) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    var thisWeek = 0, thisMonth = 0, older = 0;
    for (final n in notes) {
      if (!n.createdAt.isBefore(startOfWeek)) {
        thisWeek++;
        thisMonth++;
      } else if (!n.createdAt.isBefore(startOfMonth)) {
        thisMonth++;
      } else {
        older++;
      }
    }
    return _PeriodBuckets(
      thisWeek: thisWeek,
      thisMonth: thisMonth,
      older: older,
    );
  }

  List<_TagCount> _topTags(List<NoteEntity> notes) {
    final counter = <String, int>{};
    for (final n in notes) {
      for (final t in n.tags) {
        counter[t] = (counter[t] ?? 0) + 1;
      }
    }
    final entries = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(8)
        .map((e) => _TagCount(tag: e.key, count: e.value))
        .toList();
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
        return 'Tautan lain';
    }
  }
}

class _SourceCount {
  final String label;
  final int count;
  const _SourceCount({required this.label, required this.count});
}

class _PeriodBuckets {
  final int thisWeek;
  final int thisMonth;
  final int older;
  const _PeriodBuckets({
    required this.thisWeek,
    required this.thisMonth,
    required this.older,
  });
}

class _TagCount {
  final String tag;
  final int count;
  const _TagCount({required this.tag, required this.count});
}

class _EmptyNotesStats extends StatelessWidget {
  const _EmptyNotesStats();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BELUM ADA CATATAN', style: eyebrowStyle()),
          const SizedBox(height: 12),
          Text('Mulai\nmenulis.', style: pageTitleStyle(size: 38)),
          const SizedBox(height: 14),
          Text(
            'Statistik akan muncul di sini setelah kamu menyimpan catatan pertama.',
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
