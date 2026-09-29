import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_overview_cards.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/load_material_test_font.dart';

void main() {
  setUpAll(loadMaterialTestFont);
  for (final locale in const [
    Locale('en', 'US'),
    Locale('es', 'US'),
    Locale('fr', 'CA'),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'money cards $locale scale=$scale preserve amounts and destinations',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          WorkRecord invoice(
            String id,
            double total,
            DateTime due, {
            String creator = 'owner',
            WorkRecordStatus status = WorkRecordStatus.due,
          }) => WorkRecord(
            id: id,
            kind: WorkRecordKind.invoice,
            number: id,
            title: id,
            client: 'Client',
            detail: '',
            pricing: WorkPricingModel.flatRate,
            status: status,
            total: total,
            dueOn: due,
            createdByEmployeeId: creator,
          );
          final now = DateTime.now();
          final partial = invoice(
            'partial',
            100,
            now.subtract(const Duration(days: 2)),
          );
          final next = invoice('next', 200, now.add(const Duration(days: 2)));
          final store = PrototypeOperationsStore(
            workRecords: [
              partial,
              next,
              invoice('settled', 125, now, status: WorkRecordStatus.paid),
              invoice('private', 9000, now, creator: 'other'),
            ],
            financialEntries: [
              PrototypeFinancialEntry(
                id: 'p',
                kind: PrototypeFinancialKind.paymentReceived,
                occurredOn: now,
                amountCents: 4000,
                sourceId: 'partial',
              ),
              PrototypeFinancialEntry(
                id: 'unrelated',
                kind: PrototypeFinancialKind.paymentReceived,
                occurredOn: now,
                amountCents: 50000,
                sourceId: 'private',
              ),
            ],
          );
          final scope = OperationalScopeController(view: AppViewMode.admin)
            ..selectEmployee('owner');
          addTearDown(store.dispose);
          addTearDown(scope.dispose);
          WorkOverviewFilter? selected;
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  locale: locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: scale == 1 ? AppTheme.light : AppTheme.dark,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: WorkOverviewCards(
                      onSelected: (filter) => selected = filter,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = lookupAppLocalizations(locale);
          expect(find.text(l10n.workMoneyPaid), findsOneWidget);
          expect(find.text(l10n.workMoneyUnpaid), findsOneWidget);
          expect(find.text(l10n.workMoneyOverdue), findsOneWidget);
          expect(find.text(l10n.workBrowseRecords), findsNothing);
          final paid = find.byKey(
            const ValueKey('dashboard-summary-work-paidInvoices'),
          );
          if (scale == 1 && locale.languageCode == 'en') {
            expect(tester.getSize(paid), const Size(96, 120));
            expect(find.text(r'$125.00'), findsOneWidget);
            expect(find.text(r'$200.00'), findsOneWidget);
            expect(find.text(r'$60.00'), findsNWidgets(2));
          }
          final unpaid = find.byKey(
            const ValueKey('dashboard-summary-work-invoicesWithoutPayments'),
          );
          await tester.ensureVisible(unpaid);
          await tester.tap(unpaid);
          expect(selected, WorkOverviewFilter.invoicesWithoutPayments);
          await tester.ensureVisible(paid);
          await tester.tap(paid);
          expect(selected, WorkOverviewFilter.paidInvoices);
          final overdue = find.byKey(
            const ValueKey('dashboard-summary-work-overdueInvoices'),
          );
          await tester.ensureVisible(overdue);
          await tester.tap(overdue);
          expect(selected, WorkOverviewFilter.overdueInvoices);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
