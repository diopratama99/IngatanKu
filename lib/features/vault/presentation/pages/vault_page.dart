import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/shimmer_loader.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/book_colors.dart';
import '../widgets/vault_shelf_view.dart';
import '../widgets/vault_note_row.dart';
import '../../../companion/presentation/widgets/pet_activities.dart';

/// Layout mode for the Pustaka page. Persists across launches via
/// SharedPreferences so the user only picks once.
enum _VaultLayout {
  list, // grouped cards
  grid, // Instagram-Explore-style mosaic
}

/// Pustaka — the pet's reading room: the pet reading your latest find,
/// then search, collections (top tags) and notes grouped by day, all in
/// one scroll.
class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  static const _layoutPrefKey = 'vault_layout_mode';

  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _tag;
  _VaultLayout _layout = _VaultLayout.list;

  @override
  void initState() {
    super.initState();
    context.read<VaultBloc>().add(const VaultLoadRequested());
    _loadLayoutPref();
  }

  Future<void> _loadLayoutPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_layoutPrefKey);
      if (raw == null || !mounted) return;
      final next = _VaultLayout.values.firstWhere(
        (l) => l.name == raw,
        orElse: () => _VaultLayout.list,
      );
      if (next != _layout) setState(() => _layout = next);
    } catch (_) {/* fall back to default */}
  }

  Future<void> _toggleLayout() async {
    final next =
        _layout == _VaultLayout.list ? _VaultLayout.grid : _VaultLayout.list;
    setState(() => _layout = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_layoutPrefKey, next.name);
    } catch (_) {/* not fatal — preference just won't persist */}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<NoteEntity> _filter(List<NoteEntity> notes) => notes.where((n) {
        if (_tag != null && !n.tags.contains(_tag)) return false;
        if (_query.isEmpty) return true;
        return n.title?.toLowerCase().contains(_query) == true ||
            n.manualNotes.toLowerCase().contains(_query) ||
            n.tags.any((t) => t.toLowerCase().contains(_query));
      }).toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    // Read above the Scaffold: inside its body the keyboard inset is
    // already taken out.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    // The reading nook gives up some height on short screens, so the list
    // below still has room.
    final nookHeight =
        (MediaQuery.sizeOf(context).height * 0.24).clamp(150.0, 220.0);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<VaultBloc, VaultState>(
          builder: (_, state) {
            final all =
                state is VaultLoaded ? state.notes : const <NoteEntity>[];
            final notes = _filter(all);
            final latest = all.isEmpty ? null : all.first;
            // Everything above the list stays put; only the notes scroll.
            final header = <Widget>[
              // The pet in its reading nook, reading your latest find. It
              // steps aside while you type a search, so results have room.
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: keyboard
                    ? const SizedBox(width: double.infinity)
                    : PetReadingNook(
                        height: nookHeight,
                        lines: all.isEmpty
                            ? [l10n.libraryPetEmpty]
                            : [
                                l10n.libraryPetCount(all.length),
                                l10n.libraryPetReading(_shortTitle(latest!)),
                              ],
                      ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _SearchPill(
                        controller: _searchCtrl,
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SoftButton(
                      onTap: _toggleLayout,
                      shape: BoxShape.circle,
                      child: Tooltip(
                        message: _layout == _VaultLayout.list
                            ? l10n.vaultLayoutGridTooltip
                            : l10n.vaultLayoutListTooltip,
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(
                            _layout == _VaultLayout.list
                                ? Icons.shelves
                                : Icons.view_agenda_outlined,
                            size: 20,
                            color: palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Collections(
                notes: all,
                selected: _tag,
                onSelect: (t) => setState(() => _tag = t),
              ),
              const SizedBox(height: 4),
            ];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 22),
                Center(child: SpacedTitle(l10n.navLibrary)),
                const SizedBox(height: 4),
                ...header,
                Expanded(child: _body(context, state, notes)),
              ],
            );
          },
        ),
      ),
    );
  }

  String _shortTitle(NoteEntity n) {
    final t = n.title?.trim();
    final s =
        (t == null || t.isEmpty) ? (Uri.tryParse(n.url)?.host ?? n.url) : t;
    return s.length > 34 ? '${s.substring(0, 33)}…' : s;
  }

  Widget _body(BuildContext context, VaultState state, List<NoteEntity> notes) {
    Future<void> refresh() async =>
        context.read<VaultBloc>().add(const VaultLoadRequested(fetch: true));
    void open(NoteEntity n) => context.push('/vault/${n.id}', extra: n);
    // Notes slip softly under the fixed part above as they scroll.
    Widget fadeTop(Widget child) => ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black],
            stops: [0, 0.035],
          ).createShader(r),
          child: child,
        );
    Widget list(List<Widget> items) => fadeTop(RefreshIndicator(
          color: context.palette.textPrimary,
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
                top: 6, bottom: 40 + kEditorialNavBarOverlay),
            children: items,
          ),
        ));

    if (state is VaultLoading || state is VaultInitial) {
      return list([_LoadingSkeleton(layout: _layout)]);
    }
    if (state is VaultError) {
      return list([
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(state.message, style: context.textStyles.bodyMedium),
        ),
      ]);
    }
    if (notes.isEmpty) return list([_EmptyState(query: _query)]);

    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    String group(NoteEntity n) {
      final d = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      final days = today.difference(d).inDays;
      if (days <= 0) return l10n.vaultGroupToday;
      if (days == 1) return l10n.vaultGroupYesterday;
      if (days < 7) return l10n.vaultGroupWeek;
      return l10n.vaultGroupOlder;
    }

    // The shelf view: books on wooden shelves, grouped the same way.
    if (_layout == _VaultLayout.grid) {
      final groups = <(String, List<NoteEntity>)>[];
      for (final n in notes) {
        final g = group(n);
        if (groups.isEmpty || groups.last.$1 != g) groups.add((g, []));
        groups.last.$2.add(n);
      }
      return fadeTop(VaultShelfView(
        groups: groups,
        groupHeader: (label, count) => _GroupHeader(label: label, count: count),
        onTap: open,
        onRefresh: refresh,
        padding:
            const EdgeInsets.only(top: 6, bottom: 40 + kEditorialNavBarOverlay),
      ));
    }

    final items = <Widget>[];
    String? current;
    for (final n in notes) {
      final g = group(n);
      if (g != current) {
        current = g;
        final count = notes.where((x) => group(x) == g).length;
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: _GroupHeader(label: g, count: count),
        ));
      }
      items.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: VaultNoteRow(note: n, onTap: () => open(n)),
      ));
    }
    return list(items);
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _GroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Text(
          label,
          style: AppFonts.body(fontSize: 12.5, color: palette.textSecondary),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: AppFonts.body(fontSize: 12, color: palette.textTertiary),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: palette.surfaceStroke)),
      ],
    );
  }
}

