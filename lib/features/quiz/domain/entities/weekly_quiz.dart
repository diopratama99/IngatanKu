import 'package:equatable/equatable.dart';

/// One multiple-choice question in a weekly quiz.
class QuizQuestion extends Equatable {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? sourceNoteId;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.sourceNoteId,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String? ?? '',
      options:
          (json['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
      sourceNoteId: json['sourceNoteId'] as String?,
    );
  }

  @override
  List<Object?> get props =>
      [question, options, correctIndex, explanation, sourceNoteId];
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
class WeeklyQuiz extends Equatable {
  final String id;
  final String weekStart; // YYYY-MM-DD
  final List<QuizQuestion> questions;
  final List<String> sourceNoteIds;
  final List<QuizAnswer>? userAnswers;
  final DateTime? completedAt;
  final int? score;
  final int noteCount;

  const WeeklyQuiz({
    required this.id,
    required this.weekStart,
    required this.questions,
    required this.sourceNoteIds,
    required this.userAnswers,
    required this.completedAt,
    required this.score,
    required this.noteCount,
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
      weekStart: json['weekStart'] as String,
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
    );
  }

  WeeklyQuiz copyWith({
    List<QuizAnswer>? userAnswers,
    DateTime? completedAt,
    int? score,
  }) {
    return WeeklyQuiz(
      id: id,
      weekStart: weekStart,
      questions: questions,
      sourceNoteIds: sourceNoteIds,
      userAnswers: userAnswers ?? this.userAnswers,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      noteCount: noteCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        weekStart,
        questions,
        sourceNoteIds,
        userAnswers,
        completedAt,
        score,
        noteCount,
      ];
}
