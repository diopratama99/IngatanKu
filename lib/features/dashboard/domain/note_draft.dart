/// What the pet wrote down for a link on Beranda, before you check it:
/// the title, the summary notes and the tags it picked, plus what it
/// learned about the source.
class NoteDraft {
  final String url;
  final String? title;
  final String notes;
  final List<String> tags;
  final String sourceType;
  final String? thumbnailUrl;

  /// The source's own title and site, for the preview row.
  final String? sourceTitle;
  final String? siteName;

  /// False when the summary couldn't be made — the notes are then empty
  /// and the review sheet says so.
  final bool summarized;

  /// Not summarized because today's write-ups were used up.
  final bool outOfQuota;

  /// Whether the quizzes may ask about the note (on unless you switch it
  /// off in the review sheet).
  final bool inQuiz;

  const NoteDraft({
    required this.url,
    this.title,
    this.notes = '',
    this.tags = const [],
    required this.sourceType,
    this.thumbnailUrl,
    this.sourceTitle,
    this.siteName,
    this.summarized = true,
    this.outOfQuota = false,
    this.inQuiz = true,
  });

  NoteDraft copyWith({
    String? title,
    String? notes,
    List<String>? tags,
    bool? inQuiz,
  }) =>
      NoteDraft(
        url: url,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        sourceType: sourceType,
        thumbnailUrl: thumbnailUrl,
        sourceTitle: sourceTitle,
        siteName: siteName,
        summarized: summarized,
        outOfQuota: outOfQuota,
        inQuiz: inQuiz ?? this.inQuiz,
      );
}

/// Splits the `# Title` the summary starts with from the rest of the
/// markdown. Returns a null title (and the text untouched) when the first
/// non-empty line isn't an H1, or the heading is empty or too long.
(String?, String) splitMarkdownTitle(String markdown) {
  final lines = markdown.split('\n');
  final first = lines.indexWhere((l) => l.trim().isNotEmpty);
  if (first == -1) return (null, markdown.trim());
  final h1 = RegExp(r'^#\s+(.+)$').firstMatch(lines[first].trim());
  final title = h1?.group(1)?.trim();
  if (title == null || title.isEmpty || title.length > 120) {
    return (null, markdown.trim());
  }
  return (title, lines.sublist(first + 1).join('\n').trim());
}

/// Picks up to [max] tags for a note: hashtags in [hashtagSource] (the
/// source's own title / caption), then the ones the summary [picked], then
/// tags you already use, then common ones — those two only when they
/// appear in [text] as a whole word.
List<String> suggestTags(
  String text, {
  String hashtagSource = '',
  Iterable<String> picked = const [],
  Iterable<String> known = const [],
  Iterable<String> common = const [],
  int max = 4,
}) {
  final tags = <String>[];
  void add(String raw) {
    final tag = raw.trim().toLowerCase().replaceFirst('#', '');
    if (tag.isEmpty || tag.length > 24 || tags.contains(tag)) return;
    if (tags.length < max) tags.add(tag);
  }

  final lower = text.toLowerCase();
  bool mentions(String tag) {
    final t = tag.toLowerCase();
    if (t.isEmpty) return false;
    return RegExp('(^|[^a-z0-9])${RegExp.escape(t)}([^a-z0-9]|\$)')
        .hasMatch(lower);
  }

  for (final m in RegExp(r'#([\p{L}\p{N}_]{2,})', unicode: true)
      .allMatches(hashtagSource)) {
    add(m.group(1)!);
  }
  for (final t in picked) {
    add(t);
  }
  for (final t in known) {
    if (mentions(t)) add(t);
  }
  for (final t in common) {
    if (mentions(t)) add(t);
  }
  return tags;
}
