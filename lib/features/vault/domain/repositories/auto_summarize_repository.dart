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

/// Progress event surfaced by the transcribe pipeline so the UI can show a
/// staged spinner ("Download audio…" → "Transcribe…" → "Summarize…").
/// Sent before the first [AutoSummarizeToken]. Optional — meta-only runs
/// will never emit this.
///
/// `stage` is one of: `resolve`, `download`, `transcribe`, `summarize`.
class AutoSummarizeStage extends AutoSummarizeEvent {
  final String stage;
  final String label;
  const AutoSummarizeStage({required this.stage, required this.label});
}

/// One markdown token from the LLM. UI should append it to its draft buffer.
class AutoSummarizeToken extends AutoSummarizeEvent {
  final String token;
  const AutoSummarizeToken(this.token);
}

/// The tags the model picked for the note, sent once it's written.
class AutoSummarizeTags extends AutoSummarizeEvent {
  final List<String> tags;
  const AutoSummarizeTags(this.tags);
}

/// Stream finished cleanly — UI can stop the typing indicator.
class AutoSummarizeDone extends AutoSummarizeEvent {
  const AutoSummarizeDone();
}

/// Something went wrong; payload is a human-readable Indonesian message safe
/// to surface in a SnackBar. [outOfQuota] when today's write-ups are used
/// up (the function's 429), so the app can say that instead.
class AutoSummarizeError extends AutoSummarizeEvent {
  final String message;
  final bool outOfQuota;
  const AutoSummarizeError(this.message, {this.outOfQuota = false});
}

abstract class AutoSummarizeRepository {
  /// Stream a markdown note draft generated from [url]. The stream completes
  /// after exactly one [AutoSummarizeDone] or [AutoSummarizeError] event.
  ///
  /// [locale] selects the language for the draft (`id` or `en`); defaults to
  /// Indonesian to match the rest of the app.
  ///
  /// When [transcribe] is true the backend resolves the URL via Cobalt,
  /// downloads the audio, and runs Whisper before summarizing. Only
  /// supported for instagram/tiktok/twitter (YouTube already uses native
  /// caption transcripts). Total round-trip is ~10–30s vs. ~3s for the
  /// default meta-scrape path, so callers should warn the user.
  Stream<AutoSummarizeEvent> summarize({
    required String url,
    String locale = 'id',
    bool transcribe = false,
  });
}
