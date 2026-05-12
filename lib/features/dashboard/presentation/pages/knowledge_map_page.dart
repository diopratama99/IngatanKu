import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../../vault/domain/entities/note_entity.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';

/// Editorial chart of how the user's notes are distributed across tags.
///
/// Drops the typical "bubble cloud" cliché in favour of a typographic
/// readout: each tag occupies one row with its name as a column header,
/// the count on the far right, and a thin indigo bar that maps the
/// share of the largest tag. Reads like a print chart, not a generic
/// dashboard widget.
class KnowledgeMapPage extends StatefulWidget {
  const KnowledgeMapPage({super.key});

  @override
  State<KnowledgeMapPage> createState() => _KnowledgeMapPageState();
}

class _KnowledgeMapPageState extends State<KnowledgeMapPage> {
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
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('PETA PENGETAHUAN', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: BlocBuilder<VaultBloc, VaultState>(
          builder: (_, state) {
            if (state is VaultLoading || state is VaultInitial) {
              return const _LoadingSkeleton();
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
              return _Content(notes: state.notes);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                            CONTENT
// ════════════════════════════════════════════════════════════════

class _Content extends StatelessWidget {
  final List<NoteEntity> notes;
  const _Content({required this.notes});

  @override
  Widget build(BuildContext context) {
    final counter = <String, int>{};
    for (final n in notes) {
      for (final t in n.tags) {
        counter[t] = (counter[t] ?? 0) + 1;
      }
    }
    if (counter.isEmpty) return const _EmptyMap();

    final entries = counter.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = entries.first.value;
    final totalTaggedRefs = entries.fold<int>(0, (acc, e) => acc + e.value);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
      children: [
        // ── Editorial title ────────────────────────────
        Text('Peta\ntopik.', style: pageTitleStyle(size: 38)),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entries.length}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'tag',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Text(
              '${notes.length}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'catatan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Single hairline ridge separating header / chart ─
        Container(
          height: 1,
          color: AppColors.surfaceStroke,
        ),
        const SizedBox(height: 28),

        // ── Bar chart rows ─────────────────────────────
        ...List.generate(entries.length, (i) {
          final e = entries[i];
          return _BarRow(
            rank: i + 1,
            tag: e.key,
            count: e.value,
            ratio: e.value / maxCount,
            isLeader: i == 0,
            onTap: () => context.push(Routes.tagDetail, extra: e.key),
          );
        }),

        const SizedBox(height: 28),
        Container(
          height: 1,
          color: AppColors.surfaceStroke,
        ),
        const SizedBox(height: 18),

        // ── Footer eyebrow note ─────────────────────────
        Text(
          'Total $totalTaggedRefs penanda dari '
          '${notes.length} catatan.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.55,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                      EDITORIAL BAR ROW
// ════════════════════════════════════════════════════════════════

/// One tag row in the chart.
///
/// Layout per row (top → bottom):
///   1. Header line: tiny rank index (e.g. `01`) | tag name in caps |
///      count on the far right.
///   2. Indigo distribution bar whose width = `ratio * available width`.
///
/// The leading row gets a subtly heavier bar height + glowing tint to
/// signal "dominant topic" without resorting to a bubble.
class _BarRow extends StatelessWidget {
  final int rank;
  final String tag;
  final int count;
  final double ratio;
  final bool isLeader;
  final VoidCallback onTap;

  const _BarRow({
    required this.rank,
    required this.tag,
    required this.count,
    required this.ratio,
    required this.isLeader,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final barColor =
        isLeader ? AppColors.primary : AppColors.primary.withValues(alpha: 0.78);
    final barHeight = isLeader ? 8.0 : 5.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header line
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Rank index — tiny faded prefix
                SizedBox(
                  width: 28,
                  child: Text(
                    rank.toString().padLeft(2, '0'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                // Tag name in print-style caps
                Expanded(
                  child: Text(
                    tag.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: isLeader ? 22 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  '$count',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isLeader ? 22 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    color: isLeader
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Distribution bar — flush left, fixed-height,
            // indigo, with a faint backplate so the user can
            // sense the missing remainder.
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final fillWidth =
                      (ratio.clamp(0.0, 1.0) * constraints.maxWidth)
                          .clamp(3.0, constraints.maxWidth);
                  return Stack(
                    children: [
                      Container(
                        height: barHeight,
                        width: constraints.maxWidth,
                        color: AppColors.surfaceStroke,
                      ),
                      Container(
                        height: barHeight,
                        width: fillWidth,
                        color: barColor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                          STATES
// ════════════════════════════════════════════════════════════════

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const ShimmerBox(height: 80, radius: 6),
        const SizedBox(height: 28),
        ...List.generate(
          6,
          (i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(height: 22, radius: 4),
                SizedBox(height: 10),
                ShimmerBox(height: 6, radius: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PETA KOSONG', style: eyebrowStyle()),
          const SizedBox(height: 12),
          Text('Belum ada\ntag.', style: pageTitleStyle(size: 38)),
          const SizedBox(height: 14),
          Text(
            'Tambahkan tag ke catatanmu untuk melihat distribusinya di sini.',
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
