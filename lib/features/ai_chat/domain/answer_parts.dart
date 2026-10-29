import '../../../core/utils/markdown_strip.dart';
import 'entities/message_entity.dart';

/// An answer as the Tanya page shows it: the pet says its opening line out
/// loud in the room ("Wah, yang ini aku ingat banget! 😋"), and the card
/// below holds the rest.
class AnswerParts {
  /// What the pet says, as plain text. Null when the answer opens straight
  /// with its content (a list, a heading, a cited fact) or the first
  /// sentence is too long to say.
  final String? opener;

  /// The answer without its opener (Markdown).
  final String rest;

  /// Still coming in, and its first sentence isn't finished yet.
  final bool pending;

  const AnswerParts._(this.opener, this.rest, {this.pending = false});

  /// A line longer than this is content, not a reaction.
  static const maxOpener = 140;

  static final _structure = RegExp(r'^(#|[-*+] |\d+[.)] |```|>|\|)');
  static final _sentenceEnd = RegExp(r'[.!?…](?=\s|$)');

  /// Emoji or closing marks right after the sentence ("! 😋").
  static final _trailing = RegExp(r'^(?:[ \t]*[^\s\w\[\]*#_`]+)+');
  static final _citation = RegExp(r'\[\d');

  factory AnswerParts.of(MessageEntity m) {
    final text = m.content.trimLeft();
    AnswerParts whole() => AnswerParts._(null, m.content);
    if (text.isEmpty) {
      return AnswerParts._(null, '', pending: m.streaming);
    }
    if (_structure.hasMatch(text)) return whole();

    final newline = text.indexOf('\n');
    final line = newline < 0 ? text : text.substring(0, newline);
    var cut = -1;
    final end = _sentenceEnd.firstMatch(line);
    if (end != null) {
      cut = end.end;
      cut += _trailing.matchAsPrefix(line.substring(cut))?.end ?? 0;
    } else if (newline >= 0 || !m.streaming) {
      // A first line with no full stop, now complete.
      cut = line.length;
    } else if (line.length <= maxOpener) {
      return const AnswerParts._(null, '', pending: true);
    }
    if (cut < 0) return whole();

    final said = text.substring(0, cut).trim();
    if (said.length > maxOpener || _citation.hasMatch(said)) return whole();
    final opener = stripMarkdown(said).trim();
    if (opener.isEmpty) return whole();
    return AnswerParts._(opener, text.substring(cut).trimLeft());
  }
}

/// The notes [m] actually cites ("[1]", "[2, 3]"), in order. The search
/// hands over its closest notes whether or not they helped.
List<SourceEntity> citedSources(MessageEntity m) {
  final cited = <int>{
    for (final c in RegExp(r'\[(\d+(?:\s*,\s*\d+)*)\]').allMatches(m.content))
      for (final n in c.group(1)!.split(',')) int.parse(n.trim()),
  };
  return [
    for (var i = 0; i < m.sources.length; i++)
      if (cited.contains(i + 1)) m.sources[i],
  ];
}
