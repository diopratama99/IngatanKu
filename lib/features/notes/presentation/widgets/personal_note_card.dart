import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_palette.dart';
import '../../data/datasources/personal_note_image_store.dart';
import '../../domain/entities/personal_note.dart';
import '../../../vault/presentation/widgets/book_colors.dart';
import 'note_color_palette.dart';
import 'note_paper.dart';
import 'sticky_note.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../shared/widgets/markdown_editor.dart';

/// A personal note on the board in Catatan: a sticky note in the note's
/// colour, turned a little and held on with a pushpin (pinned notes are
/// taped down instead). Optional photo (pasted on like a snapshot) →
/// title → body preview → link / tag chips. Each note grows to fit its
/// content, but never shorter than a square-ish sticky note.
class PersonalNoteCard extends StatelessWidget {
  final PersonalNote note;
  final VoidCallback onTap;
  final VoidCallback? onTogglePin;
  const PersonalNoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onTogglePin,
  });

  /// The pushpin: a deeper shade of the note's own colour, or a red one on
  /// plain paper.
  static Color _pin(NoteColor c, BuildContext context) =>
      c == NoteColor.defaultColor
          ? StickyNote.pinRed
          : Color.lerp(NoteColorPalette.swatch(c), Colors.black, 0.12)!;

  @override
  Widget build(BuildContext context) {
    final firstImage =
        note.imageFiles.isNotEmpty ? note.imageFiles.first : null;
    final ink = context.palette.textPrimary;
    final hasTitle = note.title != null && note.title!.trim().isNotEmpty;
    final hasBody = note.body.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, box) => StickyNote(
        paper: NoteColorPalette.background(note.color),
        angle: StickyNote.tiltFor(note.id),
        fix: note.pinned ? StickyFix.tape : StickyFix.pin,
        accent: note.pinned
            ? NotePaper.tapeFor(note.color, context)
            : _pin(note.color, context),
        minHeight: box.maxWidth * 0.82,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (firstImage != null) ...[
              _CardImage(noteId: note.id, filename: firstImage),
              const SizedBox(height: 10),
            ],
            if (hasTitle) ...[
              Text(
                note.title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.display(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: ink,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              if (hasBody) const SizedBox(height: 6),
            ],
            if (hasBody)
              // As it reads (bold, bullets), without the Markdown marks.
              Text.rich(
                markdownPreview(
                  note.body,
                  style: AppFonts.body(
                    fontSize: 13.5,
                    color: ink.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
                  palette: context.palette,
                ),
                // Cap previews so very long notes don't blow up the
                // board. The note itself is one tap away.
                maxLines: firstImage != null ? 4 : 8,
                overflow: TextOverflow.ellipsis,
              ),
            if (note.links.isNotEmpty) ...[
              const SizedBox(height: 8),
              _LinksRow(links: note.links),
            ],
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              _TagsRow(tags: note.tags),
            ],
          ],
        ),
      ),
    );
  }
}

/// The note's first photo, pasted on like a snapshot with a white border.
/// Resolves a basename → absolute path on first build then renders
/// `Image.file`. Wrapped in `FutureBuilder` because `pathFor` is async
/// (it `mkdir`s on first access).
class _CardImage extends StatelessWidget {
  final String noteId;
  final String filename;
  const _CardImage({required this.noteId, required this.filename});

  @override
  Widget build(BuildContext context) {
    final store = sl<PersonalNoteImageStore>();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: FutureBuilder<String>(
          future: store.pathFor(noteId: noteId, filename: filename),
          builder: (_, snap) {
            if (!snap.hasData) {
              return Container(
                height: 110,
                color: context.palette.bgTertiary.withValues(alpha: 0.4),
              );
            }
            return Image.file(
              File(snap.data!),
              fit: BoxFit.cover,
              // Capped height so short captions don't get dwarfed by a
              // tall portrait image.
              height: 120,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                height: 110,
                color: context.palette.bgTertiary,
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: context.palette.textTertiary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LinksRow extends StatelessWidget {
  final List<NoteLink> links;
  const _LinksRow({required this.links});

  @override
  Widget build(BuildContext context) {
    final sample = links.take(2).toList();
    final extra = links.length - sample.length;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in sample)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: context.palette.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.link_rounded,
                    size: 12, color: context.palette.textSecondary),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Text(
                    l.effectiveLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.body(
                      fontSize: 11,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (extra > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              '+$extra',
              style: AppFonts.body(
                fontSize: 11,
                color: context.palette.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagsRow extends StatelessWidget {
  final List<String> tags;
  const _TagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    // Each tag in its book colour, as on the shelves in Pustaka.
    return Text.rich(
      TextSpan(children: [
        for (final (i, t) in tags.take(4).indexed)
          TextSpan(
            text: '${i == 0 ? '' : '  '}#$t',
            style: TextStyle(color: BookColor.of(t).ink),
          ),
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.body(fontSize: 12, fontWeight: FontWeight.w600),
    );
  }
}
