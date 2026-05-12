import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/weekly_quiz.dart';
import '../../domain/repositories/quiz_repository.dart';

// ─── State ───────────────────────────────────────────────────────────
abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => const [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizError extends QuizState {
  final String message;
  const QuizError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Quiz is loaded — either fresh or already-completed (review mode).
/// `selections[i]` is the user's chosen index for question `i`, or null
/// if not yet selected. `revealed` toggles per-question explanation —
/// in review mode all questions are revealed from the start.
class QuizActive extends QuizState {
  final WeeklyQuiz quiz;
  final int currentIndex;
  final List<int?> selections;
  final bool revealed;
  final bool submitting;

  /// XP awarded after a successful submit. When non-null, the UI flips to
  /// the result screen.
  final int? earnedXp;

  const QuizActive({
    required this.quiz,
    required this.currentIndex,
    required this.selections,
    required this.revealed,
    required this.submitting,
    required this.earnedXp,
  });

  bool get isReadonly => quiz.isCompleted && earnedXp == null;
  bool get isLastQuestion => currentIndex == quiz.questions.length - 1;
  bool get hasSelection => selections[currentIndex] != null;
  int get score => List.generate(
        quiz.questions.length,
        (i) => selections[i] != null &&
                selections[i] == quiz.questions[i].correctIndex
            ? 1
            : 0,
      ).fold(0, (a, b) => a + b);

  QuizActive copyWith({
    int? currentIndex,
    List<int?>? selections,
    bool? revealed,
    bool? submitting,
    int? earnedXp,
    WeeklyQuiz? quiz,
  }) {
    return QuizActive(
      quiz: quiz ?? this.quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      selections: selections ?? this.selections,
      revealed: revealed ?? this.revealed,
      submitting: submitting ?? this.submitting,
      earnedXp: earnedXp ?? this.earnedXp,
    );
  }

  @override
  List<Object?> get props =>
      [quiz, currentIndex, selections, revealed, submitting, earnedXp];
}

// ─── Cubit ───────────────────────────────────────────────────────────
class QuizCubit extends Cubit<QuizState> {
  final QuizRepository repo;
  QuizCubit(this.repo) : super(const QuizInitial());

  Future<void> load() async {
    emit(const QuizLoading());
    final res = await repo.getOrGenerateWeeklyQuiz();
    res.fold(
      (f) => emit(QuizError(f.message)),
      (quiz) {
        // Completed quiz → review mode: pre-fill selections from
        // userAnswers and reveal explanations on every question.
        if (quiz.isCompleted && quiz.userAnswers != null) {
          emit(QuizActive(
            quiz: quiz,
            currentIndex: 0,
            selections:
                quiz.userAnswers!.map<int?>((a) => a.selectedIndex).toList(),
            revealed: true,
            submitting: false,
            earnedXp: null,
          ));
        } else {
          emit(QuizActive(
            quiz: quiz,
            currentIndex: 0,
            selections: List<int?>.filled(quiz.questions.length, null),
            revealed: false,
            submitting: false,
            earnedXp: null,
          ));
        }
      },
    );
  }

  void selectOption(int idx) {
    final s = state;
    if (s is! QuizActive || s.isReadonly || s.revealed) return;
    final newSel = List<int?>.of(s.selections);
    newSel[s.currentIndex] = idx;
    emit(s.copyWith(selections: newSel));
  }

  void revealAnswer() {
    final s = state;
    if (s is! QuizActive || !s.hasSelection) return;
    emit(s.copyWith(revealed: true));
  }

  void nextQuestion() {
    final s = state;
    if (s is! QuizActive) return;
    if (s.currentIndex < s.quiz.questions.length - 1) {
      emit(s.copyWith(
        currentIndex: s.currentIndex + 1,
        // In review mode keep revealed; in answer mode, hide explanations
        // for the new question.
        revealed: s.isReadonly ? true : false,
      ));
    }
  }

  void previousQuestion() {
    final s = state;
    if (s is! QuizActive) return;
    if (s.currentIndex > 0) {
      emit(s.copyWith(
        currentIndex: s.currentIndex - 1,
        revealed: true, // user already saw it; keep revealed
      ));
    }
  }

  /// After successful submission, the user can tap "Lihat jawaban" to
  /// review each question with revealed explanations. We construct a new
  /// state directly because [QuizActive.copyWith] uses `??` and can't
  /// distinguish "leave alone" from "set to null" for the earnedXp field.
  void reviewAnswers() {
    final s = state;
    if (s is! QuizActive) return;
    emit(QuizActive(
      quiz: s.quiz,
      currentIndex: 0,
      selections: s.selections,
      revealed: true,
      submitting: false,
      earnedXp: null,
    ));
  }

  Future<void> submit() async {
    final s = state;
    if (s is! QuizActive) return;
    // Don't allow re-submission.
    if (s.quiz.isCompleted) return;

    emit(s.copyWith(submitting: true));
    final answers = List.generate(s.quiz.questions.length, (i) {
      final picked = s.selections[i] ?? 0;
      return QuizAnswer(
        selectedIndex: picked,
        correct: picked == s.quiz.questions[i].correctIndex,
      );
    });

    final score = s.score;
    final res = await repo.submitWeeklyQuiz(
      quizId: s.quiz.id,
      answers: answers,
      score: score,
    );

    res.fold(
      (f) => emit(QuizError(f.message)),
      (xp) {
        emit(s.copyWith(
          submitting: false,
          earnedXp: xp,
          quiz: s.quiz.copyWith(
            userAnswers: answers,
            completedAt: DateTime.now(),
            score: score,
          ),
        ));
      },
    );
  }
}
