import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/theme/app_palette.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/shared/widgets/markdown_editor.dart';

/// The controller after setting [text] with the selection given as `|`
/// (a caret) or `[…]` (selected text).
MarkdownEditingController editing(String marked) {
  final caret = marked.indexOf('|');
  if (caret != -1) {
    return MarkdownEditingController(text: marked.replaceFirst('|', ''))
      ..selection = TextSelection.collapsed(offset: caret);
  }
  final s = marked.indexOf('[');
  final e = marked.indexOf(']') - 1;
  return MarkdownEditingController(
      text: marked.replaceFirst('[', '').replaceFirst(']', ''))
    ..selection = TextSelection(baseOffset: s, extentOffset: e);
}

/// The text with the selection marked the same way.
String shown(TextEditingController c) {
  final t = c.text, s = c.selection;
  if (s.isCollapsed) return t.replaceRange(s.start, s.start, '|');
  return '${t.substring(0, s.start)}[${t.substring(s.start, s.end)}]'
      '${t.substring(s.end)}';
}

TextEditingValue enter(String before) {
  final caret = before.indexOf('|');
  final text = before.replaceFirst('|', '');
  final old = TextEditingValue(
      text: text, selection: TextSelection.collapsed(offset: caret));
  final typed = TextEditingValue(
    text: text.replaceRange(caret, caret, '\n'),
    selection: TextSelection.collapsed(offset: caret + 1),
  );
  return const MarkdownListContinuation().formatEditUpdate(old, typed);
}

String shownValue(TextEditingValue v) =>
    v.text.replaceRange(v.selection.start, v.selection.start, '|');

