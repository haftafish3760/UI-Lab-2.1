import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_overview_list_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final locale in const [
    Locale('en', 'US'),
    Locale('es', 'US'),
    Locale('fr', 'CA'),
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
        'Work records $locale dark=$dark reflow and preserve original text',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final record = WorkRecord(
            id: 'saved-job',
            kind: WorkRecordKind.job,
            number: 'J-42',
            title: 'Replace kitchen cabinets',
            client: 'María Tremblay',
            detail: '',
            pricing: WorkPricingModel.flatRate,
          );
          final store = PrototypeOperationsStore(
            workRecords: [record],
            financialEntries: [],
          );
          final scope = OperationalScopeController();
          addTearDown(store.dispose);
          addTearDown(scope.dispose);
          WorkRecord? opened;
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: child!,
                  ),
                  home: WorkOverviewListScreen(
                    initialFilter: WorkOverviewFilter.allJobs,
                    onOpen: (record) => opened = record,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l10n = lookupAppLocalizations(locale);
          expect(find.text(l10n.workRecordsHeading), findsOneWidget);
          expect(find.text(l10n.workFilterAllJobs), findsOneWidget);
          expect(find.text(l10n.workRecordCount(1)), findsOneWidget);
          final row = find.byKey(
            const ValueKey('work-overview-record-saved-job'),
          );
          await tester.ensureVisible(row);
          await tester.pumpAndSettle();
          expect(
            find.text('María Tremblay\nReplace kitchen cabinets'),
            findsOneWidget,
          );
          expect(
            find.text(
              'J-42 · ${l10n.workStatusDraft}\n${l10n.workNotScheduled}',
            ),
            findsOneWidget,
          );
          await tester.tap(row);
          expect(opened?.id, 'saved-job');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
