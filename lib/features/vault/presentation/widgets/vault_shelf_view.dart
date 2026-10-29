import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/data/pet_store.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/widgets/food_painter.dart';
import '../../domain/entities/note_entity.dart';
import 'book_colors.dart';

/// Pustaka's shelf view: every saved note as a book standing on a wooden
/// shelf, like the pet's reading nook above. Grouped the same way as the
/// list (today, yesterday…), a few books to a shelf.
class VaultShelfView extends StatelessWidget {
  /// The notes, already grouped: a label and that group's notes.
  final List<(String, List<NoteEntity>)> groups;
  final Widget Function(String label, int count) groupHeader;
  final ValueChanged<NoteEntity> onTap;
  final Future<void> Function() onRefresh;
  final EdgeInsets padding;

  const VaultShelfView({
    super.key,
    required this.groups,
    required this.groupHeader,
    required this.onTap,
    required this.onRefresh,
    this.padding = EdgeInsets.zero,
  });

  static const _side = 20.0;
  static const _gap = 14.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final inner = c.maxWidth - _side * 2;
      // Three books to a shelf on phones, more on wider screens.
      final cols = math.max(3, ((inner + _gap) / 132).floor()).clamp(3, 6);
      final coverW = (inner - _gap * (cols - 1)) / cols;
      final coverH = coverW * 1.4;
      final children = <Widget>[];
      for (final (label, notes) in groups) {
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: groupHeader(label, notes.length),
        ));
        for (var i = 0; i < notes.length; i += cols) {
          children.add(_Shelf(
            books: notes.sublist(i, math.min(i + cols, notes.length)),
            coverW: coverW,
            coverH: coverH,
            onTap: onTap,
          ));
        }
      }
      return RefreshIndicator(
        color: context.palette.textPrimary,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          children: children,
        ),
      );
    });
  }
}

/// One wooden shelf with a few books standing on it.
class _Shelf extends StatelessWidget {
  final List<NoteEntity> books;
  final double coverW;
  final double coverH;
  final ValueChanged<NoteEntity> onTap;
  const _Shelf({
    required this.books,
    required this.coverW,
    required this.coverH,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const plankH = 26.0;
    // Books stand on the plank's top face, about halfway back.
    final surface = coverH;
    return SizedBox(
      height: surface + plankH * 0.5 + 22,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The shelf's shadow on the wall below it.
          Positioned(
            left: 30,
            right: 24,
            top: surface + plankH * 0.25,
            height: 8,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 14,
                    spreadRadius: -2,
                    offset: const Offset(3, 6),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            top: surface - plankH * 0.5,
            height: plankH,
            child: Image.asset(
              'assets/library/plank.png',
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
          for (var i = 0; i < books.length; i++)
            () {
              final note = books[i];
              // Not every book is the same height.
              final h = coverH * (0.9 + 0.1 * _wobble(note.id));
              return Positioned(
                left: VaultShelfView._side + i * (coverW + VaultShelfView._gap),
                top: surface - h,
                width: coverW,
                height: h,
                child: _BookCover(note: note, onTap: () => onTap(note)),
              );
            }(),
        ],
      ),
    );
  }

  /// 0..1, the same for a note every time.
  static double _wobble(String id) {
    var hash = 7;
    for (final c in id.codeUnits) {
      hash = (hash * 31 + c) & 0x7fffffff;
    }
    return (hash % 100) / 100;
  }
}

/// A saved note as a book seen from the front: a board in its tag's
/// colour with a darker spine, the note's picture in a window, its title
/// printed below, where it's from, and the dish it is for the pet (faded
/// until eaten).
class _BookCover extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  const _BookCover({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final book =
        BookColor.of(note.tags.isNotEmpty ? note.tags.first : note.sourceType);
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : l10n.vaultUntitled;
    final thumb = note.thumbnailUrl;
    final hasThumb = thumb != null && thumb.isNotEmpty;
    final digested = sl<PetStore>().state.hasEaten(note.id);
    const radius = BorderRadius.only(
      topLeft: Radius.circular(3),
      bottomLeft: Radius.circular(3),
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(8),
    );
    final window = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: hasThumb
          ? CachedNetworkImage(
              imageUrl: thumb,
              fit: BoxFit.cover,
              placeholder: (_, __) => ColoredBox(color: book.chip),
              errorWidget: (_, __, ___) => _Art(note: note, color: book),
            )
          : _Art(note: note, color: book),
    );

    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 6,
                offset: const Offset(3, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Container(
              decoration: BoxDecoration(
                // A touch of light from the left, so it reads as a board.
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(book.spine, Colors.white, 0.18)!,
                    book.spine,
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Spine(color: Color.lerp(book.spine, Colors.black, 0.14)!),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(5, 5, 6, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.75),
                                      width: 1.5,
                                    ),
                                  ),
                                  position: DecorationPosition.foreground,
                                  child: window,
                                ),
                                Positioned(
                                  left: 4,
                                  top: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          Colors.black.withValues(alpha: 0.45),
                                    ),
                                    child: Icon(
                                        SourceMeta.icon(note.sourceType),
                                        size: 9,
                                        color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.display(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: const Color(0xFF2A2520),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Opacity(
                                    opacity: digested ? 1 : 0.35,
                                    child: FoodIcon(
                                        kind: FoodKind.fromSource(
                                            note.sourceType),
                                        size: 13),
                                  ),
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
      ),
    );
  }
}

/// No picture: the dish this note is for the pet, on the tag's colour.
class _Art extends StatelessWidget {
  final NoteEntity note;
  final BookColor color;
  const _Art({required this.note, required this.color});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color.chip,
        child: Center(
          child: FoodIcon(kind: FoodKind.fromSource(note.sourceType), size: 30),
        ),
      );
}

/// The book's spine: a darker strip with two light bands near its ends.
class _Spine extends StatelessWidget {
  final Color color;
  const _Spine({required this.color});

  @override
  Widget build(BuildContext context) {
    final band = Colors.white.withValues(alpha: 0.4);
    return SizedBox(
      width: 9,
      child: ColoredBox(
        color: color,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(height: 1.5, color: band),
            const SizedBox(height: 3),
            Container(height: 1.5, color: band),
            const Spacer(),
            Container(height: 1.5, color: band),
            const SizedBox(height: 3),
            Container(height: 1.5, color: band),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
