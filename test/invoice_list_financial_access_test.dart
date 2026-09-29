import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_overview_list_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('financial access removal clears payment-based list disclosure', (
    tester,
  ) async {
    WorkRecord invoice(String id, WorkRecordStatus status) => WorkRecord(
      id: id,
      kind: WorkRecordKind.invoice,
      number: 'INV-$id',
      title: 'Repair $id',
      client: 'Customer',
      detail: '',
      total: 100,
      pricing: WorkPricingModel.flatRate,
      status: status,
      createdByEmployeeId: 'alex',
      dueOn: DateTime(2020),
    );
    final store = PrototypeOperationsStore(
      workRecords: [
        invoice('settled', WorkRecordStatus.paid),
        invoice('open', WorkRecordStatus.due),
      ],
    );
    final scope = OperationalScopeController(view: AppViewMode.admin);
    final access = ValueNotifier(true);
    addTearDown(store.dispose);
    addTearDown(scope.dispose);
    addTearDown(access.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: ValueListenableBuilder<bool>(
              valueListenable: access,
              builder: (_, allowed, _) => WorkOverviewListScreen(
                initialFilter: WorkOverviewFilter.paidInvoices,
                showFinancials: allowed,
                onOpen: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('work-overview-record-open')),
      findsNothing,
    );
    access.value = false;
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('work-overview-record-open')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('work-overview-record-settled')),
      findsOneWidget,
    );
    expect(find.textContaining(' · Paid'), findsNothing);
    expect(find.textContaining('Balance due:'), findsNothing);
    expect(
      find.byKey(const ValueKey('invoice-status-paidInvoices')),
      findsNothing,
    );
    expect(find.text('All dates · 2 records'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
