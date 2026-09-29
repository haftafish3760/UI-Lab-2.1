import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'support/storage/database_harness.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_models.dart';
import 'work_document_presentation_test.dart' as fixtures;

EstimateDraftInput priceInput(String price, {bool detailedItems = false}) =>
    EstimateDraftInput.fromPayload({
      ...fixtures.input(WorkDocumentPresentation.summary).toPayload(),
      if (!detailedItems) 'items': [],
      'servicePrice': price,
    });

void main() {
  test(
    'unfinished service price survives SQLite recovery before confirmation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openUiLabWorkSession(database);
      var draft = await work.openEstimateDraft(creatorId: 'alex');
      final id = draft.session.draftId;
      draft.updateInput(priceInput('245,50'));
      await draft.session.flush();
      await draft.session.close();
      work.dispose();
      await harness.close(database);
      database = await harness.open();
      work = await openUiLabWorkSession(database);
      draft = await work.openEstimateDraft(
        creatorId: 'alex',
        recoveryDraftId: id,
      );
      expect(draft.recoveredInput!.servicePrice, '245,50');
      final record = await draft.confirm();
      expect(record!.total, 245.50);
      expect(record.items.single.type, WorkLineItemType.service);
      await draft.session.close();
      work.dispose();
    },
  );

  test(
    'one price confirms as service, survives codec and job adapter without misclassifying labor',
    () {
      final raw = priceInput('123,45');
      final recovered = EstimateDraftInput.fromPayload(raw.toPayload());
      expect(recovered.servicePrice, '123,45');
      final record = decodeWorkRecord(
        encodeWorkRecord(
          buildConfirmedEstimate(recovered, now: DateTime(2026, 9, 28)),
        ),
      );
      expect(record.total, 123.45);
      expect(record.items.single.type, WorkLineItemType.service);
      expect(record.items.single.quantity, 1);
      expect(record.items.single.name, 'Repair');
      expect(record.items.single.description, 'Repair framing');
      expect(
        JobLineItem.fromWorkLineItem(record.items.single).toWorkLineItem().type,
        WorkLineItemType.service,
      );
    },
  );
  test('simple price cannot overwrite a detailed breakdown', () {
    expect(
      () => buildConfirmedEstimate(
        priceInput('99', detailedItems: true),
        now: DateTime(2026),
      ),
      throwsA(isA<EstimateInputValidation>()),
    );
  });
  test(
    'invalid values remain raw draft input and cannot become confirmed money',
    () {
      for (final raw in ['-1', 'NaN', 'Infinity', '1.001', '1e3', 'abc']) {
        final recovered = EstimateDraftInput.fromPayload(
          priceInput(raw).toPayload(),
        );
        expect(recovered.servicePrice, raw);
        expect(
          () => buildConfirmedEstimate(recovered, now: DateTime(2026)),
          throwsA(isA<EstimateInputValidation>()),
        );
      }
    },
  );
  test(
    'clearing an existing service price does not silently reuse its previous value',
    () {
      final old = buildConfirmedEstimate(priceInput('25'), now: DateTime(2026));
      final cleared = EstimateDraftInput.fromPayload({
        ...priceInput('').toPayload(),
        'items': encodeWorkRecord(old)['items'],
        'baseRecord': encodeWorkRecord(old),
      });
      expect(
        () => buildConfirmedEstimate(cleared, now: DateTime(2026)),
        throwsA(isA<EstimateInputValidation>()),
      );
    },
  );
}
