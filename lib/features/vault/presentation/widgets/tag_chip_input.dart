import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_fonts.dart';
import 'book_colors.dart';

class TagChipInput extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  const TagChipInput({super.key, required this.tags, required this.onChanged});

  @override
  State<TagChipInput> createState() => _TagChipInputState();
}

class _TagChipInputState extends State<TagChipInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final v = raw.trim().toLowerCase().replaceAll('#', '');
    if (v.isEmpty || widget.tags.contains(v)) {
      _controller.clear();
      return;
    }
    widget.onChanged([...widget.tags, v]);
    _controller.clear();
  }

  void _remove(String tag) {
    widget.onChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final suggestions = AppConstants.suggestedTags
        .where((s) => !widget.tags.contains(s))
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          onSubmitted: _add,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.tagChipHint,
            prefixIcon: const Icon(Icons.tag, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              onPressed: () => _add(_controller.text),
            ),
          ),
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags
                .map((t) => _SelectedTagChip(
                      label: '#$t',
                      onDeleted: () => _remove(t),
                    ))
                .toList(),
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            l10n.tagChipSuggestionsLabel,
            style: AppFonts.body(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: context.palette.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((s) => _SuggestedTagChip(
                      label: s,
                      onPressed: () => _add(s),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

/// A tag you've added, in its book colour (the same one its notes wear
/// on the shelves in Pustaka).
class _SelectedTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  const _SelectedTagChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final c = BookColor.of(label.replaceFirst('#', ''));
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
      decoration: BoxDecoration(
        color: c.chip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.spine),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.body(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(width: 2),
          InkResponse(
            onTap: onDeleted,
            radius: 14,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.close_rounded,
                  size: 15, color: c.ink.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestedTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _SuggestedTagChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      shape: StadiumBorder(side: BorderSide(color: palette.surfaceStroke)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 6, 12, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: palette.textTertiary),
              const SizedBox(width: 3),
              Text(
                label,
                style: AppFonts.body(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
