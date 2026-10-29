import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/markdown_strip.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../companion/data/pet_store.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/widgets/food_painter.dart';
import '../../domain/entities/note_entity.dart';
import 'book_colors.dart';

/// A saved note as a little book: a coloured spine on the left (the
/// colour of its first tag, like the books on the pet's shelves), the
/// thumbnail with its source, the title and a peek at the notes, where it
/// came from and when, its tags, and whether the pet has eaten it yet.
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
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : l10n.vaultUntitled;
    // Strip markdown markers before the snippet so the preview stays clean.
    final stripped = stripMarkdown(note.manualNotes).replaceAll('\n', ' ');
    final preview = stripped.isEmpty
        ? null
        : (stripped.length > 140 ? '${stripped.substring(0, 140)}…' : stripped);
    final hasThumb = note.thumbnailUrl != null && note.thumbnailUrl!.isNotEmpty;
    final host = (Uri.tryParse(note.url)?.host ?? '').replaceFirst('www.', '');
    final digested = sl<PetStore>().state.hasEaten(note.id);
    final book =
        BookColor.of(note.tags.isNotEmpty ? note.tags.first : note.sourceType);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SoftButton(
        onTap: onTap,
        radius: 18,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Spine(color: book.spine),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Thumb(
                          url: hasThumb ? note.thumbnailUrl : null,
                          sourceType: note.sourceType,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.display(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.28,
                                  color: palette.textPrimary,
                                ),
                              ),
                              if (preview != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppFonts.body(
                                    fontSize: 12.5,
                                    height: 1.35,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              _Source(
                                host: host,
                                url: note.url,
                                when: _when(context, note.createdAt),
                              ),
                              const SizedBox(height: 7),
                              Row(
                                children: [
                                  // The first tag, and how many more.
                                  if (note.tags.isNotEmpty) ...[
                                    Flexible(
                                      child: _TagChip(
                                        tag: note.tags.first,
                                        color: book,
                                      ),
                                    ),
                                    if (note.tags.length > 1) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '+${note.tags.length - 1}',
                                        style: AppFonts.body(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: palette.textTertiary,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(width: 6),
                                  ],
                                  const Spacer(),
                                  _Digested(
                                    sourceType: note.sourceType,
                                    digested: digested,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The time for something saved today, else the date.
  static String _when(BuildContext context, DateTime at) {
    final now = DateTime.now();
    if (at.year == now.year && at.month == now.month && at.day == now.day) {
      return MaterialLocalizations.of(context).formatTimeOfDay(
          TimeOfDay.fromDateTime(at),
          alwaysUse24HourFormat: true);
    }
    return at.prettyDateLocalized(context);
  }
}

/// The book's spine: a strip of colour with two lighter bands near its
/// ends, like the books on the shelves.
class _Spine extends StatelessWidget {
  final Color color;
  const _Spine({required this.color});

  @override
  Widget build(BuildContext context) {
    final band = Colors.white.withValues(alpha: 0.45);
    return SizedBox(
      width: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color),
        child: Column(
          children: [
            const SizedBox(height: 14),
            Container(height: 1.6, color: band),
            const SizedBox(height: 3),
            Container(height: 1.6, color: band),
            const Spacer(),
            Container(height: 1.6, color: band),
            const SizedBox(height: 3),
            Container(height: 1.6, color: band),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

/// The note's picture (or the dish it is for the pet), with a little badge
/// for where it's from.
class _Thumb extends StatelessWidget {
  final String? url;
  final String sourceType;
  const _Thumb({required this.url, required this.sourceType});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: url == null
                  ? _Placeholder(sourceType: sourceType)
                  : CachedNetworkImage(
                      imageUrl: url!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: palette.bgTertiary),
                      errorWidget: (_, __, ___) =>
                          _Placeholder(sourceType: sourceType),
                    ),
            ),
          ),
          Positioned(
            left: 5,
            bottom: 5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: Icon(SourceMeta.icon(sourceType),
                  size: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// "youtube.com · 08.30   ↗" — tap the arrow to open the source.
class _Source extends StatelessWidget {
  final String host;
  final String url;
  final String when;
  const _Source({required this.host, required this.url, required this.when});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = AppFonts.body(fontSize: 11.5, color: palette.textTertiary);
    return Row(
      children: [
        Expanded(
          child: Text(
            host.isEmpty ? when : '$host · $when',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (host.isNotEmpty)
          Semantics(
            button: true,
            label: host,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                final uri = Uri.tryParse(url);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(Icons.north_east_rounded,
                    size: 14, color: palette.textTertiary),
              ),
            ),
          ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final BookColor color;
  const _TagChip({required this.tag, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.chip,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '#$tag',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.body(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.ink,
          ),
        ),
      );
}

/// The dish this note is for the pet — bright once eaten, faded while it's
/// still waiting.
class _Digested extends StatelessWidget {
  final String sourceType;
  final bool digested;
  const _Digested({required this.sourceType, required this.digested});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final label = digested ? l10n.vaultRowDigested : l10n.vaultRowNotDigested;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: digested ? 1 : 0.35,
            child: FoodIcon(kind: FoodKind.fromSource(sourceType), size: 16),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppFonts.body(
              fontSize: 11,
              fontWeight: digested ? FontWeight.w600 : FontWeight.w400,
              color: digested ? palette.success : palette.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// No thumbnail: a soft tile with the dish this note becomes for the pet.
class _Placeholder extends StatelessWidget {
  final String sourceType;
  const _Placeholder({required this.sourceType});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      color: palette.bgTertiary,
      alignment: Alignment.center,
      child: FoodIcon(kind: FoodKind.fromSource(sourceType), size: 40),
    );
  }
}
