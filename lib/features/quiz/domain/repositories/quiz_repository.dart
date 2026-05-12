import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/weekly_quiz.dart';

abstract class QuizRepository {
  /// Fetches (or generates) the current week's quiz for the user. When the
  /// user has no quiz yet, the implementation triggers the
  /// `generate-weekly-quiz` Edge Function to produce one. Idempotent —
  /// repeated calls in the same week return the same row.
  Future<Either<Failure, WeeklyQuiz>> getOrGenerateWeeklyQuiz();

  /// Persists [answers] + final [score] for [quizId] and triggers the
  /// XP/badge RPC. Returns the XP awarded so the UI can show a celebratory
  /// number on the result screen.
  Future<Either<Failure, int>> submitWeeklyQuiz({
    required String quizId,
    required List<QuizAnswer> answers,
    required int score,
  });
}
