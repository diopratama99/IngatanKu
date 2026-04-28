/// Stream events emitted while the `auto-summarize` Edge Function generates a
/// note draft from a URL. Mirrors the design of `ChatStreamEvent` so the UI
/// layer can listen to a single sealed family of events.
abstract class AutoSummarizeEvent {
  const AutoSummarizeEvent();
}

/// First event from the server — tells the UI what kind of source content was
/// found (transcript, article body, OG meta, …) so we can show the right
/// pre-stream hint ("✓ transkrip ditemukan, menyusun catatan…").
class AutoSummarizeMeta extends AutoSummarizeEvent {
  /// One of `youtube`, `twitter`, `tiktok`, `instagram`, `article`.
  final String source;

  /// Human-readable label, e.g. "transkrip video YouTube".
  final String contentLabel;

  /// Length of the source text fed to the LLM, in characters.
  final int contentLength;

  const AutoSummarizeMeta({
    required this.source,
    required this.contentLabel,
    required this.contentLength,
  });
}

/// One markdown token from the LLM. UI should append it to its draft buffer.
class AutoSummarizeToken extends AutoSummarizeEvent {
  final String token;
  const AutoSummarizeToken(this.token);
}

/// Stream finished cleanly — UI can stop the typing indicator.
class AutoSummarizeDone extends AutoSummarizeEvent {
  const AutoSummarizeDone();
}

/// Something went wrong; payload is a human-readable Indonesian message safe
/// to surface in a SnackBar.
class AutoSummarizeError extends AutoSummarizeEvent {
  final String message;
  const AutoSummarizeError(this.message);
}

abstract class AutoSummarizeRepository {
  /// Stream a markdown note draft generated from [url]. The stream completes
  /// after exactly one [AutoSummarizeDone] or [AutoSummarizeError] event.
  ///
  /// [locale] selects the language for the draft (`id` or `en`); defaults to
  /// Indonesian to match the rest of the app.
  Stream<AutoSummarizeEvent> summarize({
    required String url,
    String locale = 'id',
  });
}
