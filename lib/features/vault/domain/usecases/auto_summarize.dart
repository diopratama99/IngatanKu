import '../repositories/auto_summarize_repository.dart';

/// Generates a markdown note draft from a URL using the `auto-summarize`
/// Edge Function. Returns a [Stream] of [AutoSummarizeEvent]s; the UI
/// appends [AutoSummarizeToken]s into the notes TextField as they arrive.
class AutoSummarize {
  final AutoSummarizeRepository repo;
  AutoSummarize(this.repo);

  Stream<AutoSummarizeEvent> call({
    required String url,
    String locale = 'id',
  }) {
    return repo.summarize(url: url, locale: locale);
  }
}
