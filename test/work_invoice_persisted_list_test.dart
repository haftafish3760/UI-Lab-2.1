import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_overview_list_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';

void main() {
  testWidgets('reopened invoices retain balances, scope and exact identity', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    var database = (await tester.runAsync(harness.open))!;
    final access = WorkSessionPermissions(
      organizationId: 'list-test-company',
      actorEmployeeId: 'owner',
      permissionRevision: 'test-1',
      visibleCreatorIds: {'owner'},
      editableKinds: {},
    );
    WorkRecord invoice(String id, String owner) => WorkRecord(
      id: id,
      kind: WorkRecordKind.invoice,
      number: 'INV-$id',
      // Duplicate names deliberately require navigation by stable identity.
      title: 'Repair kitchen',
      client: 'Taylor Smith',
      detail: '',
      pricing: WorkPricingModel.flatRate,
      total: 100,
      status: WorkRecordStatus.due,
      createdByEmployeeId: owner,
      dueOn: DateTime(2020),
    );
    await tester.runAsync(() async {
      final repository = SqliteWorkRepository(database);
      for (final id in ['partial', 'settled', 'hidden']) {
        final owner = id == 'hidden' ? 'other' : 'owner';
        await repository.commit(
          organizationId: access.organizationId,
          commandId: 'test-create-$id',
          actorEmployeeId: owner,
          permissionRevision: access.permissionRevision,
          occurredAt: DateTime.utc(2026, 9, 1),
          mutations: [
            WorkRecordMutation(
              record: invoice(id, owner),
              expectedStorageRevision: 0,
            ),
          ],
          financialEntries: [
            PrototypeFinancialEntry(
              id: 'payment-$id',
              kind: PrototypeFinancialKind.paymentReceived,
              occurredOn: DateTime.utc(2026, 9, 1),
              amountCents: id == 'partial' ? 4000 : 10000,
              sourceId: id,
            ),
          ],
        );
      }
      await database.verifyIntegrity();
      await harness.close(database);
      database = await harness.open();
    });
    final session = (await tester.runAsync(
      () => WorkPersistenceSession.open(SqliteWorkRepository(database), access),
    ))!;
    final store = PrototypeOperationsStore(workSession: session);
    final scope = OperationalScopeController(view: AppViewMode.admin);
    addTearDown(() async {
      store.dispose();
      scope.dispose();
      session.dispose();
      await tester.runAsync(harness.dispose);
    });
    expect(session.records.map((r) => r.id).toSet(), {'partial', 'settled'});
    expect(session.financialEntries.map((e) => e.id).toSet(), {
      'payment-partial',
      'payment-settled',
    });
    WorkRecord? opened;
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: WorkOverviewListScreen(
              initialFilter: WorkOverviewFilter.overdueInvoices,
              onOpen: (record) => opened = record,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    Finder row(String id) => find.byKey(ValueKey('work-overview-record-$id'));
    expect(row('partial'), findsOneWidget);
    expect(row('settled'), findsNothing);
    expect(row('hidden'), findsNothing);
    expect(find.textContaining('Balance due: \$60.00'), findsOneWidget);
    await tester.ensureVisible(row('partial'));
    await tester.tap(row('partial'));
    expect(opened?.id, 'partial');
    expect(opened?.number, 'INV-partial');

    final paid = find.byKey(const ValueKey('invoice-status-paidInvoices'));
    await tester.ensureVisible(paid);
    await tester.tap(paid);
    await tester.pumpAndSettle();
    expect(row('partial'), findsNothing);
    expect(row('settled'), findsOneWidget);
    expect(row('hidden'), findsNothing);
    expect(find.textContaining('Balance due: \$0.00'), findsOneWidget);
    await tester.ensureVisible(row('settled'));
    await tester.tap(row('settled'));
    expect(opened?.id, 'settled');

    await tester.enterText(find.byType(TextField), 'INV-hidden');
    await tester.pumpAndSettle();
    expect(find.textContaining('No matching records'), findsOneWidget);
    expect(row('hidden'), findsNothing);
    expect(tester.takeException(), isNull);
    Future<void> review(WorkRecord candidate) async {
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: InvoiceDetailScreen(record: candidate),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Supplying a fully populated route argument cannot bypass the query scope.
    await review(invoice('hidden', 'other'));
    expect(
      find.byKey(const ValueKey('invoice-unavailable-hidden')),
      findsOneWidget,
    );
    expect(find.textContaining('INV-hidden'), findsNothing);
    expect(find.text('Repair kitchen'), findsNothing);
    expect(find.text('Send invoice'), findsNothing);

    await review(invoice('settled', 'owner'));
    expect(
      find.byKey(const ValueKey('invoice-detail-settled')),
      findsOneWidget,
    );
    scope.selectEmployee('other');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-unavailable-settled')),
      findsOneWidget,
    );
    expect(find.text('Repair kitchen'), findsNothing);
    expect(find.text('Send invoice'), findsNothing);
    scope.selectEmployee(null);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-detail-settled')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    scope.setView(AppViewMode.technician);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: InvoiceWorkspaceScreen(
              initialDay: DateTime.now(),
              showDateActivity: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-attention-row-partial')),
      findsOneWidget,
    );
    final search = find.byKey(const ValueKey('invoice-search'));
    await tester.ensureVisible(search);
    await tester.enterText(search, 'INV-settled');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invoice-row-settled')), findsOneWidget);
    await tester.enterText(search, 'INV-hidden');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('invoice-row-hidden')), findsNothing);
    expect(
      find.text('No authorized invoices match that search.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
