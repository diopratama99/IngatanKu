import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ingatanku/core/di/injection_container.dart';
import 'package:ingatanku/core/services/media_download_service.dart';
import 'package:ingatanku/core/theme/app_theme.dart';
import 'package:ingatanku/features/companion/data/pet_store.dart';
import 'package:ingatanku/features/companion/domain/pet_state.dart';
import 'package:ingatanku/features/vault/domain/entities/note_entity.dart';
import 'package:ingatanku/features/vault/presentation/bloc/vault_bloc.dart';
import 'package:ingatanku/features/vault/presentation/pages/note_detail_page.dart';
import 'package:ingatanku/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Vault extends MockBloc<VaultEvent, VaultState> implements VaultBloc {}

class _Media extends Mock implements MediaDownloadService {}


final _t0 = DateTime(2026, 10, 15, 10);

NoteEntity _note(String id, String title, String notes) => NoteEntity(
      id: id,
      userId: 'u',
      url: 'https://example.com/$id',
      title: title,
      manualNotes: notes,
      tags: const ['reading'],
      sourceType: 'article',
      createdAt: _t0,
    );

void main() {
  final notes = [
    _note(
      'n1',
      'A long one',
      [for (var i = 1; i <= 30; i++) 'Paragraph number $i of the note.']
          .join('\n\n'),
    ),
    _note('n2', 'A short one', 'Just a line.'),
  ];

  Future<void> open(WidgetTester tester) async {
    final pet = PetState(
      bornAt: _t0.subtract(const Duration(days: 4)),
      hatchedAt: _t0.subtract(const Duration(days: 3)),
      fullness: 90,
      fullnessUpdatedAt: DateTime.now(),
      happiness: 80,
      happinessUpdatedAt: DateTime.now(),
      growth: 150,
    );
    SharedPreferences.setMockInitialValues(
        {'pet.state': jsonEncode(pet.toJson())});
    await sl.reset();
    sl.registerSingleton<PetStore>(
        PetStore(await SharedPreferences.getInstance()));
    final media = _Media();
    when(() => media.existingFile(any())).thenAnswer((_) async => null);
    sl.registerSingleton<MediaDownloadService>(media);
    final vault = _Vault();
    whenListen(vault, const Stream<VaultState>.empty(),
        initialState: VaultLoaded(notes));
    tester.view.physicalSize = const Size(392 * 2, 850 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BlocProvider<VaultBloc>.value(
      value: vault,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: NoteDetailPage(note: notes[0]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// The pet never stops breathing, so no pumpAndSettle: long enough for
  /// a page to turn or a scroll to stop.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('a long note scrolls on its page', (tester) async {
    await open(tester);
    final title = find.text('A long one');
    final before = tester.getTopLeft(title).dy;
    await tester.drag(
        find.textContaining('Paragraph number 3 '), const Offset(0, -400));
    await settle(tester);
    expect(tester.getTopLeft(title).dy, lessThan(before - 300));
    // Still the same page: scrolling isn't turning.
    expect(find.text('Page 1 of 2'), findsOneWidget);
    await close(tester);
  });

  testWidgets('a sideways swipe turns the page, and back', (tester) async {
    await open(tester);
    await tester.fling(find.textContaining('Paragraph number 2 '),
        const Offset(-250, 0), 1200);
    await settle(tester);
    expect(find.text('Page 2 of 2'), findsOneWidget);
    expect(find.text('A short one'), findsOneWidget);
    // The page is live: taps reach it.
    await tester.tap(find.text('Article'));
    await tester.pump();

    await tester.fling(find.text('Just a line.'), const Offset(250, 0), 1200);
    await settle(tester);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    await close(tester);
  });

  testWidgets('the arrows turn the pages too', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Next page'));
    await settle(tester);
    expect(find.text('Page 2 of 2'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous page'));
    await settle(tester);
    expect(find.text('Page 1 of 2'), findsOneWidget);
    await close(tester);
  });
}
