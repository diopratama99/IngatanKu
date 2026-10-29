import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../vault/presentation/widgets/book_colors.dart';
import '../../data/pet_store.dart';
import '../../domain/companion_style.dart';
import '../pet_labels.dart';
import '../widgets/blob_mascot.dart';
import '../widgets/pet_activities.dart';

/// The boutique ("Butik"): the premium accessories and outfits. Up top
/// is its fitting corner, where the pet tries on whatever you tap; below,
/// the stock in sections. Buying comes later; what's been bought already
/// ([PetStore.owned]) can be put on from here or from the wardrobe
/// (`showPetWardrobe`).
class PetShopPage extends StatefulWidget {
  const PetShopPage({super.key});

  @override
  State<PetShopPage> createState() => _PetShopPageState();
}

/// The boutique's sections, each with a fabric colour (the library's book
/// colours, so the app keeps one palette).
enum _Shelf {
  all(null),
  hats(BookColor(Color(0xFFD9B88A), Color(0xFFF1E5D2), Color(0xFF75582F))),
  everyday(BookColor(Color(0xFF8DB8E6), Color(0xFFDCE9F7), Color(0xFF365F8C))),
  costume(BookColor(Color(0xFF8FC4A0), Color(0xFFDCEDE1), Color(0xFF3A6B4A))),
  seasonal(BookColor(Color(0xFFEE9F98), Color(0xFFF8DEDB), Color(0xFF9C433C)));

  final BookColor? _color;
  const _Shelf(this._color);
  BookColor get color => _color ?? BookColor.all();
}

/// Something for sale: a hat (or other accessory), or an outfit.
class _Item {
  const _Item.hat(BlobAccessory this.accessory) : outfit = null;
  const _Item.outfit(BlobOutfit this.outfit) : accessory = null;

  final BlobAccessory? accessory;
  final BlobOutfit? outfit;

  _Shelf get shelf {
    final a = accessory;
    if (a != null) return a.seasonal ? _Shelf.seasonal : _Shelf.hats;
    return switch (outfit!.group) {
      OutfitGroup.everyday => _Shelf.everyday,
      OutfitGroup.costume => _Shelf.costume,
      OutfitGroup.seasonal => _Shelf.seasonal,
    };
  }

  String label(AppLocalizations l10n) => accessory != null
      ? l10n.accessoryLabel(accessory!)
      : l10n.outfitLabel(outfit!);

  String get itemId => accessory?.itemId ?? outfit!.itemId;

  @override
  bool operator ==(Object other) =>
      other is _Item && other.accessory == accessory && other.outfit == outfit;

  @override
  int get hashCode => Object.hash(accessory, outfit);
}

/// Everything in the boutique: the premium things.
final _stock = [
  for (final a in BlobAccessory.values)
    if (a.premium) _Item.hat(a),
  for (final o in BlobOutfit.values)
    if (o.premium) _Item.outfit(o),
];

class _PetShopPageState extends State<PetShopPage> {
  final _store = sl<PetStore>();
  var _shelf = _Shelf.all;

  /// On for a try (not kept). Null: what it's wearing anyway.
  BlobAccessory? _hat;
  BlobOutfit? _outfit;

  /// The one shown in the bar at the bottom.
  _Item? _focus;

  bool _tried(_Item item) =>
      item.accessory != null ? _hat == item.accessory : _outfit == item.outfit;

  void _try(_Item item) {
    final on = !_tried(item);
    if (on) SoundService.instance.play(Sfx.equip);
    setState(() {
      if (item.accessory != null) {
        _hat = on ? item.accessory : null;
        // A hat needs the hood down to show.
        if (on && (_outfit?.coversHead ?? false)) _outfit = null;
      } else {
        _outfit = on ? item.outfit : null;
      }
      _focus = on ? item : _stillOn();
    });
  }

  /// Puts on something it owns, for real.
  void _wear(_Item item) {
    SoundService.instance.play(Sfx.equip);
    final a = item.accessory;
    if (a != null) {
      _store.setAccessory(a);
      // A hat needs the hood down to show.
      if (a.onHead && _store.outfit.coversHead) {
        _store.setOutfit(BlobOutfit.none);
      }
    } else {
      _store.setOutfit(item.outfit!);
    }
  }

  bool _wearing(_Item item) => item.accessory != null
      ? _store.accessory == item.accessory
      : _store.outfit == item.outfit;

  void _takeOff(_Item item) {
    setState(() {
      if (item.accessory != null) {
        _hat = null;
      } else {
        _outfit = null;
      }
      _focus = _stillOn();
    });
  }

  /// Whatever's still on after taking something off.
  _Item? _stillOn() => _outfit != null
      ? _Item.outfit(_outfit!)
      : _hat != null
          ? _Item.hat(_hat!)
          : null;

  String _shelfLabel(AppLocalizations l10n, _Shelf s) => switch (s) {
        _Shelf.all => l10n.shopShelfAll,
        _Shelf.hats => l10n.shopShelfHats,
        _Shelf.everyday => l10n.outfitGroupLabel(OutfitGroup.everyday),
        _Shelf.costume => l10n.outfitGroupLabel(OutfitGroup.costume),
        _Shelf.seasonal => l10n.outfitGroupLabel(OutfitGroup.seasonal),
      };

