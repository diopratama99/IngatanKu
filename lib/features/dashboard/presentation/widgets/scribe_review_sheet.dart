import 'package:flutter/material.dart';

import '../../../../core/theme/app_fonts.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/source_meta.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../../shared/widgets/markdown_editor.dart';
import '../../../companion/domain/companion_style.dart';
import '../../../companion/presentation/widgets/food_painter.dart';
import '../../../vault/presentation/widgets/quiz_toggle.dart';
import '../../../vault/presentation/widgets/tag_chip_input.dart';
import '../../domain/note_draft.dart';

/// What the pet wrote up for a link — title, notes and tags, plus where it
/// came from — for you to check and fix before it's saved and eaten.
/// Returns the edited draft, or null when you cancel.
Future<NoteDraft?> showScribeReview(
  BuildContext context, {
  required NoteDraft draft,
  required String petName,
}) {
  SoundService.instance.play(Sfx.sheetOpen);
  return showModalBottomSheet<NoteDraft>(
    context: context,
    // Above the shell so the floating nav bar doesn't cover it.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.bgSecondary,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _ScribeReviewSheet(draft: draft, petName: petName),
  );
}

class _ScribeReviewSheet extends StatefulWidget {
  final NoteDraft draft;
  final String petName;
  const _ScribeReviewSheet({required this.draft, required this.petName});

  @override
  State<_ScribeReviewSheet> createState() => _ScribeReviewSheetState();
}

class _ScribeReviewSheetState extends State<_ScribeReviewSheet> {
  late final _title = TextEditingController(text: widget.draft.title ?? '');
  late final _notes = MarkdownEditingController(text: widget.draft.notes);
  late List<String> _tags = List.of(widget.draft.tags);
  late bool _inQuiz = widget.draft.inQuiz;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    Navigator.of(context).pop(widget.draft.copyWith(
      title: title,
      notes: _notes.text.trim(),
      tags: _tags,
      inQuiz: _inQuiz,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.palette;
    final draft = widget.draft;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      // The fields scroll; the buttons stay put at the bottom.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.surfaceStroke,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.scribeSheetEyebrow(widget.petName).toUpperCase(),
                    style: eyebrowStyle(context: context),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.scribeSheetTitle,
                    style: AppFonts.display(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SourceRow(draft: draft),
                  // With the link, where it's seen straight away.
                  const SizedBox(height: 10),
                  QuizToggle(
                    value: _inQuiz,
                    onChanged: (v) => setState(() => _inQuiz = v),
                  ),
                  if (!draft.summarized) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: palette.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            draft.outOfQuota
                                ? l10n.scribeSheetOutOfQuota
                                : l10n.scribeSheetNoSummary,
                            style: AppFonts.body(
                              fontSize: 13,
                              height: 1.4,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(l10n.addNoteSectionTitle,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppFonts.body(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                    decoration:
                        InputDecoration(hintText: l10n.addNoteTitleHint),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.addNoteSectionNotes,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 6),
                  MarkdownToolbar(controller: _notes),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notes,
                    inputFormatters: const [MarkdownListContinuation()],
                    minLines: 5,
                    maxLines: 12,
                    keyboardType: TextInputType.multiline,
                    style: AppFonts.body(
                      fontSize: 14,
                      height: 1.5,
                      color: palette.textPrimary,
                    ),
                    decoration:
                        InputDecoration(hintText: l10n.addNoteNotesHint),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.addNoteSectionTags,
                      style: eyebrowStyle(context: context)),
                  const SizedBox(height: 8),
                  TagChipInput(
                    tags: _tags,
                    onChanged: (t) => setState(() => _tags = t),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 24, 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.surfaceStroke)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                        foregroundColor: palette.textSecondary),
                    child: Text(l10n.addNoteReplaceDialogCancel),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: FoodIcon(
                        kind: FoodKind.fromSource(draft.sourceType),
                        size: 22,
                      ),
                      label: Text(
                        l10n.scribeSheetSave(widget.petName),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the link came from: thumbnail, platform and the source's title.
class _SourceRow extends StatelessWidget {
  final NoteDraft draft;
  const _SourceRow({required this.draft});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final host =
        (Uri.tryParse(draft.url)?.host ?? draft.url).replaceFirst('www.', '');
    final thumb = draft.thumbnailUrl;
    final placeholder = Center(
      child: FoodIcon(kind: FoodKind.fromSource(draft.sourceType), size: 30),
    );
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: softCard(context, radius: 18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              height: 58,
              color: palette.bgPrimary,
              child: thumb == null || thumb.isEmpty
                  ? placeholder
                  : Image.network(
                      thumb,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholder,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (draft.siteName ??
                          SourceMeta.labelLocalized(context, draft.sourceType))
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: eyebrowStyle(context: context).copyWith(fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  draft.sourceTitle?.trim().isNotEmpty == true
                      ? draft.sourceTitle!.trim()
                      : host,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 13.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.body(
                    fontSize: 11.5,
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
