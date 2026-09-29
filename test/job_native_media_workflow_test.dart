import 'dart:convert';
import 'package:ui_lab_2_1/src/data/work/job_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/job_material_permissions.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';
import 'package:ui_lab_2_1/src/data/work/job_photos_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_photo_media_adoption.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_photo_media_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/fake_native_media_gateway.dart';

void main() {
  for (final interrupted in [false, true]) {
    test(
      'job photo ${interrupted ? "restart recovery" : "capture"} commits once and rejects unauthorized writes',
      () async {
        final harness = await DatabaseHarness.create();
        addTearDown(harness.dispose);
        final db = await harness.open();
        final work = await openUiLabWorkSession(db);
        addTearDown(work.dispose);
        final job = WorkRecord(
          id: 'photo-job',
          kind: WorkRecordKind.job,
          number: 'JOB-1',
          title: 'Window cleaning',
          client: 'Client',
          detail: 'Clean windows',
          createdByEmployeeId: work.permissions.actorEmployeeId,
          pricing: WorkPricingModel.flatRate,
          total: 200,
        );
        expect(await work.create(job), isTrue);
        var form = await work.openJobPhotosDraft(job.id);
        form.updateInput(form.input);
        await form.session.flush();
        final source = File('${harness.directory.path}/source.png');
        await source.writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOIqpgGRAwQCgAmfgWhCo6K7AAAAABJRU5ErkJggg==',
          ),
        );
        final returned = MediaPickerReturnedFile(
          path: source.path,
          name: 'Window condition.png',
        );
        final gateway = FakeNativeMediaGateway()
          ..onPick = () async {
            if (interrupted) throw StateError('Simulated process interruption');
            return [returned];
          };
        final adoption = WorkPhotoMediaAdoption.job(
          work.repository,
          work.permissions,
        );
        final coordinator = NativeMediaPickerCoordinator(
          requests: LocalMediaPickerRequestStore(db),
          retention: MediaPickerResultRetention(
            requests: LocalMediaPickerRequestStore(db),
            attachments: LocalAttachmentStore(db),
          ),
          gateway: gateway,
          authorize: adoption.authorize,
        );
        var media = work.jobPhotoMediaWorkflow(
          draft: form.session,
          coordinator: coordinator,
        );
        if (interrupted) {
          await expectLater(
            media.pick(MediaPickerSource.camera),
            throwsStateError,
          );
          await form.session.close();
          final recovery = JobActionDraftRecovery(
            work,
            materialPermissions: () =>
                const JobWorkspacePermissions.development(),
          );
          final entry = (await recovery.list()).single;
          expect(entry.domain, 'work/job-photos');
          form =
              ((await recovery.resume(entry)) as ResumedJobPhotos).controller;
          media = work.jobPhotoMediaWorkflow(
            draft: form.session,
            coordinator: coordinator,
          );
          expect(await media.pendingSelection(), isNotNull);
          gateway.lost = [returned];
          expect((await media.recover())!.photos.length, 1);
        } else {
          expect(
            (await media.pick(MediaPickerSource.library))!.photos.length,
            1,
          );
        }
        final photo = form.input.photos.photos.single;
        expect(photo.path, isNot(source.path));
        expect(
          await File(photo.path).readAsBytes(),
          await source.readAsBytes(),
        );
        expect(work.records.single.sitePhotos, isEmpty);
        expect(await media.pendingSelection(), isNull);
        final denied = await WorkPersistenceSession.open(
          work.repository,
          WorkSessionPermissions(
            organizationId: work.permissions.organizationId,
            actorEmployeeId: work.permissions.actorEmployeeId,
            permissionRevision: 'no-photos',
            visibleCreatorIds: work.permissions.visibleCreatorIds,
            editableKinds: {WorkRecordKind.job},
            canManageOtherCreators: true,
          ),
        );
        addTearDown(denied.dispose);
        await expectLater(denied.openJobPhotosDraft(job.id), throwsStateError);
        final proposed = decodeWorkRecord({
          ...encodeWorkRecord(job),
          'sitePhotos': form.input.toPayload()['photoEditor'] is Map
              ? (form.input.toPayload()['photoEditor'] as Map)['photos']
              : [],
        });
        expect(await denied.update(proposed), isFalse);
        await db.customStatement(
          "CREATE TRIGGER fail_photo BEFORE UPDATE ON local_records BEGIN SELECT RAISE(ABORT, 'injected photo failure'); END",
        );
        expect(await form.confirm(), isNull);
        expect(form.input.photos.photos.length, 1);
        expect(work.records.single.sitePhotos, isEmpty);
        await db.customStatement('DROP TRIGGER fail_photo');
        expect(await form.confirm(), isNotNull, reason: work.failureMessage);
        await form.session.close();
        final reopened = await openUiLabWorkSession(await harness.open());
        addTearDown(reopened.dispose);
        expect(reopened.records.single.sitePhotos.single.path, photo.path);
        expect(await File(photo.path).exists(), isTrue);
        expect(await source.exists(), isTrue);
      },
    );
  }
}
