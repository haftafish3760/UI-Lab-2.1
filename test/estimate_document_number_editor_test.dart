import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/document_form_navigation.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('new estimate saves a chosen number and suggests the next one', (
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
            home: EstimateEditorScreen(initialDay: DateTime(2030, 1, 1)),
          ),
        ),
      ),
    );
    await openDocumentSection(tester, 'estimate-information');
    final number = find.byKey(const ValueKey('estimate-document-number'));
    expect(tester.widget<TextFormField>(number).initialValue, 'Estimate 1');
    await tester.enterText(number, '777');
    await closeDocumentSection(tester);
    await tester.ensureVisible(
      find.byKey(const ValueKey('save-estimate-draft')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-estimate-draft')));
    await waitForNativeSave(
      tester,
      () => work.records.any(
        (record) =>
            record.kind == WorkRecordKind.estimate && record.number == '777',
      ),
    );
    expect(
      await tester.runAsync(
        () => work.nextDocumentNumber(WorkRecordKind.estimate),
      ),
      'Estimate 778',
    );
    expect(tester.takeException(), isNull);
  });
}
