/// Lightweight Markdown → plain text converter for preview snippets.
///
/// Note detail / shared note pages render the full Markdown via
/// `MarkdownBody`, but inline previews on the dashboard carousel, vault
/// list, etc. only show 1-2 lines truncated — and there `**bold**`,
/// `- list`, `# heading` markers leak as raw text. This utility strips
/// the syntax while preserving the readable content.
///
/// We deliberately keep this regex-based (not a full Markdown parser)
/// because previews are visual hints, not authoritative renders. If a
/// rare construct sneaks through, the worst outcome is a stray symbol
/// — the user still sees the gist.
String stripMarkdown(String input) {
  if (input.isEmpty) return input;
  String s = input;

  // Fenced code blocks: keep the inner code, drop the fences.
  s = s.replaceAllMapped(
    RegExp(r'```[\w]*\n([\s\S]*?)```', multiLine: true),
    (m) => m.group(1) ?? '',
  );

  // Inline code: `code` → code
  s = s.replaceAllMapped(
    RegExp(r'`([^`]+)`'),
    (m) => m.group(1) ?? '',
  );

  // Images: ![alt](url) → alt (preserves descriptive text if any)
  s = s.replaceAllMapped(
    RegExp(r'!\[([^\]]*)\]\([^)]+\)'),
    (m) => m.group(1) ?? '',
  );

  // Links: [text](url) → text
  s = s.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\([^)]+\)'),
    (m) => m.group(1) ?? '',
  );

  // Bold: **text** or __text__
  s = s.replaceAllMapped(
    RegExp(r'\*\*([^*]+)\*\*'),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAllMapped(
    RegExp(r'__([^_]+)__'),
    (m) => m.group(1) ?? '',
  );

  // Italic: *text* or _text_ — guarded so it doesn't eat snake_case words.
  s = s.replaceAllMapped(
    RegExp(r'(?<![*\w])\*([^*\n]+)\*(?!\w)'),
    (m) => m.group(1) ?? '',
  );
  s = s.replaceAllMapped(
    RegExp(r'(?<![_\w])_([^_\n]+)_(?!\w)'),
    (m) => m.group(1) ?? '',
  );

  // Strikethrough: ~~text~~
  s = s.replaceAllMapped(
    RegExp(r'~~([^~]+)~~'),
    (m) => m.group(1) ?? '',
  );

  // ATX headings at line start: # Heading → Heading
  s = s.replaceAll(RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true), '');

  // Blockquote markers
  s = s.replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '');

  // Unordered list bullets: - * + → strip leading marker
  s = s.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');

  // Ordered list: 1. 2. 3. → strip leading marker
  s = s.replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '');

  // Horizontal rules: --- *** ___
  s = s.replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '');

  // Collapse whitespace: tabs/multiple spaces → single space, multiple
  // newlines → single newline. Inline previews don't need paragraphs.
  s = s.replaceAll(RegExp(r'[ \t]+'), ' ');
  s = s.replaceAll(RegExp(r'\n{2,}'), '\n');

  return s.trim();
}
