import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../l10n/generated/app_localizations.dart';

// Notes are kept as Markdown — the AI writes it, the note page and the
// shared page render it. Writing it by hand is another matter, so the
// editors use these: a controller that shows the Markdown the way it will
// read while you type, buttons that put the marks in for you, and lists
// that carry on by themselves.

// ─── what each character looks like ──────────────────────────────────

// Bits; a character can have several.
const _faint = 1 << 0; // a mark near the caret: shown, but quietly
const _hidden = 1 << 1; // a mark anywhere else: out of sight
const _bold = 1 << 2;
const _italic = 1 << 3;
const _code = 1 << 4;
const _h1 = 1 << 5;
const _h2 = 1 << 6;
const _h3 = 1 << 7;
const _bullet = 1 << 8; // a list's mark (`-`, `*`, `+` are drawn as •)
const _quote = 1 << 9;
const _link = 1 << 10;
const _composing = 1 << 11; // the word the keyboard is still writing

final _heading = RegExp(r'^(#{1,6})[ \t]+');
final _listMark = RegExp(r'^([ \t]*)([-*+]|\d{1,3}[.)])[ \t]+');
final _bulletMark = RegExp(r'^[ \t]*[-*+][ \t]+');
final _numberMark = RegExp(r'^[ \t]*\d{1,3}[.)][ \t]+');
final _quoteMark = RegExp(r'^[ \t]*>[ \t]?');
final _anyLineMark = RegExp(r'^[ \t]*(?:[-*+]|\d{1,3}[.)]|#{1,6})[ \t]+');
final _codeSpan = RegExp(r'`[^`\n]+`');
final _strong = RegExp(r'(\*\*|__)(?=\S)(.+?)(?<=\S)\1');
final _em = RegExp(
  r'(?<![*_\p{L}\p{N}])([*_])(?=\S)([^*_\n]+?)(?<=\S)\1(?![*_\p{L}\p{N}])',
  unicode: true,
);
final _linkSpan = RegExp(r'\[([^\]\n]+)\]\(([^)\s]+)\)');
final _wordChar = RegExp(r"[\p{L}\p{N}_'’-]", unicode: true);

/// A mark (`**`, `## `, a link's `](…)`) at [from]–[to], and the bit of
/// text it belongs to ([ownerFrom]–[ownerTo]): it shows while the caret is
/// in that bit, so you can see where it starts and ends, and hides
/// otherwise.
typedef _Mark = ({int from, int to, int ownerFrom, int ownerTo});

/// What's in a note's text: how each character looks (bits above), its
/// marks, and where list bullets are.
class _Parsed {
  _Parsed(int length) : looks = List<int>.filled(length, 0);
  final List<int> looks;
  final marks = <_Mark>[];
  final bullets = <int>{};

  void look(int a, int b, int bits) {
    for (var i = a; i < b; i++) {
      looks[i] |= bits;
    }
  }

  void mark(int a, int b, int ownerFrom, int ownerTo) =>
      marks.add((from: a, to: b, ownerFrom: ownerFrom, ownerTo: ownerTo));
}

_Parsed _parse(String text) {
  final p = _Parsed(text.length);
  var at = 0;
  for (final line in text.split('\n')) {
    final end = at + line.length;
    var body = 0;
    final h = _heading.firstMatch(line);
    final l = h == null ? _listMark.firstMatch(line) : null;
    final q = h == null && l == null ? _quoteMark.firstMatch(line) : null;
    if (h != null) {
      final size = switch (h.group(1)!.length) { 1 => _h1, 2 => _h2, _ => _h3 };
      p.look(at, end, size);
      p.look(at + h.end, end, _bold);
      p.mark(at, at + h.end, at, end);
      body = h.end;
    } else if (l != null) {
      final mark = at + l.group(1)!.length;
      final sign = l.group(2)!;
      p.look(mark, mark + sign.length, _bullet);
      // `-`, `*` or `+` (numbers are two characters or more).
      if (sign.length == 1) p.bullets.add(mark);
      body = l.end;
    } else if (q != null) {
      p.look(at + q.end, end, _quote);
      p.mark(at, at + q.end, at, end);
      body = q.end;
    }
    _parseInline(line.substring(body), at + body, p);
    at = end + 1;
  }
  return p;
}

