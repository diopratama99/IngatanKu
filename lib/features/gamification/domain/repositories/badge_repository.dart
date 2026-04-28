import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/badge_entity.dart';

abstract class BadgeRepository {
  Future<Either<Failure, List<BadgeEntity>>> listAll();
}
