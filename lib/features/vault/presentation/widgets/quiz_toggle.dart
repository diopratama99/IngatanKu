import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/widgets/food_painter.dart';

/// Whether the quizzes may ask about a note: a card you tap to switch it.
/// On, the pet's onigiri (the daily quiz is its meal) shows; off, it fades
/// and the note just stays saved — for a comic or book title, say.
class QuizToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const QuizToggle({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Semantics(
      toggled: value,
      child: SoftButton(
        onTap: () => onChanged(!value),
        radius: 18,
        shadow: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              AnimatedOpacity(
                opacity: value ? 1 : 0.35,
                duration: const Duration(milliseconds: 180),
                child: const FoodIcon(kind: FoodKind.onigiri, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.quizToggleTitle,
                      style: AppFonts.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value ? l10n.quizToggleOn : l10n.quizToggleOff,
                      style: AppFonts.body(
                        fontSize: 12.5,
                        height: 1.4,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Pill(on: value),
            ],
          ),
        ),
      ),
    );
  }
}

/// The on/off pill at the card's end.
class _Pill extends StatelessWidget {
  final bool on;
  const _Pill({required this.on});

  static const _move = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedContainer(
      duration: _move,
      curve: Curves.easeOut,
      width: 46,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? palette.primary : palette.bgTertiary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: on ? palette.primary : palette.surfaceStroke),
      ),
      child: AnimatedAlign(
        duration: _move,
        curve: Curves.easeOut,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: on ? palette.onPrimary : palette.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