/// Bold, italic, code and links within one line, starting at [at].
void _parseInline(String s, int at, _Parsed p) {
  // Code first: nothing inside it is formatting. Marks taken by one span
  // can't start or end another.
  final taken = List<bool>.filled(s.length, false);
  bool free(int a, int b) {
    for (var i = a; i < b; i++) {
      if (taken[i]) return false;
    }
    return true;
  }

  void take(int a, int b) {
    for (var i = a; i < b; i++) {
      taken[i] = true;
    }
  }

  /// A span from [a] to [b] with [n]-character marks at each end.
  void span(int a, int b, int n, int bits) {
    p.look(at + a + n, at + b - n, bits);
    p.mark(at + a, at + a + n, at + a, at + b);
    p.mark(at + b - n, at + b, at + a, at + b);
  }

  for (final m in _codeSpan.allMatches(s)) {
    span(m.start, m.end, 1, _code);
    take(m.start, m.end);
  }
  for (final m in _strong.allMatches(s)) {
    if (!free(m.start, m.end)) continue;
    final n = m.group(1)!.length;
    span(m.start, m.end, n, _bold);
    take(m.start, m.start + n);
    take(m.end - n, m.end);
  }
  for (final m in _em.allMatches(s)) {
    if (!free(m.start, m.end)) continue;
    span(m.start, m.end, 1, _italic);
  }
  for (final m in _linkSpan.allMatches(s)) {
    if (!free(m.start, m.end)) continue;
    final label = m.start + 1 + m.group(1)!.length;
    p.look(at + m.start + 1, at + label, _link);
    p.mark(at + m.start, at + m.start + 1, at + m.start, at + m.end);
    p.mark(at + label, at + m.end, at + m.start, at + m.end);
  }
}

TextStyle _styleOf(int looks, TextStyle base, AppPalette palette) {
  if (looks == 0) return base;
  // Out of sight: next to no width, no ink.
  if (looks & _hidden != 0) {
    return base.copyWith(
      fontSize: 0.01,
      color: const Color(0x00000000),
      letterSpacing: 0,
      wordSpacing: 0,
      decoration: TextDecoration.none,
    );
  }
  final size = base.fontSize ?? 15;
  final ink = base.color ?? palette.textPrimary;
  var s = base;
  if (looks & _h1 != 0) {
    s = s.copyWith(fontSize: size * 1.3);
  } else if (looks & _h2 != 0) {
    s = s.copyWith(fontSize: size * 1.18);
  } else if (looks & _h3 != 0) {
    s = s.copyWith(fontSize: size * 1.08);
  }
  if (looks & _bold != 0) s = s.copyWith(fontWeight: FontWeight.w700);
  if (looks & (_italic | _quote) != 0) {
    s = s.copyWith(fontStyle: FontStyle.italic);
  }
  if (looks & _quote != 0) s = s.copyWith(color: ink.withValues(alpha: 0.72));
  if (looks & _code != 0) {
    s = s.copyWith(
      color: palette.primaryDark,
      backgroundColor: palette.primarySoft.withValues(alpha: 0.7),
    );
  }
  if (looks & _bullet != 0) {
    s = s.copyWith(color: palette.primary, fontWeight: FontWeight.w800);
  }
  if (looks & _link != 0) {
    s = s.copyWith(
      color: palette.primary,
      decoration: TextDecoration.underline,
      decorationColor: palette.primary.withValues(alpha: 0.5),
    );
  }
  if (looks & _faint != 0) s = s.copyWith(color: ink.withValues(alpha: 0.28));
  if (looks & _composing != 0) {
    s = s.copyWith(decoration: TextDecoration.underline);
  }
  return s;
}

// ─── previews ─────────────────────────────────────────────────────────

