import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';

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
            hintText: 'Tambahkan tag, tekan enter',
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
            'SARAN',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.textTertiary,
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

class _SelectedTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  const _SelectedTagChip({required this.label, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close_rounded,
                  size: 14, color: AppColors.textSecondary),
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surfaceStroke),
        ),
        child: Text(
          '+ $label',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
