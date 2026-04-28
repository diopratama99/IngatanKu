import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Compact chip that toggles between Bahasa Indonesia (`id_ID`) and
/// English (`en_US`) for voice input. Tap to switch.
class LocaleToggleChip extends StatelessWidget {
  final String localeId;
  final ValueChanged<String> onChanged;

  const LocaleToggleChip({
    super.key,
    required this.localeId,
    required this.onChanged,
  });

  bool get _isId => localeId.toLowerCase().startsWith('id');

  @override
  Widget build(BuildContext context) {
    final label = _isId ? 'ID' : 'EN';
    final next = _isId ? 'en_US' : 'id_ID';
    return Tooltip(
      message: _isId
          ? 'Bahasa Indonesia · ketuk untuk EN'
          : 'English · ketuk untuk ID',
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onChanged(next),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
