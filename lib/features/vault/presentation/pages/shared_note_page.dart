import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/share_repository.dart';

/// Public read-only page reachable via /share/:token. No auth required.
class SharedNotePage extends StatefulWidget {
  final String token;
  const SharedNotePage({super.key, required this.token});

  @override
  State<SharedNotePage> createState() => _SharedNotePageState();
}

class _SharedNotePageState extends State<SharedNotePage> {
  NoteEntity? _note;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<ShareRepository>().getByToken(widget.token);
    if (!mounted) return;
    res.fold(
      (f) => setState(() => _error = f.message),
      (n) => setState(() => _note = n),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('PUBLIK · BACA SAJA', style: eyebrowStyle()),
        actions: [
          if (_note != null)
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              tooltip: 'Buka sumber',
              onPressed: () async {
                final uri = Uri.tryParse(_note!.url);
                if (uri != null) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GAGAL MEMUAT', style: eyebrowStyle()),
                    const SizedBox(height: 12),
                    Text('Tautan tidak\nvalid.',
                        style: pageTitleStyle(size: 36)),
                    const SizedBox(height: 14),
                    Text(_error!, style: context.textStyles.bodyMedium),
                  ],
                ),
              )
            : _note == null
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    children: [
                      Text(_note!.createdAt.prettyDate,
                          style: eyebrowStyle()),
                      const SizedBox(height: 12),
                      Text(_note!.title ?? '(Tanpa judul)',
                          style: pageTitleStyle(size: 32)),
                      const SizedBox(height: 32),
                      const ThinDivider(),
                      const SizedBox(height: 28),
                      MarkdownBody(
                        data: _note!.manualNotes,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                                Theme.of(context))
                            .copyWith(
                          p: GoogleFonts.inter(
                            fontSize: 16,
                            height: 1.7,
                            color: AppColors.textPrimary,
                          ),
                          h1: GoogleFonts.spaceGrotesk(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          h2: GoogleFonts.spaceGrotesk(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          h3: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (_note!.tags.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        const ThinDivider(),
                        const SizedBox(height: 20),
                        Text('TAG', style: eyebrowStyle()),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: _note!.tags
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
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'Disimpan di IngatanKu — otak kedua tech-mu',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
