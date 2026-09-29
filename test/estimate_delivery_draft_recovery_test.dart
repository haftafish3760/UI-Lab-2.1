import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/shared/editor_draft_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_delivery_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'delivery method recipients recover and preparation never claims sending',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
      final original = work.records.singleWhere(
        (record) => record.id == 'est-1040',
      );
      expect(
        await tester.runAsync(
          () => work.update(
            original.withEstimateStage(
              EstimateStage.readyToSend,
              DateTime.now(),
            ),
          ),
        ),
        isTrue,
      );
      final field = find.byKey(const ValueKey('estimate-delivery-recipient'));
      Future<void> open() async {
        await tester.pumpWidget(UiLabApp(workSession: work));
        await tester.pumpAndSettle();
        final record = work.records.singleWhere(
          (record) => record.id == original.id,
        );
        Navigator.of(tester.element(find.byType(DashboardScreen))).push(
          MaterialPageRoute<void>(
            builder: (_) => EstimateDetailScreen(
              initialRecord: record,
              onUpdated: (_) {},
              onCreateJob: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final options = find.byKey(const ValueKey('estimate-primary-send'));
        await tester.ensureVisible(options);
        await tester.tap(options);
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => tester.widget<TextField>(field).enabled == true,
        );
      }

      Future<void> choose(String method) async {
        final choice = find.byKey(ValueKey('delivery-$method'));
        await tester.ensureVisible(choice);
        await tester.tap(choice);
        await tester.pumpAndSettle();
      }

      try {
        await open();
        expect(
          find.byKey(const ValueKey('preview-estimate-for-delivery')),
          findsOneWidget,
        );
        await tester.enterText(field, '  customer@  ');
        await choose('textMessage');
        await tester.enterText(field, '555-123');
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.byType(EstimateDeliveryScreen).evaluate().isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(() => harness.close(db));
        db = (await tester.runAsync(harness.open))!;
        work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
        await open();
        expect(tester.widget<TextField>(field).controller!.text, '555-123');
        await choose('email');
        expect(
          tester.widget<TextField>(field).controller!.text,
          '  customer@  ',
        );
        await choose('textMessage');
        expect(tester.widget<TextField>(field).controller!.text, '555-123');
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        // Ensure all queued draft writes precede the injected atomic-consumption failure.
        await waitForNativeSave(
          tester,
          () => find
              .byWidgetPredicate(
                (widget) =>
                    widget is EditorDraftStatus &&
                    widget.state == DraftSaveState.savedLocally,
              )
              .evaluate()
              .isNotEmpty,
        );
        await tester.runAsync(
          () => db.customStatement(
            "CREATE TRIGGER fail_delivery BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-delivery' BEGIN SELECT RAISE(ABORT, 'fail'); END",
          ),
        );
        final confirm = find.byKey(const ValueKey('confirm-estimate-delivery'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => work.failureMessage != null && !work.isSaving,
        );
        expect(find.byType(EstimateDeliveryScreen), findsOneWidget);
        expect(
          work.records
              .singleWhere((record) => record.id == original.id)
              .estimateDeliveries,
          isEmpty,
        );
        await tester.runAsync(
          () => db.customStatement('DROP TRIGGER fail_delivery'),
        );
        await tester.tap(confirm);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () =>
              work.records
                      .singleWhere((record) => record.id == original.id)
                      .estimateDeliveries
                      .length ==
                  1 &&
              tester.widget<FilledButton>(confirm).onPressed != null,
        );
        // The widget-test host has no native sharing plugin. Preparation must
        // remain durable and a retry must reuse it instead of posting twice.
        expect(find.byType(EstimateDeliveryScreen), findsOneWidget);
        expect(
          find.text(
            'Recipient-aware composition is unavailable on this device. Choose Share PDF to use an installed app.',
          ),
          findsOneWidget,
        );
        await tester.tap(confirm);
        await tester.pump();
        await waitForNativeSave(
          tester,
          () => tester.widget<FilledButton>(confirm).onPressed != null,
        );
        final saved = work.records.singleWhere(
          (record) => record.id == original.id,
        );
        expect(
          saved.estimateDeliveries.single.method,
          EstimateDeliveryMethod.textMessage,
        );
        expect(saved.estimateDeliveries.single.recipient, '555-123');
        expect(
          saved.estimateDeliveries.single.description,
          contains('delivery not confirmed'),
        );
        expect(saved.resolvedEstimateStage, EstimateStage.readyToSend);
        expect(saved.estimateDates!.sentOn, isNull);
        expect(
          await tester.runAsync(
            () => LocalDraftStore(db).list(
              organizationId: work.permissions.organizationId,
              domain: 'work/estimate-delivery',
              ownerId: work.permissions.actorEmployeeId,
            ),
          ),
          isEmpty,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        work.dispose();
        await tester.runAsync(() => harness.close(db));
        db = (await tester.runAsync(harness.open))!;
        work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
        final reopened = work.records.singleWhere(
          (record) => record.id == original.id,
        );
        expect(reopened.estimateDeliveries, hasLength(1));
        expect(
          reopened.estimateDeliveries.single.occurredOn,
          saved.estimateDeliveries.single.occurredOn,
        );
        expect(reopened.estimateDates!.sentOn, isNull);
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
