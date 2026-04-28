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
              return const Center(child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ));
            }
            if (state is VaultError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(state.message,
                      style: context.textStyles.bodyMedium),
                ),
              );
            }
            final notes =
                state is VaultLoaded ? state.notes : <NoteEntity>[];
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
    final controller = TextEditingController(text: oldTag);
    final newTag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: const Text('Ubah nama tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nama tag baru'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (newTag == null || newTag.isEmpty || newTag == oldTag) return;
    final affected = notes.where((n) => n.tags.contains(oldTag));
    final bloc = context.read<VaultBloc>();
    for (final n in affected) {
      final next =
          n.tags.map((t) => t == oldTag ? newTag : t).toSet().toList();
      bloc.add(VaultNoteUpdated(UpdateNoteParams(id: n.id, tags: next)));
    }
    if (mounted) {
      context.showSnack(
          'Tag "$oldTag" → "$newTag" (${affected.length} catatan)');
    }
  }

  Future<void> _deleteTag(String tag, List<NoteEntity> notes) async {
    final affected = notes.where((n) => n.tags.contains(tag)).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSecondary,
        title: Text('Hapus tag #$tag?'),
        content: Text(
            'Tag akan dilepas dari ${affected.length} catatan. Catatan tetap ada, hanya tag-nya yang hilang.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final bloc = context.read<VaultBloc>();
    for (final n in affected) {
      final next = n.tags.where((t) => t != tag).toList();
      bloc.add(VaultNoteUpdated(UpdateNoteParams(id: n.id, tags: next)));
    }
    if (mounted) {
      context
          .showSnack('Tag #$tag dihapus dari ${affected.length} catatan');
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
