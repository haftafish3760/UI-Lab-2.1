import 'package:ui_lab_2_1/src/data/work/estimate_photos_draft_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';

import 'support/storage/database_harness.dart';

EstimateDraftInput inputFor(
  String actor, {
  WorkRecord? base,
  bool pending = false,
}) => EstimateDraftInput(
  creatorId: actor,
  number: 'EST-WORKFLOW',
  baseStorageRevision: base == null ? 0 : 1,
  title: base == null ? '' : 'Changed title',
  discount: '0.',
  tax: '',
  terms: '',
  client: base == null ? null : 'Customer',
  pricing: WorkPricingModel.flatRate,
  template: 'Service standard',
  createdOn: DateTime(2026, 9, 9),
  items: const [],
  baseRecord: base,
  estimateId: 'workflow-estimate',
  scope: base == null ? '' : 'Scope',
  expiresOn: DateTime(2026, 10, 9),
  followUpOn: null,
  proposedServiceOn: null,
  pendingLineItems: const {},
  pendingPhotos: pending
      ? EstimatePhotosDraftInput(
          photos: [],
          pendingNotes: {'photo': 'Half-written note'},
        )
      : null,
  sitePhotos: const [],
);

void main() {
  test(
    'approved estimate recovery preserves photo input and atomically revises approval',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      final actor = work.permissions.actorEmployeeId;
      final base = WorkRecord(
        id: 'workflow-estimate',
        kind: WorkRecordKind.estimate,
        createdByEmployeeId: actor,
        number: 'EST-WORKFLOW',
        title: 'Original title',
        client: 'Customer',
        detail: 'Scope',
        pricing: WorkPricingModel.flatRate,
        estimateStage: EstimateStage.approved,
        customerSignature: WorkCustomerSignature(
          signedBy: 'Customer',
          signedOn: DateTime(2026, 9, 9),
          signedRevision: 1,
        ),
      );
      expect(await work.create(base), isTrue);
      var controller = await work.openEstimateDraft(
        creatorId: actor,
        existingRecordId: base.id,
      );
      final draftId = controller.session.draftId;
      controller.updateInput(inputFor(actor, base: base, pending: true));
      await expectLater(
        controller.confirm(),
        throwsA(isA<EstimateInputValidation>()),
      );
      await controller.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      addTearDown(work.dispose);
      controller = await work.openEstimateDraft(
        creatorId: actor,
        existingRecordId: base.id,
      );
      expect(controller.session.draftId, draftId);
      expect(
        controller.recoveredInput!.pendingPhotos!.pendingNotes['photo'],
        'Half-written note',
      );
      expect(controller.recoveredInput!.discount, '0.');
      controller.updateInput(inputFor(actor, base: base));
      await database.customStatement(
        "CREATE TRIGGER reject_estimate BEFORE UPDATE ON local_records WHEN NEW.record_id = 'workflow-estimate' BEGIN SELECT RAISE(ABORT, 'injected failure'); END",
      );
      expect(await controller.confirm(), isNull);
      expect(
        work.records
            .singleWhere((r) => r.id == base.id)
            .hasCurrentCustomerSignature,
        isTrue,
      );
      expect(controller.recoveredInput!.title, 'Changed title');
      await database.customStatement('DROP TRIGGER reject_estimate');
      final saved = await controller.confirm();
      expect(saved!.revision, 2);
      expect(saved.resolvedEstimateStage, EstimateStage.readyToSend);
      expect(saved.hasCurrentCustomerSignature, isFalse);
      expect(saved.estimateRevisionHistory, hasLength(1));
      expect(work.storageRevisionFor(base.id), 2);
      await expectLater(controller.confirm(), throwsStateError);
      expect(
        await work.drafts.find(
          organizationId: work.permissions.organizationId,
          ownerId: actor,
          domain: 'work/estimate-editor',
          draftId: draftId,
        ),
        isNull,
      );
      await controller.session.close();
    },
  );

  test(
    'incomplete estimate can still be explicitly confirmed as a draft',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final work = await openUiLabWorkSession(await harness.open());
      addTearDown(work.dispose);
      final actor = work.permissions.actorEmployeeId;
      final controller = await work.openEstimateDraft(creatorId: actor);
      controller.updateInput(inputFor(actor));
      final saved = await controller.confirm();
      expect(saved!.title, 'Untitled estimate');
      expect(saved.client, 'Client not selected');
      expect(saved.detail, 'Proposed work not entered yet.');
      expect(saved.resolvedEstimateStage, EstimateStage.draft);
      await controller.session.close();
      await expectLater(
        work.openEstimateDraft(creatorId: actor, recoveryDraftId: 'missing'),
        throwsStateError,
      );
      await expectLater(
        work.openEstimateDraft(creatorId: 'unauthorized'),
        throwsStateError,
      );
      expect(
        () => work.estimateDraftRecovery('unauthorized'),
        throwsStateError,
      );
    },
  );
}
