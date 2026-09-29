import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_approval_content.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_approval_actions.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('request, correction and approval use saved invoice history', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final work = (await tester.runAsync(
      () => WorkPersistenceSession.open(
        SqliteWorkRepository(database),
        WorkSessionPermissions(
          organizationId: 'test',
          actorEmployeeId: 'owner',
          permissionRevision: 'v1',
          visibleCreatorIds: {'owner'},
          editableKinds: {WorkRecordKind.invoice},
          canApproveInvoices: true,
        ),
      ),
    ))!;
    const invoice = WorkRecord(
      id: 'approval-ui',
      kind: WorkRecordKind.invoice,
      number: 'INV-101',
      title: 'Replace faucet',
      client: 'Taylor Smith',
      detail: '',
      pricing: WorkPricingModel.flatRate,
      createdByEmployeeId: 'owner',
      total: 100,
    );
    expect(await tester.runAsync(() => work.create(invoice)), isTrue);
    final store = PrototypeOperationsStore(workSession: work);
    addTearDown(() async {
      store.dispose();
      work.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => InvoiceApprovalActions(
                record: PrototypeOperationsScope.of(context).workRecords.single,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('invoice-submit-approval')));
    await waitForNativeSave(
      tester,
      () => work.records.single.invoiceApprovalHistory.length == 1,
    );
    expect(find.text('Needs approval'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invoice-request-changes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('invoice-confirm-changes')));
    await tester.pumpAndSettle();
    expect(find.text('Explain which changes are needed.'), findsOneWidget);
    expect(work.records.single.invoiceApprovalHistory, hasLength(1));
    await tester.enterText(
      find.byKey(const ValueKey('invoice-changes-reason')),
      'Include the agreed disposal fee.',
    );
    await tester.tap(find.byKey(const ValueKey('invoice-confirm-changes')));
    await waitForNativeSave(
      tester,
      () => work.records.single.invoiceApprovalHistory.length == 2,
    );
    expect(find.text('Include the agreed disposal fee.'), findsOneWidget);
    expect(find.byKey(const ValueKey('invoice-approve')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('invoice-submit-approval')));
    await waitForNativeSave(
      tester,
      () => work.records.single.invoiceApprovalHistory.length == 3,
    );
    await tester.tap(find.byKey(const ValueKey('invoice-approve')));
    await waitForNativeSave(
      tester,
      () => invoiceHasCurrentApproval(work.records.single),
    );
    expect(find.text('Approved'), findsOneWidget);
    expect(find.byKey(const ValueKey('invoice-submit-approval')), findsNothing);
    expect(
      work.records.single.invoiceApprovalHistory.last.actorEmployeeId,
      'owner',
    );
    expect(tester.takeException(), isNull);
  });
}
