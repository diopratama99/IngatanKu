import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../data/pet_store.dart';
import '../../domain/companion_style.dart';
import '../../domain/pet_state.dart';
import '../pet_labels.dart';
import 'pet_host.dart';
import 'pet_wardrobe_sheet.dart';

/// The pet's own page: its name (which you can change), how it's doing —
/// full, happy, growing towards its next stage — and its story so far.
/// Its looks live in the wardrobe ([showPetWardrobe]).
Future<void> showPetProfile(BuildContext context) {
  SoundService.instance.play(Sfx.sheetOpen);
  return showModalBottomSheet<void>(
    context: context,
    // Above the shell so the floating nav bar doesn't cover it.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _PetProfileSheet(),
  );
}

class _PetProfileSheet extends StatefulWidget {
  const _PetProfileSheet();

  @override
  State<_PetProfileSheet> createState() => _PetProfileSheetState();
}

class _PetProfileSheetState extends State<_PetProfileSheet> {
  final _store = sl<PetStore>();
  late final _nameCtrl = TextEditingController(text: _store.customName);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _moodLine(AppLocalizations l10n, PetState pet, DateTime now) {
    if (!pet.hatched) return l10n.petStatusEgg;
    return switch (pet.moodAt(now)) {
      CompanionMood.sleepy => l10n.petStatusResting,
      CompanionMood.hungry => l10n.petStatusHungry,
      CompanionMood.lonely => l10n.petStatusLonely,
      CompanionMood.happy => l10n.petStatusHappy,
      CompanionMood.content => l10n.petStatusReady,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final now = DateTime.now();
        final pet = _store.state;
        final stage = pet.stage;
        final name = l10n.petName(_store);
        final next = stage.next;
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.surfaceStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const PetHost(height: 76),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.display(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: palette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.stageLabel(stage),
                            style: AppFonts.body(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _moodLine(l10n, pet, now),
                            style: AppFonts.body(
                              fontSize: 13,
                              height: 1.35,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(l10n.petNameLabel, style: eyebrowStyle(context: context)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  maxLength: PetStore.maxNameLength,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: l10n.petDefaultName,
                    counterText: '',
                  ),
                  onChanged: _store.setName,
                ),
                if (pet.hatched) ...[
                  const SizedBox(height: 22),
                  Text(l10n.petVitalsLabel,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 12),
                  _Vital(
                    icon: Icons.restaurant_rounded,
                    label: l10n.petMeterFullness,
                    value: pet.fullnessAt(now) / 100,
                    color: palette.accent,
                  ),
                  const SizedBox(height: 12),
                  _Vital(
                    icon: Icons.favorite_rounded,
                    label: l10n.petMeterHappiness,
                    value: pet.happinessAt(now) / 100,
                    color: const Color(0xFFD9898C),
                  ),
                  const SizedBox(height: 12),
                  _Vital(
                    icon: Icons.spa_rounded,
                    label: l10n.petMeterGrowth,
                    value: stage.progress(pet.growth),
                    color: palette.primary,
                    warn: false,
                    note: next == null
                        ? l10n.petGrowthMax
                        : l10n.petGrowthNext(l10n.stageLabel(next)),
                  ),
                ],
                const SizedBox(height: 24),
                Text(l10n.petStatsLabel, style: eyebrowStyle(context: context)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _Stat(
                      label: l10n.petStatAge,
                      value: l10n.petStatDays(pet.ageDays(now)),
                    ),
                    _Stat(
                      label: l10n.petStatCare,
                      value: l10n.petStatDays(pet.careStreakAt(now)),
                      semantics:
                          l10n.petStatCareSemantics(pet.careStreakAt(now)),
                    ),
                    _Stat(
                      label: l10n.petStatDigested,
                      value: '${pet.notesEaten}',
                    ),
                    _Stat(
                      label: l10n.petStatPets,
                      value: '${pet.petCount}',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Its looks are one tap away.
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      final root =
                          Navigator.of(context, rootNavigator: true).context;
                      Navigator.of(context).pop();
                      showPetWardrobe(root);
                    },
                    icon: const Icon(Icons.checkroom_rounded, size: 18),
                    label: Text(l10n.homeActionWardrobe),
                    style: TextButton.styleFrom(
                      foregroundColor: palette.textPrimary,
                      textStyle: AppFonts.body(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One of the pet's needs: icon, name, a bar and the percentage — red when
/// it's running low (unless [warn] is off). [note] goes under the bar.
class _Vital extends StatelessWidget {
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool warn;
  final String? note;
  const _Vital({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.warn = true,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final v = value.clamp(0.0, 1.0);
    final c = warn && v < 0.25 ? palette.danger : color;
    final percent = '${(v * 100).round()}%';
    return Semantics(
      label: '$label $percent${note == null ? '' : ', $note'}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.withValues(alpha: 0.14),
            ),
            child: Icon(icon, size: 16, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppFonts.body(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      percent,
                      style: AppFonts.body(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 6,
                    backgroundColor: palette.bgTertiary,
                    valueColor: AlwaysStoppedAnimation(c),
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note!,
                    style: AppFonts.body(
                        fontSize: 12, color: palette.textTertiary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? semantics;
  const _Stat({required this.label, required this.value, this.semantics});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Expanded(
      child: Semantics(
        label: semantics,
        excludeSemantics: semantics != null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppFonts.display(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: eyebrowStyle(context: context).copyWith(fontSize: 9.5)),
          ],
        ),
      ),
    );
  }
}
