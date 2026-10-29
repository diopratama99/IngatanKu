import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/weekly_quiz.dart';

abstract class QuizRepository {
  /// Fetches (or generates) today's quiz ([QuizKind.daily], through the
  /// `daily-quiz` Edge Function) or this week's ([QuizKind.weekly],
  /// through `generate-weekly-quiz`). Idempotent — repeated calls the same
  /// day / week return the same row.
  Future<Either<Failure, WeeklyQuiz>> getOrGenerate(QuizKind kind);

  /// Persists [answers] + final [score] for [quiz].
  Future<Either<Failure, void>> submit({
    required WeeklyQuiz quiz,
    required List<QuizAnswer> answers,
    required int score,
  });

  /// Catat jawaban per soal ke `quiz_question_history`. Dipanggil
  /// setiap kali user reveal answer (atau saat submit final). Server
  /// menentukan difficulty + cooldown next show.
  ///
  /// Fire-and-forget dari sisi UI — kalau gagal, gak ngeganggu flow
  /// quiz utama. Backend retry-safe (idempotent per
  /// user+question+week).
  Future<Either<Failure, void>> recordAnswer({
    required String questionHash,
    required String questionText,
    String? sourceNoteId,
    required bool correct,
    int? timeToAnswerMs,
    QuizSelfRating? selfRating,
  });
}
