import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_document_heading.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/seeded_directory_fixture.dart';

void main() {
  testWidgets('estimate heading reads saved company information', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final directory = (await tester.runAsync(
      () => openSeededTestDirectory(database),
    ))!;
    await tester.runAsync(
      () => directory.saveCompany(
        directory.company.copyWith(
          companyName: 'Saved business',
          address: '12 Test Street',
          email: 'office@example.test',
        ),
      ),
    );
    final store = PrototypeOperationsStore(directorySession: directory);
    addTearDown(() async {
      store.dispose();
      directory.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: const MaterialApp(
          home: Scaffold(
            body: EstimateDocumentHeading(number: 'E-123', status: 'Draft'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved business'), findsOneWidget);
    expect(find.text('12 Test Street'), findsOneWidget);
    expect(find.text('office@example.test'), findsOneWidget);
    expect(find.text('E-123'), findsNothing);
    expect(find.text('ESTIMATE'), findsNothing);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Company information unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
