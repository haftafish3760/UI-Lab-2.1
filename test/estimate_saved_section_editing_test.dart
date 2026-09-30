import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'saved section edit preserves original on failure and returns to review after retry',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(
        () => openUiLabWorkSession(database),
      ))!;
      final store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      const id = 'section-edit';
      final original = WorkRecord(
        id: id,
        kind: WorkRecordKind.estimate,
        number: 'Estimate 71',
        title: 'Original work',
        client: 'Customer',
        detail: 'Replace fitting',
        pricing: WorkPricingModel.flatRate,
        total: 50,
        createdByEmployeeId: work.permissions.actorEmployeeId,
        createdOn: DateTime(2026, 9, 27),
        items: const [
          WorkLineItem(
            id: 'line',
            type: WorkLineItemType.labor,
            name: 'Repair',
            quantity: 1,
            unit: 'job',
            customerPrice: 50,
          ),
        ],
      );
      expect(
        await tester.runAsync(() => store.addWorkRecord(original)),
        isTrue,
      );
      await tester.runAsync(
        () => database.customStatement("""
      CREATE TRIGGER fail_section_edit BEFORE UPDATE ON local_records
      WHEN NEW.record_id = 'section-edit'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: EstimateDetailScreen(
                showRecordActions: true,
                initialRecord: original,
                onUpdated: (_) {},
                onCreateJob: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final detailState = tester.state(find.byType(EstimateDetailScreen));
      final edit = find.byKey(const ValueKey('estimate-primary-edit'));
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      final position = Scrollable.of(tester.element(edit)).position;
      final offset = position.pixels;
      await tester.tap(edit);
      await waitForNativeSave(
        tester,
        () => find.text('Editing work details').evaluate().isNotEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('estimate-title')),
        'Updated work',
      );
      await tester.tap(find.text('Save changes'));
      await waitForNativeSave(tester, () => work.failureMessage != null);
      expect(
        store.workRecords.singleWhere((r) => r.id == id).title,
        'Original work',
      );
      expect(
        find.byKey(const ValueKey('estimate-editor-screen')),
        findsOneWidget,
      );
      await tester.runAsync(
        () => database.customStatement('DROP TRIGGER fail_section_edit'),
      );
      final save = find.byKey(const ValueKey('save-estimate-changes'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find.byType(EstimateDetailScreen).evaluate().isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(EstimateDetailScreen)),
        same(detailState),
      );
      expect(position.pixels, closeTo(offset, 1));
      expect(find.text('Updated work'), findsOneWidget);
      final saved = store.workRecords.singleWhere((r) => r.id == id);
      expect(saved.title, 'Updated work');
      expect(saved.client, original.client);
      expect(saved.total, original.total);
      expect(tester.takeException(), isNull);
    },
  );
}
