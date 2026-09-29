import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_approval_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  for (final scenario in [
    'valid',
    'missing',
    'foreign',
    'altered',
    'duplicate',
  ]) {
    test('approval attachment $scenario is checked before commit', () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final work = await openSeededTestWorkSession(db);
      addTearDown(work.dispose);
      final base = work.records.firstWhere((r) => r.id == 'est-1040');
      final before = work.storageRevisionFor(base.id);
      final source = File('${harness.directory.path}/approval.eml');
      await source.writeAsString('Customer approval for shelf installation');
      final retained = await LocalAttachmentStore(db).retain(
        source: source,
        organizationId: work.permissions.organizationId,
        ownerId: scenario == 'foreign'
            ? 'different-actor'
            : work.permissions.actorEmployeeId,
      );
      final evidence = WorkApprovalEvidence(
        attachmentId: scenario == 'missing'
            ? 'attachment-deadbeef'
            : retained.uri.pathSegments.last.replaceAll('.image', ''),
        name: 'approval.eml',
      );
      if (scenario == 'altered') await retained.writeAsString('Changed bytes');
      var draft = await work.openEstimateApprovalDraft(base.id);
      draft.updateInput(
        EstimateApprovalInput(
          base: base,
          baseRevision: before,
          name: 'Morgan Customer',
          method: CustomerApprovalMethod.email,
          accepted: true,
          evidence: [evidence, if (scenario == 'duplicate') evidence],
        ),
      );
      await draft.session.flush();
      await draft.session.close();
      draft = await work.openEstimateApprovalDraft(base.id);
      expect(draft.input.evidence.first.toJson(), evidence.toJson());
      final result = await draft.confirm();
      if (scenario == 'valid') {
        expect(result, isNotNull);
        expect(
          result!.customerApprovals.last.evidence.single.toJson(),
          evidence.toJson(),
        );
        expect(work.storageRevisionFor(base.id), before + 1);
      } else {
        expect(result, isNull);
        expect(work.storageRevisionFor(base.id), before);
        expect(draft.input.evidence, isNotEmpty);
      }
      expect(await source.exists(), isTrue);
      await draft.session.close();
    });
  }
  test(
    'legacy approvals decode without evidence and invalid paths are rejected',
    () {
      final legacy = WorkCustomerApproval(
        method: CustomerApprovalMethod.verbal,
        customerName: 'Customer',
        recordedByEmployeeId: 'owner',
        recordedOn: DateTime.utc(2026),
        revision: 1,
      );
      expect(WorkCustomerApproval.fromJson(legacy.toJson()).evidence, isEmpty);
      expect(
        () => WorkApprovalEvidence.fromJson({
          'attachmentId': '/private/file',
          'name': 'approval',
        }),
        throwsFormatException,
      );
      expect(
        () => WorkApprovalEvidence.fromJson({
          'attachmentId': 'attachment-abcd',
          'name': '../approval',
        }),
        throwsFormatException,
      );
    },
  );
}
