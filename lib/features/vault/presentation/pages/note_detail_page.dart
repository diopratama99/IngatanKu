import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/env.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/share_repository.dart';
import '../bloc/vault_bloc.dart';

class NoteDetailPage extends StatelessWidget {
  final NoteEntity note;
  const NoteDetailPage({super.key, required this.note});

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

  @override
  Widget build(BuildContext context) {
    final title = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!
        : '(Tanpa judul)';
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_sourceLabel(note.sourceType), style: eyebrowStyle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Bagikan publik',
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
            onPressed: _openUrl,
            tooltip: 'Buka sumber',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Hapus',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Hapus catatan ini?'),
                  content: const Text('Tindakan ini tidak bisa dibatalkan.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Hapus',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.read<VaultBloc>().add(VaultNoteDeleted(note.id));
                context.pop();
              }
            },
          ),
        ],
      ),
      floatingActionButton: BlocListener<VaultBloc, VaultState>(
        listenWhen: (prev, curr) => curr is VaultNoteUpdateSuccess,
        listener: (ctx, state) {
          if (state is VaultNoteUpdateSuccess &&
              state.updatedNote.id == note.id) {
            context.pop();
          }
        },
        child: FloatingActionButton.extended(
          heroTag: 'edit-note-${note.id}',
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.edit_rounded),
          label: Text('Edit',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          onPressed: () => context.push(Routes.editNote, extra: note),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
          children: [
            Text(note.createdAt.prettyDate, style: eyebrowStyle()),
            const SizedBox(height: 12),
            Text(
              title,
              style: pageTitleStyle(size: 32),
            ),
            const SizedBox(height: 20),
            // Source URL — quiet underlined inline link.
            InkWell(
              onTap: _openUrl,
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const ThinDivider(),
            const SizedBox(height: 28),
            // Body — plain markdown, generous line-height, no card chrome.
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
                    left: BorderSide(
                        color: AppColors.surfaceStroke, width: 2),
                  ),
                ),
                blockquotePadding: const EdgeInsets.only(left: 16),
                code: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: AppColors.accent,
                  backgroundColor: AppColors.bgTertiary.withOpacity(0.4),
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
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 32),
              const ThinDivider(),
              const SizedBox(height: 20),
              Text('TAG', style: eyebrowStyle()),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: note.tags
                    .map((t) => Text(
                          '#$t',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
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
}
