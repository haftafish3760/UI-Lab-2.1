import 'support/load_material_test_font.dart';
import 'support/visible_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  setUpAll(loadMaterialTestFont);
  for (final locale in const [
    Locale('en', 'US'),
    Locale('es', 'US'),
    Locale('fr', 'CA'),
  ]) {
    for (final width in [320.0, 1100.0]) {
      testWidgets('invoice date activity $locale at $width LP', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PrototypeOperationsStore(
          workRecords: [
            WorkRecord(
              id: 'locale-record',
              kind: WorkRecordKind.invoice,
              number: 'INV-LOCALE',
              title: 'Original work title',
              client: 'Original customer',
              detail: '',
              status: WorkRecordStatus.due,
              pricing: WorkPricingModel.flatRate,
              total: 100,
              dueOn: DateTime(2020),
              createdOn: DateTime.now(),
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
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                theme: width == 320 ? AppTheme.light : AppTheme.dark,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(width == 320 ? 1.5 : 1),
                  ),
                  child: child!,
                ),
                home: InvoiceWorkspaceScreen(
                  initialDay: DateTime.now(),
                  showDateActivity: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(InvoiceWorkspaceScreen));
        final l10n = AppLocalizations.of(context);
        expect(find.text(l10n.workInvoiceHeading), findsOneWidget);
        expect(
          find.text(l10n.workInvoiceOverdueReason('Original customer')),
          findsOneWidget,
        );
        expect(find.text('Original work title'), findsNWidgets(2));
        expect(find.text(l10n.workInvoiceActivityCreated), findsOneWidget);
        final search = find.byKey(const ValueKey('invoice-search'));
        await revealControl(tester, search);
        expect(find.text(l10n.workSearchInvoices), findsOneWidget);
        await tester.enterText(search, 'INV-LOCALE');
        await tester.pumpAndSettle();
        expect(find.text(l10n.workInvoiceMatches), findsOneWidget);
        expect(
          find.byKey(const ValueKey('invoice-row-locale-record')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('invoice-row-locale-record')),
            matching: find.text(l10n.workMoneyOverdue),
          ),
          findsOneWidget,
        );
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.bottomSheet, isNull);
        expect(scaffold.bottomNavigationBar, isNull);
        final fab = find.byKey(const ValueKey('new-invoice'));
        final fabBeforeScroll = tester.getRect(fab);
        final content = find.byKey(const ValueKey('invoice-activity-content'));
        final scrolling = tester.state<ScrollableState>(
          find.descendant(of: content, matching: find.byType(Scrollable)).first,
        );
        final offsetBefore = scrolling.position.pixels;
        await tester.dragFrom(
          tester.getRect(content).bottomLeft + const Offset(8, -160),
          Offset(0, offsetBefore > 0 ? 240 : -240),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(fab), fabBeforeScroll);
        expect(scrolling.position.pixels, isNot(offsetBefore));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
