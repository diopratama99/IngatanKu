import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/media_download_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../vault/domain/entities/note_entity.dart';
import '../../../vault/presentation/bloc/vault_bloc.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../companion/presentation/widgets/pet_host.dart';

/// Storage management page — lists every downloaded video/photo with its
/// owning note's title and lets the user delete them individually or
/// wipe the whole cache.
///
/// Cross-references file basename (= noteId) against [VaultBloc] state
/// so the UI can render "Homeserver Stack — Instagram · 8.4 MB" instead
/// of a bare uuid. When a file's note has been deleted from the vault
/// (orphan), we still surface it so the user can reclaim the space.
class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  late final MediaDownloadService _svc = sl<MediaDownloadService>();
  List<DownloadedMedia> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await _svc.listAll();
    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });
  }

  Future<void> _deleteOne(DownloadedMedia m) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      title: l10n.storageDeleteOneTitle,
      body: m.isImage
          ? l10n.storageDeleteOnePhotoBody
          : l10n.storageDeleteOneVideoBody,
    );
    if (!confirmed || !mounted) return;
    await _svc.delete(m.noteId);
    await _refresh();
    if (!mounted) return;
    context.showSnack(l10n.storageFileDeleted);
  }

  Future<void> _deleteAll() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      title: l10n.storageDeleteAllTitle,
      body: l10n.storageDeleteAllBody,
      destructiveLabel: l10n.storageDeleteAllAction,
    );
    if (!confirmed || !mounted) return;
    final n = await _svc.deleteAll();
    await _refresh();
    if (!mounted) return;
    context.showSnack(l10n.storageFilesDeleted(n));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    String? destructiveLabel,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
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
          title,
          style: AppFonts.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: context.palette.textPrimary,
            height: 1.2,
          ),
        ),
        content: Text(
          body,
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
            ),
            child: Text(l10n.storageConfirmCancel,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textTertiary,
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
            ),
            child: Text(destructiveLabel ?? l10n.storageConfirmDelete,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                )),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  /// Look the note up in the loaded vault state so we can render its
  /// title. Returns null when the note is missing (deleted) — callers
  /// then render the file as an "orphan".
  NoteEntity? _noteFor(BuildContext context, String noteId) {
    final state = context.read<VaultBloc>().state;
    if (state is VaultLoaded) {
      for (final n in state.notes) {
        if (n.id == noteId) return n;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totalBytes =
        _items.fold<int>(0, (sum, m) => sum + m.sizeBytes);
    final hasItems = _items.isNotEmpty;

    return Scaffold(
      appBar: PageTopBar(title: l10n.storageAppBarTitle),
      body: SafeArea(
        child: RefreshIndicator(
          color: context.palette.primary,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 96),
            children: [
              Text(l10n.storageTitle, style: pageTitleStyle(context: context, size: 30)),
              const SizedBox(height: 6),
              Text(
                hasItems
                    ? l10n.storageUsage(_items.length, _humanSize(totalBytes))
                    : l10n.storageEmptySubtitle,
                style: AppFonts.body(
                  fontSize: 13,
                  color: context.palette.textTertiary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.palette.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (hasItems) ...[
                const ThinDivider(),
                ...List.generate(_items.length, (i) {
                  final m = _items[i];
                  return Column(
                    children: [
                      _MediaRow(
                        media: m,
                        note: _noteFor(context, m.noteId),
                        onDelete: () => _deleteOne(m),
                        onTap: () {
                          // Tap → jump to the owning note's detail page
                          // when the note still exists. Orphan files
                          // are tap-inert; the only useful action is
                          // delete.
                          final n = _noteFor(context, m.noteId);
                          if (n != null) {
                            context.push('/vault/${n.id}', extra: n);
                          }
                        },
                      ),
                      if (i != _items.length - 1) const ThinDivider(),
                    ],
                  );
                }),
                const ThinDivider(),
                const SizedBox(height: 24),
                _DangerButton(
                  label: l10n.storageDeleteAllButton,
                  onPressed: _deleteAll,
                ),
              ] else
                // Nothing saved offline yet: just the pet.
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: PetHost(height: 110)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaRow extends StatelessWidget {
  final DownloadedMedia media;
  final NoteEntity? note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MediaRow({
    required this.media,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  String _label(AppLocalizations l10n) {
    if (note != null) {
      final t = note!.title?.trim();
      if (t != null && t.isNotEmpty) return t;
      return l10n.storageRowUntitled;
    }
    return l10n.storageRowOrphan;
  }

  String _byline(AppLocalizations l10n) {
    final parts = <String>[];
    if (note != null) {
      parts.add(SourceMeta.label(note!.sourceType));
    } else {
      parts.add(l10n.storageRowOrphanLabel(media.ext.toUpperCase()));
    }
    parts.add(_humanSize(media.sizeBytes));
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orphan = note == null;
    return InkWell(
      onTap: orphan ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Thumbnail tile — image preview when local file is a
            // photo, generic source icon for video/audio.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: media.isImage
                    ? Image.file(
                        media.file,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _IconTile(
                          icon: Icons.broken_image_outlined,
                        ),
                      )
                    : _IconTile(
                        icon: note != null
                            ? SourceMeta.icon(note!.sourceType)
                            : Icons.movie_outlined,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(l10n),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: orphan
                          ? context.palette.textSecondary
                          : context.palette.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _byline(l10n),
                    style: AppFonts.body(
                      fontSize: 12,
                      color: context.palette.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.storageRowDeleteTooltip,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.danger,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  const _IconTile({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.palette.bgSecondary,
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: context.palette.textTertiary),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _DangerButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.delete_sweep_rounded, size: 18, color: palette.danger),
        label: Text(
          label,
          style: AppFonts.body(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: palette.danger,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: Color.alphaBlend(
              palette.danger.withValues(alpha: 0.1), palette.bgPrimary),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

// ── helpers ────────────────────────────────────────────────────

String _humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}
