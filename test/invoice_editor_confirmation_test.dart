import 'support/load_material_test_font.dart';
import 'support/visible_control.dart';
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
  setUpAll(loadMaterialTestFont);
  for (final scale in [1.0, 2.0]) {
    testWidgets('invoice creation actions reflow at 320LP and $scale text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      final draft = WorkRecord(
        id: 'direct-create-invoice',
        kind: WorkRecordKind.invoice,
        number: 'INV-DIRECT',
        title: 'Repair',
        client: 'Customer',
        detail: 'Completed repair',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: work.permissions.actorEmployeeId,
        createdOn: DateTime(2026, 9, 9),
        total: 50,
        items: const [
          WorkLineItem(
            id: 'repair',
            type: WorkLineItemType.labor,
            name: 'Repair',
            quantity: 1,
            unit: 'service',
            customerPrice: 50,
          ),
        ],
      );
      expect(await tester.runAsync(() => work.create(draft)), isTrue);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: InvoiceEditorScreen(
                initialDay: DateTime(2026, 9, 9),
                initialRecord: draft,
              ),
            ),
          ),
        ),
      );
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('invoice-information'))
            .evaluate()
            .isNotEmpty,
      );
      await revealControl(
        tester,
        find.byKey(const ValueKey('create-issued-invoice')),
      );
      await waitForNativeSave(tester, () {
        final button = find.byKey(const ValueKey('create-issued-invoice'));
        return button.evaluate().isNotEmpty &&
            tester.widget<FilledButton>(button).onPressed != null;
      });
      final save = find.byKey(const ValueKey('save-invoice-draft'));
      final create = find.byKey(const ValueKey('create-issued-invoice'));
      expect(save, findsOneWidget);
      if (scale == 1) {
        expect(tester.getTopLeft(create).dy, tester.getTopLeft(save).dy);
      } else {
        expect(
          tester.getTopLeft(create).dy,
          greaterThan(tester.getTopLeft(save).dy),
        );
      }
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.textContaining('does not send the invoice'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('confirm-create-invoice')));
      await waitForNativeSave(
        tester,
        () => work.records.any(
          (record) =>
              record.id == draft.id && record.status == WorkRecordStatus.due,
        ),
      );
      expect(
        work.financialEntries
            .where(
              (entry) =>
                  entry.kind == PrototypeFinancialKind.invoiceIssued &&
                  entry.sourceId == draft.number,
            )
            .single
            .amountCents,
        5000,
      );
      expect(tester.takeException(), isNull);
    });
  }

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
      await tapVisibleControl(
        tester,
        find.byKey(const ValueKey('save-invoice-draft')),
      );
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
      await tapVisibleControl(
        tester,
        find.byKey(const ValueKey('save-invoice-draft')),
      );
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
