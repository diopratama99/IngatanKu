import 'package:equatable/equatable.dart';

/// Which quiz: the daily one (three questions, the pet's daily meal) or
/// the weekly one (a longer review, the pet's weekly feast).
enum QuizKind { daily, weekly }

/// One multiple-choice question in a quiz.
class QuizQuestion extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? sourceNoteId;

  /// SHA-256 hash dari question text + correct answer text. Server
  /// menyertakan ini untuk soal yang baru di-generate; soal recall
  /// dari history juga tetap bawa hash. Dipakai untuk
  /// `record-quiz-answer` supaya backend bisa update history.
  final String? questionHash;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.sourceNoteId,
    required this.questionHash,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options:
          (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
      sourceNoteId: json['sourceNoteId'] as String?,
      questionHash: json['questionHash'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [question, options, correctIndex, explanation, sourceNoteId, questionHash];
}

/// Self-rating yang dipilih user setelah lihat jawaban. Pakai
/// untuk drive spaced-repetition cooldown di history.
enum QuizSelfRating {
  easy, // Mudah, gak perlu lihat lagi
  medium, // Pas
  hard; // Sulit

  String get value => switch (this) {
        QuizSelfRating.easy => 'easy',
        QuizSelfRating.medium => 'medium',
        QuizSelfRating.hard => 'hard',
      };
}

/// One stored answer the user submitted. We persist this so the UI can
/// re-render the post-completion review screen on subsequent visits.
class QuizAnswer extends Equatable {
  final int selectedIndex;
  final bool correct;

  const QuizAnswer({required this.selectedIndex, required this.correct});

  factory QuizAnswer.fromJson(Map<String, dynamic> json) => QuizAnswer(
        selectedIndex: (json['selectedIndex'] as num?)?.toInt() ?? 0,
        correct: json['correct'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'selectedIndex': selectedIndex, 'correct': correct};

  @override
  List<Object?> get props => [selectedIndex, correct];
}

/// One row of the `weekly_quizzes` table, including the user's progress.
/// A quiz — daily or weekly (see [kind]); the name stays from when there
/// was only the weekly one.
class WeeklyQuiz extends Equatable {
  final String id;
  final QuizKind kind;

  /// YYYY-MM-DD: the quiz's day (daily) or its week's Monday (weekly).
  final String weekStart;
  final List<QuizQuestion> questions;
  final List<String> sourceNoteIds;
  final List<QuizAnswer>? userAnswers;
  final DateTime? completedAt;
  final int? score;
  final int noteCount;
  final int targetCount;

  const WeeklyQuiz({
    required this.id,
    this.kind = QuizKind.weekly,
    required this.weekStart,
    required this.questions,
    required this.sourceNoteIds,
    required this.userAnswers,
    required this.completedAt,
    required this.score,
    required this.noteCount,
    required this.targetCount,
  });

  bool get isCompleted => completedAt != null;

  factory WeeklyQuiz.fromJson(Map<String, dynamic> json) {
    final qs = (json['questions'] as List?)
            ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <QuizQuestion>[];
    final answersRaw = json['userAnswers'] as List?;
    return WeeklyQuiz(
      id: json['id'] as String,
      kind: json['kind'] == 'daily' ? QuizKind.daily : QuizKind.weekly,
      weekStart: (json['weekStart'] ?? json['quizDate']) as String,
      questions: qs,
      sourceNoteIds: (json['sourceNoteIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      userAnswers: answersRaw
          ?.map((e) => QuizAnswer.fromJson(e as Map<String, dynamic>))
          .toList(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      score: (json['score'] as num?)?.toInt(),
      noteCount: (json['noteCount'] as num?)?.toInt() ?? 0,
      targetCount: (json['targetCount'] as num?)?.toInt() ?? qs.length,
    );
  }

  WeeklyQuiz copyWith({
    List<QuizAnswer>? userAnswers,
    DateTime? completedAt,
    int? score,
  }) {
    return WeeklyQuiz(
      id: id,
      kind: kind,
      weekStart: weekStart,
      questions: questions,
      sourceNoteIds: sourceNoteIds,
      userAnswers: userAnswers ?? this.userAnswers,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      noteCount: noteCount,
      targetCount: targetCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kind,
        weekStart,
        questions,
        sourceNoteIds,
        userAnswers,
        completedAt,
        score,
        noteCount,
        targetCount,
      ];
}
