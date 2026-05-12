// Placeholder smoke test for the IngatanKu app.
//
// The original boilerplate from `flutter create` referenced a non-existent
// `MyApp` class and a counter UI that was never part of this project. Mounting
// the real entry widget (`IngatanKuApp`) inside a vanilla widget test would
// require mocking Supabase, the local DB, and several Bloc providers — that
// effort belongs in dedicated feature-level test files (see future
// `test/features/<feature>/...`), not in a top-level smoke test.
//
// For now this file exists so `flutter test` has at least one passing target
// and CI doesn't choke on the test runner missing entries. Replace this with
// a real smoke test once a lightweight `IngatanKuApp.testHarness()` factory
// exists.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a trivial widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('IngatanKu test harness'))),
    );
    expect(find.text('IngatanKu test harness'), findsOneWidget);
  });
}
