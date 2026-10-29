import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/features/vault/presentation/widgets/quiz_toggle.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('a note can be switched out of the quizzes and back',
      (tester) async {
    // A small phone: the longer "off" line has to wrap, not overflow.
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    var inQuiz = true;
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
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) => QuizToggle(
              value: inQuiz,
              onChanged: (v) => setState(() => inQuiz = v),
            ),
          ),
        ),
      ),
    ));

    expect(find.text('Jadi bahan kuis'), findsOneWidget);
    expect(find.textContaining('kuis harian'), findsOneWidget);

    await tester.tap(find.byType(QuizToggle));
    await tester.pump(const Duration(milliseconds: 300));
    expect(inQuiz, isFalse);
    expect(find.textContaining('judul komik atau buku'), findsOneWidget);

    await tester.tap(find.byType(QuizToggle));
    await tester.pump(const Duration(milliseconds: 300));
    expect(inQuiz, isTrue);
  });
}
