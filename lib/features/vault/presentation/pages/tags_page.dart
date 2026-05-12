import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/update_note.dart';
import '../bloc/vault_bloc.dart';

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
      context.read<VaultBloc>().add(VaultLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('KELOLA TAG', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: BlocBuilder<VaultBloc, VaultState>(
          builder: (_, state) {
            if (state is VaultLoading || state is VaultInitial) {
              return const Center(
                  child: CircularProgressIndicator(
                color: AppColors.primary,
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
                Text('Tag.', style: pageTitleStyle(size: 36)),
                const SizedBox(height: 4),
                Text(
                  '${entries.length} tag · ${notes.length} catatan',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 32),
                const ThinDivider(),
                ...List.generate(entries.length, (i) {
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
                      if (i != entries.length - 1) const ThinDivider(),
                    ],
                  );
                }),
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
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          'Ubah nama tag',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Nama tag baru',
            hintStyle: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: AppColors.bgPrimary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.surfaceStroke, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.surfaceStroke, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 0.1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
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
        backgroundColor: AppColors.bgSecondary,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.surfaceStroke, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 14, 12),
        title: Text(
          'Hapus tag #$tag?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        content: Text(
          'Tag akan dilepas dari ${affected.length} catatan. '
          'Catatan tetap ada, hanya tag-nya yang hilang.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.55,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textTertiary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
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
              'Hapus',
              style: GoogleFonts.inter(
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
    return InkWell(
      onTap: onRename,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$tag',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count catatan',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Ubah nama',
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.textSecondary),
              onPressed: onRename,
            ),
            IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.danger),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TAG KOSONG', style: eyebrowStyle()),
          const SizedBox(height: 12),
          Text('Belum\nada tag.', style: pageTitleStyle(size: 38)),
          const SizedBox(height: 14),
          Text(
            'Tag akan muncul di sini setelah kamu menambahkannya ke catatan. Tambahkan tag saat membuat atau mengedit catatan.',
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
