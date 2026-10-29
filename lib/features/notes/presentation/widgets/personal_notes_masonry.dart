import 'package:flutter/material.dart';

import '../../domain/entities/personal_note.dart';
import 'personal_note_card.dart';

/// Two-column masonry layout — same packing strategy as Pinterest /
/// Google Keep. Cards keep their natural height; we just alternate
/// which column the next card lands in based on which column is
/// currently shorter (visually, by index parity since we don't
/// measure; the variable card heights take care of the rest).
///
/// Why not `flutter_staggered_grid_view`? We avoid the extra dep —
/// the layout we need is simple enough to handroll, and it lets the
/// list scroll lazily via `ListView.builder` rather than building a
/// CustomScrollView under the hood.
class PersonalNotesMasonry extends StatelessWidget {
  final List<PersonalNote> notes;
  final void Function(PersonalNote) onTap;
  final EdgeInsetsGeometry padding;
  const PersonalNotesMasonry({
    super.key,
    required this.notes,
    required this.onTap,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();

    // Split into two interleaved columns. Index parity is "good
    // enough" for personal-note volumes (<200 items) where adjacent
    // cards are usually similarly tall. For pathological cases the
    // user just sees a tiny gap at the bottom of one column, same as
    // Keep does.
    final left = <PersonalNote>[];
    final right = <PersonalNote>[];
    for (var i = 0; i < notes.length; i++) {
      (i.isEven ? left : right).add(notes[i]);
    }

    Widget column(List<PersonalNote> items) {
      return Column(
        children: [
          for (final n in items) ...[
            PersonalNoteCard(note: n, onTap: () => onTap(n)),
            // Room between the sticky notes for their tilt and pins.
            const SizedBox(height: 18),
          ],
        ],
      );
    }

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: column(left)),
          const SizedBox(width: 14),
          Expanded(child: column(right)),
        ],
      ),
    );
  }
}