/// "All" plus the most-used tags, as a row of slim book-spine pills.
class _Collections extends StatelessWidget {
  final List<NoteEntity> notes;
  final String? selected;
  final ValueChanged<String?> onSelect;
  const _Collections({
    required this.notes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = <String, int>{};
    for (final n in notes) {
      for (final t in n.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final tags = (counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(8)
        .toList();
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        children: [
          _SpinePill(
            label: l10n.vaultAll,
            count: notes.length,
            color: BookColor.all(),
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final t in tags)
            _SpinePill(
              label: '#${t.key}',
              count: t.value,
              color: BookColor.of(t.key),
              selected: selected == t.key,
              onTap: () => onSelect(selected == t.key ? null : t.key),
            ),
        ],
      ),
    );
  }
}

/// One collection filter: a slim pill with its book colour as a spine on
/// the left, the name, and how many notes it holds. Filled with its colour
/// while selected.
class _SpinePill extends StatelessWidget {
  final String label;
  final int count;
  final BookColor color;
  final bool selected;
  final VoidCallback onTap;
  const _SpinePill({
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
                // The spine, with a band near each end.
                Container(
                  width: 6,
                  color: color.spine,
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      Container(
                          height: 1.2,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const Spacer(),
                      Container(
                          height: 1.2,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(height: 6),
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

class _SearchPill extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchPill({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Container(
      height: 50,
      decoration: softCard(context, radius: 25),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search_rounded,
                size: 20, color: palette.textSecondary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.vaultSearchHint,
                hintStyle:
                    AppFonts.body(color: palette.textTertiary, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: AppFonts.body(fontSize: 14, color: palette.textPrimary),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            query.isEmpty ? l10n.vaultEmptyEyebrow : l10n.vaultNotFoundEyebrow,
            style: eyebrowStyle(context: context),
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty
                ? l10n.vaultEmptyTitle
                : l10n.vaultNotFoundTitle(query),
            style: pageTitleStyle(context: context, size: 34),
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty ? l10n.vaultEmptyMessage : l10n.vaultNotFoundMessage,
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Loading skeleton matched to the active layout so the page doesn't jump
/// between modes once data loads.
class _LoadingSkeleton extends StatelessWidget {
  final _VaultLayout layout;
  const _LoadingSkeleton({required this.layout});

  @override
  Widget build(BuildContext context) {
    if (layout == _VaultLayout.grid) {
      // Shelves of faint book shapes.
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: [
            for (var row = 0; row < 2; row++) ...[
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 14),
                    const Expanded(child: ShimmerBox(height: 140, radius: 8)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              const ShimmerBox(height: 12, radius: 6),
              const SizedBox(height: 24),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: ShimmerBox(height: 120, radius: 18),
            ),
        ],
      ),
    );
  }
}
