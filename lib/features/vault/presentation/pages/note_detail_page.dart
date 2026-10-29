import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/media_download_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/widgets/pet_host.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../../notes/domain/entities/personal_note.dart';
import '../../../notes/presentation/widgets/note_color_palette.dart';
import '../../../notes/presentation/widgets/note_paper.dart';
import '../../../notes/presentation/widgets/sticky_note.dart';
import '../../domain/entities/note_entity.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/book_colors.dart';
import '../widgets/inline_media_player.dart';
import '../../../../core/theme/app_fonts.dart';

part 'note_detail_journal.dart';

/// A note from Pustaka, opened full screen as a page of a spiral-bound
/// journal; swipe sideways to turn the pages (one note each).
///
/// Each page has the date and where it's from, the title, the video or
/// picture taped on like a photo (it plays right there), the whole note
/// written out on the ruled lines and its tags on strips of tape. The pet
/// reads along by the notebook. Edit, save offline and delete are behind
/// the ••• button.
class NoteDetailPage extends StatefulWidget {
  /// The note the user tapped to open. Used to compute the initial page
  /// against the vault list.
  final NoteEntity note;
  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  /// Materialised feed list — captured once from VaultBloc state at first
  /// build. Re-grabbing on every state change would shuffle the index
  /// out from under the user.
  List<NoteEntity>? _feed;
  int _index = 0;

  /// The pet reading along by the notebook.
  final _pet = BlobController();
  final _journal = GlobalKey<_JournalState>();

  /// A page has been turned this time (the hint can go).
  bool _turned = false;

  /// Bumped when a downloaded video is deleted, so the players look on
  /// the phone again.
  int _mediaRev = 0;

  void _mediaChanged() => setState(() => _mediaRev++);

  void _hydrateFeed(List<NoteEntity> notes) {
    final at = notes.indexWhere((n) => n.id == widget.note.id);
    final feed = at == -1 ? <NoteEntity>[widget.note] : notes;
    final old = _feed;
    if (old == null) {
      _index = at == -1 ? 0 : at;
    } else {
      // The list changed: stay on the same note if it's still there.
      final current = old[_index.clamp(0, old.length - 1)];
      final still = feed.indexWhere((n) => n.id == current.id);
      _index = still != -1 ? still : _index.clamp(0, feed.length - 1);
    }
    _feed = feed;
  }

