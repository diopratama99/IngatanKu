import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../data/pet_store.dart';
import '../pet_labels.dart';
import 'pet_host.dart';

/// Asks a new user what to call their pet, once, as they finish the
/// welcome story. The name is filled in and selected, so typing replaces
/// it and "Simpan" keeps it; swiping the sheet away keeps the default.
/// It can be changed any time from the pet's profile ([showPetProfile]).
Future<void> showPetNaming(BuildContext context) {
  SoundService.instance.play(Sfx.sheetOpen);
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _PetNamingSheet(),
  );
}

class _PetNamingSheet extends StatefulWidget {
  const _PetNamingSheet();

  @override
  State<_PetNamingSheet> createState() => _PetNamingSheetState();
}

class _PetNamingSheetState extends State<_PetNamingSheet> {
  final _store = sl<PetStore>();
  TextEditingController? _nameCtrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameCtrl != null) return;
    final name = AppLocalizations.of(context)!.petName(_store);
    _nameCtrl = TextEditingController(text: name)
      ..selection = TextSelection(baseOffset: 0, extentOffset: name.length);
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _store.setName(_nameCtrl!.text);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                        l10n.petNamingTitle,
                        style: AppFonts.display(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.petNamingBody,
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
              autofocus: true,
              maxLength: PetStore.maxNameLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.petDefaultName,
                counterText: '',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.petNamingSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