/// A note's text for a preview — a sticky note on the board, say: bold and
/// italic as they'll read, lists with • and their numbers, headings as bold
/// lines, and none of the Markdown marks. Blank lines close up so more of
/// the note fits.
TextSpan markdownPreview(
  String text, {
  required TextStyle style,
  required AppPalette palette,
}) {
  final t = text
      .trim()
      .replaceAll(RegExp(r'\n[ \t]*\n+'), '\n')
      // One space after a list mark (the AI often writes `*   `).
      .replaceAllMapped(_listLine, (m) => '${m[1]}${m[2]} ');
  final p = _parse(t);
  final drop = List<bool>.filled(t.length, false);
  for (final m in p.marks) {
    for (var i = m.from; i < m.to; i++) {
      drop[i] = true;
    }
  }
  const sizes = _h1 | _h2 | _h3;
  final spans = <TextSpan>[];
  final run = StringBuffer();
  var look = -1;
  void flush() {
    if (run.isEmpty) return;
    spans.add(TextSpan(
        text: run.toString(), style: _styleOf(look, style, palette)));
    run.clear();
  }

  for (var i = 0; i < t.length; i++) {
    if (drop[i]) continue;
    final l = p.looks[i] & ~sizes;
    if (l != look) {
      flush();
      look = l;
    }
    run.write(p.bullets.contains(i) ? '•' : t[i]);
  }
  flush();
  return TextSpan(style: style, children: spans);
}

final _listLine =
    RegExp(r'^([ \t]*)([-*+]|\d{1,3}[.)])[ \t]+', multiLine: true);

// ─── the controller ───────────────────────────────────────────────────

/// A note's text, shown the way it will read: `**bold**` is bold with the
/// stars out of sight, a `## heading` is big without its `##`, a list's
/// `-` or `*` is a bullet. Around the caret the marks come back, faintly,
/// so you can see where a bold bit starts and ends while you edit it. The
/// text stays plain Markdown; [MarkdownToolbar] puts the marks in, so
/// nobody has to know them.
class MarkdownEditingController extends TextEditingController {
  MarkdownEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    final t = text;
    if (t.isEmpty) return TextSpan(style: base, text: t);
    final p = _parse(t);
    final looks = p.looks;
    final sel = value.selection;
    for (final m in p.marks) {
      final near =
          sel.isValid && sel.start <= m.ownerTo && sel.end >= m.ownerFrom;
      p.look(m.from, m.to, near ? _faint : _hidden);
    }
    if (withComposing && value.isComposingRangeValid) {
      p.look(value.composing.start, value.composing.end, _composing);
    }
    final palette = context.palette;
    final spans = <InlineSpan>[];
    var from = 0;
    void run(int to) {
      if (to > from) {
        spans.add(TextSpan(
          text: t.substring(from, to),
          style: _styleOf(looks[from], base, palette),
        ));
      }
    }

