import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/markdown_strip.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/entities/note_entity.dart';

/// Editorial note list row — no card chrome, just typography + meta.
/// Shared between [VaultPage] and [TagDetailPage].
class VaultNoteRow extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  const VaultNoteRow({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : '(Tanpa judul)';
    // Strip markdown markers (↑`**bold**`, lists, headings) before the
    // 140-char snippet so the row preview stays clean.
    final stripped = stripMarkdown(note.manualNotes);
    final hasPreview = stripped.isNotEmpty;
    final preview = hasPreview
        ? (stripped.length > 140 ? '${stripped.substring(0, 140)}…' : stripped)
        : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_sourceLabel(note.sourceType).toUpperCase(),
                      style: eyebrowStyle()),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
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
              padding: EdgeInsets.only(top: 18),
              child: Icon(Icons.arrow_outward_rounded,
                  size: 16, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

String _meta(NoteEntity n) {
  final parts = <String>[
    _relTime(n.createdAt),
    if (n.tags.isNotEmpty) '#${n.tags.first}',
    if (n.tags.length > 1) '+${n.tags.length - 1}',
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
