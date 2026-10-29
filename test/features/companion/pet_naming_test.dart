import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/di/injection_container.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/companion/presentation/widgets/pet_naming_sheet.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late PetStore store;

  Future<void> openSheet(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    store = PetStore(await SharedPreferences.getInstance());
    sl.registerSingleton<PetStore>(store);
    // A phone's screen.
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
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showPetNaming(context),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    // The sheet's slide starts on the frame it's built in.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('a new pet is offered the name Bolubi', (tester) async {
    await openSheet(tester);
    expect(find.text('Kasih dia nama'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Bolubi');
    // All of it selected: typing replaces it.
    expect(field.controller!.selection.textInside(field.controller!.text),
        'Bolubi');
  });

  testWidgets('the name typed is the one kept', (tester) async {
    await openSheet(tester);
    // The whole sheet fits on the screen.
    expect(tester.getBottomLeft(find.text('Simpan nama')).dy, lessThan(850));
    await tester.enterText(find.byType(TextField), 'Mochi');
    await tester.tap(find.text('Simpan nama'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(store.customName, 'Mochi');
    expect(find.text('Kasih dia nama'), findsNothing);
  });
}
