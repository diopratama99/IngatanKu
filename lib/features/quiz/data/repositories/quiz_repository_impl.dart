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
  Future<Either<Failure, WeeklyQuiz>> getOrGenerateWeeklyQuiz() async {
    try {
      return Right(await remote.getOrGenerate());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> submitWeeklyQuiz({
    required String quizId,
    required List<QuizAnswer> answers,
    required int score,
  }) async {
    try {
      final earned = await remote.submit(
        quizId: quizId,
        answers: answers,
        score: score,
      );
      return Right(earned);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
