import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'support/storage/database_harness.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_record_revision.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';

EstimateDraftInput input(WorkDocumentPresentation presentation) =>
    EstimateDraftInput(
      creatorId: 'alex',
      number: 'E-1',
      baseStorageRevision: 0,
      title: 'Repair',
      discount: '',
      tax: '',
      terms: '',
      client: 'Customer',
      pricing: WorkPricingModel.timeAndMaterials,
      documentPresentation: presentation,
      template: 'Service standard',
      createdOn: DateTime(2026, 9, 28),
      items: const [
        WorkLineItem(
          id: 'material',
          type: WorkLineItemType.material,
          name: '2 x 4 lumber',
          description: 'Framing timber',
          quantity: 4,
          unit: 'each',
          customerPrice: 10,
          internalUnitCost: 6,
        ),
      ],
      baseRecord: null,
      estimateId: 'e1',
      scope: 'Repair framing',
      expiresOn: DateTime(2027),
      followUpOn: null,
      proposedServiceOn: null,
      pendingLineItems: const {},
      pendingPhotos: null,
      sitePhotos: const [],
    );

void main() {
  test(
    'summary choice and internal items survive draft recovery and database reopen',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      var draft = await work.openEstimateDraft(creatorId: 'alex');
      final draftId = draft.session.draftId;
      draft.updateInput(input(WorkDocumentPresentation.summary));
      await draft.session.flush();
      await draft.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      draft = await work.openEstimateDraft(
        creatorId: 'alex',
        recoveryDraftId: draftId,
      );
      expect(
        draft.recoveredInput!.documentPresentation,
        WorkDocumentPresentation.summary,
      );
      final saved = await draft.confirm();
      expect(saved, isNotNull);
      await draft.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      final reopened = work.records.singleWhere((r) => r.id == saved!.id);
      expect(reopened.documentPresentation, WorkDocumentPresentation.summary);
      expect(reopened.items.single.name, '2 x 4 lumber');
      expect(reopened.items.single.internalUnitCost, 6);
      expect(reopened.total, 40);
      work.dispose();
    },
  );
  test(
    'presentation survives draft and record codecs without changing pricing or items',
    () {
      for (final presentation in WorkDocumentPresentation.values) {
        final recovered = EstimateDraftInput.fromPayload(
          input(presentation).toPayload(),
        );
        expect(recovered.documentPresentation, presentation);
        final saved = decodeWorkRecord(
          encodeWorkRecord(
            buildConfirmedEstimate(recovered, now: DateTime(2026, 9, 28)),
          ),
        );
        expect(saved.documentPresentation, presentation);
        expect(saved.pricing, WorkPricingModel.timeAndMaterials);
        expect(saved.items.single.description, 'Framing timber');
        expect(saved.items.single.internalUnitCost, 6);
        expect(saved.total, 40);
        expect(
          saved.copyWith(jobNotes: 'Private note').documentPresentation,
          presentation,
        );
        expect(
          saved.withEstimateStage(
            EstimateStage.awaitingCustomer,
            DateTime(2026),
          ),
          isNotNull,
        );
      }
    },
  );

  test(
    'legacy payloads remain detailed; unknown presentation fails instead of silently exposing items',
    () {
      final raw = input(WorkDocumentPresentation.detailed).toPayload()
        ..remove('documentPresentation');
      expect(
        EstimateDraftInput.fromPayload(raw).documentPresentation,
        WorkDocumentPresentation.detailed,
      );
      final record = encodeWorkRecord(
        buildConfirmedEstimate(
          input(WorkDocumentPresentation.detailed),
          now: DateTime(2026),
        ),
      )..remove('documentPresentation');
      expect(
        decodeWorkRecord(record).documentPresentation,
        WorkDocumentPresentation.detailed,
      );
      record['documentPresentation'] = 'future-private-style';
      expect(() => decodeWorkRecord(record), throwsArgumentError);
    },
  );

  test(
    'style-only revision invalidates customer and company approval and retains costs',
    () {
      final base = buildConfirmedEstimate(
        input(WorkDocumentPresentation.detailed),
        now: DateTime(2026, 9, 28),
      );
      final approved = decodeWorkRecord({
        ...encodeWorkRecord(base),
        'estimateStage': 'approved',
        'requiresCompanyReview': true,
        'estimateCompanyReviewStatus': 'approved',
        'customerSignature': {
          'signedBy': 'Customer',
          'signedOn': '2026-09-28T12:00:00.000',
          'signedRevision': 1,
        },
      });
      final revised = approved.reviseEstimate(
        title: approved.title,
        client: approved.client,
        scope: approved.detail,
        pricing: approved.pricing,
        items: approved.items,
        documentPresentation: WorkDocumentPresentation.summary,
        template: approved.template,
        terms: approved.terms,
        discount: approved.discount,
        tax: approved.tax,
        dates: approved.estimateDates!,
        changedOn: DateTime(2026, 9, 29),
      );
      expect(revised.revision, approved.revision + 1);
      expect(revised.hasCurrentCustomerSignature, isFalse);
      expect(
        revised.estimateCompanyReviewStatus,
        EstimateCompanyReviewStatus.changesRequested,
      );
      expect(revised.documentPresentation, WorkDocumentPresentation.summary);
      expect(revised.total, approved.total);
      expect(revised.items.single.internalUnitCost, 6);
      expect(
        revised
            .withEstimateStage(
              EstimateStage.awaitingCustomer,
              DateTime(2026, 9, 30),
            )
            .documentPresentation,
        WorkDocumentPresentation.summary,
      );
      expect(
        revised.reviseItems([
          ...revised.items,
          revised.items.single,
        ], changedOn: DateTime(2026, 10)).documentPresentation,
        WorkDocumentPresentation.summary,
      );
    },
  );
}
