import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/features/ai_chat/domain/suggested_prompts.dart';
import 'package:ingatanku/features/vault/domain/entities/note_entity.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';

void main() {
  final id = lookupAppLocalizations(const Locale('id'));
  final en = lookupAppLocalizations(const Locale('en'));
  final day = DateTime(2026, 10, 15);

  NoteEntity note(String title, List<String> tags) => NoteEntity(
        id: title,
        userId: 'u',
        url: 'https://example.com/$title',
        title: title,
        manualNotes: '',
        tags: tags,
        sourceType: 'article',
        createdAt: day,
      );

  test('starter prompts come in the app language', () {
    expect(SuggestedPromptsBuilder.build(const [], l10n: id, now: day), [
      id.chatStarterAsk,
      id.chatStarterHow,
      id.chatStarterWhat,
    ]);
    expect(SuggestedPromptsBuilder.build(const [], l10n: en, now: day).first,
        en.chatStarterAsk);
  });

  test('prompts are built from the notes, the same all day', () {
    final notes = [
      note('Sambal matah', ['resep']),
      note('Hemat belanja', ['keuangan']),
    ];
    final a = SuggestedPromptsBuilder.build(notes, l10n: en, now: day);
    final b = SuggestedPromptsBuilder.build(notes, l10n: en, now: day);
    expect(a, hasLength(3));
    expect(a, b);
    // Every prompt is English, whatever it's about.
    final allEnglish = {
      ...SuggestedPromptsBuilder.build(notes, l10n: en, now: day),
      for (var d = 1; d < 8; d++)
        ...SuggestedPromptsBuilder.build(notes,
            l10n: en, now: day.add(Duration(days: d))),
    };
    expect(allEnglish.any((p) => p.contains('Rangkum')), isFalse);
  });
}
