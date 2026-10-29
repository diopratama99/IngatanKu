import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../bloc/personal_notes_bloc.dart';
import '../widgets/notes_board.dart';
import '../widgets/personal_notes_masonry.dart';
import '../../../companion/presentation/widgets/pet_activities.dart';
import '../../../../core/theme/app_fonts.dart';

/// Catatan tab — a scratchpad for free-form notes (not anchored to a URL
/// like Brankas), stuck up as sticky notes on a pegboard. Pinned notes
/// go on top under a "TERSEMAT" label; the rest under "LAINNYA".
class PersonalNotesPage extends StatefulWidget {
  const PersonalNotesPage({super.key});

  @override
  State<PersonalNotesPage> createState() => _PersonalNotesPageState();
}

class _PersonalNotesPageState extends State<PersonalNotesPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matches(dynamic note, String q) {
    if (q.isEmpty) return true;
    final hay =
        '${note.title ?? ''} ${note.body} ${note.tags.join(' ')}'.toLowerCase();
    return hay.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<PersonalNotesBloc, PersonalNotesState>(
          builder: (_, state) {
            final total = state is PersonalNotesLoaded ? state.notes.length : 0;
            final header = <Widget>[
              const SizedBox(height: 22),
              Center(child: SpacedTitle(l10n.navNotes)),
              const SizedBox(height: 4),
              // The pet at its desk, scribbling away.
              PetWritingDesk(
                lines: total == 0
                    ? [l10n.notesPetEmpty]
                    : [l10n.notesPetWriting(total), l10n.notesPetCopying],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _SearchField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(height: 16),
            ];
            final body = <Widget>[];
            if (state is PersonalNotesLoading ||
                state is PersonalNotesInitial) {
              body.add(Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: context.palette.primary,
                    strokeWidth: 2,
                  ),
                ),
              ));
            } else if (state is PersonalNotesError) {
              body.add(Padding(
                padding: const EdgeInsets.all(24),
                child:
                    Text(state.message, style: context.textStyles.bodyMedium),
              ));
            } else if (state is PersonalNotesLoaded) {
              final pinned =
                  state.pinned.where((n) => _matches(n, _query)).toList();
              final others =
                  state.others.where((n) => _matches(n, _query)).toList();
              if (pinned.isEmpty && others.isEmpty) {
                body.add(_EmptyState(query: _query));
              } else {
                // Your notes, stuck up on the pegboard: pinned ones on
                // top, each group under its own little label.
                body.add(NotesBoard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (pinned.isNotEmpty) ...[
                        BoardLabel(l10n.personalNotesPinnedEyebrow),
                        const SizedBox(height: 18),
                        PersonalNotesMasonry(
                          notes: pinned,
                          onTap: (n) =>
                              context.push(Routes.notesEdit, extra: n),
                        ),
                      ],
                      if (others.isNotEmpty) ...[
                        if (pinned.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          BoardLabel(l10n.personalNotesOthersEyebrow),
                          const SizedBox(height: 18),
                        ],
                        PersonalNotesMasonry(
                          notes: others,
                          onTap: (n) =>
                              context.push(Routes.notesEdit, extra: n),
                        ),
                      ],
                    ],
                  ),
                ));
              }
            }
            return RefreshIndicator(
              color: context.palette.primary,
              onRefresh: () async => context
                  .read<PersonalNotesBloc>()
                  .add(const PersonalNotesLoadRequested(fetch: true)),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                    16, 0, 16, 40 + kEditorialNavBarOverlay),
                children: [...header, ...body],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-personal-note-fab',
        onPressed: () => context.push(Routes.notesNew),
        // Colours from the theme: warm brown on cream, like the nav bar.
        icon: const Icon(Icons.edit_outlined),
        label: Text(l10n.personalNotesFabNew),
      ),
      // Sits above the floating nav bar, or right on the keyboard while
      // the bar is hidden for typing.
      // (Both const, so a rebuild doesn't look like a move to the Scaffold.)
      floatingActionButtonLocation: MediaQuery.viewInsetsOf(context).bottom > 0
          ? const _LiftedFabLocation(FloatingActionButtonLocation.endFloat, 0)
          : const _LiftedFabLocation(
              FloatingActionButtonLocation.endFloat,
              kEditorialNavBarOverlay,
            ),
    );
  }
}

class _LiftedFabLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation base;
  final double lift;
  const _LiftedFabLocation(this.base, this.lift);
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final offset = base.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy - lift);
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 50,
      decoration: softCard(context, radius: 25),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search_rounded,
                size: 18, color: context.palette.textTertiary),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l10n.personalNotesSearchHint,
                hintStyle: AppFonts.body(
                  color: context.palette.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
              ),
              style: AppFonts.body(
                fontSize: 14,
                color: context.palette.textPrimary,
              ),
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
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            query.isEmpty
                ? l10n.personalNotesEmptyEyebrow
                : l10n.personalNotesNotFoundEyebrow,
            style: eyebrowStyle(context: context),
          ),
          const SizedBox(height: 12),
          Text(
            query.isEmpty
                ? l10n.personalNotesEmptyTitle
                : l10n.personalNotesNotFoundTitle(query),
            style: pageTitleStyle(context: context, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            query.isEmpty
                ? l10n.personalNotesEmptyMessage
                : l10n.personalNotesNotFoundMessage,
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
