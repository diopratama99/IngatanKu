import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/update_note.dart';
import '../bloc/vault_bloc.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/presentation/widgets/pet_host.dart';
import '../widgets/book_colors.dart';

/// Tag-management page accessed from the dashboard "Tag teratas" card.
/// Lists every tag the user has used (with note count) and lets them rename
/// or delete each one. Renames/deletes loop through the affected notes and
/// dispatch [VaultNoteUpdated] for each, so the regular Bloc flow handles
/// optimistic updates and error reporting.
class TagsPage extends StatefulWidget {
  const TagsPage({super.key});

  @override
  State<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends State<TagsPage> {
  @override
  void initState() {
    super.initState();
    final state = context.read<VaultBloc>().state;
    if (state is! VaultLoaded) {
      context.read<VaultBloc>().add(const VaultLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: PageTopBar(title: l10n.tagsPageEyebrow),
      body: SafeArea(
        child: BlocBuilder<VaultBloc, VaultState>(
          builder: (_, state) {
            if (state is VaultLoading || state is VaultInitial) {
              return Center(
                  child: CircularProgressIndicator(
                color: context.palette.primary,
                strokeWidth: 2,
              ));
            }
            if (state is VaultError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child:
                      Text(state.message, style: context.textStyles.bodyMedium),
                ),
              );
            }
            final notes = state is VaultLoaded ? state.notes : <NoteEntity>[];
            final counter = <String, int>{};
            for (final n in notes) {
              for (final t in n.tags) {
                counter[t] = (counter[t] ?? 0) + 1;
              }
            }
            if (counter.isEmpty) return const _EmptyTags();
            final entries = counter.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
              children: [
                Text(l10n.tagsPageTitle,
                    style: pageTitleStyle(context: context, size: 36)),
                const SizedBox(height: 4),
                Text(
                  l10n.tagsPageSummary(entries.length, notes.length),
                  style: AppFonts.body(
                    fontSize: 13,
                    color: context.palette.textTertiary,
                  ),
                ),
                const SizedBox(height: 24),
                // The tags as a row of books, each in its colour from the
                // shelves in Pustaka.
                Container(
                  decoration: softCard(context, radius: 22),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: List.generate(entries.length, (i) {
                      final tag = entries[i].key;
                      final count = entries[i].value;
                      return Column(
                        children: [
                          _TagRow(
                            tag: tag,
                            count: count,
                            onRename: () => _renameTag(tag, notes),
                            onDelete: () => _deleteTag(tag, notes),
                          ),
                          if (i != entries.length - 1)
                            const Padding(
                              padding: EdgeInsets.only(left: 40),
                              child: ThinDivider(),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _renameTag(String oldTag, List<NoteEntity> notes) async {
    // Grab the bloc up-front so we don't have to use `context` after the
    // dialog `await` (silences `use_build_context_synchronously`).
    final bloc = context.read<VaultBloc>();
    final controller = TextEditingController(text: oldTag);
    final newTag = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.palette.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          AppLocalizations.of(context)!.tagsRenameDialogTitle,
          style: AppFonts.display(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: context.palette.textPrimary,
            height: 1.15,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppFonts.body(
            fontSize: 15,
            color: context.palette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.tagsRenameDialogHint,
            hintStyle: AppFonts.body(
              fontSize: 14,
              color: context.palette.textTertiary,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: context.palette.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: context.palette.surfaceStroke, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: context.palette.surfaceStroke, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: context.palette.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              AppLocalizations.of(context)!.tagsRenameDialogCancel,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              AppLocalizations.of(context)!.tagsRenameDialogConfirm,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.palette.primary,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
    if (newTag == null || newTag.isEmpty || newTag == oldTag) return;
    final affected = notes.where((n) => n.tags.contains(oldTag));
    for (final n in affected) {
      final next = n.tags.map((t) => t == oldTag ? newTag : t).toSet().toList();
      bloc.add(VaultNoteUpdated(UpdateNoteParams(id: n.id, tags: next)));
    }
    if (mounted) {
      context
          .showSnack('Tag "$oldTag" → "$newTag" (${affected.length} catatan)');
    }
  }

  Future<void> _deleteTag(String tag, List<NoteEntity> notes) async {
    final bloc = context.read<VaultBloc>();
    final affected = notes.where((n) => n.tags.contains(tag)).toList();
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: context.palette.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          AppLocalizations.of(context)!.tagsDeleteDialogTitle,
          style: AppFonts.display(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: context.palette.textPrimary,
            height: 1.15,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.tagsDeleteDialogBody,
          style: AppFonts.body(
            fontSize: 14,
            height: 1.55,
            color: context.palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              AppLocalizations.of(context)!.tagsDeleteDialogCancel,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              AppLocalizations.of(context)!.tagsDeleteDialogConfirm,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final n in affected) {
      final next = n.tags.where((t) => t != tag).toList();
      bloc.add(VaultNoteUpdated(UpdateNoteParams(id: n.id, tags: next)));
    }
    if (mounted) {
      context.showSnack('Tag #$tag dihapus dari ${affected.length} catatan');
    }
  }
}

class _TagRow extends StatelessWidget {
  final String tag;
  final int count;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  const _TagRow({
    required this.tag,
    required this.count,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final c = BookColor.of(tag);
    return InkWell(
      onTap: onRename,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: Row(
          children: [
            // A book spine in the tag's colour.
            Container(
              width: 12,
              height: 40,
              decoration: BoxDecoration(
                color: c.spine,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 7),
              child: Container(
                width: 12,
                height: 3,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$tag',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.tagsRowNoteCount(count),
                    style: AppFonts.body(
                      fontSize: 12,
                      color: palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.tagsEditTooltip,
              icon: Icon(Icons.edit_outlined,
                  size: 19, color: palette.textSecondary),
              onPressed: onRename,
            ),
            IconButton(
              tooltip: l10n.tagsDeleteTooltip,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 19, color: palette.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTags extends StatelessWidget {
  const _EmptyTags();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PetHost(height: 88),
          const SizedBox(height: 18),
          Text(l10n.tagsEmptyEyebrow, style: eyebrowStyle(context: context)),
          const SizedBox(height: 12),
          Text(l10n.tagsEmptyTitle,
              style: pageTitleStyle(context: context, size: 38)),
          const SizedBox(height: 14),
          Text(
            l10n.tagsEmptyBody,
            style: AppFonts.body(
              fontSize: 14,
              height: 1.55,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
