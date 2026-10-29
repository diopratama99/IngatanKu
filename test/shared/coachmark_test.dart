import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';
import 'package:ingatanku/shared/widgets/coachmark.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final pet = GlobalKey();
  final options = GlobalKey();
  final gone = GlobalKey();
  late BuildContext page;

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(392 * 2, 850 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
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
      home: Builder(builder: (context) {
        page = context;
        return Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 120),
              SizedBox(key: pet, width: 70, height: 70),
              const SizedBox(height: 300),
              SizedBox(key: options, width: 300, height: 200),
            ],
          ),
        );
      }),
    ));
  }

  // The spotlight's ring keeps breathing, so it never "settles".
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  List<CoachStep> steps() => [
        CoachStep(target: pet, text: 'kasih makan', circle: true),
        // Not on screen: left out.
        CoachStep(target: gone, text: 'tidak ada'),
        CoachStep(target: options, text: 'pilih jawaban'),
      ];

  testWidgets('a tour walks through what is on screen, then never again',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester);

    final first = Coachmark.showOnce(page, id: 'test', steps: steps());
    await settle(tester);
    expect(Coachmark.showing.value, isTrue);
    expect(find.text('kasih makan'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await settle(tester);
    expect(find.text('tidak ada'), findsNothing);
    expect(find.text('pilih jawaban'), findsOneWidget);
    // The card sits above a spotlight in the lower half.
    expect(tester.getBottomLeft(find.text('Mengerti')).dy,
        lessThan(tester.getTopLeft(find.byKey(options)).dy));

    await tester.tap(find.text('Mengerti'));
    await settle(tester);
    expect(await first, isTrue);
    expect(find.text('pilih jawaban'), findsNothing);
    expect(Coachmark.showing.value, isFalse);

    expect(await Coachmark.seen('test'), isTrue);
    final again = Coachmark.showOnce(page, id: 'test', steps: steps());
    await settle(tester);
    expect(await again, isFalse);
    expect(find.text('kasih makan'), findsNothing);
  });

  testWidgets('skipping counts as seen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester);

    final shown = Coachmark.showOnce(page, id: 'skip', steps: steps());
    await settle(tester);
    await tester.tap(find.text('Lewati'));
    await settle(tester);
    expect(await shown, isTrue);
    expect(find.text('kasih makan'), findsNothing);
    expect(await Coachmark.seen('skip'), isTrue);
  });

  testWidgets('a tap anywhere moves on', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpPage(tester);

    Coachmark.showOnce(page, id: 'tap', steps: steps());
    await settle(tester);
    await tester.tapAt(const Offset(20, 20));
    await settle(tester);
    expect(find.text('pilih jawaban'), findsOneWidget);
  });

  testWidgets('a tour whose page goes away first is kept for next time',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final here = ValueNotifier(true);
    final key = GlobalKey();
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
      home: Builder(builder: (context) {
        page = context;
        return ValueListenableBuilder<bool>(
          valueListenable: here,
          builder: (_, on, __) => Scaffold(
            body: on ? SizedBox(key: key, width: 80, height: 80) : null,
          ),
        );
      }),
    ));

    final shown = Coachmark.showOnce(page, id: 'gone', steps: [
      CoachStep(target: key, text: 'di sini'),
      const CoachStep(target: null, text: 'dan juga ini'),
    ]);
    // Sign-in takes over before the tour gets going.
    here.value = false;
    await settle(tester);
    expect(await shown, isFalse);
    expect(find.text('dan juga ini'), findsNothing);
    expect(await Coachmark.seen('gone'), isFalse);
  });
}
