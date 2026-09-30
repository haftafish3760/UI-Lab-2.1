import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_approval_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_approval_media_adoption.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/startup/application_media_coordinator.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'support/storage/fake_native_media_gateway.dart';

void main() {
  for (final scenario in [
    'reopen',
    'changed-document',
    'cancelled',
    'wrong-kind',
  ]) {
    test(
      'approval picker $scenario preserves job/document and retained proof',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        var db = await harness.open();
        var work = await openSeededTestWorkSession(db);
        final base = work.records.firstWhere(
          (record) => record.id == 'est-1040',
        );
        var draft = await work.openEstimateApprovalDraft(base.id);
        draft.updateInput(
          EstimateApprovalInput(
            base: base,
            baseRevision: work.storageRevisionFor(base.id),
            name: 'Customer',
            method: CustomerApprovalMethod.email,
          ),
        );
        await draft.session.flush();
        final source = File('${harness.directory.path}/message.eml');
        await source.writeAsString(
          'From: customer@example.test\n\nI approve this estimate.',
        );
        final gateway = FakeNativeMediaGateway()
          ..onPick = () async => scenario == 'cancelled'
              ? []
              : [
                  MediaPickerReturnedFile(
                    path: source.path,
                    name: 'message.eml',
                  ),
                ];
        var media = createApplicationMediaCoordinator(
          database: db,
          gateway: gateway,
          receiptPermissions: receiptDraftUiLabOwnerPermissions(),
          work: work,
        );
        final destination = scenario == 'wrong-kind'
            ? MediaPickerDestination.quoteApproval
            : MediaPickerDestination.estimateApproval;
        Future<LocalMediaPickerRequest?> pick() => media.start(
          organizationId: work.permissions.organizationId,
          ownerId: work.permissions.actorEmployeeId,
          destination: destination,
          targetId: draft.session.draftId,
          targetRevision: draft.session.savedRevision,
          source: MediaPickerSource.files,
        );
        if (scenario == 'wrong-kind') {
          await expectLater(pick, throwsA(isA<Exception>()));
          expect(gateway.picks, 0);
        } else {
          var request = await pick();
          if (scenario == 'cancelled') {
            expect(request, isNull);
            expect(draft.input.evidence, isEmpty);
          } else {
            expect(request!.retainedAttachmentIds, hasLength(1));
            if (scenario == 'reopen') {
              await draft.session.close();
              work.dispose();
              await harness.close(db);
              db = await harness.open();
              work = await openSeededTestWorkSession(db);
              draft = await work.openEstimateApprovalDraft(base.id);
              media = createApplicationMediaCoordinator(
                database: db,
                gateway: gateway,
                receiptPermissions: receiptDraftUiLabOwnerPermissions(),
                work: work,
              );
              request = await media.recover(
                organizationId: work.permissions.organizationId,
                ownerId: work.permissions.actorEmployeeId,
              );
            } else {
              expect(
                await work.save(
                  records: [
                    decodeWorkRecord({
                      ...encodeWorkRecord(base),
                      'title': 'Changed scope',
                      'revision': base.revision + 1,
                    }),
                  ],
                ),
                isTrue,
              );
            }
            final adoption = WorkApprovalMediaAdoption(work, destination);
            if (scenario == 'changed-document') {
              await expectLater(
                adoption.adopt(request: request!, draft: draft.session),
                throwsA(isA<Exception>()),
              );
              expect(draft.input.evidence, isEmpty);
              expect(
                await media.requests.findFor(
                  organizationId: work.permissions.organizationId,
                  ownerId: work.permissions.actorEmployeeId,
                ),
                isNotNull,
              );
            } else {
              final input = await adoption.adopt(
                request: request!,
                draft: draft.session,
              );
              expect(input.evidence.single.name, 'message.eml');
              final files = await LocalAttachmentStore(db).verifiedFiles(
                organizationId: work.permissions.organizationId,
                ownerIds: {work.permissions.actorEmployeeId},
                attachmentIds: {input.evidence.single.attachmentId},
              );
              expect(
                await files.single.readAsString(),
                await source.readAsString(),
              );
              expect(
                await media.requests.findFor(
                  organizationId: work.permissions.organizationId,
                  ownerId: work.permissions.actorEmployeeId,
                ),
                isNull,
              );
              expect(
                draft.input.evidence.single.attachmentId,
                input.evidence.single.attachmentId,
              );
            }
          }
        }
        expect(
          work.records
              .firstWhere((r) => r.id == base.id)
              .customerApprovals
              .length,
          base.customerApprovals.length,
        );
        expect(await source.exists(), isTrue);
        await draft.session.close();
        work.dispose();
      },
    );
  }
}
