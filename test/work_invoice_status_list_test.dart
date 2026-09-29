import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/screens/work/work_invoice_filter_strip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_overview_list_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final locale in const [
    Locale('en', 'US'),
    Locale('es', 'US'),
    Locale('fr', 'CA'),
  ]) {
    testWidgets(
      'status strip $locale keeps selected choice visible at 320LP and 2x',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: WorkInvoiceFilterStrip(
                selected: WorkOverviewFilter.paidInvoices,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final selected = find.byKey(
          const ValueKey('invoice-status-paidInvoices'),
        );
        expect(selected.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'invoice-only status controls preserve search, scope and exact record',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      WorkRecord invoice(String id, {String creator = 'owner'}) => WorkRecord(
        id: id,
        kind: WorkRecordKind.invoice,
        number: 'INV-$id',
        title: 'Repair $id',
        client: 'Smith',
        detail: '',
        pricing: WorkPricingModel.flatRate,
        total: 100,
        status: WorkRecordStatus.due,
        createdByEmployeeId: creator,
        dueOn: DateTime(2020),
      );
      final store = PrototypeOperationsStore(
        workRecords: [
          invoice('partial'),
          invoice('settled'),
          invoice('hidden', creator: 'other'),
        ],
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'p',
            kind: PrototypeFinancialKind.paymentReceived,
            occurredOn: DateTime(2020),
            amountCents: 4000,
            sourceId: 'partial',
          ),
          PrototypeFinancialEntry(
            id: 's',
            kind: PrototypeFinancialKind.paymentReceived,
            occurredOn: DateTime(2020),
            amountCents: 10000,
            sourceId: 'settled',
          ),
        ],
      );
      final scope = OperationalScopeController(view: AppViewMode.admin)
        ..selectEmployee('owner');
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      String? opened;
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: WorkOverviewListScreen(
                initialFilter: WorkOverviewFilter.overdueInvoices,
                onOpen: (record) => opened = record.id,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byType(DropdownButtonFormField<WorkOverviewFilter>),
        findsNothing,
      );
      expect(find.text('Invoices'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('work-overview-record-hidden')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('work-overview-record-settled')),
        findsNothing,
      );
      expect(find.textContaining('Balance due: \$60.00'), findsOneWidget);
      expect(find.textContaining('Overdue · Partially paid'), findsOneWidget);
      final partial = find.byKey(
        const ValueKey('work-overview-record-partial'),
      );
      await tester.ensureVisible(partial);
      await tester.tap(partial);
      expect(opened, 'partial');
      final paid = find.byKey(const ValueKey('invoice-status-paidInvoices'));
      await tester.ensureVisible(paid);
      await tester.tap(paid);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('work-overview-record-settled')),
        findsOneWidget,
      );
      expect(partial, findsNothing);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pumpAndSettle();
      expect(find.textContaining('No matching records'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'INV-settled');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('work-overview-record-settled')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
