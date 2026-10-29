import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/markdown_editor.dart';
import '../../../companion/presentation/widgets/pet_offline.dart';
import '../../data/datasources/metadata_remote_datasource.dart';
import '../../data/models/url_metadata.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/auto_summarize_repository.dart';
import '../../domain/usecases/add_note.dart';
import '../../domain/usecases/auto_summarize.dart';
import '../../domain/usecases/update_note.dart';
import '../bloc/vault_bloc.dart';
import '../widgets/locale_toggle_chip.dart';
import '../widgets/quiz_toggle.dart';
import '../widgets/tag_chip_input.dart';
import '../widgets/url_preview_card.dart';
import '../widgets/voice_input_button.dart';
import '../../../../core/theme/app_fonts.dart';

class AddNotePage extends StatefulWidget {
  /// Pre-fill the URL field. (Links shared from other apps now go to
  /// Beranda's link bar instead, where the pet writes them up.)
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
  final _notesCtrl = MarkdownEditingController();
  List<String> _tags = [];

  /// Whether the quizzes may ask about this note.
  bool _inQuiz = true;
  bool _previewMode = false;

  // URL preview
  Timer? _debounce;
  UrlMetadata? _urlMeta;
  bool _metaLoading = false;
  String? _lastFetchedUrl;
  // Captured at fetch-meta time so it can be persisted on save without
  // re-running the scrape. Cleared whenever the URL changes.
  String? _capturedThumbnailUrl;

  // Voice input
  late final VoiceInputService _voice = sl<VoiceInputService>();
  String _notesBeforeVoice = '';
  String _voiceLocale = 'id_ID';

  // Auto-fill
  StreamSubscription<AutoSummarizeEvent>? _autoFillSub;
  bool _autoFilling = false;
  String? _autoFillHint;

  bool get _isEdit => widget.existingNote != null;

  /// True when the typed URL points to a platform supported by the
  /// transcribe-and-summarize backend path. YouTube already uses native
  /// caption transcripts via the meta path so we don't expose the button
  /// for it. Backend currently routes IG / TikTok / X through Cobalt +
  /// Whisper; Threads & Facebook fall back to the default OG-scrape
  /// path which doesn't need the slow CTA.
  bool get _supportsTranscribe {
    final src = _urlCtrl.text.trim().sourceFromUrl;
    return src == 'instagram' || src == 'tiktok' || src == 'x';
  }

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.online.addListener(_onNetwork);
    _urlCtrl.addListener(_onUrlChanged);
    final n = widget.existingNote;
    if (n != null) {
      // Edit mode — pre-fill everything from the existing note.
      _urlCtrl.text = n.url;
      _titleCtrl.text = n.title ?? '';
      _notesCtrl.text = n.manualNotes;
      _tags = List.of(n.tags);
      _inQuiz = n.inQuiz;
      _notesBeforeVoice = n.manualNotes;
      _capturedThumbnailUrl = n.thumbnailUrl;
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
    ConnectivityService.instance.online.removeListener(_onNetwork);
    _debounce?.cancel();
    _autoFillSub?.cancel();
    _typing(false);
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
    // Rebuild so the transcribe button shows/hides as the user types.
    if (mounted) setState(() {});
  }

