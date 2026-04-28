import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  const MessageBubble({super.key, required this.message});

  bool get _isUser => message.role == MessageRole.user;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: context.screenSize.width * 0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _isUser ? _buildUserBubble(context) : _buildAssistantBubble(context),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.content,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      );

  Widget _buildAssistantBubble(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border.all(color: AppColors.surfaceStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: message.content.isEmpty ? '…' : message.content,
              selectable: true,
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
                code: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  backgroundColor: AppColors.bgTertiary.withValues(alpha: 0.5),
                  color: AppColors.accent,
                ),
                codeblockDecoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.surfaceStroke),
                ),
              ),
            ),
            if (message.streaming) ...[
              const SizedBox(height: 8),
              const _TypingDots(),
            ],
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                height: 1,
                color: AppColors.surfaceStroke.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 10),
              Text(
                'SUMBER',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.sources.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.surfaceStroke),
                    ),
                    child: Text(
                      '[${i + 1}] ${s.title ?? s.noteId.substring(0, 6)} · ${(s.similarity * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
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

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textSecondary,
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
