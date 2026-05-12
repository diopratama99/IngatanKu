import 'package:dartz/dartz.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/supabase_client.dart';
import '../../domain/entities/note_entity.dart';
import '../../domain/repositories/share_repository.dart';
import '../models/note_model.dart';

class ShareRepositoryImpl implements ShareRepository {
  final SupabaseService service;
  ShareRepositoryImpl(this.service);

  @override
  Future<Either<Failure, String>> enable(String noteId) async {
    try {
      final token = await service.db.rpc(
        'toggle_share',
        params: {'note_id': noteId, 'enable': true},
      );
      if (token is! String || token.isEmpty) {
        return const Left(ServerFailure('Share failed'));
      }
      return Right(token);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disable(String noteId) async {
    try {
      await service.db.rpc(
        'toggle_share',
        params: {'note_id': noteId, 'enable': false},
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, NoteEntity>> getByToken(String token) async {
    try {
      final res = await service.db
          .from(AppConstants.tContentVault)
          .select()
          .eq('share_token', token)
          .maybeSingle();
      if (res == null) return const Left(ServerFailure('Not found'));
      return Right(NoteModel.fromMap(res));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
