import 'support/document_form_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'failed invoice save keeps editor and recovery draft; retry commits both',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(
        () => openUiLabWorkSession(database),
      ))!;
      final store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      final invoice = WorkRecord(
        id: 'invoice-editor-confirm',
        kind: WorkRecordKind.invoice,
        number: 'INV-CONFIRM',
        revision: 3,
        linkedExpenseIds: const ['linked-expense'],
        jobNotes: 'Retained operational note',
        title: 'Service',
        client: 'Maya Thompson',
        detail: 'Completed service',
        pricing: WorkPricingModel.flatRate,
        total: 50,
        createdOn: DateTime(2026, 9, 9),
        items: const [
          WorkLineItem(
            id: 'labor',
            type: WorkLineItemType.labor,
            name: 'Repair',
            quantity: 1,
            unit: 'service',
            customerPrice: 50,
          ),
        ],
      );
      expect(await tester.runAsync(() => store.addWorkRecord(invoice)), isTrue);
      await tester.runAsync(
        () => database.customStatement("""
      CREATE TRIGGER fail_editor_confirmation BEFORE UPDATE ON local_records
      WHEN NEW.record_id = 'invoice-editor-confirm'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => InvoiceEditorScreen(
                          initialDay: DateTime(2026, 9, 9),
                          initialRecord: invoice,
                        ),
                      ),
                    ),
                    child: const Text('Edit invoice'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit invoice'));
      await tester.pumpAndSettle();
      await openDocumentSection(tester, 'invoice-information');
      await waitForNativeSave(
        tester,
        () => find.byKey(const ValueKey('invoice-title')).evaluate().isNotEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('invoice-title')),
        'Repair completed',
      );
      await closeDocumentSection(tester);
      await tester.tap(find.byKey(const ValueKey('save-invoice-draft')));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(
        find.byKey(const ValueKey('invoice-editor-screen')),
        findsOneWidget,
      );
      expect(
        store.workRecords.singleWhere((r) => r.id == invoice.id).title,
        'Service',
      );
      final permissions = work.permissions;
      final drafts = LocalDraftStore(database);
      final retained = (await tester.runAsync(
        () => drafts.list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: permissions.actorEmployeeId,
        ),
      ))!;
      expect(drafts.decode(retained.single)['title'], 'Repair completed');
      await tester.runAsync(
        () => database.customStatement('DROP TRIGGER fail_editor_confirmation'),
      );
      await tester.tap(find.byKey(const ValueKey('save-invoice-draft')));
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('invoice-editor-screen'))
            .evaluate()
            .isEmpty,
      );
      expect(
        store.workRecords.singleWhere((r) => r.id == invoice.id).title,
        'Repair completed',
      );
      final saved = store.workRecords.singleWhere((r) => r.id == invoice.id);
      expect(saved.revision, 3);
      expect(saved.linkedExpenseIds, ['linked-expense']);
      expect(saved.jobNotes, 'Retained operational note');
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: permissions.organizationId,
            domain: 'work/invoice-editor',
            ownerId: permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
