import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/editorial.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../cubit/quiz_cubit.dart';

class WeeklyQuizPage extends StatelessWidget {
  const WeeklyQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => QuizCubit(sl<QuizRepository>())..load(),
      child: const _WeeklyQuizScaffold(),
    );
  }
}

class _WeeklyQuizScaffold extends StatelessWidget {
  const _WeeklyQuizScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text('QUIZ MINGGUAN', style: eyebrowStyle()),
      ),
      body: SafeArea(
        child: BlocBuilder<QuizCubit, QuizState>(
          builder: (context, state) {
            if (state is QuizInitial || state is QuizLoading) {
              return const _LoadingView();
            }
            if (state is QuizError) {
              return _ErrorView(message: state.message);
            }
            if (state is QuizActive) {
              if (state.earnedXp != null) {
                return _ResultView(state: state);
              }
              return _QuestionView(state: state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ─── Loading ─────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Membuat quiz dari catatan minggu ini…',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error ───────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 36, color: AppColors.warning),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => context.read<QuizCubit>().load(),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              child: Text(
                'COBA LAGI',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Question view ───────────────────────────────────────────────────
class _QuestionView extends StatelessWidget {
  final QuizActive state;
  const _QuestionView({required this.state});

  @override
  Widget build(BuildContext context) {
    final q = state.quiz.questions[state.currentIndex];
    final selected = state.selections[state.currentIndex];
    final revealed = state.revealed;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress eyebrow + linear bar
              Row(
                children: [
                  Text(
                    'PERTANYAAN ${state.currentIndex + 1} / ${state.quiz.questions.length}',
                    style: eyebrowStyle(),
                  ),
                  const Spacer(),
                  if (state.isReadonly) Text('REVIEW', style: eyebrowStyle()),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (state.currentIndex + 1) / state.quiz.questions.length,
                  backgroundColor: AppColors.bgTertiary.withValues(alpha: 0.4),
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            children: [
              const SizedBox(height: 8),
              // The question itself
              Text(
                q.question,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.3,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 22),
              // Options
              ...List.generate(q.options.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OptionTile(
                    text: q.options[i],
                    index: i,
                    isSelected: selected == i,
                    isCorrect: revealed && i == q.correctIndex,
                    isWrong: revealed && selected == i && i != q.correctIndex,
                    onTap: state.isReadonly || revealed
                        ? null
                        : () => context.read<QuizCubit>().selectOption(i),
                  ),
                );
              }),
              if (revealed) ...[
                const SizedBox(height: 16),
                _ExplanationBox(
                  correct: selected == q.correctIndex,
                  explanation: q.explanation,
                ),
              ],
            ],
          ),
        ),
        // Bottom CTA
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: _BottomCTA(state: state),
        ),
      ],
    );
  }
}

// One radio-like option tile.
class _OptionTile extends StatelessWidget {
  final String text;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.text,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppColors.surfaceStroke;
    Color bg = AppColors.bgSecondary;
    Color textColor = AppColors.textPrimary;
    IconData? trailing;
    Color trailingColor = AppColors.textSecondary;

    if (isCorrect) {
      borderColor = AppColors.success;
      bg = AppColors.success.withValues(alpha: 0.08);
      trailing = Icons.check_circle_rounded;
      trailingColor = AppColors.success;
    } else if (isWrong) {
      borderColor = AppColors.danger;
      bg = AppColors.danger.withValues(alpha: 0.08);
      trailing = Icons.cancel_rounded;
      trailingColor = AppColors.danger;
    } else if (isSelected) {
      borderColor = AppColors.primary;
      bg = AppColors.primary.withValues(alpha: 0.08);
    }

    final letter = String.fromCharCode(65 + index); // A, B, C, D

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor),
              ),
              child: Text(
                letter,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.5,
                  color: textColor,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              Icon(trailing, size: 18, color: trailingColor),
            ],
          ],
        ),
      ),
    );
  }
}

// Explanation card shown after answer reveal.
class _ExplanationBox extends StatelessWidget {
  final bool correct;
  final String explanation;
  const _ExplanationBox({required this.correct, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final accent = correct ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            correct ? 'BENAR' : 'KELIRU',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: accent,
            ),
          ),
          if (explanation.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              explanation,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Bottom CTA: changes label/behaviour based on state.
class _BottomCTA extends StatelessWidget {
  final QuizActive state;
  const _BottomCTA({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuizCubit>();

    // Layout: Prev button on the left when not on the first question, plus
    // a primary button on the right whose label depends on phase.
    final showPrev = state.currentIndex > 0;
    String primaryLabel;
    VoidCallback? primaryAction;

    if (state.isReadonly) {
      // Review mode for already-completed quiz.
      primaryLabel = state.isLastQuestion ? 'SELESAI' : 'LANJUT';
      primaryAction =
          state.isLastQuestion ? () => context.pop() : cubit.nextQuestion;
    } else if (!state.revealed) {
      // Active answering — show "Periksa" once a selection is made.
      primaryLabel = 'PERIKSA';
      primaryAction = state.hasSelection ? cubit.revealAnswer : null;
    } else if (!state.isLastQuestion) {
      primaryLabel = 'LANJUT';
      primaryAction = cubit.nextQuestion;
    } else {
      primaryLabel = state.submitting ? 'MEMPROSES…' : 'SELESAIKAN QUIZ';
      primaryAction = state.submitting ? null : cubit.submit;
    }

    return Row(
      children: [
        if (showPrev)
          TextButton.icon(
            onPressed: cubit.previousQuestion,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(
              'KEMBALI',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        const Spacer(),
        ElevatedButton(
          onPressed: primaryAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
            disabledForegroundColor: Colors.white70,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.submitting) ...[
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                primaryLabel,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Result view ─────────────────────────────────────────────────────
class _ResultView extends StatelessWidget {
  final QuizActive state;
  const _ResultView({required this.state});

  @override
  Widget build(BuildContext context) {
    final score = state.quiz.score ?? state.score;
    final total = state.quiz.questions.length;
    final xp = state.earnedXp ?? 0;
    final perfect = score == total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SKOR MINGGU INI', style: eyebrowStyle()),
          const SizedBox(height: 18),
          // Big editorial score
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 96,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  height: 0.95,
                  color: perfect ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  '/ $total',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 38,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -1,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            perfect
                ? 'Sempurna! Catatan kamu betul-betul nempel.'
                : score >= 3
                    ? 'Bagus, mayoritas materi terserap dengan baik.'
                    : 'Mari ulang catatan-catatan yang masih lemah.',
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 26),
          // XP chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  '+$xp XP',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const ThinDivider(),
          const SizedBox(height: 24),
          // Per-question summary
          Text('RINCIAN', style: eyebrowStyle()),
          const SizedBox(height: 14),
          ...List.generate(total, (i) {
            final correct =
                state.selections[i] == state.quiz.questions[i].correctIndex;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 16,
                    color: correct ? AppColors.success : AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.quiz.questions[i].question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(),
          // Action row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide(color: AppColors.surfaceStroke),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'TUTUP',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.read<QuizCubit>().reviewAnswers(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'LIHAT JAWABAN',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
