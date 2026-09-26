import 'support/document_form_navigation.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_record_extensions.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

part 'estimate_record_rules_test_part.dart';
part 'estimate_attention_workflow_test_part.dart';
part 'estimate_detail_layout_test_part.dart';

WorkRecord _estimate({
  EstimateStage stage = EstimateStage.readyToSend,
  DateTime? createdOn,
}) {
  final created = createdOn ?? DateTime(2026, 8, 30);
  return WorkRecord(
    id: 'estimate-test',
    kind: WorkRecordKind.estimate,
    number: 'EST-TEST',
    title: 'Test estimate',
    client: 'Maya Thompson',
    detail: 'Replace a test fixture and verify operation.',
    pricing: WorkPricingModel.flatRate,
    createdOn: created,
    status: stage == EstimateStage.approved
        ? WorkRecordStatus.accepted
        : WorkRecordStatus.ready,
    total: 250,
    estimateStage: stage,
    estimateDates: EstimateDates(
      createdOn: created,
      lastEditedOn: created,
      followUpOn: created.add(const Duration(days: 2)),
      expiresOn: created.add(const Duration(days: 30)),
    ),
  );
}

void main() {
  registerEstimateRecordRuleTests();
  registerEstimateAttentionWorkflowTests();
  registerEstimateDetailLayoutTests();

  testWidgets('estimate form helper text remains complete at large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: MaterialApp(
              theme: AppTheme.light,
              home: EstimateEditorScreen(
                initialDay: DateTime(2026, 8, 30),
                initialRecord: _estimate(
                  stage: EstimateStage.draft,
                  createdOn: DateTime(2026, 8, 30),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await openDocumentSection(tester, 'estimate-terms');
    final helper = find.text(
      'These are the terms for this document. Review them before sharing.',
    );
    await tester.ensureVisible(helper);
    await tester.pumpAndSettle();
    expect(helper, findsOneWidget);
    expect(tester.widget<Text>(helper).maxLines, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draft preview cannot bypass the guarded delivery flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: EstimateDetailScreen(
              initialRecord: _estimate(stage: EstimateStage.draft),
              onUpdated: (_) {},
              onCreateJob: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('estimate-primary-preview')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('document-preview-estimate-test')),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Document actions'));
    await tester.pumpAndSettle();
    expect(find.text('PDF delivery options'), findsOneWidget);
    await tester.tap(find.text('PDF delivery options'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('estimate-delivery-screen')), findsOne);
    expect(find.text('Continue to sharing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sendable preview continues into the guarded delivery route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: EstimateDetailScreen(
              initialRecord: _estimate(),
              onUpdated: (_) {},
              onCreateJob: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('estimate-primary-preview')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Document actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PDF delivery options'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('estimate-delivery-screen')), findsOne);
    expect(find.text('Email PDF to customer'), findsOneWidget);
    expect(find.text('Text message'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('company reviewer sees exact estimate decision controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PrototypeOperationsStore();
    final scope = OperationalScopeController(view: AppViewMode.admin);
    addTearDown(store.dispose);
    addTearDown(scope.dispose);
    final pending = store.workRecords.singleWhere(
      (record) => record.id == 'est-1039',
    );

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: EstimateDetailScreen(
              initialRecord: pending,
              onUpdated: store.updateWorkRecord,
              onCreateJob: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Company review'), findsOneWidget);
    expect(find.text('Awaiting company approval'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('approve-estimate-for-sending')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('return-estimate-for-changes')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('reject-estimate')), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const ValueKey('approve-estimate-for-sending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('approve-estimate-for-sending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-company-approval')));
    await tester.pumpAndSettle();

    expect(find.text('Approved for sending'), findsOneWidget);
    expect(
      find.textContaining('Customer approval is still separate'),
      findsOneWidget,
    );
    final updated = store.workRecords.singleWhere(
      (record) => record.id == 'est-1039',
    );
    expect(
      updated.estimateCompanyReviewStatus,
      EstimateCompanyReviewStatus.approved,
    );
    expect(updated.hasCurrentCustomerSignature, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Estimate workspace starts with a date, compact records, drafts, and search',
    (tester) async {
      const size = Size(390, 844);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const UiLabApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('app-destination-work')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('work-view-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('quick-estimates')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('estimate-selected-date')), findsOne);
      expect(find.byKey(const ValueKey('estimate-date-records')), findsOne);
      expect(find.byKey(const ValueKey('open-work-drafts')), findsOne);
      expect(find.byKey(const ValueKey('estimate-attention')), findsOne);
      expect(find.byKey(const ValueKey('estimate-search')), findsOneWidget);
      expect(find.byKey(const ValueKey('new-estimate')), findsOneWidget);
      expect(find.text('Estimate pipeline'), findsNothing);

      final row = find.byKey(const ValueKey('estimate-row-est-1042'));
      await tester.ensureVisible(row);
      expect(row, findsOneWidget);
      expect(tester.getSize(row).height, lessThanOrEqualTo(70));

      await tester.ensureVisible(
        find.byKey(const ValueKey('open-work-drafts')),
      );
      await tester.tap(find.byKey(const ValueKey('open-work-drafts')));
      await tester.pumpAndSettle();
      expect(find.text('Drafts'), findsWidgets);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final attentionRow = find.byKey(
        const ValueKey('estimate-attention-row-est-1039'),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('estimate-attention')),
          matching: attentionRow,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('estimate-date-records')),
          matching: attentionRow,
        ),
        findsNothing,
      );
      expect(find.text('Show all 1'), findsOneWidget);
      expect(find.byTooltip('Dismiss Needs attention'), findsOneWidget);

      final today = DateUtils.dateOnly(DateTime.now());
      final todayCell = find.byKey(
        ValueKey('work-calendar-day-${today.year}-${today.month}-${today.day}'),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(todayCell);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('estimate-day-screen')), findsOneWidget);
      final datedEstimate = find.byKey(
        const ValueKey('estimate-day-row-est-1042'),
      );
      await tester.ensureVisible(datedEstimate);
      await tester.tap(datedEstimate);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('estimate-detail-est-1042')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      final tomorrow = DateUtils.dateOnly(
        DateTime.now().add(const Duration(days: 1)),
      );
      final tomorrowCell = find.byKey(
        ValueKey(
          'work-calendar-day-${tomorrow.year}-${tomorrow.month}-${tomorrow.day}',
        ),
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      await tester.tap(tomorrowCell);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('estimate-day-screen')), findsOneWidget);
      expect(
        find.textContaining('No estimates are recorded for this date'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('estimate-row-est-1042')), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('work-estimate-workspace')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Open navigation'));
      await tester.pumpAndSettle();
      final customers = find.byKey(const ValueKey('menu-customers'));
      await tester.ensureVisible(customers);
      await tester.pumpAndSettle();
      await tester.tap(customers);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maya Thompson'));
      await tester.pumpAndSettle();
      expect(find.text('Work history'), findsOneWidget);
      expect(find.textContaining('EST-1042'), findsOneWidget);
      expect(find.text('New estimate'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Estimate totals stay hidden without total permission', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: EstimateWorkspaceScreen(
              initialDay: DateTime.now(),
              permissions: const EstimatePermissions(
                canView: true,
                canCreate: true,
                canEditItems: true,
                canSend: false,
                canCollectSignature: false,
                canConvertToJob: false,
                canViewEstimateTotals: false,
                canViewInternalCosts: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$685.00'), findsNothing);
    expect(find.text('Maya Thompson'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-estimate')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 412.0, 800.0, 1440.0]) {
    testWidgets('Estimate home reflows cleanly at ${width.toInt()} LP', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scope = OperationalScopeController();
      final store = PrototypeOperationsStore();
      addTearDown(scope.dispose);
      addTearDown(store.dispose);

      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: EstimateWorkspaceScreen(initialDay: DateTime.now()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('estimate-selected-date')), findsOne);
      expect(find.byKey(const ValueKey('estimate-date-records')), findsOne);
      expect(find.byKey(const ValueKey('work-5-7-calendar')), findsOne);
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
