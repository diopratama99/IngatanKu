import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../data/pet_store.dart';
import '../pet_labels.dart';
import '../../../notes/presentation/widgets/note_paper.dart';
import 'pet_host.dart';
import 'pet_profile_sheet.dart';
import 'pet_wardrobe_sheet.dart';

/// The pet's card on the profile tab: who it is, how it's doing (these
/// replace the old level / streak numbers) and a way into its wardrobe.
/// Tap the card for the pet's full profile.
class PetRoomCard extends StatelessWidget {
  const PetRoomCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = sl<PetStore>();
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final pet = store.state;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showPetProfile(context),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
            decoration: notePaperDecoration(context),
            child: Column(
              children: [
                Row(
                  children: [
                    // Sitting in a card: only small, quiet moves.
                    const PetHost(height: 64, calm: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profileRoomTitle(l10n.petName(store)),
                            style: AppFonts.display(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.stageLabel(pet.stage),
                            style: AppFonts.body(
                              fontSize: 12.5,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => showPetWardrobe(context),
                      icon: const Icon(Icons.checkroom_rounded, size: 18),
                      label: Text(l10n.homeActionWardrobe),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.textPrimary,
                        textStyle: AppFonts.body(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ThinDivider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Stat(
                      value: l10n.petStatDays(pet.ageDays(now)),
                      label: l10n.petStatAge,
                    ),
                    _Stat(
                      value: l10n.petStatDays(pet.careStreakAt(now)),
                      label: l10n.petStatCare,
                    ),
                    _Stat(
                      value: '${pet.notesEaten}',
                      label: l10n.petStatDigested,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppFonts.display(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: eyebrowStyle(context: context).copyWith(fontSize: 9.5)),
        ],
      ),
    );
  }
}
