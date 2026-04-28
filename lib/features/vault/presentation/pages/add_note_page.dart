import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../data/datasources/metadata_remote_datasource.dart';
import '../../data/models/url_metadata.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/update_note.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/locale_toggle_chip.dart';
import '../widgets/tag_chip_input.dart';
import '../widgets/url_preview_card.dart';
import '../widgets/voice_input_button.dart';

class AddNotePage extends StatefulWidget {
  /// Pre-fill the URL field — used by the share-intent handler so the user
  /// can drop an Instagram/X link into IngatanKu via the Android share sheet.
  final String? initialUrl;

  /// When non-null, the page renders in edit mode: fields are pre-filled
  /// from the note and Save dispatches an update instead of an insert.
  final NoteEntity? existingNote;

  const AddNotePage({super.key, this.initialUrl, this.existingNote});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  List<String> _tags = [];
  bool _previewMode = false;

  // URL preview
  Timer? _debounce;
  UrlMetadata? _urlMeta;
  bool _metaLoading = false;
  String? _lastFetchedUrl;

  // Voice input
  late final VoiceInputService _voice = sl<VoiceInputService>();
  String _notesBeforeVoice = '';
  String _voiceLocale = 'id_ID';

  bool get _isEdit => widget.existingNote != null;

  @override
  void initState() {
    super.initState();
    _urlCtrl.addListener(_onUrlChanged);
    final n = widget.existingNote;
    if (n != null) {
      // Edit mode — pre-fill everything from the existing note.
      _urlCtrl.text = n.url;
      _titleCtrl.text = n.title ?? '';
      _notesCtrl.text = n.manualNotes;
      _tags = List.of(n.tags);
      _notesBeforeVoice = n.manualNotes;
      // Skip auto-metadata refetch on edit; user already curated this note.
      _lastFetchedUrl = n.url;
    } else if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      _urlCtrl.text = widget.initialUrl!;
      // Kick off metadata fetch immediately instead of waiting for debounce.
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchMeta());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _urlCtrl.removeListener(_onUrlChanged);
    _urlCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _voice.cancel();
    super.dispose();
  }

  void _onUrlChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _fetchMeta);
  }

  Future<void> _fetchMeta() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      if (_urlMeta != null || _metaLoading) {
        setState(() {
          _urlMeta = null;
          _metaLoading = false;
        });
      }
      return;
    }
    if (url == _lastFetchedUrl) return;
    _lastFetchedUrl = url;
    setState(() => _metaLoading = true);
    try {
      final meta = await sl<MetadataRemoteDataSource>().fetch(url);
      if (!mounted || _urlCtrl.text.trim() != url) return;
      setState(() {
        _urlMeta = meta.hasContent ? meta : null;
        _metaLoading = false;
      });
      // Auto-fill title if user hasn't typed one
      if (_titleCtrl.text.trim().isEmpty && meta.title != null) {
        _titleCtrl.text = meta.title!;
      }
    } catch (_) {
      if (mounted) setState(() => _metaLoading = false);
    }
  }

  void _onVoiceTranscript(String text, bool isFinal) {
    if (text.isEmpty) return;
    setState(() {
      final base = _notesBeforeVoice.isEmpty
          ? text
          : '$_notesBeforeVoice $text';
      _notesCtrl.text = base;
      _notesCtrl.selection =
          TextSelection.collapsed(offset: _notesCtrl.text.length);
    });
    if (isFinal) {
      _notesBeforeVoice = _notesCtrl.text;
    }
  }

  void _startVoice() {
    _notesBeforeVoice = _notesCtrl.text;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlCtrl.text.trim();
    final title = _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    if (_isEdit) {
      context.read<VaultBloc>().add(
            VaultNoteUpdated(UpdateNoteParams(
              id: widget.existingNote!.id,
              url: url,
              title: title,
              manualNotes: notes,
              tags: _tags,
              sourceType: url.sourceFromUrl,
            )),
          );
    } else {
      context.read<VaultBloc>().add(
            VaultNoteAdded(AddNoteParams(
              url: url,
              title: title,
              manualNotes: notes,
              tags: _tags,
              sourceType: url.sourceFromUrl,
            )),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VaultBloc, VaultState>(
      listener: (ctx, state) {
        if (state is VaultNoteAddSuccess) {
          context.showSnack('Catatan tersimpan · +10 XP');
          context.pop();
        } else if (state is VaultNoteUpdateSuccess) {
          context.showSnack('Perubahan tersimpan');
          context.pop();
        } else if (state is VaultError) {
          context.showSnack(state.message, error: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.bgPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            _isEdit ? 'EDIT CATATAN' : 'CATATAN BARU',
            style: eyebrowStyle(),
          ),
          actions: [
            IconButton(
              tooltip: _previewMode ? 'Sunting' : 'Pratinjau',
              icon: Icon(
                _previewMode
                    ? Icons.edit_outlined
                    : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _previewMode = !_previewMode),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              children: [
                // Hero title — quiet caption + editorial display.
                Text(
                  _isEdit ? 'Edit catatan.' : 'Catatan baru.',
                  style: pageTitleStyle(size: 32),
                ),
                const SizedBox(height: 32),

                // ─── URL ──────────────────────────────────────────────
                const SectionHeader(label: 'SUMBER'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    hintText: 'https://youtube.com/shorts/…',
                    prefixIcon: Icon(Icons.link_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'URL wajib diisi';
                    }
                    if (!v.startsWith('http')) {
                      return 'Harus diawali http(s)';
                    }
                    return null;
                  },
                ),
                UrlPreviewCard(meta: _urlMeta, loading: _metaLoading),
                const SizedBox(height: 36),

                // ─── Title ────────────────────────────────────────────
                const SectionHeader(label: 'JUDUL (OPSIONAL)'),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Beri nama yang mudah diingat',
                  ),
                ),
                const SizedBox(height: 36),

                // ─── Notes ────────────────────────────────────────────
                Row(
                  children: [
                    Text('CATATANMU', style: eyebrowStyle()),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                            color: AppColors.surfaceStroke, width: 1),
                      ),
                      child: Text(
                        'MD',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          letterSpacing: 1,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: AppColors.surfaceStroke.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    LocaleToggleChip(
                      localeId: _voiceLocale,
                      onChanged: (loc) =>
                          setState(() => _voiceLocale = loc),
                    ),
                    const SizedBox(width: 8),
                    VoiceInputButton(
                      service: _voice,
                      onTranscript: _onVoiceTranscript,
                      onStart: _startVoice,
                      localeId: _voiceLocale,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _previewMode
                      ? Container(
                          key: const ValueKey('preview'),
                          constraints:
                              const BoxConstraints(minHeight: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                AppColors.bgSecondary.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.surfaceStroke),
                          ),
                          child: MarkdownBody(
                            data: _notesCtrl.text.isEmpty
                                ? '_Belum ada yang bisa dipratinjau…_'
                                : _notesCtrl.text,
                            styleSheet: MarkdownStyleSheet.fromTheme(
                                    Theme.of(context))
                                .copyWith(
                              p: GoogleFonts.inter(
                                fontSize: 15,
                                height: 1.6,
                                color: AppColors.textPrimary,
                              ),
                              code: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                backgroundColor:
                                    AppColors.bgTertiary.withValues(alpha: 0.4),
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        )
                      : TextFormField(
                          key: const ValueKey('editor'),
                          controller: _notesCtrl,
                          maxLines: 12,
                          minLines: 8,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText:
                                'Tulis insight, ringkasan, atau hal yang ingin kamu ingat dari konten ini.',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().length < 10)
                                  ? 'Minimal 10 karakter'
                                  : null,
                        ),
                ),
                const SizedBox(height: 36),

                // ─── Tags ─────────────────────────────────────────────
                const SectionHeader(label: 'TAG'),
                const SizedBox(height: 14),
                TagChipInput(
                  tags: _tags,
                  onChanged: (t) => setState(() => _tags = t),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: BlocBuilder<VaultBloc, VaultState>(
            builder: (_, state) => EditorialButton(
              label: _isEdit ? 'Simpan perubahan' : 'Simpan ke Brankas',
              icon:
                  _isEdit ? Icons.check_rounded : Icons.save_alt_rounded,
              fullWidth: true,
              loading: state is VaultActionLoading,
              onPressed: _save,
            ),
          ),
        ),
      ),
    );
  }
}
