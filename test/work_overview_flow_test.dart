import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_overview_query.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_overview_list_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

WorkRecord job(String id, {bool completed = false}) => WorkRecord(
  id: id,
  kind: WorkRecordKind.job,
  number: 'J-$id',
  title: 'Repair $id',
  client: 'Customer $id',
  detail: '',
  pricing: WorkPricingModel.flatRate,
  createdOn: DateTime(2020),
  createdByEmployeeId: 'worker',
  status: completed ? WorkRecordStatus.completed : WorkRecordStatus.ready,
);

void main() {
  test('all-date backlog retains old jobs and separates completed work', () {
    final records = [job('old'), job('finished', completed: true)];
    expect(
      workOverviewRecords(
        records: records,
        payments: [],
        filter: WorkOverviewFilter.unscheduledJobs,
        now: DateTime(2026),
      ).map((r) => r.id),
      ['old'],
    );
    expect(
      workOverviewRecords(
        records: records,
        payments: [],
        filter: WorkOverviewFilter.completedJobs,
        now: DateTime(2026),
      ).map((r) => r.id),
      ['finished'],
    );
  });

  for (final dark in [false, true]) {
    testWidgets(
      'overview opens live searchable records at 320LP large text dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PrototypeOperationsStore(
          workRecords: [job('old')],
          financialEntries: [],
        );
        final scope = OperationalScopeController(view: AppViewMode.admin);
        addTearDown(store.dispose);
        addTearDown(scope.dispose);
        String? opened;
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: WorkOverviewListScreen(
                  initialFilter: WorkOverviewFilter.unscheduledJobs,
                  onOpen: (record) => opened = record.id,
                ),
              ),
            ),
          ),
        );
        final row = find.byKey(const ValueKey('work-overview-record-old'));
        await tester.ensureVisible(row);
        await tester.tap(row);
        expect(opened, 'old');
        expect(find.textContaining('Not scheduled'), findsOneWidget);
        store.addWorkRecord(job('new'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('work-overview-record-new')),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), 'J-new');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('work-overview-record-old')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('work-overview-record-new')),
          findsOneWidget,
        );
        final filter = find.byType(DropdownButtonFormField<WorkOverviewFilter>);
        await tester.ensureVisible(filter);
        await tester.tap(filter);
        await tester.pumpAndSettle();
        final approval = find.text('Estimates awaiting company approval').last;
        await Scrollable.ensureVisible(tester.element(approval), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(approval);
        await tester.pumpAndSettle();
        expect(find.textContaining('No matching records'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
