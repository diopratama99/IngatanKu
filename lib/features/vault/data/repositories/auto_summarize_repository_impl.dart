import '../../domain/repositories/auto_summarize_repository.dart';
import '../datasources/auto_summarize_remote_datasource.dart';

/// Thin pass-through to the remote datasource — no offline caching since
/// auto-summarize is a "live" interactive feature, not something the user
/// would expect to work offline.
class AutoSummarizeRepositoryImpl implements AutoSummarizeRepository {
  final AutoSummarizeRemoteDataSource remote;
  AutoSummarizeRepositoryImpl(this.remote);

  @override
  Stream<AutoSummarizeEvent> summarize({
    required String url,
    String locale = 'id',
  }) {
    return remote.summarize(url: url, locale: locale);
  }
}