    for (var i = 0; i < t.length; i++) {
      if (p.bullets.contains(i)) {
        // One character either way, so the text and caret stay in step.
        run(i);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Text('•', style: _styleOf(_bullet, base, palette)),
        ));
        from = i + 1;
      } else if (i > from && looks[i] != looks[from]) {
        run(i);
        from = i;
      }
    }
    run(t.length);
    return TextSpan(style: base, children: spans);
  }

  // What's under the caret, for the toolbar's lit buttons.

  /// The caret, or the end when the field hasn't been touched yet.
  TextSelection get _sel => selection.isValid
      ? selection
      : TextSelection.collapsed(offset: text.length);

  int _lineStart(int o) => o <= 0 ? 0 : text.lastIndexOf('\n', o - 1) + 1;

  int _lineEnd(int o) {
    final i = text.indexOf('\n', o);
    return i == -1 ? text.length : i;
  }

  String get _line =>
      text.substring(_lineStart(_sel.start), _lineEnd(_sel.start));

  bool get isBold => _boldAround() != null;
  bool get isHeading => _heading.hasMatch(_line);
  bool get isBulleted => _bulletMark.hasMatch(_line);
  bool get isNumbered => _numberMark.hasMatch(_line);

  /// The `**…**` the selection sits in, marks included.
  (int, int)? _boldAround() {
    final sel = _sel;
    final ls = _lineStart(sel.start);
    if (sel.end > _lineEnd(sel.start)) return null;
    final line = text.substring(ls, _lineEnd(sel.start));
    for (final m in _strong.allMatches(line)) {
      final n = m.group(1)!.length;
      if (sel.start >= ls + m.start + n && sel.end <= ls + m.end - n) {
        return (ls + m.start, ls + m.end);
      }
    }
    return null;
  }

  void _set(String text, TextSelection selection) =>
      value = TextEditingValue(text: text, selection: selection);

  // The toolbar's actions.

  /// Makes the selection bold — or the word at the caret, or starts a bold
  /// bit to type into — and takes it off again when it's already bold.
  void toggleBold() {
    final t = text;
    final sel = _sel;
    final around = _boldAround();
    if (around != null) {
      // The selection is inside the marks, so only the opening two come
      // out before it.
      final (a, b) = around;
      _set(
        t.replaceRange(b - 2, b, '').replaceRange(a, a + 2, ''),
        TextSelection(
            baseOffset: sel.baseOffset - 2, extentOffset: sel.extentOffset - 2),
      );
      return;
    }
    var s = sel.start, e = sel.end;
    // Spaces at the edges stay outside: `**word **` isn't bold.
    while (s < e && t[s].trim().isEmpty) {
      s++;
    }
    while (e > s && t[e - 1].trim().isEmpty) {
      e--;
    }
    if (s == e) {
      final word = _wordAround(s);
      if (word == null) {
        // Nothing to wrap: a pair to type into.
        _set(t.replaceRange(s, s, '****'), TextSelection.collapsed(offset: s + 2));
        return;
      }
      final (ws, we) = word;
      _set('${t.substring(0, ws)}**${t.substring(ws, we)}**${t.substring(we)}',
          TextSelection.collapsed(offset: sel.start + 2));
      return;
    }
    _set('${t.substring(0, s)}**${t.substring(s, e)}**${t.substring(e)}',
        TextSelection(baseOffset: s + 2, extentOffset: e + 2));
  }

  (int, int)? _wordAround(int o) {
    var s = o, e = o;
    while (s > 0 && _wordChar.hasMatch(text[s - 1])) {
      s--;
    }
    while (e < text.length && _wordChar.hasMatch(text[e])) {
      e++;
    }
    return s == e ? null : (s, e);
  }

  /// Makes the caret's line a heading, or a plain line again.
  void toggleHeading() {
    final sel = _sel;
    final ls = _lineStart(sel.start);
    final line = text.substring(ls, _lineEnd(sel.start));
    final h = _heading.firstMatch(line);
    _replaceLineStart(ls, h?.end ?? _anyLineMark.firstMatch(line)?.end ?? 0,
        h == null ? '## ' : '', sel);
  }

  /// Turns the selected lines into a list (bulleted or [numbered]), or
  /// back into plain lines when they already are one.
  void toggleList({required bool numbered}) {
    final sel = _sel;
    final ls = _lineStart(sel.start);
    final le = _lineEnd(sel.end);
    final lines = text.substring(ls, le).split('\n');
    if (lines.length == 1) {
      final line = lines.single;
      final mine = (numbered ? _numberMark : _bulletMark).firstMatch(line);
      _replaceLineStart(ls, mine?.end ?? _anyLineMark.firstMatch(line)?.end ?? 0,
          mine != null ? '' : (numbered ? '1. ' : '- '), sel);
      return;
    }
    final mine = numbered ? _numberMark : _bulletMark;
    final filled = lines.where((l) => l.trim().isNotEmpty);
    final off = filled.isNotEmpty && filled.every(mine.hasMatch);
    var n = 0;
    final block = [
      for (final l in lines)
        if (off)
          l.replaceFirst(_listMark, '')
        else if (l.trim().isEmpty)
          l
        else
          '${numbered ? '${++n}.' : '-'} ${l.replaceFirst(_anyLineMark, '')}',
    ].join('\n');
    _set(text.replaceRange(ls, le, block),
        TextSelection(baseOffset: ls, extentOffset: ls + block.length));
  }

  /// Swaps the first [cut] characters of the line at [ls] for [put],
  /// moving the selection along with the text.
  void _replaceLineStart(int ls, int cut, String put, TextSelection sel) {
    int move(int o) => o <= ls
        ? o
        : o < ls + cut
            ? ls + put.length
            : o + put.length - cut;
    _set(
      text.replaceRange(ls, ls + cut, put),
      TextSelection(
          baseOffset: move(sel.baseOffset), extentOffset: move(sel.extentOffset)),
    );
  }
}

