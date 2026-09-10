import 'dart:io';
import 'package:ui_lab_2_1/src/data/work/estimate_photo_media_workflow.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_media_adoption.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_detail_codec.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'support/storage/database_harness.dart';

class _UnusedGateway extends Fake implements NativeMediaPickerGateway {}

void main() {
  for (final editingExisting in [false, true]) {
    test(
      'authorized media adoption preserves unfinished ${editingExisting ? "existing" : "new"} estimate and notes',
      () async {
        final harness = await DatabaseHarness.create();
        var database = await harness.open();
        final work = await openUiLabWorkSession(database);
        final permissions = work.permissions;
        final base = work.records.firstWhere(
          (record) => record.kind == WorkRecordKind.estimate,
        );
        final savedWorkBefore = canonicalJson(
          (await work.repository.query(
            organizationId: permissions.organizationId,
            visibleCreatorIds: permissions.visibleCreatorIds,
          )).map((item) => encodeWorkRecord(item.record)).toList(),
        );
        DraftAutosaveSession makeDraft() => DraftAutosaveSession(
          store: LocalDraftStore(database),
          organizationId: permissions.organizationId,
          domain: EstimateMediaAdoption.draftDomain,
          draftId: 'photo-input',
          ownerId: permissions.actorEmployeeId,
        );
        var draft = makeDraft();
        try {
          await draft.initialize();
          draft.replaceInput({
            'baseRecord': editingExisting ? encodeWorkRecord(base) : null,
            'baseStorageRevision': editingExisting
                ? work.storageRevisionFor(base.id)
                : 0,
            'estimateId': editingExisting ? base.id : 'new-estimate',
            'creatorId': editingExisting
                ? base.createdByEmployeeId
                : permissions.actorEmployeeId,
            'title': 'Unfinished estimate',
            'discount': '7.',
            'sitePhotos': [],
            'photoEditor': {
              'photos': [
                encodeWorkSitePhoto(
                  WorkSitePhoto(
                    id: 'prior-photo',
                    path: '${harness.directory.path}/prior.png',
                    name: 'Prior photo',
                    source: WorkSitePhotoSource.file,
                    addedOn: DateTime(2030),
                    note: 'Saved note',
                  ),
                ),
              ],
              'pendingNotes': {'prior-photo': 'unfinished note...'},
            },
          });
          await draft.flush();
          final before = draft.input;
          final requests = LocalMediaPickerRequestStore(database);
          final pending = await requests.begin(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            destination: MediaPickerDestination.estimate,
            targetId: draft.draftId,
            targetRevision: draft.savedRevision,
            source: MediaPickerSource.camera,
          );
          final source = File('${harness.directory.path}/camera.png');
          await source.writeAsBytes([1, 2, 3, 4, 5]);
          await requests.recordReturnedFiles(
            request: pending,
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            files: [
              MediaPickerReturnedFile(
                path: source.path,
                name: 'Original job site.png',
              ),
            ],
          );
          final retained =
              await MediaPickerResultRetention(
                requests: requests,
                attachments: LocalAttachmentStore(database),
              ).retain(
                requestId: pending.requestId,
                organizationId: permissions.organizationId,
                ownerId: permissions.actorEmployeeId,
              );
          final denied = EstimateMediaAdoption(
            work.repository,
            WorkSessionPermissions(
              organizationId: permissions.organizationId,
              actorEmployeeId: permissions.actorEmployeeId,
              permissionRevision: 'denied',
              visibleCreatorIds: permissions.visibleCreatorIds,
              editableKinds: {},
            ),
          );
          await expectLater(
            denied.adopt(request: retained, draft: draft),
            throwsStateError,
          );
          expect(draft.input, before);
          expect(
            await requests.findFor(
              organizationId: permissions.organizationId,
              ownerId: permissions.actorEmployeeId,
            ),
            isNotNull,
          );
          final service = EstimateMediaAdoption(work.repository, permissions);
          await source.delete();
          final coordinator = NativeMediaPickerCoordinator(
            requests: requests,
            retention: MediaPickerResultRetention(
              requests: requests,
              attachments: LocalAttachmentStore(database),
            ),
            gateway: _UnusedGateway(),
            authorize: service.authorize,
          );
          final workflow = work.photoMediaWorkflow(
            draft: draft,
            coordinator: coordinator,
          );
          final selection = (await workflow.pendingSelection())!;
          expect(selection.source, MediaPickerSource.camera);
          expect(selection.requiresFileReselection, isFalse);
          final otherDraft = DraftAutosaveSession(
            store: LocalDraftStore(database),
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            domain: EstimateMediaAdoption.draftDomain,
            draftId: 'other-estimate',
          );
          final otherWorkflow = work.photoMediaWorkflow(
            draft: otherDraft,
            coordinator: coordinator,
          );
          expect(await otherWorkflow.pendingSelection(), isNull);
          await expectLater(otherWorkflow.discard(selection), throwsStateError);
          final editor = (await workflow.recover())!;
          expect(editor.pendingNotes, {'prior-photo': 'unfinished note...'});
          final photos = editor.photos;
          expect(photos.map((photo) => photo.name), [
            'Prior photo',
            'Original job site.png',
          ]);
          expect(photos.first.note, 'Saved note');
          expect(photos.last.source, WorkSitePhotoSource.camera);
          expect(await File(photos.last.path).readAsBytes(), [1, 2, 3, 4, 5]);
          expect(draft.input['discount'], '7.');
          expect(draft.input['sitePhotos'], isEmpty);
          expect(draft.input['photoEditor'], editor.toPayload());
          expect(
            await requests.findFor(
              organizationId: permissions.organizationId,
              ownerId: permissions.actorEmployeeId,
            ),
            isNull,
          );
          expect(
            canonicalJson(
              (await work.repository.query(
                organizationId: permissions.organizationId,
                visibleCreatorIds: permissions.visibleCreatorIds,
              )).map((item) => encodeWorkRecord(item.record)).toList(),
            ),
            savedWorkBefore,
          );
          await expectLater(
            service.adopt(request: retained, draft: draft),
            throwsA(isA<LocalRecordConflict>()),
          );
          await draft.close();
          await harness.close(database);
          database = await harness.open();
          draft = makeDraft();
          await draft.initialize();
          expect(draft.input['photoEditor'], editor.toPayload());
          expect(draft.input['discount'], '7.');
          if (editingExisting) {
            final repository = SqliteWorkRepository(database);
            await repository.commit(
              organizationId: permissions.organizationId,
              commandId: 'concurrent-work-change',
              actorEmployeeId: permissions.actorEmployeeId,
              permissionRevision: permissions.permissionRevision,
              occurredAt: DateTime.now(),
              mutations: [
                WorkRecordMutation(
                  record: base.copyWith(jobNotes: 'Updated notes'),
                  expectedStorageRevision: work.storageRevisionFor(base.id),
                ),
              ],
            );
            await expectLater(
              EstimateMediaAdoption(repository, permissions).authorize(
                organizationId: permissions.organizationId,
                ownerId: permissions.actorEmployeeId,
                destination: MediaPickerDestination.estimate,
                targetId: draft.draftId,
                targetRevision: draft.savedRevision,
              ),
              throwsA(isA<LocalRecordConflict>()),
            );
            expect(draft.input['photoEditor'], editor.toPayload());
          }
        } finally {
          await draft.close();
          work.dispose();
          await harness.dispose();
        }
      },
    );
  }
}