  Future<void> _fetchMeta() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      if (_urlMeta != null || _metaLoading) {
        setState(() {
          _urlMeta = null;
          _metaLoading = false;
          _capturedThumbnailUrl = null;
        });
      }
      return;
    }
    if (url == _lastFetchedUrl) return;
    // Offline: no preview for now (it's fetched once back online).
    if (!ConnectivityService.instance.hasNetwork) return;
    _lastFetchedUrl = url;
    setState(() => _metaLoading = true);
    try {
      final meta = await sl<MetadataRemoteDataSource>().fetch(url);
      if (!mounted || _urlCtrl.text.trim() != url) return;
      setState(() {
        _urlMeta = meta.hasContent ? meta : null;
        _metaLoading = false;
        // Even when the card decides not to render (no title/image present
        // on the meta object), `meta.image` may still hold a thumbnail
        // worth persisting — so we capture from the raw meta.
        _capturedThumbnailUrl = meta.image;
      });
      // NOTE: tidak auto-fill title dari OG meta. Title dari sumber
      // (mis. "@username on Instagram") jarang akurat untuk catatan
      // teknis. User bisa:
      //   * Ketik judul sendiri di field title, atau
      //   * Tap "Rapikan dengan AI" → AI generate H1 yang sesuai isi
      //     dan otomatis dipindah ke title via _hoistTitleFromMarkdown.
    } catch (e) {
      // No connection: try again when there is one.
      if (isOfflineError(e)) _lastFetchedUrl = null;
      if (mounted) setState(() => _metaLoading = false);
    }
  }

  void _onNetwork() {
    if (ConnectivityService.instance.hasNetwork && mounted) _fetchMeta();
  }

  void _onVoiceTranscript(String text, bool isFinal) {
    if (text.isEmpty) return;
    setState(() {
      final base =
          _notesBeforeVoice.isEmpty ? text : '$_notesBeforeVoice $text';
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

  // ─── Auto-fill ──────────────────────────────────────────────────
  // Streams a markdown draft from the auto-summarize Edge Function and
  // appends each token to the notes field as it arrives.
  //
  // Routing strategy: when the URL is on a Cobalt-supported video
  // platform (IG / TikTok / X), we automatically opt into the
  // transcribe path because it produces a far richer markdown draft
  // (full spoken transcript → LLM) compared to the meta-scrape path
  // (just the og:description). With the self-hosted Whisper + Cobalt
  // stack the transcribe round-trip is ~5s — same order of magnitude
  // as the meta path — so there's no UX reason to expose a choice.
  // YouTube already has native captions on the meta path so it stays
  // on the fast track. Everything else (Threads, Facebook, articles)
  // falls back to meta-scrape.
  //
  // If the user has already drafted >10 chars we ask before discarding.
  Future<void> _runAutoFill() async {
    if (_autoFilling) return;
    final l10n = AppLocalizations.of(context)!;
    final url = _urlCtrl.text.trim();
    if (url.isEmpty || !url.startsWith('http')) {
      context.showSnack(l10n.addNoteAutoFillNeedUrl, error: true);
      return;
    }
    if (!await ensureOnline(context, OnlineFeature.summary) || !mounted) {
      return;
    }
    final transcribe = _supportsTranscribe;
    final existing = _notesCtrl.text.trim();
    if (existing.length > 10) {
      final ok = await _confirmReplace(transcribe: transcribe);
      if (!ok || !mounted) return;
    }
    _notesCtrl.clear();
    setState(() {
      _autoFilling = true;
      _autoFillHint = transcribe
          ? l10n.addNoteAutoFillTranscribing
          : l10n.addNoteAutoFillProcessing;
    });

    _autoFillSub = sl<AutoSummarize>()(
      url: url,
      transcribe: transcribe,
      // Pull from app settings so AI output language matches whatever
      // the user picked in `/profile/account` — lets bilingual users
      // get an English summary even on an ID-default device.
      locale: AppSettingsService.instance.resolvedLocale.languageCode,
    ).listen(
      (event) {
        if (!mounted) return;
        if (event is AutoSummarizeMeta) {
          setState(() => _autoFillHint =
              l10n.addNoteAutoFillContentFound(event.contentLabel));
        } else if (event is AutoSummarizeStage) {
          // Server-driven stage label — overrides the local hint so the
          // user sees progressive copy ("Mengunduh audio…" →
          // "Transkripsi…" → "Meringkas…").
          setState(() => _autoFillHint = event.label);
        } else if (event is AutoSummarizeToken) {
          _typing(true);
          // Append directly via .text — TextField will rebuild and scroll
          // its inner view to follow the cursor.
          _notesCtrl.text = _notesCtrl.text + event.token;
          _notesCtrl.selection =
              TextSelection.collapsed(offset: _notesCtrl.text.length);
        } else if (event is AutoSummarizeDone) {
          // LLM diminta nge-emit baris pertama sebagai `# Judul`.
          // Setelah stream selesai, extract baris itu jadi title note
          // (overwrite OG-meta title yang sering jelek dari IG/TikTok)
          // dan strip dari body biar gak duplicated di catatan.
          _typing(false);
          _hoistTitleFromMarkdown();
          setState(() {
            _autoFilling = false;
            _autoFillHint = null;
          });
        } else if (event is AutoSummarizeError) {
          _typing(false);
          _autoFillFailed(event.message);
          setState(() {
            _autoFilling = false;
            _autoFillHint = null;
          });
        }
      },
      onError: (e) {
        if (!mounted) return;
        _typing(false);
        _autoFillFailed(e);
        setState(() {
          _autoFilling = false;
          _autoFillHint = null;
        });
      },
      onDone: () {
        if (!mounted) return;
        _typing(false);
        if (_autoFilling) {
          _hoistTitleFromMarkdown();
          setState(() {
            _autoFilling = false;
            _autoFillHint = null;
          });
        }
      },
    );
  }

  /// Keys click softly while the words come in (not while it's still
  /// fetching or transcribing).
  void _typing(bool on) => SoundService.instance.setLoop(SfxLoop.typing, on);

  /// The pet says it needs the internet when that was why; otherwise the
  /// error, briefly.
  void _autoFillFailed(Object error) {
    if (isOfflineError(error)) {
      showPetOffline(context, OnlineFeature.summary);
    } else {
      context.showSnack(
          AppLocalizations.of(context)!.addNoteAutoFillError(error.toString()),
          error: true);
    }
  }

  /// Pisahkan baris pertama `# Judul` dari body markdown hasil
  /// auto-summarize. Title-nya dipindah ke [_titleCtrl] (overwrite
  /// OG-meta title kalau ada — user intent saat trigger auto-fill
  /// adalah dapat judul yang sesuai isi konten, bukan caption IG)
  /// dan body-nya dibersihkan biar judul tidak muncul ganda. Aman
  /// kalau LLM gak comply (no-op kalau baris pertama bukan H1).
  void _hoistTitleFromMarkdown() {
    final body = _notesCtrl.text;
    if (body.isEmpty) return;
    // Skip leading whitespace lines to find first non-empty line.
    final lines = body.split('\n');
    var firstNonEmpty = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) {
        firstNonEmpty = i;
        break;
      }
    }
    if (firstNonEmpty == -1) return;
    final headLine = lines[firstNonEmpty].trim();
    final h1Match = RegExp(r'^#\s+(.+)$').firstMatch(headLine);
    if (h1Match == null) return;
    final extracted = h1Match.group(1)!.trim();
    if (extracted.isEmpty || extracted.length > 120) return;

    // Drop H1 line + any following blank line so body starts cleanly.
    var cutFrom = firstNonEmpty + 1;
    if (cutFrom < lines.length && lines[cutFrom].trim().isEmpty) {
      cutFrom += 1;
    }
    final remaining = lines.sublist(cutFrom).join('\n').trimLeft();

    // Selalu overwrite title saat auto-fill sukses keluarkan H1.
    // Title OG/Microlink (`Maven (@mavenhq) • Instagram reel`) gak
    // akurat untuk catatan teknis — user yang trigger auto-fill jelas
    // pengen judul yang sesuai isi, bukan caption sumber. Kalau user
    // emang mau judul lain, dia bisa edit ulang setelah AI selesai.
    _titleCtrl.text = extracted;
    _notesCtrl.text = remaining;
    _notesCtrl.selection =
        TextSelection.collapsed(offset: _notesCtrl.text.length);
  }

  /// Handler saat note berhasil ke-save. Pop kembali ke halaman
  /// sebelumnya, lalu surface snack di parent.
  void _onSavedSuccess(
    BuildContext context, {
    required bool isUpdate,
    required AppLocalizations l10n,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    SoundService.instance.play(Sfx.noteSaved);
    context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content:
            Text(isUpdate ? l10n.addNoteUpdatedSnack : l10n.addNoteSavedSnack),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ));
  }

  Future<bool> _confirmReplace({required bool transcribe}) async {
    final l10n = AppLocalizations.of(context)!;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.palette.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: context.palette.surfaceStroke),
        ),
        title: Text(
          l10n.addNoteReplaceDialogTitle,
          style: AppFonts.display(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.palette.textPrimary,
          ),
        ),
        content: Text(
          transcribe
              ? l10n.addNoteReplaceDialogTranscribe
              : l10n.addNoteReplaceDialogScrape,
          style: AppFonts.body(
            fontSize: 14,
            height: 1.5,
            color: context.palette.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
                foregroundColor: context.palette.textSecondary),
            child: Text(l10n.addNoteReplaceDialogCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: context.palette.primary),
            child: Text(l10n.addNoteReplaceDialogConfirm),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final url = _urlCtrl.text.trim();
    final title =
        _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim();
    final notes = _notesCtrl.text.trim();
    final thumb =
        (_capturedThumbnailUrl != null && _capturedThumbnailUrl!.isNotEmpty)
            ? _capturedThumbnailUrl
            : null;
    if (_isEdit) {
      context.read<VaultBloc>().add(
            VaultNoteUpdated(UpdateNoteParams(
              id: widget.existingNote!.id,
              url: url,
              title: title,
              manualNotes: notes,
              tags: _tags,
              sourceType: url.sourceFromUrl,
              thumbnailUrl: thumb,
              inQuiz: _inQuiz,
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
              thumbnailUrl: thumb,
              inQuiz: _inQuiz,
            )),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<VaultBloc, VaultState>(
      listener: (ctx, state) {
        if (state is VaultNoteAddSuccess) {
          _onSavedSuccess(
            context,
            isUpdate: false,
            l10n: l10n,
          );
        } else if (state is VaultNoteUpdateSuccess) {
          _onSavedSuccess(
            context,
            isUpdate: true,
            l10n: l10n,
          );
        } else if (state is VaultError) {
          context.showSnack(state.message, error: true);
        }
      },
      child: Scaffold(
        appBar: PageTopBar(
          title: _isEdit ? l10n.addNoteEditEyebrow : l10n.addNoteNewEyebrow,
          trailing: RoundIconButton(
            tooltip: _previewMode
                ? l10n.addNoteToggleEdit
                : l10n.addNoteTogglePreview,
            icon: _previewMode ? Icons.edit_outlined : Icons.visibility_outlined,
            onTap: () => setState(() => _previewMode = !_previewMode),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              children: [
                // Hero title — quiet caption + editorial display.
                Text(
                  _isEdit ? l10n.addNoteEditTitle : l10n.addNoteNewTitle,
                  style: pageTitleStyle(context: context, size: 32),
                ),
                const SizedBox(height: 32),

                // ─── URL ──────────────────────────────────────────────
                SectionHeader(label: l10n.addNoteSectionSource),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    hintText: l10n.addNoteUrlHint,
                    prefixIcon: const Icon(Icons.link_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l10n.addNoteUrlRequired;
                    }
                    if (!v.startsWith('http')) {
                      return l10n.addNoteUrlMustStartWithHttp;
                    }
                    return null;
                  },
                ),
                UrlPreviewCard(meta: _urlMeta, loading: _metaLoading),
                // Up here, with the link: whether it's something to learn
                // or just to keep (a comic or book title) is about the link.
                const SizedBox(height: 12),
                QuizToggle(
                  value: _inQuiz,
                  onChanged: (v) => setState(() => _inQuiz = v),
                ),
                const SizedBox(height: 36),

                // ─── Title ────────────────────────────────────────────
                SectionHeader(label: l10n.addNoteSectionTitle),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(
                    hintText: l10n.addNoteTitleHint,
                  ),
                ),
                const SizedBox(height: 36),

                // ─── Notes ────────────────────────────────────────────
                Row(
                  children: [
                    Text(l10n.addNoteSectionNotes,
                        style: eyebrowStyle(context: context)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: context.palette.surfaceStroke
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Auto-fill — streams an LLM draft into the notes
                    // field. For IG/TikTok/X URLs we automatically use
                    // the transcribe path (richer output, slower). For
                    // everything else we use meta-scrape (fast).
                    Tooltip(
                      message: _autoFilling
                          ? l10n.addNoteAutoFillTooltipProcessing
                          : (_supportsTranscribe
                              ? l10n.addNoteAutoFillTooltipTranscribe
                              : l10n.addNoteAutoFillTooltipUrl),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _autoFilling ? null : _runAutoFill,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _autoFilling
                                  ? context.palette.primary
                                  : context.palette.surfaceStroke,
                            ),
                          ),
                          child: _autoFilling
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.6,
                                    color: context.palette.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 18,
                                  color: context.palette.textSecondary,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LocaleToggleChip(
                      localeId: _voiceLocale,
                      onChanged: (loc) => setState(() => _voiceLocale = loc),
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
                if (_autoFillHint != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: context.palette.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: context.palette.primary.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.4,
                            color: context.palette.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _autoFillHint!,
                            style: AppFonts.body(
                              fontSize: 12,
                              color: context.palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Bold, headings and lists without knowing Markdown.
                if (!_previewMode) ...[
                  const SizedBox(height: 10),
                  MarkdownToolbar(controller: _notesCtrl),
                ],
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _previewMode
                      ? Container(
                          key: const ValueKey('preview'),
                          constraints: const BoxConstraints(minHeight: 180),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.palette.bgSecondary
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: context.palette.surfaceStroke),
                          ),
                          child: MarkdownBody(
                            data: _notesCtrl.text.isEmpty
                                ? l10n.addNotePreviewEmpty
                                : _notesCtrl.text,
                            styleSheet:
                                MarkdownStyleSheet.fromTheme(Theme.of(context))
                                    .copyWith(
                              p: AppFonts.body(
                                fontSize: 15,
                                height: 1.6,
                                color: context.palette.textPrimary,
                              ),
                              code: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                backgroundColor: context.palette.bgTertiary
                                    .withValues(alpha: 0.4),
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        )
                      : TextFormField(
                          key: const ValueKey('editor'),
                          controller: _notesCtrl,
                          inputFormatters: const [MarkdownListContinuation()],
                          maxLines: 12,
                          minLines: 8,
                          style: AppFonts.body(
                            fontSize: 15,
                            height: 1.6,
                            color: context.palette.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.addNoteNotesHint,
                          ),
                          validator: (v) => (v == null || v.trim().length < 10)
                              ? l10n.addNoteNotesMinLength
                              : null,
                        ),
                ),
                const SizedBox(height: 36),

                // ─── Tags ─────────────────────────────────────────────
                SectionHeader(label: l10n.addNoteSectionTags),
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
              label:
                  _isEdit ? l10n.addNoteUpdateButton : l10n.addNoteSaveButton,
              icon: _isEdit ? Icons.check_rounded : Icons.save_alt_rounded,
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
