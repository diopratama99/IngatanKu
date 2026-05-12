import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/media_download_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/share_repository.dart';
import '../bloc/vault_bloc.dart';

/// Detail view for a single note.
///
/// Editorial dark layout that mirrors the rest of the app:
///   * Slim AppBar — back + a single overflow menu (Buka sumber, Bagikan
///     publik, Hapus). The previous three icon actions felt cluttered.
///   * Date eyebrow → big SpaceGrotesk title (no inline source label,
///     since the URL card directly below already names it).
///   * URL card with a source-specific icon, the platform name, and a
///     truncated URL — replaces the earlier underlined inline link.
///   * Markdown body with generous typography.
///   * Tags rendered as indigo-tinted pill chips, not plain text.
///   * Edit promoted from a floating FAB to a bottom-anchored full-width
///     primary button so it doesn't compete with content.
class NoteDetailPage extends StatelessWidget {
  final NoteEntity note;
  const NoteDetailPage({super.key, required this.note});

  // ── Source helpers ────────────────────────────────────────────

  /// Returns true for source types where a media artifact (video/photo) is
  /// likely to exist and worth offering a download for. Articles fall
  /// through to false because their og:image is usually a hero thumbnail,
  /// not the content itself.
  bool _supportsDownload(String s) {
    return s == 'youtube' || s == 'tiktok' || s == 'instagram' || s == 'x';
  }

  String _sourceLabel(String s) {
    switch (s) {
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'instagram':
        return 'Instagram';
      case 'x':
        return 'X';
      case 'article':
        return 'Artikel';
      default:
        return 'Tautan';
    }
  }

  IconData _sourceIcon(String s) {
    switch (s) {
      case 'youtube':
        return Icons.play_circle_outline_rounded;
      case 'tiktok':
        return Icons.music_note_rounded;
      case 'instagram':
        return Icons.photo_camera_outlined;
      case 'x':
        return Icons.alternate_email_rounded;
      case 'article':
        return Icons.article_outlined;
      default:
        return Icons.link_rounded;
    }
  }

