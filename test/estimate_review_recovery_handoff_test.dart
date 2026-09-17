import 'package:ui_lab_2_1/src/data/work/estimate_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_action_recovery_routes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_review_reason_dialog.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mismatch in [false, true]) {
    testWidgets(
      'selected review decision mismatch=$mismatch preserves unconfirmed reason',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final work = (await tester.runAsync(
          () async => openSeededTestWorkSession(await harness.open()),
        ))!;
        final pending = work.records
            .singleWhere((r) => r.id == 'est-1040')
            .submitForCompanyReview(
              submittedBy: 'alex',
              submittedOn: DateTime.utc(2026, 9, 10),
            );
        expect(await tester.runAsync(() => work.update(pending)), isTrue);
        const decision = EstimateCompanyReviewDecision.changesRequested;
        const permissions = EstimatePermissions.development();
        final workflow = (await tester.runAsync(
          () => work.openEstimateReviewDraft(
            pending,
            decision: decision,
            reviewPermissions: permissions,
          ),
        ))!;
        await tester.runAsync(() async {
          workflow.updateReason('Unfinished reason');
          await workflow.session.flush();
        });
        final revision = work.storageRevisionFor(pending.id);
        final store = PrototypeOperationsStore(workSession: work);
        Future<void>? route;
        try {
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: MaterialApp(
                theme: AppTheme.light,
                home: !mismatch
                    ? Builder(
                        builder: (context) => Scaffold(
                          body: TextButton(
                            onPressed: () => route = openEstimateActionRecovery(
                              context,
                              ResumedEstimateReview(workflow),
                              reviewPermissions: permissions,
                            ),
                            child: const Text('Resume action'),
                          ),
                        ),
                      )
                    : EstimateReviewReasonDialog(
                        record: pending,
                        decision: mismatch
                            ? EstimateCompanyReviewDecision.rejected
                            : decision,
                        permissions: permissions,
                        recoveredWorkflow: workflow,
                      ),
              ),
            ),
          );
          if (!mismatch) await tester.tap(find.text('Resume action'));
          await tester.pumpAndSettle();
          if (mismatch) {
            await waitForNativeSave(
              tester,
              () => find
                  .text('Selected review belongs to another workflow.')
                  .evaluate()
                  .isNotEmpty,
            );
          } else {
            expect(find.text('Unfinished reason'), findsOneWidget);
            await tester.enterText(
              find.byKey(const ValueKey('company-review-reason')),
              'Continued reason',
            );
            await finishNativeOperation(tester, workflow.session.flush);
          }
          if (!mismatch) {
            await tester.ensureVisible(find.text('Keep unfinished'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Keep unfinished'));
            await finishNativeOperation(tester, () => route!);
            expect(find.text('Resume action'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          final saved = await tester.runAsync(
            () => work.drafts.find(
              organizationId: workflow.session.organizationId,
              domain: workflow.session.domain,
              draftId: workflow.session.draftId,
              ownerId: workflow.session.ownerId,
            ),
          );
          expect(
            jsonDecode(saved!.payload)['reason'],
            mismatch ? 'Unfinished reason' : 'Continued reason',
          );
          expect(work.storageRevisionFor(pending.id), revision);
          expect(
            work.records
                .singleWhere((r) => r.id == pending.id)
                .estimateCompanyReviewStatus,
            EstimateCompanyReviewStatus.pending,
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          store.dispose();
          work.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