  List<_Item> _on(_Shelf s) => [
        for (final item in _stock)
          if (s == _Shelf.all || item.shelf == s) item,
      ];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _store,
        builder: (context, _) => _build(context),
      );

  Widget _build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final shelves = _shelf == _Shelf.all
        ? _Shelf.values.where((s) => s != _Shelf.all)
        : [_shelf];
    final focus = _focus;
    // Trying a hat on over a hood it's wearing: the hood comes down.
    final outfit = _outfit ??
        ((_hat?.onHead ?? false) && _store.outfit.coversHead
            ? BlobOutfit.none
            : null);
    return Scaffold(
      backgroundColor: palette.bgPrimary,
      appBar: PageTopBar(title: l10n.shopTitle),
      body: Column(
        children: [
          // The fitting corner stays in sight while the stock scrolls.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: PetFittingRoom(accessory: _hat, outfit: outfit),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
              children: [
                for (final s in _Shelf.values)
                  _ShelfPill(
                    label: _shelfLabel(l10n, s),
                    count: _on(s).length,
                    color: s.color,
                    selected: s == _shelf,
                    onTap: () => setState(() => _shelf = s),
                  ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                for (final s in shelves) ...[
                  if (_shelf == _Shelf.all)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(
                            label: _shelfLabel(l10n, s).toUpperCase()),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        20, _shelf == _Shelf.all ? 0 : 14, 20, 0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildListDelegate([
                        for (final item in _on(s))
                          _ItemTile(
                            item: item,
                            color: _store.color,
                            tried: _tried(item),
                            owned: _store.owns(item.itemId),
                            onTap: () => _try(item),
                          ),
                      ]),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: focus == null
            ? const SizedBox(width: double.infinity)
            : _TryOnBar(
                label: focus.label(l10n),
                owned: _store.owns(focus.itemId),
                wearing: _wearing(focus),
                onWear: () => _wear(focus),
                onTakeOff: () => _takeOff(focus),
              ),
      ),
    );
  }
}

/// One section: a slim pill with its fabric colour on the left, its name,
/// and how much hangs there. Filled with its colour while selected (like
/// Pustaka's collections).
class _ShelfPill extends StatelessWidget {
  final String label;
  final int count;
  final BookColor color;
  final bool selected;
  final VoidCallback onTap;
  const _ShelfPill({
    required this.label,
    required this.count,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? color.chip : palette.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? color.spine : palette.surfaceStroke,
                width: selected ? 1.4 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A swatch of the fabric, its weave in faint lines.
                Container(
                  width: 6,
                  color: color.spine,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(height: 4),
                        Container(
                            height: 1.2,
                            color: Colors.white.withValues(alpha: 0.45)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: AppFonts.body(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? color.ink : palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? palette.surface.withValues(alpha: 0.7)
                        : color.chip,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    '$count',
                    style: AppFonts.body(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One thing for sale: the pet wearing it on its section's colour, its
/// name, and that it's premium — or already [owned].
class _ItemTile extends StatelessWidget {
  final _Item item;
  final BlobColor color;
  final bool tried;
  final bool owned;
  final VoidCallback onTap;
  const _ItemTile({
    required this.item,
    required this.color,
    required this.tried,
    required this.owned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final label = item.label(l10n);
    final meta = owned ? l10n.shopOwned : l10n.petPremiumBadge;
    return Semantics(
      button: true,
      selected: tried,
      label: '$label, $meta',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: softCard(context, radius: 20).copyWith(
            border: Border.all(
              color: tried ? palette.primary : palette.surfaceStroke,
              width: tried ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.shelf.color.chip.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Its body about half the swatch's height, standing
                      // near the bottom (room above for a tall hat).
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, c) => Padding(
                            padding:
                                EdgeInsets.only(bottom: c.maxHeight * 0.08),
                            child: OverflowBox(
                              alignment: Alignment.bottomCenter,
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: BlobMascot(
                                size: c.maxHeight * 0.52 / 0.74,
                                color: color,
                                accessory: item.accessory ?? BlobAccessory.none,
                                outfit: item.outfit ?? BlobOutfit.none,
                                interactive: false,
                                animate: false,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (tried)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.check_rounded,
                                size: 15, color: palette.onPrimary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                            owned
                                ? Icons.check_circle_rounded
                                : Icons.auto_awesome_rounded,
                            size: 12,
                            color: owned ? palette.primary : palette.accent),
                        const SizedBox(width: 4),
                        Text(
                          meta,
                          style: AppFonts.body(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: palette.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// While something's on: its name, that it'll be for sale soon (or that
/// it's [owned], with a way to put it on for real), and a way to take it
/// off.
class _TryOnBar extends StatelessWidget {
  final String label;
  final bool owned;
  final bool wearing;
  final VoidCallback onWear;
  final VoidCallback onTakeOff;
  const _TryOnBar({
    required this.label,
    required this.owned,
    required this.wearing,
    required this.onWear,
    required this.onTakeOff,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: softCard(context, radius: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                          owned
                              ? Icons.check_circle_outline_rounded
                              : Icons.shopping_bag_outlined,
                          size: 14,
                          color: palette.textTertiary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          !owned
                              ? l10n.shopBarSoon
                              : wearing
                                  ? l10n.shopWearing
                                  : l10n.shopOwned,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.body(
                              fontSize: 12, color: palette.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onTakeOff,
              style:
                  TextButton.styleFrom(foregroundColor: palette.textSecondary),
              child: Text(l10n.shopTakeOff),
            ),
            if (owned && !wearing) ...[
              const SizedBox(width: 4),
              FilledButton(
                onPressed: onWear,
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  minimumSize: const Size(0, 40),
                ),
                child: Text(l10n.shopWear),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