  /// Show host + first ~40 chars of path; collapse query params with "?…".
  String _shortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.replaceFirst('www.', '');
      var path = uri.path;
      if (path.isEmpty || path == '/') return host;
      if (path.length > 42) path = '${path.substring(0, 42)}…';
      final query = uri.hasQuery ? '?…' : '';
      return '$host$path$query';
    } catch (_) {
      return url;
    }
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _openUrl() async {
    final uri = Uri.tryParse(note.url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(const SnackBar(
      content: Text('Membuat tautan berbagi…'),
      duration: Duration(seconds: 1),
    ));
    final res = await sl<ShareRepository>().enable(note.id);
    res.fold(
      (f) => messenger
          .showSnackBar(SnackBar(content: Text('Gagal: ${f.message}'))),
      (token) async {
        final base = Env.supabaseUrl.isNotEmpty
            ? Env.supabaseUrl.replaceFirst(RegExp(r'^https?://'), 'https://')
            : 'https://ingatanku.app';
        final link = '$base/share/$token';
        await Clipboard.setData(ClipboardData(text: link));
        await Share.share('Lihat catatan tech-ku di IngatanKu:\n$link');
        messenger.showSnackBar(const SnackBar(
          content: Text('Tautan disalin ke clipboard'),
        ));
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<VaultBloc>();
    final confirm = await showDialog<bool>(
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
          'Hapus catatan ini?',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: AppColors.textPrimary,
            height: 1.15,
          ),
        ),
        content: Text(
          'Catatan akan dihapus dari brankas. Tindakan ini tidak bisa dibatalkan.',
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
    if (confirm == true && context.mounted) {
      bloc.add(VaultNoteDeleted(note.id));
      context.pop();
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : '(Tanpa judul)';

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      // Slim AppBar — no title here; the page acts as the eyebrow itself.
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          // Single overflow menu collects the secondary actions instead of
          // three loud icon buttons.
          PopupMenuButton<String>(
            tooltip: 'Aksi lainnya',
            icon: const Icon(Icons.more_horiz_rounded, size: 22),
            color: AppColors.bgSecondary,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.surfaceStroke, width: 1),
            ),
            position: PopupMenuPosition.under,
            onSelected: (action) {
              switch (action) {
                case 'open':
                  _openUrl();
                  break;
                case 'share':
                  _share(context);
                  break;
                case 'delete':
                  _confirmDelete(context);
                  break;
              }
            },
            itemBuilder: (_) => [
              _menuItem(
                value: 'open',
                icon: Icons.open_in_new_rounded,
                label: 'Buka sumber',
              ),
              _menuItem(
                value: 'share',
                icon: Icons.ios_share_rounded,
                label: 'Bagikan publik',
              ),
              _menuItem(
                value: 'delete',
                icon: Icons.delete_outline,
                label: 'Hapus',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),

      // Bottom-anchored primary CTA — replaces the Edit FAB.
      bottomNavigationBar: SafeArea(
        top: false,
        child: BlocListener<VaultBloc, VaultState>(
          listenWhen: (prev, curr) => curr is VaultNoteUpdateSuccess,
          listener: (ctx, state) {
            if (state is VaultNoteUpdateSuccess &&
                state.updatedNote.id == note.id) {
              context.pop();
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(Routes.editNote, extra: note),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.edit_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'EDIT CATATAN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            // ── Date eyebrow ───────────────────────────────────
            Text(note.createdAt.prettyDate.toUpperCase(),
                style: eyebrowStyle()),
            const SizedBox(height: 14),

            // ── Editorial title ───────────────────────────────
            Text(title, style: pageTitleStyle(size: 32)),
            const SizedBox(height: 22),

            // ── Source URL card ───────────────────────────────
            _SourceUrlCard(
              icon: _sourceIcon(note.sourceType),
              label: _sourceLabel(note.sourceType),
              shortUrl: _shortUrl(note.url),
              onTap: _openUrl,
            ),

            // ── Media download card (only for media-bearing sources) ──
            // Article URLs rarely have a downloadable artifact — hide the
            // card there to avoid suggesting an action that often fails.
            if (_supportsDownload(note.sourceType)) ...[
              const SizedBox(height: 12),
              _MediaDownloadCard(note: note),
            ],

            const SizedBox(height: 30),
            const ThinDivider(),
            const SizedBox(height: 26),

            // ── Body markdown ─────────────────────────────────
            MarkdownBody(
              data: note.manualNotes.trim().isEmpty
                  ? '_Belum ada catatan._'
                  : note.manualNotes,
              selectable: true,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.inter(
                  fontSize: 16,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
                h1: GoogleFonts.spaceGrotesk(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
                h2: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
                h3: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                blockquote: GoogleFonts.inter(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.surfaceStroke, width: 2),
                  ),
                ),
                blockquotePadding: const EdgeInsets.only(left: 16),
                code: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgTertiary.withValues(alpha: 0.4),
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceStroke),
                ),
                listBullet: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ── Tags ──────────────────────────────────────────
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 32),
              const ThinDivider(),
              const SizedBox(height: 20),
              Text('TAG', style: eyebrowStyle()),
              const SizedBox(height: 14),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: note.tags
                    .map((t) => Text(
                          '#$t',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                            color: AppColors.primary,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
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
    final fg = color ?? AppColors.textPrimary;
    return PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
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
//                       SUPPORTING WIDGETS
// ════════════════════════════════════════════════════════════════

/// Tappable card showing the note's source platform + truncated URL.
/// Replaces the earlier underlined inline hyperlink — gives the URL a
/// proper visual home and makes the tap target much larger.
class _SourceUrlCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortUrl;
  final VoidCallback onTap;

  const _SourceUrlCard({
    required this.icon,
    required this.label,
    required this.shortUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceStroke, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: eyebrowStyle(),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_outward_rounded,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Download card — resolves the source URL via `resolve-media`,
// streams the file to the app sandbox via Dio, then offers Open /
// Bagikan / Hapus buttons. Reflects 4 visual states:
//   • checking — initial existence probe (rendered as nothing).
//   • idle — no local file; primary "Download" CTA.
//   • downloading — linear progress + Batal button.
//   • saved — green check + size + Buka/Bagikan/Hapus.
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
    setState(() {
      _downloading = true;
      _progress = 0.0;
    });
    _cancelToken = CancelToken();
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
    } on MediaDownloadException catch (e) {
      if (!mounted) return;
      setState(() => _downloading = false);
      context.showSnack('Download gagal: ${e.message}', error: true);
    } catch (e) {
      if (!mounted) return;
      // Cancel races: when the user taps Batal, dio raises a cancel error
      // that we intentionally swallow without an alarming SnackBar.
      if (e is DioException && CancelToken.isCancel(e)) {
        setState(() => _downloading = false);
        return;
      }
      setState(() => _downloading = false);
      context.showSnack('Download gagal: $e', error: true);
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
      context.showSnack('Tidak ada app yang bisa membuka file ini',
          error: true);
    }
  }

  Future<void> _share() async {
    final f = _localFile;
    if (f == null) return;
    await Share.shareXFiles([XFile(f.path)],
        text: widget.note.title ?? 'Lihat ini');
  }

  Future<void> _delete() async {
    await _svc.delete(widget.note.id);
    if (!mounted) return;
    setState(() {
      _localFile = null;
      _localSize = 0;
    });
    context.showSnack('File lokal dihapus');
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
    if (_checking) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceStroke, width: 1),
      ),
      child: _downloading
          ? _buildDownloading()
          : _localFile != null
              ? _buildSaved()
              : _buildIdle(),
    );
  }

  Widget _buildIdle() {
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
              Text('SIMPAN OFFLINE', style: eyebrowStyle()),
              const SizedBox(height: 3),
              Text(
                'Download video/foto ke perangkat ini',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
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
            'DOWNLOAD',
            style: GoogleFonts.spaceGrotesk(
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
                hasPct ? 'Mengunduh… $pct%' : 'Mempersiapkan…',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: _cancelDownload,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'BATAL',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
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
            backgroundColor: AppColors.bgTertiary.withValues(alpha: 0.4),
            color: AppColors.accent,
            minHeight: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildSaved() {
    final size = _localSize > 0 ? _humanSize(_localSize) : '—';
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
              Text('TERSIMPAN OFFLINE', style: eyebrowStyle()),
              const SizedBox(height: 3),
              Text(
                size,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Buka',
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          color: AppColors.textSecondary,
          onPressed: _open,
        ),
        IconButton(
          tooltip: 'Bagikan',
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          color: AppColors.textSecondary,
          onPressed: _share,
        ),
        IconButton(
          tooltip: 'Hapus dari perangkat',
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: AppColors.danger,
          onPressed: _delete,
        ),
      ],
    );
  }
}
