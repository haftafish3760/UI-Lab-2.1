import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_items_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/stored_estimate_items_editor.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'detail item editing recovers partial nested input and commits atomically',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
      final original = work.records.singleWhere(
        (record) => record.id == 'est-1040',
      );
      final line = original.items.first;
      final quantity = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Quantity',
      );
      Future<void> open() async {
        await tester.pumpWidget(UiLabApp(workSession: work));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.byType(DashboardScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateDetailScreen(
              initialRecord: work.records.singleWhere(
                (record) => record.id == original.id,
              ),
              onUpdated: (_) {},
              onCreateJob: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final edit = find.byKey(const ValueKey('edit-estimate-items'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find.byType(EstimateItemsScreen).evaluate().isNotEmpty,
        );
      }

      try {
        await open();
        final editLine = find.byKey(ValueKey('edit-estimate-item-${line.id}'));
        await tester.ensureVisible(editLine);
        await tester.tap(editLine);
        await tester.pumpAndSettle();
        await tester.enterText(quantity, '');
        await tester.binding.handlePopRoute();
        await waitForNativeSave(tester, () => quantity.evaluate().isEmpty);
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('save-estimate-items')),
              )
              .onPressed,
          isNull,
        );
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.byType(StoredEstimateItemsEditor).evaluate().isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(() => harness.close(db));
        db = (await tester.runAsync(harness.open))!;
        work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        await open();
        await tester.tap(find.text('Continue unfinished item'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(quantity).controller!.text, '');
        await tester.enterText(quantity, '3.');
        final saveLine = find.text('Save item changes');
        await tester.ensureVisible(saveLine);
        await tester.tap(saveLine);
        await tester.pump();
        await waitForNativeSave(tester, () => quantity.evaluate().isEmpty);
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_item_draft BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-items' BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        final save = find.byKey(const ValueKey('save-estimate-items'));
        await tester.tap(save);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => work.failureMessage != null && !work.isSaving,
        );
        expect(find.byType(StoredEstimateItemsEditor), findsOneWidget);
        expect(
          work.records
              .singleWhere((record) => record.id == original.id)
              .items
              .first
              .quantity,
          line.quantity,
        );
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_item_draft'),
        );
        await tester.tap(save);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => find.byType(StoredEstimateItemsEditor).evaluate().isEmpty,
        );
        final saved = work.records.singleWhere(
          (record) => record.id == original.id,
        );
        expect(saved.items.first.quantity, 3);
        expect(saved.revision, original.revision + 1);
        expect(work.storageRevisionFor(original.id), 2);
        expect(
          await tester.runAsync(
            () => LocalDraftStore(db).list(
              organizationId: work.permissions.organizationId,
              domain: 'work/estimate-items',
              ownerId: work.permissions.actorEmployeeId,
            ),
          ),
          isEmpty,
        );
        expect(find.textContaining('The saved record changed.'), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(harness.dispose);
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    },
  );
}
