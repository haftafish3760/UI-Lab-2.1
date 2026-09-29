import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_document_export_authorization.dart';
import 'package:ui_lab_2_1/src/data/work/work_primary_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'support/storage/database_harness.dart';

EstimateDraftInput quoteInput(
  String actor, {
  String id = 'quote-1',
  String number = 'Quote 1',
  WorkRecordKind kind = WorkRecordKind.quote,
  WorkPricingModel pricing = WorkPricingModel.flatRate,
}) => EstimateDraftInput(
  documentKind: kind,
  creatorId: actor,
  number: number,
  baseStorageRevision: 0,
  title: 'Replace kitchen tap',
  discount: '',
  tax: '',
  terms: 'Fixed price for the work described.',
  client: 'Jamie Morgan',
  pricing: pricing,
  template: 'Service standard',
  createdOn: DateTime(2026, 9, 28),
  items: const [],
  servicePrice: '245.00',
  baseRecord: null,
  estimateId: id,
  scope: 'Supply and install a kitchen mixer tap.',
  expiresOn: DateTime(2026, 10, 28),
  followUpOn: null,
  proposedServiceOn: null,
  pendingLineItems: const {},
  pendingPhotos: null,
  sitePhotos: const [],
);

void main() {
  test(
    'quote recovery survives restart and saves with its own number claim',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var work = await openUiLabWorkSession(db);
      final actor = work.permissions.actorEmployeeId;
      var controller = await work.openEstimateDraft(
        documentKind: WorkRecordKind.quote,
        creatorId: actor,
      );
      final draftId = controller.session.draftId;
      controller.updateInput(quoteInput(actor));
      await controller.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      work = await openUiLabWorkSession(db);
      final entries = await WorkPrimaryDraftRecovery(work).list();
      expect(entries.single.domain, 'work/quote-editor');
      controller = await work.openEstimateDraft(
        documentKind: WorkRecordKind.quote,
        creatorId: actor,
        recoveryDraftId: draftId,
      );
      expect(controller.recoveredInput!.documentKind, WorkRecordKind.quote);
      expect(controller.recoveredInput!.servicePrice, '245.00');
      final quote = await controller.confirm();
      expect(quote!.kind, WorkRecordKind.quote);
      expect(quote.total, 245);
      expect(quote.pricing, WorkPricingModel.flatRate);
      expect(
        decodeWorkRecord(encodeWorkRecord(quote)).kind,
        WorkRecordKind.quote,
      );
      expect(await work.nextDocumentNumber(WorkRecordKind.quote), 'Quote 2');
      expect(
        await work.nextDocumentNumber(WorkRecordKind.estimate),
        'Estimate 1',
      );
      expect(
        await work.nextDocumentNumber(WorkRecordKind.invoice),
        'Invoice 1',
      );
      expect(await WorkPrimaryDraftRecovery(work).list(), isEmpty);
      await controller.session.close();
      work.dispose();
      await harness.close(db);
      db = await harness.open();
      final reopened = await openUiLabWorkSession(db);
      addTearDown(reopened.dispose);
      expect(reopened.records.single.kind, WorkRecordKind.quote);
      expect(reopened.records.single.total, 245);
    },
  );

  test(
    'quote workflow rejects estimate input and preserves recoverable input',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final controller = await work.openEstimateDraft(
        documentKind: WorkRecordKind.quote,
        creatorId: work.permissions.actorEmployeeId,
      );
      controller.updateInput(
        quoteInput(
          work.permissions.actorEmployeeId,
          kind: WorkRecordKind.estimate,
        ),
      );
      await expectLater(controller.confirm(), throwsStateError);
      expect(work.records, isEmpty);
      expect(controller.recoveredInput, isNotNull);
      await controller.session.close();
    },
  );

  test('quote cannot be saved with time and materials pricing', () {
    expect(
      () => buildConfirmedEstimate(
        quoteInput('alex', pricing: WorkPricingModel.timeAndMaterials),
        now: DateTime(2026, 9, 28),
      ),
      throwsA(isA<EstimateInputValidation>()),
    );
  });

  test(
    'existing document kind cannot be rewritten through raw record save',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final input = quoteInput(work.permissions.actorEmployeeId);
      final quote = buildConfirmedEstimate(input, now: DateTime(2026, 9, 28));
      expect(await work.create(quote), isTrue);
      final altered = decodeWorkRecord({
        ...encodeWorkRecord(quote),
        'kind': 'estimate',
      });
      expect(await work.save(records: [altered]), isFalse);
      expect(work.records.single.kind, WorkRecordKind.quote);
      // The saved ready quote can now use the permission-checked delivery flow.
      expect(
        () => requireWorkDocumentExport(quote, work.permissions),
        returnsNormally,
      );
    },
  );
  test(
    'quote grant and supervisor approval requirement are enforced at save',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final owner = await openUiLabWorkSession(await harness.open());
      addTearDown(owner.dispose);
      final actor = owner.permissions.actorEmployeeId;
      WorkSessionPermissions grants(Set<WorkRecordKind> kinds) =>
          WorkSessionPermissions(
            organizationId: owner.permissions.organizationId,
            actorEmployeeId: actor,
            permissionRevision: 'quote-policy-1',
            visibleCreatorIds: {actor},
            editableKinds: kinds,
            requiresQuoteApproval: true,
          );
      final denied = await WorkPersistenceSession.open(
        owner.repository,
        grants({WorkRecordKind.estimate}),
      );
      addTearDown(denied.dispose);
      await expectLater(
        denied.openEstimateDraft(
          documentKind: WorkRecordKind.quote,
          creatorId: actor,
        ),
        throwsStateError,
      );
      final allowed = await WorkPersistenceSession.open(
        owner.repository,
        grants({WorkRecordKind.quote}),
      );
      addTearDown(allowed.dispose);
      final controller = await allowed.openEstimateDraft(
        documentKind: WorkRecordKind.quote,
        creatorId: actor,
      );
      controller.updateInput(quoteInput(actor));
      final saved = await controller.confirm();
      expect(saved, isNotNull);
      expect(saved!.requiresCompanyReview, isTrue);
      expect(
        saved.estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.pending,
      );
      expect(
        await allowed.save(
          records: [saved.copyWith(requiresCompanyReview: false)],
        ),
        isFalse,
      );
      expect(
        await allowed.save(
          records: [
            saved.copyWith(
              estimateCompanyReviewStatus: EstimateCompanyReviewStatus.approved,
            ),
          ],
        ),
        isFalse,
      );
      expect(
        allowed.records.single.estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.pending,
      );
      await controller.session.close();
    },
  );
}
