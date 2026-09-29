import 'package:ui_lab_2_1/src/screens/work/invoice_permissions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets(
    'Invoices filters update one landing screen and preserve search and date context',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      WorkRecord invoice(String id) => WorkRecord(
        id: id,
        kind: WorkRecordKind.invoice,
        number: 'INV-$id',
        title: 'Repair $id',
        client: 'Customer',
        detail: '',
        total: 100,
        pricing: WorkPricingModel.flatRate,
        status: id == 'draft' ? WorkRecordStatus.draft : WorkRecordStatus.due,
        createdByEmployeeId: 'alex',
        createdOn: DateTime(2020),
        dueOn: DateTime(2020),
      );
      final store = PrototypeOperationsStore(
        workRecords: [invoice('paid'), invoice('open'), invoice('draft')],
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'payment',
            kind: PrototypeFinancialKind.paymentReceived,
            occurredOn: DateTime(2020),
            amountCents: 10000,
            sourceId: 'paid',
          ),
        ],
      );
      final scope = OperationalScopeController(view: AppViewMode.admin);
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: InvoiceWorkspaceScreen(initialDay: DateTime(2030)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final draftsAction = find.byKey(const ValueKey('open-work-drafts'));
      final paid = find.byKey(
        const ValueKey('dashboard-summary-work-paidInvoices'),
      );
      bool paidSelected() => tester
          .widget<Semantics>(
            find.descendant(of: paid, matching: find.byType(Semantics)).first,
          )
          .properties
          .selected!;
      expect(paidSelected(), isFalse);
      expect(draftsAction, findsOneWidget);
      expect(
        tester.getTopLeft(draftsAction).dy,
        lessThan(tester.getTopLeft(paid).dy),
      );
      expect(find.byKey(const ValueKey('invoice-date-activity')), findsNothing);
      expect(
        find.byKey(const ValueKey('invoice-selected-date')),
        findsOneWidget,
      );
      await tester.ensureVisible(paid);
      await tester.tap(paid);
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceWorkspaceScreen), findsOneWidget);
      expect(paidSelected(), isTrue);
      expect(
        find.descendant(
          of: paid,
          matching: find.byIcon(Icons.check_circle_outline),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('invoice-selected-date')), findsNothing);
      expect(find.byKey(const ValueKey('invoice-attention')), findsNothing);
      expect(find.byKey(const ValueKey('invoice-row-open')), findsNothing);
      expect(find.byKey(const ValueKey('invoice-row-paid')), findsOneWidget);
      final searchField = find.byKey(const ValueKey('invoice-search'));
      await tester.enterText(searchField, 'no matching invoice');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invoice-row-paid')), findsNothing);
      final clearSearch = find.byKey(const ValueKey('clear-invoice-search'));
      await tester.ensureVisible(clearSearch);
      await tester.tap(clearSearch);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(searchField).controller!.text, isEmpty);
      expect(find.byKey(const ValueKey('invoice-row-paid')), findsOneWidget);
      expect(find.byKey(const ValueKey('invoice-row-open')), findsNothing);
      final row = find.byKey(const ValueKey('invoice-row-paid'));
      expect(paidSelected(), isTrue);
      await tester.ensureVisible(row);
      await tester.tap(
        find.ancestor(of: row, matching: find.byType(InkWell)).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invoice-detail-paid')), findsOneWidget);
      Navigator.of(
        tester.element(find.byKey(const ValueKey('invoice-detail-paid'))),
      ).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invoice-row-open')), findsNothing);
      final dateAction = find.byKey(const ValueKey('invoice-view-date'));
      await tester.ensureVisible(dateAction);
      await tester.tap(dateAction);
      await tester.pumpAndSettle();
      expect(find.byType(InvoiceWorkspaceScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('invoice-selected-date')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('invoice-date-records')), findsNothing);
      expect(paidSelected(), isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: InvoiceWorkspaceScreen(
                initialDay: DateTime(2030),
                permissions: const InvoicePermissions(
                  canView: true,
                  canCreate: false,
                  canViewFinancials: false,
                  canEditDraft: false,
                  canPreviewCustomerCopy: false,
                  canIssue: false,
                  canRecordPayment: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('new-invoice')), findsNothing);
      expect(
        find.byKey(const ValueKey('dashboard-summary-work-paidInvoices')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('invoice-view-all')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('invoice-row-open')), findsOneWidget);
      expect(find.byKey(const ValueKey('invoice-row-paid')), findsOneWidget);
      expect(find.text('Paid in full'), findsNothing);
      expect(find.textContaining('Balance due:'), findsNothing);
      expect(find.textContaining('Invoice total:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
