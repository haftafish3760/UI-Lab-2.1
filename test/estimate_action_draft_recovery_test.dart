import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_delivery_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_items_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_review_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'support/storage/database_harness.dart';

DraftAutosaveSession sessionOf(ResumedEstimateAction resumed) =>
    switch (resumed) {
      ResumedEstimateSignature(:final controller) => controller.session,
      ResumedEstimateDelivery(:final controller) => controller.session,
      ResumedEstimateItems(:final controller) => controller.session,
      ResumedEstimateReview(:final controller) => controller.session,
    };

Future<WorkRecord> seedActions(WorkPersistenceSession work) async {
  final pending = work.records
      .singleWhere((r) => r.id == 'est-1040')
      .submitForCompanyReview(
        submittedBy: 'alex',
        submittedOn: DateTime.utc(2026, 9, 10),
      );
  expect(await work.update(pending), isTrue);
  final signature = await work.openEstimateSignatureDraft(pending.id);
  signature.updateName('  Unfinished customer  ');
  await signature.session.close();
  final delivery = await work.openEstimateDeliveryDraft(
    pending.id,
    customers: [],
  );
  delivery.updateRecipient('unfinished@');
  await delivery.session.close();
  final items = await work.openEstimateItemsDraft(pending);
  await items.session.close();
  for (final decision in [
    EstimateCompanyReviewDecision.changesRequested,
    EstimateCompanyReviewDecision.rejected,
  ]) {
    final review = await work.openEstimateReviewDraft(
      pending,
      decision: decision,
      reviewPermissions: const EstimatePermissions.development(),
    );
    review.updateReason('  Partial reason\n${decision.name}  ');
    await review.session.close();
  }
  return pending;
}

EstimateActionDraftRecovery recoveryFor(WorkPersistenceSession work) =>
    EstimateActionDraftRecovery(
      work,
      reviewPermissions: () => const EstimatePermissions.development(),
      customers: () => [],
    );

void main() {
  test(
    'all estimate actions survive reopen and resume exact input without confirming work',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openSeededTestWorkSession(database);
      final pending = await seedActions(work);
      final before = await work.drafts.listOwned(
        organizationId: work.permissions.organizationId,
        ownerId: work.permissions.actorEmployeeId,
        domains: {
          'work/estimate-signature',
          'work/estimate-delivery',
          'work/estimate-items',
          'work/estimate-review',
        },
      );
      final raw = {
        for (final row in before)
          '${row.domain}/${row.draftId}': work.drafts.decode(row),
      };
      final revision = work.storageRevisionFor(pending.id);
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openSeededTestWorkSession(database);
      addTearDown(work.dispose);
      final recovery = recoveryFor(work);
      final entries = await recovery.list();
      expect(entries, hasLength(5));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final resumed = await recovery.resume(entry);
        final session = sessionOf(resumed);
        expect(session.input, raw['${entry.domain}/${entry.draftId}']);
        expect(session.savedRevision, entry.revision);
        await session.close();
      }
      expect(work.storageRevisionFor(pending.id), revision);
      expect(
        work.records
            .singleWhere((r) => r.id == pending.id)
            .estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.pending,
      );
    },
  );

  test(
    'review authority is rechecked for list resume and discard without granting editor approval',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      await seedActions(work);
      var permission = const EstimatePermissions.development();
      final recovery = EstimateActionDraftRecovery(
        work,
        reviewPermissions: () => permission,
        customers: () => [],
      );
      final entries = await recovery.list();
      final review = entries.firstWhere(
        (e) => e.domain == 'work/estimate-review',
      );
      permission = const EstimatePermissions.technicianDevelopment();
      expect(await recovery.list(), hasLength(3));
      await expectLater(recovery.resume(review), throwsStateError);
      await expectLater(recovery.discard(review), throwsStateError);
      permission = const EstimatePermissions.development();
      expect(await recovery.list(), hasLength(5));
    },
  );

  test(
    'selected revisions and consumed drafts cannot silently reopen or reseed',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      final pending = await seedActions(work);
      final recovery = recoveryFor(work);
      final entries = await recovery.list();
      for (final entry in entries) {
        Future<Object> open(int revision) {
          final selection = DraftRecoverySelection(
            domain: entry.domain,
            draftId: entry.draftId,
            revision: revision,
          );
          return switch (entry.domain) {
            'work/estimate-signature' => work.openEstimateSignatureDraft(
              pending.id,
              recoverySelection: selection,
            ),
            'work/estimate-delivery' => work.openEstimateDeliveryDraft(
              pending.id,
              customers: [],
              recoverySelection: selection,
            ),
            'work/estimate-items' => work.openEstimateItemsDraft(
              pending,
              recoverySelection: selection,
            ),
            _ => work.openEstimateReviewDraft(
              pending,
              decision: entry.draftId.endsWith('rejected')
                  ? EstimateCompanyReviewDecision.rejected
                  : EstimateCompanyReviewDecision.changesRequested,
              reviewPermissions: const EstimatePermissions.development(),
              recoverySelection: selection,
            ),
          };
        }

        await expectLater(
          open(entry.revision + 1),
          throwsA(isA<LocalRecordConflict>()),
        );
        await recovery.discard(entry);
        await expectLater(
          open(entry.revision),
          throwsA(isA<LocalRecordConflict>()),
        );
      }
      expect(await recovery.list(), isEmpty);
    },
  );

  test(
    'concurrent parent changes retain every action and refuse stale resumption',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openSeededTestWorkSession(await harness.open());
      addTearDown(work.dispose);
      final pending = await seedActions(work);
      final recovery = recoveryFor(work);
      final selected = await recovery.list();
      expect(
        await work.update(pending.copyWith(jobNotes: 'Concurrent change')),
        isTrue,
      );
      final entries = await recovery.list();
      expect(entries, hasLength(5));
      for (final entry in entries) {
        expect(entry.preview.availability, DraftRecoveryAvailability.conflict);
      }
      for (final entry in selected) {
        await expectLater(recovery.resume(entry), throwsStateError);
      }
      expect(await recovery.list(), hasLength(5));
    },
  );
}
