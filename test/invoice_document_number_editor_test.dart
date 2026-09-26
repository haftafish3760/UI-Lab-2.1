import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/document_form_navigation.dart';
import 'support/storage/database_harness.dart';

void main() {
  testWidgets('new invoice number can be changed before saving', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
    final store = PrototypeOperationsStore(workSession: work);
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      work.dispose();
      scope.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: InvoiceEditorScreen(initialDay: DateTime(2030, 1, 1)),
          ),
        ),
      ),
    );
    await openDocumentSection(tester, 'invoice-information');
    final number = find.byKey(const ValueKey('invoice-document-number'));
    expect(tester.widget<TextFormField>(number).initialValue, 'Invoice 1');
    await tester.enterText(number, 'INV-900');
    await closeDocumentSection(tester);
    await openDocumentSection(tester, 'invoice-information');
    expect(find.text('INV-900'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
