import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/dashboard/dashboard_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_review_reason_dialog.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final returning in [false, true]) {
    testWidgets(
      '${returning ? 'return' : 'reject'} reason recovers and commits atomically with review',
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
              original.submitForCompanyReview(
                submittedBy: 'alex',
                submittedOn: DateTime.now(),
              ),
            ),
          ),
          isTrue,
        );
        final field = find.byKey(const ValueKey('company-review-reason'));
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
          final action = find.byKey(
            ValueKey(
              returning ? 'return-estimate-for-changes' : 'reject-estimate',
            ),
          );
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();
          await waitForNativeSave(tester, () => field.evaluate().isNotEmpty);
        }

        Future<void> close() async {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          work.dispose();
          await tester.runAsync(() => harness.close(db));
        }

        const reason = '  Confirm panel access\nExplain the labor allowance.  ';
        try {
          await open();
          await tester.enterText(field, reason);
          await tester.tap(find.text('Keep unfinished'));
          await tester.pump();
          await waitForNativeSave(tester, () => field.evaluate().isEmpty);
          await close();
          db = (await tester.runAsync(harness.open))!;
          work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
          await open();
          expect(tester.widget<TextFormField>(field).controller!.text, reason);
          await tester.runAsync(
            () => db.customStatement(
              "CREATE TRIGGER fail_review BEFORE DELETE ON local_drafts WHEN OLD.domain = 'work/estimate-review' BEGIN SELECT RAISE(ABORT, 'fail'); END",
            ),
          );
          final confirm = find.byKey(
            const ValueKey('confirm-company-review-decision'),
          );
          await tester.tap(confirm);
          await tester.pump();
          await waitForNativeSave(
            tester,
            () => work.failureMessage != null && !work.isSaving,
          );
          expect(find.byType(EstimateReviewReasonDialog), findsOneWidget);
          expect(
            work.records
                .singleWhere((record) => record.id == original.id)
                .estimateCompanyReviewStatus,
            EstimateCompanyReviewStatus.pending,
          );
          expect(tester.widget<TextFormField>(field).controller!.text, reason);
          await tester.runAsync(
            () => db.customStatement('DROP TRIGGER fail_review'),
          );
          await tester.tap(confirm);
          await tester.pump();
          await waitForNativeSave(tester, () => field.evaluate().isEmpty);
          final saved = work.records.singleWhere(
            (record) => record.id == original.id,
          );
          expect(
            saved.estimateCompanyReviewStatus,
            returning
                ? EstimateCompanyReviewStatus.changesRequested
                : EstimateCompanyReviewStatus.rejected,
          );
          expect(saved.estimateCompanyReviewNote, reason);
          expect(saved.estimateCompanyReviewHistory, hasLength(2));
          expect(saved.estimateCompanyReviewHistory.last.actor, 'alex');
          expect(
            await tester.runAsync(
              () => LocalDraftStore(db).list(
                organizationId: work.permissions.organizationId,
                domain: 'work/estimate-review',
                ownerId: work.permissions.actorEmployeeId,
              ),
            ),
            isEmpty,
          );
          await close();
          db = (await tester.runAsync(harness.open))!;
          work = (await tester.runAsync(() => openSeededTestWorkSession(db)))!;
          final reopened = work.records.singleWhere(
            (record) => record.id == original.id,
          );
          expect(reopened.estimateCompanyReviewNote, reason);
          expect(reopened.estimateCompanyReviewHistory, hasLength(2));
          expect(
            reopened.estimateCompanyReviewHistory.last.occurredOn,
            saved.estimateCompanyReviewHistory.last.occurredOn,
          );
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
}
