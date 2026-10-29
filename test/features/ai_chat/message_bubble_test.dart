import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/di/injection_container.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/features/ai_chat/domain/entities/message_entity.dart';
import 'package:ingatanku/features/ai_chat/presentation/widgets/message_bubble.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const sources = [
    SourceEntity(noteId: 'n1', title: 'Resep ayam mentega', similarity: 0.8),
    SourceEntity(noteId: 'n2', title: 'Tips hemat belanja', similarity: 0.6),
    SourceEntity(noteId: 'n3', title: 'Docker dasar', similarity: 0.55),
  ];

  Future<void> show(WidgetTester tester, String content,
      {bool streaming = false}) async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    sl.registerSingleton(PetStore(await SharedPreferences.getInstance()));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: MessageBubble(
            message: MessageEntity(
              id: 'a',
              role: MessageRole.assistant,
              content: content,
              sources: sources,
              streaming: streaming,
              createdAt: DateTime(2026, 10, 21),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('only the notes the answer cites are listed', (tester) async {
    await show(
        tester, 'Wah, ini dia! Belanja setelah makan ya [2], terus [1, 3].');
    expect(find.text('DARI CATATANMU'), findsOneWidget);
    expect(find.text('Resep ayam mentega'), findsOneWidget);
    expect(find.text('Tips hemat belanja'), findsOneWidget);
    expect(find.text('Docker dasar'), findsOneWidget);

    await show(tester, 'Pakai yang ini aja [2] 🙂');
    expect(find.text('Tips hemat belanja'), findsOneWidget);
    expect(find.text('Resep ayam mentega'), findsNothing);
  });

  testWidgets('none cited, or still writing: no sources', (tester) async {
    await show(tester, 'Hmm, aku belum pernah makan catatan soal itu nih.');
    expect(find.text('DARI CATATANMU'), findsNothing);

    await show(tester, 'Belanja setelah makan [2]', streaming: true);
    expect(find.text('DARI CATATANMU'), findsNothing);
  });
}