// ─── lists that carry on ──────────────────────────────────────────────

/// Enter in a list starts the next item with the same mark (or the next
/// number); Enter on an empty item ends the list instead. Only for what
/// you type: the AI's draft streaming in isn't touched.
class MarkdownListContinuation extends TextInputFormatter {
  const MarkdownListContinuation();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final caret = newValue.selection;
    final old = oldValue.selection;
    if (!caret.isCollapsed || !old.isValid || caret.start < 2) return newValue;
    final at = caret.start;
    final text = newValue.text;
    // Just an Enter, where the caret was.
    if (text.length != oldValue.text.length + 1 - (old.end - old.start) ||
        text[at - 1] != '\n' ||
        text != oldValue.text.replaceRange(old.start, old.end, '\n')) {
      return newValue;
    }
    final ls = text.lastIndexOf('\n', at - 2) + 1;
    final line = text.substring(ls, at - 1);
    final m = _listMark.firstMatch(line);
    if (m == null) return newValue;
    if (line.substring(m.end).trim().isEmpty) {
      // An empty item: the list ends here.
      return TextEditingValue(
        text: text.replaceRange(ls, at, ''),
        selection: TextSelection.collapsed(offset: ls),
      );
    }
    final mark = m.group(2)!;
    final number = int.tryParse(mark.substring(0, mark.length - 1));
    final next = number == null ? mark : '${number + 1}${mark[mark.length - 1]}';
    final prefix = '${m.group(1)}$next ';
    return TextEditingValue(
      text: text.replaceRange(at, at, prefix),
      selection: TextSelection.collapsed(offset: at + prefix.length),
    );
  }
}

// ─── the toolbar ──────────────────────────────────────────────────────

/// Bold, heading, bulleted and numbered list for a note's text. A button
/// is lit when the caret is in that kind of text; tapping it again takes
/// it off. Taps don't close the keyboard.
class MarkdownToolbar extends StatelessWidget {
  final MarkdownEditingController controller;

  /// The icons' colour when off (the ink on a coloured sheet, say).
  final Color? ink;

  const MarkdownToolbar({super.key, required this.controller, this.ink});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextFieldTapRegion(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FormatButton(
              icon: Icons.format_bold_rounded,
              label: l10n.formatBold,
              on: controller.isBold,
              ink: ink,
              onTap: controller.toggleBold,
            ),
            _FormatButton(
              icon: Icons.title_rounded,
              label: l10n.formatHeading,
              on: controller.isHeading,
              ink: ink,
              onTap: controller.toggleHeading,
            ),
            _FormatButton(
              icon: Icons.format_list_bulleted_rounded,
              label: l10n.formatBullets,
              on: controller.isBulleted,
              ink: ink,
              onTap: () => controller.toggleList(numbered: false),
            ),
            _FormatButton(
              icon: Icons.format_list_numbered_rounded,
              label: l10n.formatNumbers,
              on: controller.isNumbered,
              ink: ink,
              onTap: () => controller.toggleList(numbered: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final Color? ink;
  final VoidCallback onTap;
  const _FormatButton({
    required this.icon,
    required this.label,
    required this.on,
    required this.ink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 38,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: on ? palette.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 21,
              color: on ? palette.primary : (ink ?? palette.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
