import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/weekly_quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remote;
  QuizRepositoryImpl(this.remote);

  @override
  Future<Either<Failure, WeeklyQuiz>> getOrGenerate(QuizKind kind) async {
    try {
      return Right(await remote.getOrGenerate(kind));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submit({
    required WeeklyQuiz quiz,
    required List<QuizAnswer> answers,
    required int score,
  }) async {
    try {
      await remote.submit(
        quiz: quiz,
        answers: answers,
        score: score,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> recordAnswer({
    required String questionHash,
    required String questionText,
    String? sourceNoteId,
    required bool correct,
    int? timeToAnswerMs,
    QuizSelfRating? selfRating,
  }) async {
    try {
      await remote.recordAnswer(
        questionHash: questionHash,
        questionText: questionText,
        sourceNoteId: sourceNoteId,
        correct: correct,
        timeToAnswerMs: timeToAnswerMs,
        selfRating: selfRating,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
