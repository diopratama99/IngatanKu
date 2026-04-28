import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../vault/domain/entities/note_entity.dart';

/// Auto-advancing editorial carousel that surfaces the user's most recent
/// notes between the PROGRES and STATISTIK sections of the dashboard.
///
/// Design notes:
/// - Cards lift slightly with a per-source accent (border tint + glow) so the
///   strip feels alive without breaking the editorial dark theme.
/// - Center card is at full scale/opacity; siblings dim & shrink subtly to
///   reinforce focus. Tap any card to push the note detail page.
/// - Pseudo-infinite loop via a large [itemCount] + modulo so the auto-advance
///   never has to "rewind" back to page 0.
class RecentNotesCarousel extends StatefulWidget {
  final List<NoteEntity> notes;
  const RecentNotesCarousel({super.key, required this.notes});

  @override
  State<RecentNotesCarousel> createState() => _RecentNotesCarouselState();
}

class _RecentNotesCarouselState extends State<RecentNotesCarousel> {
  static const _autoAdvanceInterval = Duration(seconds: 4);
  static const _animDuration = Duration(milliseconds: 700);
  static const _cardHeight = 196.0;
  static const _loopBase = 5000; // pseudo-infinite forward seek

  late final PageController _controller;
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    final initial = widget.notes.length > 1 ? _loopBase : 0;
    _controller = PageController(initialPage: initial);
    _page = initial;
    if (widget.notes.length > 1) _startAutoAdvance();
  }

  void _startAutoAdvance() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoAdvanceInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      // Yield to user gestures — don't interrupt manual swipes.
      if (_controller.position.isScrollingNotifier.value) return;
      _controller.animateToPage(
        _page + 1,
        duration: _animDuration,
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notes.isEmpty) return const SizedBox.shrink();
    final isSingle = widget.notes.length == 1;
    final loopCount = isSingle ? 1 : _loopBase * 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: loopCount,
            itemBuilder: (_, i) {
              final note = widget.notes[i % widget.notes.length];
              return _NoteCarouselCard(note: note);
            },
          ),
        ),
        if (!isSingle) ...[
          const SizedBox(height: 14),
          _PageDots(
            count: widget.notes.length,
            activeIndex: _page % widget.notes.length,
          ),
        ],
      ],
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int activeIndex;
  const _PageDots({required this.count, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.surfaceStroke,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

/// Editorial slate — typography-first card, deliberately stripped of the
/// generic "rounded gradient + shadow + colored dot" carousel cliché. The
/// only chrome is a 1px hairline rule between the byline and the headline,
/// echoing newspaper article excerpts.
class _NoteCarouselCard extends StatelessWidget {
  final NoteEntity note;
  const _NoteCarouselCard({required this.note});

  String get _sourceLabel {
    switch (note.sourceType) {
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

  @override
  Widget build(BuildContext context) {
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : '(Tanpa judul)';
    final preview = note.manualNotes.trim();
    final tagsLine = note.tags.take(3).map((t) => '#$t').join('   ·   ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/vault/${note.id}', extra: note),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            border: Border(
              left: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.85),
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Byline row: SOURCE · ─── · time ──────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _sourceLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.surfaceStroke,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _relTime(note.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Headline ────────────────────────────────────
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.18,
                  letterSpacing: -0.6,
                ),
              ),

              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],

              const Spacer(),

              // ── Footer: tags as inline byline ───────────────
              if (tagsLine.isNotEmpty)
                Text(
                  tagsLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
