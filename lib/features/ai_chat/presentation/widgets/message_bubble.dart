import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/answer_parts.dart';
import '../../domain/entities/message_entity.dart';
import '../../../../core/theme/app_fonts.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../../vault/presentation/widgets/book_colors.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;

  /// The pet is saying this answer's opening line in the room (the latest
  /// answer): the card holds only the rest — nothing until it comes.
  final bool spoken;
  const MessageBubble({super.key, required this.message, this.spoken = false});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    final String body;
    if (_isUser || !spoken) {
      body = message.content;
    } else {
      final parts = AnswerParts.of(message);
      if (parts.pending || parts.rest.trim().isEmpty) {
        return const SizedBox.shrink();
      }
      body = parts.rest;
    }
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: context.screenSize.width * (_isUser ? 0.85 : 0.92)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _isUser
              ? _buildUserBubble(context)
              // The pet up in the room is who's talking.
              : _buildAssistantBubble(context, body),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.palette.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Text(
          message.content,
          style: AppFonts.body(
            color: context.palette.onPrimary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      );

  Widget _buildAssistantBubble(BuildContext context, String body) {
    final cited = citedSources(message);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.bgSecondary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(color: context.palette.surfaceStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before the first words arrive, the typing dots say it all.
          if (!(message.streaming && body.isEmpty))
            MarkdownBody(
              data: body.isEmpty ? '…' : body,
              selectable: true,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: AppFonts.body(
                  fontSize: 15,
                  height: 1.6,
                  color: context.palette.textPrimary,
                ),
                code: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  backgroundColor:
                      context.palette.bgTertiary.withValues(alpha: 0.5),
                  color: AppColors.accent,
                ),
                codeblockDecoration: BoxDecoration(
                  color: context.palette.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: context.palette.surfaceStroke),
                ),
              ),
            ),
          // (When spoken, the pet up in the room is the one typing.)
          if (message.streaming && !spoken) ...[
            if (body.isNotEmpty) const SizedBox(height: 8),
            const _TypingDots(),
          ],
          // Its sources once it has finished answering (they arrive
          // first, but under a half-written answer they're noise).
          if (!message.streaming && cited.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              height: 1,
              color: context.palette.surfaceStroke.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.chatSourcesLabel,
              style: eyebrowStyle(context: context).copyWith(fontSize: 10),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: cited.map((s) {
                final title = s.title ?? s.noteId.substring(0, 6);
                // Each source in its book colour, like on the shelves.
                final c = BookColor.of(title);
                // Tap to open the note itself.
                return Semantics(
                  button: true,
                  label: title,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/vault/${s.noteId}'),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 240),
                      padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
                      decoration: BoxDecoration(
                        color: c.chip,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_rounded, size: 13, color: c.ink),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          Text(
                            ' · ${(s.similarity * 100).toStringAsFixed(0)}%',
                            style: AppFonts.body(
                              fontSize: 11,
                              color: c.ink.withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded,
                              size: 14, color: c.ink.withValues(alpha: 0.65)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_ctrl.value + i * 0.2) % 1;
            final scale = (0.5 + 0.5 * (1 - (2 * t - 1).abs()));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
