import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/l10n/app_localizations.dart';
import 'package:ui_lab_2_1/src/data/operational_attention.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_attention_panel.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  test('Dashboard attention is capability- and scope-filtered', () {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);

    final technician = OperationalAttentionQuery(
      panelId: 'dashboard-home',
      module: OperationalAttentionModule.dashboard,
      view: AppViewMode.technician,
      access: const OperationalAttentionAccess.technicianDevelopment(),
      selectedEmployeeId: 'alex',
      selectedVehicleId: 'transit-12',
    );
    final admin = OperationalAttentionQuery(
      panelId: 'dashboard-home',
      module: OperationalAttentionModule.dashboard,
      view: AppViewMode.admin,
      access: const OperationalAttentionAccess.adminDevelopment(),
    );

    final technicianItems = store.attentionCenter.itemsFor(technician);
    final adminItems = store.attentionCenter.itemsFor(admin);
    expect(technicianItems, hasLength(2));
    expect(adminItems, hasLength(4));
    expect(technicianItems.any((item) => item.sourceId == 'est-1039'), isFalse);
    expect(
      adminItems.singleWhere((item) => item.sourceId == 'est-1039').reason,
      'Approve estimate · Jordan Miller',
    );
  });

  test('No capability means no attention data is exposed', () {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    final denied = OperationalAttentionQuery(
      panelId: 'dashboard-home',
      module: OperationalAttentionModule.dashboard,
      view: AppViewMode.admin,
      access: const OperationalAttentionAccess({}),
    );

    expect(store.attentionCenter.itemsFor(denied), isEmpty);
  });

  test('Dismissal hides presentation without resolving source records', () {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    final query = OperationalAttentionQuery(
      panelId: 'expenses-home',
      module: OperationalAttentionModule.expenses,
      view: AppViewMode.admin,
      access: const OperationalAttentionAccess.adminDevelopment(),
    );
    final items = store.attentionCenter.itemsFor(query);

    expect(items, isNotEmpty);
    expect(store.attentionCenter.shouldShow(query, items), isTrue);
    store.attentionCenter.dismiss(query, items);

    expect(store.attentionCenter.shouldShow(query, items), isFalse);
    expect(store.attentionCenter.itemsFor(query), hasLength(items.length));
  });

  test(
    'Invoice attention is based on due date rather than display wording',
    () {
      final today = DateTime.now();
      final store = PrototypeOperationsStore(
        workRecords: [
          WorkRecord(
            id: 'past-due',
            kind: WorkRecordKind.invoice,
            number: 'INV-PAST',
            title: 'Past due invoice',
            client: 'Customer One',
            detail: 'Awaiting customer payment',
            pricing: WorkPricingModel.flatRate,
            status: WorkRecordStatus.due,
            dueOn: today.subtract(const Duration(days: 1)),
          ),
          WorkRecord(
            id: 'future-due',
            kind: WorkRecordKind.invoice,
            number: 'INV-FUTURE',
            title: 'Future invoice',
            client: 'Customer Two',
            detail: 'Overdue wording must not control state',
            pricing: WorkPricingModel.flatRate,
            status: WorkRecordStatus.due,
            dueOn: today.add(const Duration(days: 1)),
          ),
        ],
      );
      addTearDown(store.dispose);
      final query = OperationalAttentionQuery(
        panelId: 'invoice-home',
        module: OperationalAttentionModule.work,
        view: AppViewMode.admin,
        access: const OperationalAttentionAccess({
          OperationalAttentionCapability.reviewInvoices,
        }),
        resourceKinds: const {OperationalAttentionResourceKind.invoice},
      );

      final items = store.attentionCenter.itemsFor(query);
      expect(items.map((item) => item.sourceId), ['past-due']);
    },
  );

  testWidgets('attention heading typography follows its local lane width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const item = OperationalAttentionItem(
      id: 'attention-local-lane',
      module: OperationalAttentionModule.work,
      resourceKind: OperationalAttentionResourceKind.estimate,
      sourceId: 'estimate-local-lane',
      title: 'Estimate needs approval',
      reason: 'Approve estimate · Maya Thompson',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(
          child: SizedBox(
            width: 320,
            child: OperationalAttentionPanel(
              items: const [item],
              onOpen: (_) {},
              onOpenAll: () {},
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final heading = tester.widget<Text>(find.text('Needs attention'));
    expect(
      heading.style?.fontSize,
      AppLayoutEngine.typographyFor(320).sectionTitle,
    );
    expect(tester.takeException(), isNull);
  });
}
