import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/markdown_strip.dart';
import '../../domain/entities/note_entity.dart';

/// Editorial note card. Name kept for backwards compatibility with any
/// future caller — uses the same flat design language as the rest of
/// the app (typography + thin borders, no neon halos).
class GlassNoteCard extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback? onTap;
  const GlassNoteCard({super.key, required this.note, this.onTap});

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

  @override
  Widget build(BuildContext context) {
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : '(Tanpa judul)';
    // Strip markdown markers before the 140-char preview so the card
    // doesn't show raw `**bold**` / `- list` / `# heading` syntax.
    final stripped = stripMarkdown(note.manualNotes);
    final preview =
        stripped.length > 140 ? '${stripped.substring(0, 140)}…' : stripped;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sourceLabel(note.sourceType).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
                letterSpacing: -0.3,
              ),
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              [
                _relTime(note.createdAt),
                if (note.tags.isNotEmpty) '#${note.tags.first}',
                if (note.tags.length > 1) '+${note.tags.length - 1}',
              ].join('  ·  '),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
