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

  /// Submitted in this session: the UI flips to the result screen.
  final bool submitted;

  /// Self-rating yang user pilih per soal (untuk drive cooldown
  /// spaced-repetition di history). Default null = belum di-rate.
  /// Saat user tekan "Lanjut" tanpa milih, kita default ke
  /// [QuizSelfRating.medium] di cubit (kalau jawabannya benar).
  final List<QuizSelfRating?> selfRatings;

  /// Timestamp saat soal current ditampilkan ke user. Dipakai
  /// untuk hitung response time → implicit difficulty signal.
  final DateTime currentQuestionShownAt;

  /// Jumlah soal "hard" yang akan di-recall minggu depan. Dihitung
  /// frontend setelah answer-recording, ditampilkan di result page.
  final int hardCarryOverNext;

  const QuizActive({
    required this.quiz,
    required this.currentIndex,
    required this.selections,
    required this.revealed,
    required this.submitting,
    required this.submitted,
    required this.selfRatings,
    required this.currentQuestionShownAt,
    required this.hardCarryOverNext,
  });

  bool get isReadonly => quiz.isCompleted && !submitted;
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
    bool? submitted,
    WeeklyQuiz? quiz,
    List<QuizSelfRating?>? selfRatings,
    DateTime? currentQuestionShownAt,
    int? hardCarryOverNext,
  }) {
    return QuizActive(
      quiz: quiz ?? this.quiz,
      currentIndex: currentIndex ?? this.currentIndex,
      selections: selections ?? this.selections,
      revealed: revealed ?? this.revealed,
      submitting: submitting ?? this.submitting,
      submitted: submitted ?? this.submitted,
      selfRatings: selfRatings ?? this.selfRatings,
      currentQuestionShownAt:
          currentQuestionShownAt ?? this.currentQuestionShownAt,
      hardCarryOverNext: hardCarryOverNext ?? this.hardCarryOverNext,
    );
  }

  @override
  List<Object?> get props => [
        quiz,
        currentIndex,
        selections,
        revealed,
        submitting,
        submitted,
        selfRatings,
        hardCarryOverNext,
        currentQuestionShownAt,
      ];
}

// ─── Cubit ───────────────────────────────────────────────────────────
class QuizCubit extends Cubit<QuizState> {
  final QuizRepository repo;
  final QuizKind kind;

  /// Each answer as it's revealed (question [index], right or not) — the
  /// pet eats it straight away.
  final void Function(WeeklyQuiz quiz, int index, bool correct)? onAnswer;

  /// The quiz was submitted.
  final void Function(WeeklyQuiz quiz)? onFinished;

  QuizCubit(
    this.repo, {
    this.kind = QuizKind.weekly,
    this.onAnswer,
    this.onFinished,
  }) : super(const QuizInitial());

  Future<void> load() async {
    emit(const QuizLoading());
    final res = await repo.getOrGenerate(kind);
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
            submitted: false,
            selfRatings: List<QuizSelfRating?>.filled(
              quiz.questions.length,
              null,
            ),
            currentQuestionShownAt: DateTime.now(),
            hardCarryOverNext: 0,
          ));
        } else {
          emit(QuizActive(
            quiz: quiz,
            currentIndex: 0,
            selections: List<int?>.filled(quiz.questions.length, null),
            revealed: false,
            submitting: false,
            submitted: false,
            selfRatings: List<QuizSelfRating?>.filled(
              quiz.questions.length,
              null,
            ),
            currentQuestionShownAt: DateTime.now(),
            hardCarryOverNext: 0,
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
    if (!s.isReadonly) {
      final i = s.currentIndex;
      onAnswer?.call(
          s.quiz, i, s.selections[i] == s.quiz.questions[i].correctIndex);
    }
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
        currentQuestionShownAt: DateTime.now(),
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
        currentQuestionShownAt: DateTime.now(),
      ));
    }
  }

  /// Set self-rating untuk soal current. Optional — kalau user gak
  /// nge-tap, nanti default-nya `medium` (kalau correct) atau `hard`
  /// (kalau wrong) saat fire ke server.
  void rateCurrent(QuizSelfRating rating) {
    final s = state;
    if (s is! QuizActive) return;
    final next = List<QuizSelfRating?>.of(s.selfRatings);
    next[s.currentIndex] = rating;
    emit(s.copyWith(selfRatings: next));
  }

  /// After successful submission, the user can tap "Lihat jawaban" to
  /// review each question with revealed explanations.
  void reviewAnswers() {
    final s = state;
    if (s is! QuizActive) return;
    emit(QuizActive(
      quiz: s.quiz,
      currentIndex: 0,
      selections: s.selections,
      revealed: true,
      submitting: false,
      submitted: false,
      selfRatings: s.selfRatings,
      currentQuestionShownAt: DateTime.now(),
      hardCarryOverNext: s.hardCarryOverNext,
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

    // Fire-and-forget: catat tiap soal ke history. Wrap dalam
    // try-catch supaya error history tidak ngegagalin submit utama.
    var hardCount = 0;
    for (var i = 0; i < s.quiz.questions.length; i++) {
      final q = s.quiz.questions[i];
      final ans = answers[i];
      if (q.questionHash == null || q.questionHash!.isEmpty) continue;
      final rating = s.selfRatings[i];
      // Server akan derive difficulty final; kita tetap kirim
      // self-rating user supaya server bisa override implicit signal.
      try {
        await repo.recordAnswer(
          questionHash: q.questionHash!,
          questionText: q.question,
          sourceNoteId: q.sourceNoteId,
          correct: ans.correct,
          selfRating: rating,
        );
      } catch (_) {
        // Ignore — history adalah enhancement, bukan blocker.
      }
      // Estimate hard count untuk hint footer di result page.
      if (!ans.correct) {
        hardCount++;
      } else if (rating == QuizSelfRating.hard) {
        hardCount++;
      }
    }

    final res = await repo.submit(
      quiz: s.quiz,
      answers: answers,
      score: score,
    );

    res.fold(
      (f) => emit(QuizError(f.message)),
      (_) {
        onFinished?.call(s.quiz);
        emit(s.copyWith(
          submitting: false,
          submitted: true,
          quiz: s.quiz.copyWith(
            userAnswers: answers,
            completedAt: DateTime.now(),
            score: score,
          ),
          hardCarryOverNext: hardCount,
        ));
      },
    );
  }
}