  void _onTurned(int index) {
    setState(() {
      _index = index;
      _turned = true;
    });
    // Its eyes go to the new page.
    _pet.focus(const Offset(-0.6, 0.4), scan: true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) _pet.focus(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VaultBloc, VaultState>(
      buildWhen: (prev, curr) =>
          curr is VaultLoaded ||
          curr is VaultNoteAddSuccess ||
          curr is VaultNoteUpdateSuccess,
      builder: (ctx, state) {
        if (state is VaultLoaded) _hydrateFeed(state.notes);
        final feed = _feed ?? <NoteEntity>[widget.note];
        final index = _index.clamp(0, feed.length - 1);
        final insets = MediaQuery.paddingOf(context);
        return Scaffold(
          backgroundColor: context.palette.bgPrimary,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            // The book over the footer: a page being turned swings out
            // over the pet and the arrows.
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _JournalFooter(
                    pet: _pet,
                    position: index + 1,
                    count: feed.length,
                    hint: !_turned && feed.length > 1,
                    bottomInset: insets.bottom,
                    onPrev: index > 0
                        ? () => _journal.currentState?.turn(-1)
                        : null,
                    onNext: index < feed.length - 1
                        ? () => _journal.currentState?.turn(1)
                        : null,
                  ),
                ),
                Positioned.fill(
                  top: insets.top + 8,
                  bottom: _JournalFooter.height + insets.bottom,
                  left: 14,
                  right: 12,
                  child: _Journal(
                    key: _journal,
                    back: _BackTab(onTap: () => context.pop()),
                    ribbon: _OverflowMenu(noteForMenu: feed[index]),
                    count: feed.length,
                    index: index,
                    idOf: (i) => feed[i].id,
                    onTurned: _onTurned,
                    page: (context, i, active) => _JournalPage(
                      note: feed[i],
                      number: i + 1,
                      mediaRev: _mediaRev,
                      active: active,
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

/// Cream paper, as a decoration for the round buttons.
BoxDecoration _paperCircle(BuildContext context) {
  return BoxDecoration(
    color: NoteColorPalette.background(NoteColor.defaultColor),
    shape: BoxShape.circle,
    border: Border.all(color: NoteColorPalette.border(NoteColor.defaultColor)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

/// One of the pastels, the same every time for [note].
NoteColor _tint(NoteEntity note) => StickyNote.pick(note.id, const [
      NoteColor.yellow,
      NoteColor.pink,
      NoteColor.green,
      NoteColor.blue,
      NoteColor.purple,
      NoteColor.orange,
    ]);

class _PaperCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _PaperCircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: _paperCircle(context),
            child: Icon(icon, size: 21, color: context.palette.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Where the note is from, on a little sticker — tap to open it there.
class _SourceChip extends StatelessWidget {
  final NoteEntity note;
  final VoidCallback onTap;
  const _SourceChip({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = _tint(note);
    final swatch = NoteColorPalette.swatch(tint);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: NoteColorPalette.background(tint),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NoteColorPalette.border(tint)),
              ),
              child: Icon(
                SourceMeta.icon(note.sourceType),
                size: 15,
                color: Color.lerp(swatch, Colors.black, 0.45),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              SourceMeta.labelLocalized(context, note.sourceType),
              style: AppFonts.body(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_outward_rounded,
                size: 14, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                       OVERFLOW MENU
// ════════════════════════════════════════════════════════════════

class _OverflowMenu extends StatefulWidget {
  final NoteEntity noteForMenu;
  const _OverflowMenu({required this.noteForMenu});

  @override
  State<_OverflowMenu> createState() => _OverflowMenuState();
}

class _OverflowMenuState extends State<_OverflowMenu> {
  /// True when there's a downloaded artifact for this note. Probed on
  /// init and after every menu action that might mutate the cache so
  /// the "Hapus video offline" item appears/disappears appropriately.
  bool _hasLocal = false;

  NoteEntity get noteForMenu => widget.noteForMenu;

  @override
  void initState() {
    super.initState();
    _refreshLocalState();
  }

  @override
  void didUpdateWidget(covariant _OverflowMenu old) {
    super.didUpdateWidget(old);
    if (old.noteForMenu.id != widget.noteForMenu.id) {
      _refreshLocalState();
    }
  }

  Future<void> _refreshLocalState() async {
    try {
      final f =
          await sl<MediaDownloadService>().existingFile(widget.noteForMenu.id);
      if (!mounted) return;
      setState(() => _hasLocal = f != null);
    } catch (_) {/* non-fatal */}
  }

  bool _supportsDownload(String s) => SourceMeta.supportsCobaltResolve(s);

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(noteForMenu.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<VaultBloc>();
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
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
          l10n.noteDetailDeleteTitle,
          style: AppFonts.display(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: context.palette.textPrimary,
            height: 1.15,
          ),
        ),
        content: Text(
          l10n.noteDetailDeleteMessage,
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
              l10n.noteDetailDeleteCancel,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.palette.textTertiary,
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
              l10n.noteDetailDeleteConfirm,
              style: AppFonts.body(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      bloc.add(VaultNoteDeleted(noteForMenu.id));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // The book's ribbon bookmark; the menu opens on a slip of its paper.
    return PopupMenuButton<String>(
      tooltip: l10n.noteDetailMoreTooltip,
      padding: EdgeInsets.zero,
      color: NoteColorPalette.background(NoteColor.defaultColor),
      surfaceTintColor: Colors.transparent,
      // A soft shadow, like a slip of paper lifted off the page.
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: NoteColorPalette.border(NoteColor.defaultColor), width: 1),
      ),
      position: PopupMenuPosition.under,
      onSelected: (action) {
        switch (action) {
          case 'edit':
            context.push(Routes.editNote, extra: noteForMenu);
            break;
          case 'open':
            _openUrl();
            break;
          case 'download':
            _showDownloadSheet(context);
            break;
          case 'delete-local':
            _confirmDeleteLocal(context);
            break;
          case 'delete':
            _confirmDelete(context);
            break;
        }
      },
      itemBuilder: (_) => [
        _menuItem(
          value: 'edit',
          icon: Icons.edit_outlined,
          label: l10n.noteDetailMenuEdit,
        ),
        _menuItem(
          value: 'open',
          icon: Icons.open_in_new_rounded,
          label: l10n.noteDetailMenuOpenSource,
        ),
        // "Simpan offline" only when no local copy yet.
        if (_supportsDownload(noteForMenu.sourceType) && !_hasLocal)
          _menuItem(
            value: 'download',
            icon: Icons.download_rounded,
            label: l10n.noteDetailMenuSaveOffline,
          ),
        // "Hapus video offline" when a local copy exists — frees up
        // space without deleting the note itself.
        if (_hasLocal)
          _menuItem(
            value: 'delete-local',
            icon: Icons.sd_storage_outlined,
            label: l10n.noteDetailMenuDeleteOffline,
          ),
        _menuItem(
          value: 'delete',
          icon: Icons.delete_outline,
          label: l10n.noteDetailMenuDelete,
          color: AppColors.danger,
        ),
      ],
      child: const _Ribbon(),
    );
  }

  /// Confirm + delete the on-device media file for this note. Doesn't
  /// touch the note row in Postgres — the user can re-download anytime.
  Future<void> _confirmDeleteLocal(BuildContext context) async {
    // Looked up before the awaits, like the messenger.
    final page = context.findAncestorStateOfType<_NoteDetailPageState>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
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
          l10n.noteDetailDeleteLocalTitle,
          style: AppFonts.display(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: context.palette.textPrimary,
          ),
        ),
        content: Text(
          l10n.noteDetailDeleteLocalMessage,
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
            child: Text(l10n.noteDetailDeleteCancel,
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
            child: Text(l10n.noteDetailDeleteConfirm,
                style: AppFonts.body(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                )),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await sl<MediaDownloadService>().delete(noteForMenu.id);
    await _refreshLocalState();
    if (!mounted) return;
    // A fresh player finds the file gone and streams again.
    page?._mediaChanged();
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.noteDetailDeleteLocalDone),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  /// Opens the offline-download flow as a bottom sheet so the reels page
  /// stays uncluttered. Reuses the same `MediaDownloadCard` UI surface
  /// for consistency with the previous detail page.
  void _showDownloadSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: false,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceStroke,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                l10n.noteDetailSaveOfflineEyebrow,
                style: AppFonts.display(
                  fontSize: 11,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              _MediaDownloadCard(note: noteForMenu),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final fg = color ?? context.palette.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppFonts.body(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
//                    MEDIA DOWNLOAD CARD
//   (kept inside this file because it's only used by the detail
//   page's "Simpan offline" bottom sheet)
// ════════════════════════════════════════════════════════════════

class _MediaDownloadCard extends StatefulWidget {
  final NoteEntity note;
  const _MediaDownloadCard({required this.note});

  @override
  State<_MediaDownloadCard> createState() => _MediaDownloadCardState();
}

class _MediaDownloadCardState extends State<_MediaDownloadCard> {
  late final MediaDownloadService _svc = sl<MediaDownloadService>();

  bool _checking = true;
  File? _localFile;
  int _localSize = 0;
  bool _downloading = false;
  double _progress = 0.0;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('disposed');
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final f = await _svc.existingFile(widget.note.id);
    if (!mounted) return;
    setState(() {
      _localFile = f;
      _localSize = f?.lengthSync() ?? 0;
      _checking = false;
    });
  }

  Future<void> _download() async {
    if (_downloading) return;
    if (!await ensureOnline(context, OnlineFeature.download) || !mounted) {
      return;
    }
    setState(() {
      _downloading = true;
      _progress = 0.0;
    });
    _cancelToken = CancelToken();
    final l10n = AppLocalizations.of(context)!;
    try {
      final resolution = await _svc.resolve(widget.note.url);
      final f = await _svc.download(
        noteId: widget.note.id,
        resolution: resolution,
        cancelToken: _cancelToken,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _localFile = f;
        _localSize = f.lengthSync();
        _downloading = false;
      });
      // Close the sheet so the player behind us can re-probe for the
      // new file and switch its CTA from "PUTAR INLINE" (streaming) to
      // "PUTAR (TERSIMPAN)" (zero-network playback). The user already
      // sees the success snack from the player, so dropping the sheet
      // is the right next step.
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      if (!mounted) return;
      context.showSnack(l10n.noteDetailDownloadSavedSnack);
    } on MediaDownloadException catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      if (isOfflineError(e.message)) {
        showPetOffline(context, OnlineFeature.download);
      } else {
        context.showSnack(l10n.noteDetailDownloadFailed(e.message),
            error: true);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && CancelToken.isCancel(e)) {
        setState(() => _downloading = false);
        return;
      }
      setState(() => _downloading = false);
      if (isOfflineError(e)) {
        showPetOffline(context, OnlineFeature.download);
      } else {
        context.showSnack(l10n.noteDetailDownloadFailed(e.toString()),
            error: true);
      }
    }
  }

  void _cancelDownload() {
    _cancelToken?.cancel('user');
  }

  Future<void> _open() async {
    final f = _localFile;
    if (f == null) return;
    final res = await OpenFilex.open(f.path);
    if (res.type != ResultType.done && mounted) {
      context.showSnack(AppLocalizations.of(context)!.noteDetailOpenFileFailed,
          error: true);
    }
  }

  Future<void> _share() async {
    final f = _localFile;
    if (f == null) return;
    await Share.shareXFiles([XFile(f.path)],
        text: widget.note.title ??
            AppLocalizations.of(context)!.noteDetailShareFallbackTitle);
  }

  Future<void> _delete() async {
    await _svc.delete(widget.note.id);
    if (!mounted) return;
    setState(() {
      _localFile = null;
      _localSize = 0;
    });
    context
        .showSnack(AppLocalizations.of(context)!.noteDetailLocalDeletedSnack);
  }

  static String _humanSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 1.6,
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.palette.bgPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.surfaceStroke, width: 1),
      ),
      child: _downloading
          ? _buildDownloading()
          : _localFile != null
              ? _buildSaved()
              : _buildIdle(),
    );
  }

  Widget _buildIdle() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.download_rounded,
              size: 18, color: AppColors.accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.noteDetailDownloadIdleTitle,
                style: AppFonts.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.noteDetailDownloadIdleSubtitle,
                style: AppFonts.body(
                  fontSize: 12,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: _download,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: Text(
            l10n.noteDetailDownloadAction,
            style: AppFonts.display(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloading() {
    final l10n = AppLocalizations.of(context)!;
    final pct = (_progress * 100).round();
    final hasPct = _progress > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.6,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasPct
                    ? l10n.noteDetailDownloadingProgress(pct)
                    : l10n.noteDetailDownloadingPreparing,
                style: AppFonts.body(
                  fontSize: 13,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _cancelDownload,
              style: TextButton.styleFrom(
                foregroundColor: context.palette.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.noteDetailDownloadingCancel,
                style: AppFonts.display(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: context.palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: hasPct ? _progress : null,
            backgroundColor: context.palette.bgTertiary.withValues(alpha: 0.4),
            color: AppColors.accent,
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildSaved() {
    final l10n = AppLocalizations.of(context)!;
    final size = _localSize > 0 ? _humanSize(_localSize) : '-';
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.check_circle_outline_rounded,
              size: 18, color: AppColors.success),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.noteDetailDownloadSavedTitle,
                style: AppFonts.display(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                size,
                style: AppFonts.body(
                  fontSize: 12,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.noteDetailDownloadOpenTooltip,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          color: context.palette.textSecondary,
          onPressed: _open,
        ),
        IconButton(
          tooltip: l10n.noteDetailDownloadShareTooltip,
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          color: context.palette.textSecondary,
          onPressed: _share,
        ),
        IconButton(
          tooltip: l10n.noteDetailDownloadDeleteTooltip,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: AppColors.danger,
          onPressed: _delete,
        ),
      ],
    );
  }
}
