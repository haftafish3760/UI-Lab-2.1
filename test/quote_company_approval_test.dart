import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_record_revision.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/quote_approval_content.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'support/storage/database_harness.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;

void main() {
  test(
    'quote approval retains actor and content, reloads from storage and invalidates on edit',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final bootstrap = await openUiLabWorkSession(await harness.open());
      addTearDown(bootstrap.dispose);
      final actor = bootstrap.permissions.actorEmployeeId;
      WorkSessionPermissions permissions(bool approve) =>
          WorkSessionPermissions(
            organizationId: bootstrap.permissions.organizationId,
            actorEmployeeId: actor,
            permissionRevision: 'approval-test',
            visibleCreatorIds: {actor},
            editableKinds: {WorkRecordKind.quote},
            requiresQuoteApproval: true,
            canApproveQuotes: approve,
          );
      final work = await WorkPersistenceSession.open(
        bootstrap.repository,
        permissions(true),
      );
      addTearDown(work.dispose);
      final record =
          buildConfirmedEstimate(
            quoteInput(actor),
            now: DateTime.now(),
          ).copyWith(
            requiresCompanyReview: true,
            estimateCompanyReviewStatus: EstimateCompanyReviewStatus.pending,
          );
      expect(await work.create(record), isTrue);
      WorkRecord current() => work.records.single;
      expect(
        await work.recordQuoteApproval(
          current(),
          EstimateCompanyReviewDecision.approved,
        ),
        isFalse,
      );
      expect(
        await work.recordQuoteApproval(
          current(),
          EstimateCompanyReviewDecision.submitted,
        ),
        isTrue,
      );
      final denied = await WorkPersistenceSession.open(
        work.repository,
        permissions(false),
      );
      addTearDown(denied.dispose);
      expect(
        await denied.recordQuoteApproval(
          denied.records.single,
          EstimateCompanyReviewDecision.approved,
        ),
        isFalse,
      );
      expect(
        await work.recordQuoteApproval(
          current(),
          EstimateCompanyReviewDecision.approved,
        ),
        isTrue,
      );
      expect(quoteHasCurrentCompanyApproval(current()), isTrue);
      expect(current().estimateCompanyReviewHistory.last.actor, actor);
      final reopened = await WorkPersistenceSession.open(
        work.repository,
        permissions(true),
      );
      addTearDown(reopened.dispose);
      expect(quoteHasCurrentCompanyApproval(reopened.records.single), isTrue);
      expect(
        await work.update(current().copyWith(estimateCompanyReviewHistory: [])),
        isFalse,
      );
      expect(
        await work.update(
          decodeWorkRecord({...encodeWorkRecord(current()), 'total': '999'}),
        ),
        isFalse,
      );
      expect(
        await work.update(current().copyWith(requiresCompanyReview: false)),
        isFalse,
      );
      final changed = current().reviseEstimate(
        title: 'Tap and isolation valve replacement',
        client: record.client,
        scope: record.detail,
        pricing: record.pricing,
        items: record.items,
        template: record.template,
        terms: record.terms,
        discount: record.discount,
        tax: record.tax,
        dates: record.estimateDates!,
        changedOn: DateTime.now(),
      );
      expect(await work.update(changed), isTrue);
      expect(quoteHasCurrentCompanyApproval(current()), isFalse);
      expect(current().estimateCompanyReviewHistory, hasLength(2));
      expect(
        await work.update(
          current().copyWith(
            estimateCompanyReviewStatus: EstimateCompanyReviewStatus.approved,
          ),
        ),
        isFalse,
      );
      expect(
        await work.recordQuoteApproval(
          current(),
          EstimateCompanyReviewDecision.submitted,
        ),
        isTrue,
      );
      expect(
        await work.recordQuoteApproval(
          current(),
          EstimateCompanyReviewDecision.changesRequested,
        ),
        isFalse,
      );
      expect(
        await work.recordQuoteApproval(
          current(),
          EstimateCompanyReviewDecision.changesRequested,
          note: 'Include disposal of the old tap.',
        ),
        isTrue,
      );
      expect(
        current().estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.changesRequested,
      );
    },
  );

  test(
    'forged actor, changed content and forged decision cannot approve a quote',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final record = buildConfirmedEstimate(
        quoteInput(work.permissions.actorEmployeeId),
        now: DateTime.now(),
      );
      expect(await work.create(record), isTrue);
      expect(
        await work.recordQuoteApproval(
          record,
          EstimateCompanyReviewDecision.submitted,
        ),
        isTrue,
      );
      final pending = work.records.single;
      WorkRecord forged(String actor, {double? total}) =>
          decodeWorkRecord({
            ...encodeWorkRecord(pending),
            if (total != null) 'total': total.toString(),
          }).copyWith(
            requiresCompanyReview: true,
            estimateCompanyReviewStatus: EstimateCompanyReviewStatus.approved,
            estimateCompanyReviewHistory: [
              ...pending.estimateCompanyReviewHistory,
              EstimateCompanyReviewEvent(
                decision: EstimateCompanyReviewDecision.approved,
                actor: actor,
                occurredOn: DateTime.now().toUtc(),
                revision: pending.revision,
                note: '',
                contentFingerprint: quoteApprovalFingerprint(pending),
              ),
            ],
          );
      expect(await work.update(forged('not-the-current-user')), isFalse);
      expect(
        await work.update(forged(work.permissions.actorEmployeeId, total: 999)),
        isFalse,
      );
      expect(
        await work.update(
          pending.copyWith(
            estimateCompanyReviewStatus: EstimateCompanyReviewStatus.approved,
          ),
        ),
        isFalse,
      );
      expect(
        work.records.single.estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.pending,
      );
    },
  );
}