void main() {
  group('how it reads while you type', () {
    Future<TextSpan> render(
        WidgetTester tester, MarkdownEditingController c) async {
      late TextSpan span;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        home: Builder(builder: (context) {
          span = c.buildTextSpan(
            context: context,
            style: const TextStyle(fontSize: 15, color: Colors.black),
            withComposing: false,
          );
          return const SizedBox();
        }),
      ));
      return span;
    }

    TextStyle styleOf(TextSpan span, String s) => span.children!
        .whereType<TextSpan>()
        .firstWhere((p) => p.text == s)
        .style!;

    testWidgets('marks are out of sight, the text stays the same',
        (tester) async {
      final c = MarkdownEditingController(
          text: '## Bahan\n* **dada ayam** dan *bawang*\n1. Tumis');
      final span = await render(tester, c);
      // Same length as the text, so the caret lands where it should.
      expect(span.toPlainText(includePlaceholders: true).length,
          c.text.length);
      expect(styleOf(span, 'dada ayam').fontWeight, FontWeight.w700);
      expect(styleOf(span, 'bawang').fontStyle, FontStyle.italic);
      expect(styleOf(span, 'Bahan').fontSize, greaterThan(15));
      expect(styleOf(span, '**').fontSize, lessThan(0.1));
      expect(styleOf(span, '## ').fontSize, lessThan(0.1));
      // The list's `*` is drawn as a bullet; numbers stay.
      expect(span.children!.whereType<WidgetSpan>(), hasLength(1));
      expect(styleOf(span, '1.').fontWeight, FontWeight.w800);
    });

    testWidgets('hidden marks take next to no room', (tester) async {
      final marked = await render(
          tester, MarkdownEditingController(text: '**tebal** biasa'));
      final plain = await render(
          tester, MarkdownEditingController(text: 'tebal biasa'));
      double width(TextSpan s) {
        final tp = TextPainter(text: s, textDirection: TextDirection.ltr)
          ..layout();
        return tp.width;
      }

      expect((width(marked) - width(plain)).abs(), lessThan(1));
    });

    testWidgets('around the caret the marks come back, faintly',
        (tester) async {
      final c = MarkdownEditingController(text: 'ini **tebal** dan **lagi**')
        ..selection = const TextSelection.collapsed(offset: 8);
      final span = await render(tester, c);
      final shown = span.children!
          .whereType<TextSpan>()
          .where((p) => p.text == '**')
          .map((p) => p.style!)
          .toList();
      // The pair round "tebal" shows; the one round "lagi" stays hidden.
      expect(shown.where((s) => s.fontSize == 15), hasLength(2));
      expect(shown.first.color!.a, lessThan(0.5));
      expect(shown.where((s) => s.fontSize! < 0.1), hasLength(2));
    });
  });

  testWidgets('in a real text field: bullets show, typing works',
      (tester) async {
    final c = MarkdownEditingController(
        text: '* **System Justification**: status quo\n* kedua');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: TextField(
          controller: c,
          maxLines: null,
          inputFormatters: const [MarkdownListContinuation()],
          // Like the notepaper editor.
          strutStyle: const StrutStyle(
              fontSize: 15, height: 1.8, forceStrutHeight: true),
        ),
      ),
    ));
    expect(find.text('•'), findsNWidgets(2));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    c.selection = TextSelection.collapsed(offset: c.text.length);
    await tester.pump();
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: '${c.text}\n',
      selection: TextSelection.collapsed(offset: c.text.length + 1),
    ));
    await tester.pump();
    expect(c.text, endsWith('* kedua\n* '));
    expect(find.text('•'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('previews: no marks, bold stays bold, lists get bullets',
      (tester) async {
    late TextSpan span;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Builder(builder: (context) {
        span = markdownPreview(
          '**Daftar Bug yang Perlu Dibetulkan:**\n\n1. Sound effect\n'
          '*   **System**: quo\n## Judul',
          style: const TextStyle(fontSize: 13.5),
          palette: context.palette,
        );
        return const SizedBox();
      }),
    ));
    expect(span.toPlainText(),
        'Daftar Bug yang Perlu Dibetulkan:\n1. Sound effect\n• System: quo\nJudul');
    final parts = span.children!.cast<TextSpan>();
    expect(parts.first.text, 'Daftar Bug yang Perlu Dibetulkan:');
    expect(parts.first.style!.fontWeight, FontWeight.w700);
    // A heading is a bold line here, not big type.
    expect(parts.last.text, 'Judul');
    expect(parts.last.style!.fontSize, 13.5);
  });

  group('bold', () {
    test('wraps the selection, and unwraps it', () {
      final c = editing('Pakai [mentega] saja');
      c.toggleBold();
      expect(shown(c), 'Pakai **[mentega]** saja');
      c.toggleBold();
      expect(shown(c), 'Pakai [mentega] saja');
    });

    test('with just a caret: the word under it', () {
      final c = editing('Pakai men|tega saja');
      c.toggleBold();
      expect(shown(c), 'Pakai **men|tega** saja');
      c.toggleBold();
      expect(shown(c), 'Pakai men|tega saja');
    });

    test('caret at the end of a bold bit takes the marks off', () {
      final c = editing('a **mentega|** b');
      expect(c.isBold, isTrue);
      c.toggleBold();
      expect(shown(c), 'a mentega| b');
    });

    test('nothing to wrap: a pair to type into', () {
      final c = editing('Bahan: |');
      c.toggleBold();
      expect(shown(c), 'Bahan: **|**');
    });

    test('spaces at the edges stay outside', () {
      final c = editing('a[ kata ]b');
      c.toggleBold();
      expect(c.text, 'a **kata** b');
    });
  });

  group('heading', () {
    test('on and off', () {
      final c = editing('Bah|an');
      c.toggleHeading();
      expect(shown(c), '## Bah|an');
      expect(c.isHeading, isTrue);
      c.toggleHeading();
      expect(shown(c), 'Bah|an');
    });

    test('a list item becomes a heading', () {
      final c = editing('- Lang|kah');
      c.toggleHeading();
      expect(shown(c), '## Lang|kah');
    });
  });

  group('lists', () {
    test('a line on and off, and from bullets to numbers', () {
      final c = editing('telur|');
      c.toggleList(numbered: false);
      expect(shown(c), '- telur|');
      c.toggleList(numbered: true);
      expect(shown(c), '1. telur|');
      c.toggleList(numbered: true);
      expect(shown(c), 'telur|');
    });

    test('several lines are numbered in order, blank lines left alone', () {
      final c = editing('[telur\nmentega\n\nkecap]');
      c.toggleList(numbered: true);
      expect(c.text, '1. telur\n2. mentega\n\n3. kecap');
      c.toggleList(numbered: true);
      expect(c.text, 'telur\nmentega\n\nkecap');
    });

    test('Enter carries the list on', () {
      expect(shownValue(enter('- telur|')), '- telur\n- |');
      expect(shownValue(enter('* telur|')), '* telur\n* |');
      expect(shownValue(enter('2. Tumis|')), '2. Tumis\n3. |');
      expect(shownValue(enter('  - indented|')), '  - indented\n  - |');
    });

    test('Enter on an empty item ends the list', () {
      expect(shownValue(enter('- telur\n- |')), '- telur\n|');
    });

    test('Enter elsewhere is just Enter', () {
      expect(shownValue(enter('Biasa saja|')), 'Biasa saja\n|');
      expect(shownValue(enter('|')), '\n|');
    });

    test('a paste is left as it is', () {
      const old = TextEditingValue(
          text: '- a', selection: TextSelection.collapsed(offset: 3));
      const pasted = TextEditingValue(
          text: '- a\nb\n', selection: TextSelection.collapsed(offset: 6));
      expect(
          const MarkdownListContinuation().formatEditUpdate(old, pasted), pasted);
    });
  });
}
