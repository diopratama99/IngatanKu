import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/markdown_editor.dart';
import '../../../companion/presentation/widgets/blob_mascot.dart';
import '../../../companion/presentation/widgets/pet_host.dart';
import '../../data/datasources/personal_note_image_store.dart';
import '../../domain/entities/personal_note.dart';
import '../../domain/repositories/personal_note_repository.dart';
import '../bloc/personal_notes_bloc.dart';
import '../widgets/note_color_palette.dart';
import '../widgets/note_paper.dart';
import '../../../../core/theme/app_fonts.dart';

/// Editor surface for personal notes. Operates in two modes:
///   * Add — `existing` is null. We mint a new uuid up front so
///     image attachments can be persisted into the right folder
///     before the row exists in the DB.
///   * Edit — fully prefilled from the existing note.
///
/// Saving is auto-on-back: tap the back button, the page persists
/// silently (matches Google Keep's behaviour). Discard via the
/// trash menu.
class PersonalNoteEditorPage extends StatefulWidget {
  final PersonalNote? existing;
  const PersonalNoteEditorPage({super.key, this.existing});

  @override
  State<PersonalNoteEditorPage> createState() => _PersonalNoteEditorPageState();
}

class _PersonalNoteEditorPageState extends State<PersonalNoteEditorPage> {
  static const _uuid = Uuid();

  final _titleCtrl = TextEditingController();
  final _bodyCtrl = MarkdownEditingController();

  /// While the body's being written, the formatting buttons show.
  final _bodyFocus = FocusNode();

