import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../data/pet_store.dart';
import '../../domain/companion_style.dart';
import '../pet_labels.dart';
import '../../../../core/theme/app_fonts.dart';
import 'blob_mascot.dart';
import 'pet_host.dart';

/// Opens the wardrobe ("Lemari"): the pet's colour and what it has to
/// wear — the free accessories (each opening at a life stage), and the
/// premium accessories and outfits bought for it — with the pet up top.
/// Changes apply live: Beranda listens to the same [PetStore]. The rest is
/// in the boutique (`PetShopPage`, linked at the bottom). Its name and how
/// it's doing are in [showPetProfile].
Future<void> showPetWardrobe(BuildContext context) {
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
    builder: (_) => const PetWardrobeSheet(),
  );
}

class PetWardrobeSheet extends StatefulWidget {
  const PetWardrobeSheet({super.key});

  @override
  State<PetWardrobeSheet> createState() => _PetWardrobeSheetState();
}

class _PetWardrobeSheetState extends State<PetWardrobeSheet> {
  final _store = sl<PetStore>();

  /// A free accessory it hasn't grown into yet, just tapped.
  BlobAccessory? _lockedTapped;

  void _tapAccessory(BlobAccessory a) {
    if (!_store.canWearAccessory(a)) {
      setState(() => _lockedTapped = a);
      return;
    }
    setState(() => _lockedTapped = null);
    if (a != _store.accessory) SoundService.instance.play(Sfx.equip);
    _store.setAccessory(a);
    // A hat needs the hood down to show.
    if (a.onHead && _store.outfit.coversHead) {
      _store.setOutfit(BlobOutfit.none);
    }
  }

  void _tapOutfit(BlobOutfit o) {
    if (o != _store.outfit) SoundService.instance.play(Sfx.equip);
    _store.setOutfit(o);
  }

  void _openShop() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(Routes.shop);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final name = l10n.petName(_store);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The pet stays in sight while you scroll down to the outfits.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.surfaceStroke,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const PetHost(height: 96),
                  const SizedBox(height: 10),
                  Text(
                    l10n.petWardrobeTitle(name),
                    textAlign: TextAlign.center,
                    style: AppFonts.display(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.petWardrobeHint,
                    textAlign: TextAlign.center,
                    style: AppFonts.body(
                        fontSize: 13, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.petColorLabel} · ${l10n.colorLabel(_store.color).toUpperCase()}',
                      style: eyebrowStyle(context: context),
                    ),
                    const SizedBox(height: 12),
                    // Every colour on one line, sized to fit.
                    LayoutBuilder(builder: (context, c) {
                      final count = BlobColor.values.length;
                      final size = ((c.maxWidth - 8 * (count - 1)) / count)
                          .clamp(30.0, 44.0);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final c in BlobColor.values)
                            _ColorSwatch(
                              color: c,
                              size: size,
                              label: l10n.colorLabel(c),
                              selected: c == _store.color,
                              onTap: () {
                                if (c != _store.color) {
                                  SoundService.instance.play(Sfx.equip);
                                }
                                _store.setColor(c);
                              },
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 22),
                    Text(l10n.petAccessoryLabel,
                        style: eyebrowStyle(context: context)),
                    const SizedBox(height: 12),
                    _Grid(children: [
                      for (final a in BlobAccessory.values)
                        if (!a.premium || _store.owns(a.itemId))
                          _WardrobeTile(
                            label: l10n.accessoryLabel(a),
                            badge: _store.canWearAccessory(a)
                                ? null
                                : l10n.stageLabel(a.unlockStage),
                            selected: a == _store.accessory,
                            dim: !_store.canWearAccessory(a),
                            onTap: () => _tapAccessory(a),
                            preview: BlobMascot(
                              size: 38,
                              color: _store.color,
                              accessory: a,
                              interactive: false,
                              animate: false,
                            ),
                          ),
                    ]),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _lockedTapped == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded,
                                      size: 16, color: palette.textTertiary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l10n.petLocked(
                                          name,
                                          l10n.stageLabel(
                                              _lockedTapped!.unlockStage)),
                                      style: AppFonts.body(
                                        fontSize: 13,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 26),
                    Text(l10n.petOutfitLabel,
                        style: eyebrowStyle(context: context)),
                    const SizedBox(height: 12),
                    _Grid(children: [
                      for (final o in BlobOutfit.values)
                        if (_store.canWearOutfit(o))
                          _WardrobeTile(
                            label: l10n.outfitLabel(o),
                            selected: o == _store.outfit,
                            onTap: () => _tapOutfit(o),
                            preview: BlobMascot(
                              size: 38,
                              color: _store.color,
                              accessory: BlobAccessory.none,
                              outfit: o,
                              interactive: false,
                              animate: false,
                            ),
                          ),
                    ]),
                    const SizedBox(height: 18),
                    // More to wear is in the boutique.
                    SoftButton(
                      onTap: _openShop,
                      radius: 18,
                      shadow: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                        child: Row(
                          children: [
                            Icon(Icons.storefront_outlined,
                                size: 22, color: palette.accent),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.wardrobeShopCta,
                                style: AppFonts.body(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: palette.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Widget> children;
  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) => GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
        children: children,
      );
}

class _ColorSwatch extends StatelessWidget {
  final BlobColor color;
  final double size;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSwatch({
    required this.color,
    required this.size,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? context.palette.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                colors: [
                  Color.lerp(color.base, Colors.white, 0.3)!,
                  color.base,
                  color.shade,
                ],
                stops: const [0, 0.6, 1],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One thing in the wardrobe: the pet wearing it, its name, and — for a
/// free accessory it hasn't grown into yet — the stage it opens at.
class _WardrobeTile extends StatelessWidget {
  final Widget preview;
  final String label;
  final String? badge;
  final bool selected;
  final bool dim;
  final VoidCallback onTap;
  const _WardrobeTile({
    required this.preview,
    required this.label,
    required this.onTap,
    this.badge,
    this.selected = false,
    this.dim = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final on = selected;
    final edge = palette.primary;
    return Semantics(
      label: badge == null ? label : '$label, $badge',
      selected: on,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: on ? edge.withValues(alpha: 0.12) : palette.bgPrimary,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: on ? edge : palette.surfaceStroke,
              width: on ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: dim ? 0.4 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      preview,
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: palette.textPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: AppFonts.body(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: palette.bgSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
