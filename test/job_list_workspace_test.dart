import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/work/job_list_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpJobs(
  WidgetTester tester,
  Size size, {
  PrototypeOperationsStore? store,
  AppViewMode view = AppViewMode.technician,
  double textScale = 1,
  JobWorkspacePermissions permissions =
      const JobWorkspacePermissions.development(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final operationsStore = store ?? PrototypeOperationsStore();
  final scope = OperationalScopeController(view: view);
  addTearDown(operationsStore.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: operationsStore,
      child: OperationalScope(
        controller: scope,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: JobListWorkspaceScreen(
              initialDay: DateTime.now(),
              permissions: permissions,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Jobs workspace is date first with separate compact records', (
    tester,
  ) async {
    await _pumpJobs(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('job-selected-date')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-date-records')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-active-records')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('new-job')), findsOneWidget);
    expect(find.text('Selected date'), findsNothing);
    expect(find.text('All jobs'), findsNothing);

    final row = find.byKey(const ValueKey('job-row-job-1038'));
    expect(row, findsOneWidget);
    expect(tester.getSize(row).height, lessThanOrEqualTo(72));
    await tester.tap(
      find.ancestor(of: row, matching: find.byType(InkWell)).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('job-workspace-job-1038')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jobs search covers the authorized job file', (tester) async {
    await _pumpJobs(tester, const Size(390, 844));

    await tester.enterText(
      find.byKey(const ValueKey('job-search')),
      'Maya Thompson',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-search-results')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-row-job-1038')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Jobs calendar opens a dated route and exact Job record', (
    tester,
  ) async {
    await _pumpJobs(tester, const Size(390, 844));
    final now = DateTime.now();
    final day = find.byKey(
      ValueKey('work-calendar-day-${now.year}-${now.month}-${now.day}'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-day-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('job-day-records')), findsOneWidget);
    final job = find.byKey(const ValueKey('job-row-job-1038'));
    await tester.ensureVisible(job);
    await tester.tap(find.ancestor(of: job, matching: find.byType(InkWell)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('job-workspace-job-1038')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Job Day reviews past and future scheduled records', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final store = PrototypeOperationsStore(
      workRecords: [
        WorkRecord(
          id: 'past-job',
          kind: WorkRecordKind.job,
          number: 'JOB-PAST',
          title: 'Completed drain repair',
          client: 'Past Client',
          detail: 'Completed work history.',
          pricing: WorkPricingModel.flatRate,
          assignee: 'Alex Morgan',
          scheduledStart: today.subtract(const Duration(days: 1)),
          status: WorkRecordStatus.completed,
        ),
        WorkRecord(
          id: 'future-job',
          kind: WorkRecordKind.job,
          number: 'JOB-FUTURE',
          title: 'Scheduled lighting repair',
          client: 'Future Client',
          detail: 'Future scheduled work.',
          pricing: WorkPricingModel.flatRate,
          assignee: 'Alex Morgan',
          scheduledStart: today.add(const Duration(days: 1)),
          status: WorkRecordStatus.scheduled,
        ),
      ],
    );
    await _pumpJobs(tester, const Size(390, 844), store: store);
    final day = find.byKey(
      ValueKey('work-calendar-day-${today.year}-${today.month}-${today.day}'),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();
    expect(find.text('Completed drain repair'), findsOneWidget);

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();
    expect(find.text('Scheduled lighting repair'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Job calendar route retains action permissions', (tester) async {
    await _pumpJobs(
      tester,
      const Size(390, 844),
      permissions: const JobWorkspacePermissions(
        canEditJob: false,
        canViewEstimate: true,
        canAddMaterials: false,
        canAttachReceipts: false,
        canChangeStatus: false,
        canContactCustomer: false,
      ),
    );
    final today = DateUtils.dateOnly(DateTime.now());
    final day = find.byKey(
      ValueKey('work-calendar-day-${today.year}-${today.month}-${today.day}'),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();

    final job = find.byKey(const ValueKey('job-row-job-1038'));
    await tester.ensureVisible(job);
    await tester.tap(find.ancestor(of: job, matching: find.byType(InkWell)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('job-actions-fab')), findsNothing);
    expect(find.byKey(const ValueKey('job-link-expense')), findsNothing);
    expect(find.text('Call customer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'New job uses a real scheduled-job form and validates ownership',
    (tester) async {
      await _pumpJobs(tester, const Size(390, 844));

      await tester.tap(find.byKey(const ValueKey('new-job')));
      await tester.pumpAndSettle();
      expect(find.text('Start from an estimate'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('job-without-estimate')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('job-editor-screen')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-client-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-location-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-start-date')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-end-time')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-assignee-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-vehicle-field')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-items-section')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save-job')));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Enter a job title, choose a client, and choose a service location.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Jobs records reflow instead of clipping accessibility text', (
    tester,
  ) async {
    await _pumpJobs(tester, const Size(320, 844), textScale: 2);

    expect(find.text('Replace kitchen faucet'), findsOneWidget);
    expect(find.text('Maya Thompson · Alex Morgan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin sees unassigned work in attention, not dated records', (
    tester,
  ) async {
    final now = DateTime.now();
    final store = PrototypeOperationsStore(
      workRecords: [
        WorkRecord(
          id: 'unassigned-job',
          kind: WorkRecordKind.job,
          number: 'JOB-2200',
          title: 'Repair leaking hose connection',
          client: 'Taylor Brooks',
          detail: 'Awaiting assignment',
          pricing: WorkPricingModel.timeAndMaterials,
          createdOn: now,
          scheduledStart: DateTime(now.year, now.month, now.day, 13),
          status: WorkRecordStatus.scheduled,
        ),
      ],
    );
    await _pumpJobs(
      tester,
      const Size(390, 844),
      store: store,
      view: AppViewMode.admin,
    );

    final attentionRow = find.byKey(
      const ValueKey('job-attention-unassigned-job'),
    );
    final ordinaryRow = find.byKey(const ValueKey('job-row-unassigned-job'));
    expect(find.byKey(const ValueKey('job-attention')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('job-attention')),
        matching: attentionRow,
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('job-date-records')),
        matching: ordinaryRow,
      ),
      findsNothing,
    );
    expect(find.byTooltip('Dismiss Needs attention'), findsOneWidget);

    await tester.tap(attentionRow);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('job-workspace-unassigned-job')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Technician return visit uses shared dismissible attention', (
    tester,
  ) async {
    final now = DateTime.now();
    final store = PrototypeOperationsStore(
      workRecords: [
        WorkRecord(
          id: 'return-visit-job',
          kind: WorkRecordKind.job,
          number: 'JOB-2201',
          title: 'Return to finish valve replacement',
          client: 'Casey Green',
          detail: 'Replacement valve must be scheduled.',
          pricing: WorkPricingModel.timeAndMaterials,
          assignee: 'Alex Morgan',
          createdOn: now,
          scheduledStart: DateTime(now.year, now.month, now.day, 9),
          status: WorkRecordStatus.needsReturnVisit,
        ),
      ],
    );
    await _pumpJobs(tester, const Size(390, 844), store: store);

    expect(find.byKey(const ValueKey('job-attention')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('job-attention-return-visit-job')),
      findsOneWidget,
    );
    expect(
      find.text('Return visit needs scheduling · Casey Green'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('job-date-records')),
        matching: find.byKey(const ValueKey('job-row-return-visit-job')),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Dismiss Needs attention'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('job-attention')), findsNothing);
    expect(store.workRecords.single.status, WorkRecordStatus.needsReturnVisit);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 412.0, 800.0, 1440.0]) {
    testWidgets('Jobs workspace reflows cleanly at ${width.toInt()} LP', (
      tester,
    ) async {
      await _pumpJobs(tester, Size(width, 1000));

      expect(find.byKey(const ValueKey('job-selected-date')), findsOneWidget);
      expect(find.byKey(const ValueKey('job-date-records')), findsOneWidget);
      expect(find.byKey(const ValueKey('work-5-7-calendar')), findsOneWidget);
      if (width == 1440) {
        expect(
          tester.getSize(find.byKey(const ValueKey('work-5-7-calendar'))).width,
          lessThanOrEqualTo(AppLayoutEngine.maximumOperationsWorkspaceWidth),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