  late String _noteId;
  late List<String> _imageFiles;
  late List<NoteLink> _links;
  late List<String> _tags;
  late NoteColor _color;
  late bool _pinned;
  late DateTime _createdAt;
  bool _saving = false;
  bool _deleted = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    if (n != null) {
      _noteId = n.id;
      _titleCtrl.text = n.title ?? '';
      _bodyCtrl.text = n.body;
      _imageFiles = List.of(n.imageFiles);
      _links = List.of(n.links);
      _tags = List.of(n.tags);
      _color = n.color;
      _pinned = n.pinned;
      _createdAt = n.createdAt;
    } else {
      _noteId = _uuid.v4();
      _imageFiles = [];
      _links = [];
      _tags = [];
      _color = NoteColor.defaultColor;
      _pinned = false;
      _createdAt = DateTime.now();
    }
    // A sheet of paper slides in.
    SoundService.instance.play(Sfx.notePaper);
    _bodyFocus.addListener(_onBodyFocus);
  }

  void _onBodyFocus() => setState(() {});

  @override
  void dispose() {
    _bodyFocus
      ..removeListener(_onBodyFocus)
      ..dispose();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // ── Image actions ────────────────────────────────────────────

  Future<void> _addImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 88);
      if (picked == null) return;
      final basename = await sl<PersonalNoteImageStore>().attach(
        noteId: _noteId,
        sourcePath: picked.path,
      );
      if (!mounted) return;
      SoundService.instance.play(Sfx.notePhoto);
      setState(() => _imageFiles = [..._imageFiles, basename]);
    } catch (e) {
      if (!mounted) return;
      context.showSnack(
          AppLocalizations.of(context)!.noteEditorImageAddFailed(e.toString()),
          error: true);
    }
  }

  Future<void> _showImageSourceSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: context.palette.surfaceStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: context.palette.textPrimary),
                title: Text(l10n.noteEditorImageSourceGallery,
                    style: AppFonts.body(color: context.palette.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: context.palette.textPrimary),
                title: Text(l10n.noteEditorImageSourceCamera,
                    style: AppFonts.body(color: context.palette.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (src != null) await _addImage(src);
  }

  Future<void> _removeImage(String filename) async {
    setState(() => _imageFiles = _imageFiles.where((f) => f != filename).toList());
    try {
      await sl<PersonalNoteImageStore>().detach(
        noteId: _noteId,
        filename: filename,
      );
    } catch (_) {/* non-fatal */}
  }

  // ── Link actions ─────────────────────────────────────────────

  Future<void> _addLink() async {
    final result = await showDialog<NoteLink>(
      context: context,
      builder: (ctx) => const _LinkDialog(),
    );
    if (result == null) return;
    SoundService.instance.play(Sfx.noteClip);
    setState(() => _links = [..._links, result]);
  }

  Future<void> _editLink(int idx) async {
    final initial = _links[idx];
    final result = await showDialog<NoteLink>(
      context: context,
      builder: (ctx) => _LinkDialog(initial: initial),
    );
    if (result == null) return;
    setState(() {
      final next = [..._links];
      next[idx] = result;
      _links = next;
    });
  }

  void _removeLink(int idx) {
    setState(() => _links = [..._links]..removeAt(idx));
  }

  // ── Save / discard ───────────────────────────────────────────

  /// Auto-save on back. We persist when the note has any content
  /// (title, body, image, or link); pure-empty drafts are silently
  /// discarded and their on-disk image folder cleaned, matching how
  /// Google Keep behaves.
  Future<bool> _saveAndPop() async {
    if (_deleted) return true; // already removed via menu
    if (_saving) return false;
    final draft = _buildDraft();
    if (draft.isEmpty) {
      // Nothing worth keeping. Clean up any picked images that the
      // user added then removed and bail.
      await sl<PersonalNoteImageStore>().deleteAll(_noteId);
      return true;
    }
    setState(() => _saving = true);
    final repo = sl<PersonalNoteRepository>();
    final fut = _isEdit ? repo.update(draft) : repo.create(draft);
    final res = await fut;
    if (!mounted) return true;
    setState(() => _saving = false);
    return res.fold(
      (f) {
        context.showSnack(
            AppLocalizations.of(context)!.noteEditorSaveFailed(f.message),
            error: true);
        return false; // keep editor open so user can retry
      },
      (saved) {
        context.read<PersonalNotesBloc>().add(PersonalNotesNoteUpserted(saved));
        return true;
      },
    );
  }

  PersonalNote _buildDraft() {
    final userId = sl<SupabaseService>().currentUserId ?? '';
    return PersonalNote(
      id: _noteId,
      userId: userId,
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      body: _bodyCtrl.text,
      imageFiles: _imageFiles,
      links: _links,
      tags: _tags,
      pinned: _pinned,
      color: _color,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _isEdit
              ? l10n.noteEditorDiscardEditTitle
              : l10n.noteEditorDiscardNewTitle,
        ),
        content: Text(
          _isEdit
              ? l10n.noteEditorDiscardEditMessage
              : l10n.noteEditorDiscardNewMessage,
          style: AppFonts.body(
            fontSize: 14,
            color: context.palette.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
                foregroundColor: context.palette.textSecondary),
            child: Text(l10n.noteEditorDiscardCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
            child: Text(_isEdit
                ? l10n.noteEditorDiscardEditConfirm
                : l10n.noteEditorDiscardNewConfirm),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    SoundService.instance.play(Sfx.noteCrumple);
    setState(() => _deleted = true);
    if (_isEdit) {
      // Persisted note — go through bloc so list updates.
      context
          .read<PersonalNotesBloc>()
          .add(PersonalNotesNoteDeleted(widget.existing!.id));
    } else {
      // Draft only on disk — wipe its image folder.
      await sl<PersonalNoteImageStore>().deleteAll(_noteId);
    }
    if (mounted) context.pop();
  }

  // ── Color picker ─────────────────────────────────────────────

  Future<void> _pickColor() async {
    final next = await showModalBottomSheet<NoteColor>(
      context: context,
      builder: (_) => _ColorPickerSheet(current: _color),
    );
    if (next == null || next == _color) return;
    SoundService.instance.play(Sfx.noteColor);
    setState(() => _color = next);
  }

  Future<void> _back() async {
    final router = GoRouter.of(context);
    final ok = await _saveAndPop();
    if (ok && mounted) router.pop();
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final ink = palette.textPrimary;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _back();
      },
      child: Scaffold(
        backgroundColor: palette.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              _EditorTopBar(
                title: _isEdit
                    ? l10n.noteEditorEditTitle
                    : l10n.noteEditorNewTitle,
                pinned: _pinned,
                onBack: _back,
                onPin: () {
                  // Taped up when pinned; peeled off quietly.
                  if (!_pinned) SoundService.instance.play(Sfx.noteTape);
                  setState(() => _pinned = !_pinned);
                },
                onDelete: _discard,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  children: [
                    // The note itself: a sheet of notepaper in its colour.
                    NotePaper(
                      color: _color,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_imageFiles.isNotEmpty) ...[
                            _ImageStrip(
                              noteId: _noteId,
                              filenames: _imageFiles,
                              onRemove: _removeImage,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextField(
                            controller: _titleCtrl,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            style: AppFonts.display(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ink,
                              height: 1.25,
                              letterSpacing: -0.5,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                              hintText: l10n.noteEditorTitleHint,
                              hintStyle: AppFonts.display(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: ink.withValues(alpha: 0.28),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(_createdAt)
                                .toUpperCase(),
                            style: eyebrowStyle(
                                color: ink.withValues(alpha: 0.45)),
                          ),
                          const SizedBox(height: 10),
                          // Lined paper under the body text.
                          CustomPaint(
                            painter: RuledLines(
                              lineHeight: _lineHeight,
                              baseline: _lineHeight - 3,
                              color: ink.withValues(alpha: 0.1),
                            ),
                            child: TextField(
                              controller: _bodyCtrl,
                              focusNode: _bodyFocus,
                              inputFormatters: const [
                                MarkdownListContinuation(),
                              ],
                              maxLines: null,
                              minLines: 9,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              style: AppFonts.body(
                                fontSize: 15,
                                height: _lineHeight / 15,
                                color: ink,
                              ),
                              strutStyle: const StrutStyle(
                                fontSize: 15,
                                height: _lineHeight / 15,
                                forceStrutHeight: true,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                hintText: l10n.noteEditorBodyHint,
                                hintStyle: AppFonts.body(
                                  fontSize: 15,
                                  height: _lineHeight / 15,
                                  color: ink.withValues(alpha: 0.32),
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_links.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(l10n.noteEditorSectionLinks,
                                style: eyebrowStyle(
                                    color: ink.withValues(alpha: 0.55))),
                            const SizedBox(height: 8),
                            _LinksList(
                              links: _links,
                              onTap: _editLink,
                              onRemove: _removeLink,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bold, headings and lists, over the keyboard while the body
              // is being written. Left-aligned: the pet peeks over the
              // bar below on the right.
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.bottomCenter,
                child: _bodyFocus.hasFocus
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(4, 4, 0, 4),
                            decoration: softCard(context, radius: 18),
                            child: MarkdownToolbar(controller: _bodyCtrl),
                          ),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
              // Rides on top of the keyboard while you type.
              _BottomToolbar(
                color: _color,
                onAddImage: _showImageSourceSheet,
                onAddLink: _addLink,
                onPickColor: _pickColor,
                saving: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// One line of the body text, and of the paper's rules.
  static const double _lineHeight = 27;
}

// ════════════════════════════════════════════════════════════════
//                       SUPPORTING WIDGETS
// ════════════════════════════════════════════════════════════════

/// Back on the left, the page's name in the middle, pin and delete on
/// the right.
class _EditorTopBar extends StatelessWidget {
  final String title;
  final bool pinned;
  final VoidCallback onBack;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  const _EditorTopBar({
    required this.title,
    required this.pinned,
    required this.onBack,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PageTopBar(
      title: title,
      onBack: onBack,
      trailing: Container(
        decoration: softCard(context, radius: 22),
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PillIcon(
              icon: pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              tooltip: pinned
                  ? l10n.noteEditorUnpinTooltip
                  : l10n.noteEditorPinTooltip,
              selected: pinned,
              onTap: onPin,
            ),
            _PillIcon(
              icon: Icons.delete_outline_rounded,
              tooltip: l10n.noteEditorDeleteTooltip,
              color: context.palette.danger,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// An icon inside a pill of actions; [selected] fills it with cream.
class _PillIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;
  final Color? color;
  const _PillIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? palette.primaryMuted : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 20,
            color: selected
                ? palette.primary
                : (color ?? palette.textPrimary),
          ),
        ),
      ),
    );
  }
}

/// Photos on the note, like polaroids clipped to the page.
class _ImageStrip extends StatelessWidget {
  final String noteId;
  final List<String> filenames;
  final void Function(String) onRemove;
  const _ImageStrip({
    required this.noteId,
    required this.filenames,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final store = sl<PersonalNoteImageStore>();
    final palette = context.palette;
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: filenames.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final f = filenames[i];
          final placeholder = Container(
            width: 150,
            height: 150,
            color: palette.bgTertiary,
            alignment: Alignment.center,
            child: Icon(Icons.image_outlined, color: palette.textTertiary),
          );
          return Transform.rotate(
            angle: i.isEven ? -0.02 : 0.02,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: FutureBuilder<String>(
                      future: store.pathFor(noteId: noteId, filename: f),
                      builder: (_, snap) => !snap.hasData
                          ? placeholder
                          : Image.file(
                              File(snap.data!),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => placeholder,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Tooltip(
                    message: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                    child: InkResponse(
                      onTap: () => onRemove(f),
                      radius: 18,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.surfaceStroke),
                        ),
                        child: Icon(Icons.close_rounded,
                            size: 15, color: palette.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LinksList extends StatelessWidget {
  final List<NoteLink> links;
  final void Function(int) onTap;
  final void Function(int) onRemove;
  const _LinksList({
    required this.links,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < links.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _LinkRow(
              link: links[i],
              onTap: () => onTap(i),
              onRemove: () => onRemove(i),
            ),
          ),
      ],
    );
  }
}

/// A link clipped to the note.
class _LinkRow extends StatelessWidget {
  final NoteLink link;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _LinkRow({
    required this.link,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.attach_file_rounded,
                    size: 17, color: palette.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      link.effectiveLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.body(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (link.label.isNotEmpty)
                      Text(
                        link.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.body(
                          fontSize: 12,
                          color: palette.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    size: 16, color: palette.textTertiary),
                onPressed: onRemove,
                tooltip:
                    AppLocalizations.of(context)!.noteEditorRemoveLinkTooltip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkDialog extends StatefulWidget {
  final NoteLink? initial;
  const _LinkDialog({this.initial});

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final _urlCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _urlCtrl.text = i.url;
      _labelCtrl.text = i.label;
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    Navigator.pop(
      context,
      NoteLink(url: url, label: _labelCtrl.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        widget.initial == null
            ? l10n.noteEditorLinkDialogAddTitle
            : l10n.noteEditorLinkDialogEditTitle,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _urlCtrl,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              hintText: l10n.noteEditorLinkUrlHint,
              prefixIcon: const Icon(Icons.link_rounded, size: 18),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              hintText: l10n.noteEditorLinkLabelHint,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
              foregroundColor: context.palette.textSecondary),
          child: Text(l10n.noteEditorLinkCancel),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          ),
          child: Text(l10n.noteEditorLinkSave),
        ),
      ],
    );
  }
}

/// The paper colours, as little sticky notes to pick from.
class _ColorPickerSheet extends StatelessWidget {
  final NoteColor current;
  const _ColorPickerSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: context.palette.surfaceStroke,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l10n.noteEditorColorPickerEyebrow,
                style: eyebrowStyle(context: context)),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, c) {
              // Six to a row, however wide the sheet is.
              final size = (c.maxWidth - 5 * 12) / 6;
              return Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (final color in NoteColor.values)
                    _ColorSwatch(
                      color: color,
                      size: size,
                      selected: color == current,
                      onTap: () => Navigator.pop(context, color),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final NoteColor color;
  final double size;
  final bool selected;
  final VoidCallback onTap;
  const _ColorSwatch({
    required this.color,
    required this.size,
    required this.selected,
    required this.onTap,
  });

  String _localizedLabel(AppLocalizations l10n, NoteColor c) {
    switch (c) {
      case NoteColor.defaultColor:
        return l10n.noteColorDefault;
      case NoteColor.red:
        return l10n.noteColorRed;
      case NoteColor.orange:
        return l10n.noteColorOrange;
      case NoteColor.yellow:
        return l10n.noteColorYellow;
      case NoteColor.green:
        return l10n.noteColorGreen;
      case NoteColor.teal:
        return l10n.noteColorTeal;
      case NoteColor.blue:
        return l10n.noteColorBlue;
      case NoteColor.purple:
        return l10n.noteColorPurple;
      case NoteColor.pink:
        return l10n.noteColorPink;
      case NoteColor.brown:
        return l10n.noteColorBrown;
      case NoteColor.gray:
        return l10n.noteColorGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final label = _localizedLabel(AppLocalizations.of(context)!, color);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: NoteColorPalette.background(color),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? palette.primary
                    : NoteColorPalette.border(color),
                width: selected ? 2.2 : 1,
              ),
            ),
            child: Stack(
              children: [
                // A strip of the colour along the top, like a sticky
                // note's glue edge.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: size * 0.22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: NoteColorPalette.swatch(color)
                          .withValues(alpha: 0.55),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11)),
                    ),
                  ),
                ),
                if (selected)
                  Center(
                    child: Icon(Icons.check_rounded,
                        size: 20, color: palette.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A floating pill of tools under the note — photo, link, paper colour —
/// with the pet peeking over it in its reading glasses, keeping you
/// company while you write. Saving happens on its own when you leave.
class _BottomToolbar extends StatelessWidget {
  final NoteColor color;
  final VoidCallback onAddImage;
  final VoidCallback onAddLink;
  final VoidCallback onPickColor;
  final bool saving;
  const _BottomToolbar({
    required this.color,
    required this.onAddImage,
    required this.onAddLink,
    required this.onPickColor,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Behind the pill, so only its head and glasses show over it.
          const Positioned(
            right: 12,
            bottom: 44,
            child: IgnorePointer(
              child: PetHost(
                height: 52,
                glasses: true,
                expression: BlobExpression.serious,
              ),
            ),
          ),
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: softCard(context, radius: 29),
            child: Row(
              children: [
                _ToolButton(
                  tooltip: l10n.noteEditorAddImageTooltip,
                  onTap: onAddImage,
                  child: Icon(Icons.add_photo_alternate_outlined,
                      size: 22, color: palette.textPrimary),
                ),
                _ToolButton(
                  tooltip: l10n.noteEditorAddLinkTooltip,
                  onTap: onAddLink,
                  child: Icon(Icons.link_rounded,
                      size: 22, color: palette.textPrimary),
                ),
                _ToolButton(
                  tooltip: l10n.noteEditorColorTooltip,
                  onTap: onPickColor,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: NoteColorPalette.background(color),
                      border: Border.all(
                        // Plain paper gets a quiet ring so it still shows.
                        color: color == NoteColor.defaultColor
                            ? palette.textTertiary.withValues(alpha: 0.6)
                            : NoteColorPalette.swatch(color),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(saving),
                      children: [
                        if (saving) ...[
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: palette.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            saving
                                ? l10n.noteEditorSaving
                                : l10n.noteEditorAutoSave,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.body(
                              fontSize: 12,
                              color: palette.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Room for the pet.
                const SizedBox(width: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  const _ToolButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(width: 46, height: 46, child: Center(child: child)),
      ),
    );
  }
}
