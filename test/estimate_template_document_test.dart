import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_template_document.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_template.dart';

void main() {
  test(
    'template preview leaves unfinished and invalid draft input untouched',
    () {
      final input = EstimateDraftInput(
        creatorId: 'owner',
        number: 'EST-1',
        baseStorageRevision: 0,
        title: 'Shelf',
        discount: 'unfinished',
        tax: '1.',
        terms: 'Terms',
        client: 'Customer',
        pricing: WorkPricingModel.flatRate,
        template: 'plumbing-v1',
        createdOn: DateTime(2026, 9, 24),
        items: const [],
        baseRecord: null,
        estimateId: 'estimate',
        scope: '',
        expiresOn: DateTime(2026, 10, 24),
        followUpOn: null,
        proposedServiceOn: null,
        pendingLineItems: {'material': WorkItemsDraftInput(items: [])},
        pendingPhotos: null,
        sitePhotos: const [],
      );
      final before = input.toPayload().toString();
      final document = estimateTemplateDocument(input, demoWorkCompany);
      expect(document.draft, isTrue);
      expect(
        document.description,
        contains('unfinished entries are not included'),
      );
      expect(input.toPayload().toString(), before);
      expect(input.pendingLineItems, isNotEmpty);
    },
  );
  test(
    'catalog keeps first two and resolves retired IDs without offering them',
    () {
      expect(DocumentTemplate.catalog.take(2).map((t) => t.id), [
        'print-v1',
        'print-v1|landscape',
      ]);
      expect(
        DocumentTemplate.catalog.any((t) => t.id == 'plumbing-v1'),
        isFalse,
      );
      expect(DocumentTemplate.resolve('plumbing-v1').id, 'plumbing-v1');
      expect(
        DocumentTemplate.resolve('plumbing-v1|landscape').landscape,
        isTrue,
      );
      expect(
        DocumentTemplate.catalog.map((t) => t.id).toSet().length,
        DocumentTemplate.catalog.length,
      );
    },
  );
}
