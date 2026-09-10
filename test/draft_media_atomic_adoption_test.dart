import 'package:ui_lab_2_1/src/data/work/estimate_draft_media_commit.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_attachment_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/media_picker_result_retention.dart';

void main() {
  test(
    'estimate raw input and media acknowledgment roll back together and retry once',
    () async {
      final root = await Directory.systemTemp.createTemp('draft-media-');
      var persistence = await LocalPersistence.open(directory: root);
      DraftAutosaveSession makeSession() => DraftAutosaveSession(
        store: persistence.drafts,
        organizationId: 'org',
        domain: 'work/estimate-editor',
        draftId: 'estimate-input',
        ownerId: 'owner',
      );
      var session = makeSession();
      try {
        await session.initialize();
        session.replaceInput({
          'title': 'Unfinished estimate',
          'amount': '7.',
          'photoEditor': null,
        });
        await session.flush();
        final original = session.input;
        final revision = session.savedRevision;
        final requests = LocalMediaPickerRequestStore(persistence.database);
        final pending = await requests.begin(
          organizationId: 'org',
          ownerId: 'owner',
          destination: MediaPickerDestination.estimate,
          targetId: session.draftId,
          targetRevision: revision,
          source: MediaPickerSource.camera,
        );
        final file = File('${root.path}/camera.png');
        await file.writeAsBytes([1, 2, 3, 4]);
        await requests.recordReturnedFiles(
          request: pending,
          organizationId: 'org',
          ownerId: 'owner',
          files: [
            MediaPickerReturnedFile(path: file.path, name: 'Site original.png'),
          ],
        );
        final retained =
            await MediaPickerResultRetention(
              requests: requests,
              attachments: LocalAttachmentStore(persistence.database),
            ).retain(
              requestId: pending.requestId,
              organizationId: 'org',
              ownerId: 'owner',
            );
        final foreign = DraftAutosaveSession(
          store: persistence.drafts,
          organizationId: 'org',
          domain: 'work/estimate-editor',
          draftId: session.draftId,
          ownerId: 'other',
        );
        await foreign.initialize();
        expect(
          () => foreign.adoptMediaInput(request: retained, input: original),
          throwsA(isA<LocalRecordConflict>()),
        );
        await foreign.close();
        final incoming = {
          ...original,
          'photoEditor': {
            'photos': retained.retainedAttachmentIds,
            'pendingNotes': <String, String>{},
          },
        };
        await persistence.database.customStatement(
          "CREATE TRIGGER fail_media_draft_ack BEFORE DELETE ON local_metadata WHEN OLD.metadata_key = 'native.image-picker.request.v1' BEGIN SELECT RAISE(ABORT, 'injected acknowledgment failure'); END",
        );
        await expectLater(
          session.adoptMediaInput(request: retained, input: incoming),
          throwsA(isA<Exception>()),
        );
        expect(session.input, original);
        expect(session.savedRevision, revision);
        expect(session.state, DraftSaveState.savedLocally);
        final row = (await persistence.drafts.find(
          organizationId: 'org',
          domain: session.domain,
          draftId: session.draftId,
          ownerId: 'owner',
        ))!;
        expect(persistence.drafts.decode(row), original);
        expect(row.revision, revision);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'owner'),
          isNotNull,
        );
        await persistence.database.customStatement(
          'DROP TRIGGER fail_media_draft_ack',
        );
        await expectLater(
          session.adoptMediaInput(
            request: retained,
            input: incoming,
            validateBeforeCommit: () async {
              throw StateError('Current permission denied');
            },
          ),
          throwsStateError,
        );
        expect(session.input, original);
        expect(session.savedRevision, revision);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'owner'),
          isNotNull,
        );
        final adoption = session.adoptMediaInput(
          request: retained,
          input: incoming,
        );
        expect(session.isCommittingInput, isTrue);
        expect(
          () => session.replaceInput({'title': 'stale UI overwrite'}),
          throwsStateError,
        );
        await expectLater(session.discard(), throwsStateError);
        incoming['title'] = 'caller changed its map';
        await adoption;
        expect(session.input['title'], 'Unfinished estimate');
        expect(session.input['amount'], '7.');
        expect(session.savedRevision, revision + 1);
        expect(
          await requests.findFor(organizationId: 'org', ownerId: 'owner'),
          isNull,
        );
        await expectLater(
          session.adoptMediaInput(request: retained, input: incoming),
          throwsA(isA<LocalRecordConflict>()),
        );
        await session.close();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: root);
        session = makeSession();
        await session.initialize();
        expect(session.input['title'], 'Unfinished estimate');
        expect(session.input['amount'], '7.');
        expect(
          (session.input['photoEditor'] as Map)['photos'],
          retained.retainedAttachmentIds,
        );
        expect(session.savedRevision, revision + 1);
        // The normal queue continues from the committed adoption revision.
        session.replaceInput({...session.input, 'title': 'Continued estimate'});
        await session.flush();
        expect(session.savedRevision, revision + 2);
        final second = await LocalMediaPickerRequestStore(persistence.database)
            .begin(
              organizationId: 'org',
              ownerId: 'owner',
              destination: MediaPickerDestination.estimate,
              targetId: session.draftId,
              targetRevision: session.savedRevision,
              source: MediaPickerSource.library,
            );
        final secondRetained =
            await LocalMediaPickerRequestStore(
              persistence.database,
            ).retainResults(
              request: second,
              organizationId: 'org',
              ownerId: 'owner',
              attachmentIds: retained.retainedAttachmentIds!,
            );
        final otherEditor = makeSession();
        await otherEditor.initialize();
        otherEditor.replaceInput({
          ...otherEditor.input,
          'title': 'Newer editor input',
        });
        await otherEditor.flush();
        await expectLater(
          session.adoptMediaInput(
            request: secondRetained,
            input: {...session.input, 'title': 'Stale adoption'},
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(session.input['title'], 'Continued estimate');
        final latest = (await persistence.drafts.find(
          organizationId: 'org',
          domain: session.domain,
          draftId: session.draftId,
          ownerId: 'owner',
        ))!;
        expect(
          persistence.drafts.decode(latest)['title'],
          'Newer editor input',
        );
        expect(
          await LocalMediaPickerRequestStore(
            persistence.database,
          ).findFor(organizationId: 'org', ownerId: 'owner'),
          isNotNull,
        );
        await otherEditor.close();
      } finally {
        await session.close();
        await persistence.close();
        await root.delete(recursive: true);
      }
    },
  );
}
