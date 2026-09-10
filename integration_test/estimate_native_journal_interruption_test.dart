import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/native_device_media_gateway.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_media_adoption.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/startup/application_media_coordinator.dart';

/// Standalone QA APK. Kill after native retention, before the Dart coordinator
/// checkpoints returned paths. Reader must recover without opening any picker.
class _InterruptedGateway extends NativeDeviceMediaGateway {
  _InterruptedGateway(this.runId, this.digestFile);
  final String runId;
  final File digestFile;
  @override
  Future<List<MediaPickerReturnedFile>> pickForRequest(
    LocalMediaPickerRequest request,
  ) async {
    final files = await super.pickForRequest(request);
    if (files.isEmpty) return files;
    expect(files, hasLength(1));
    final bytes = await File(files.single.path).readAsBytes();
    expect(bytes, isNotEmpty);
    if (request.source == MediaPickerSource.library) expect(bytes, _pngBytes());
    await digestFile.writeAsString(
      sha256.convert(bytes).toString(),
      flush: true,
    );
    // ignore: avoid_print
    print('UILAB_NATIVE_REPLAY_READY_$runId');
    await Completer<void>().future;
    return files;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const runId = String.fromEnvironment('STORAGE_INTERRUPTION_RUN');
  const requestedPhase = String.fromEnvironment('STORAGE_INTERRUPTION_PHASE');
  const sourceName = String.fromEnvironment(
    'STORAGE_PICKER_SOURCE',
    defaultValue: 'library',
  );
  testWidgets('estimate native journal interruption: $requestedPhase', (
    tester,
  ) async {
    if (!Platform.isAndroid ||
        !const bool.fromEnvironment('STORAGE_QA') ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(runId) ||
        !['write', 'read', 'activity'].contains(requestedPhase) ||
        (requestedPhase == 'activity' && sourceName != 'camera') ||
        !['library', 'camera'].contains(sourceName)) {
      throw ArgumentError('Requires isolated Android QA run ID and phase.');
    }
    final source = MediaPickerSource.values.byName(sourceName);
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/estimate-journal-$runId');
    // Activity mode uses one unchanged APK across OS process recreation.
    final phase = requestedPhase == 'activity'
        ? (await root.exists() ? 'read' : 'write')
        : requestedPhase;
    if ((await root.exists()) != (phase == 'read')) {
      throw StateError(
        'Write requires a fresh fixture; read requires it intact.',
      );
    }
    final digestFile = File('${root.path}/expected-image-sha256');
    var persistence = await LocalPersistence.open(directory: root);
    var work = await openUiLabWorkSession(persistence.database);
    final permissions = work.permissions;
    final savedRequest = phase == 'read'
        ? await LocalMediaPickerRequestStore(persistence.database).findFor(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          )
        : null;
    if (phase == 'read') {
      expect(savedRequest, isNotNull);
      expect(savedRequest!.returnedFiles, isNull);
      expect(savedRequest.retainedAttachmentIds, isNull);
    }
    final draft = await work.openEstimateDraft(
      creatorId: 'alex',
      recoveryDraftId: savedRequest?.targetId,
    );
    final coordinator = createApplicationMediaCoordinator(
      database: persistence.database,
      gateway: phase == 'write'
          ? _InterruptedGateway(runId, digestFile)
          : NativeDeviceMediaGateway(),
      receiptPermissions: receiptDraftUiLabOwnerPermissions(),
      work: work,
    );
    if (phase == 'write') {
      draft.updateInput(_unfinishedEstimate());
      await draft.session.flush();
      expect(draft.session.savedRevision, 1);
      if (const bool.fromEnvironment('STORAGE_CANCEL_FIRST')) {
        // ignore: avoid_print
        print('UILAB_NATIVE_CANCEL_FIRST_$runId');
        final cancelled = await coordinator.start(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
          destination: MediaPickerDestination.estimate,
          targetId: draft.session.draftId,
          targetRevision: draft.session.savedRevision,
          source: source,
        );
        expect(cancelled, isNull);
        expect(
          await coordinator.requests.findFor(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          ),
          isNull,
        );
        _expectRawInput(draft.recoveredInput!);
        // ignore: avoid_print
        print('UILAB_NATIVE_CANCEL_VERIFIED_$runId');
      }
      // Activity mode: kill the background QA process while camera is open.
      // Other modes: wait for UILAB_NATIVE_REPLAY_READY before force-stop.
      // ignore: avoid_print
      print('UILAB_ESTIMATE_PICKER_START_$runId');
      await coordinator.start(
        organizationId: permissions.organizationId,
        ownerId: permissions.actorEmployeeId,
        destination: MediaPickerDestination.estimate,
        targetId: draft.session.draftId,
        targetRevision: draft.session.savedRevision,
        source: source,
      );
      fail(
        'The write phase must be force-stopped after native retention and before Dart checkpointing.',
      );
    }
    _expectRawInput(draft.recoveredInput!);
    var request = await coordinator.recover(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
    );
    if (requestedPhase == 'activity') {
      // Android can deliver the returning activity result after Dart starts.
      // Bounded polling preserves the same intent and never reopens a picker.
      for (
        var attempt = 0;
        attempt < 40 && request?.retainedAttachmentIds == null;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)),
        );
        request = await coordinator.recover(
          organizationId: permissions.organizationId,
          ownerId: permissions.actorEmployeeId,
        );
      }
    }
    final expectedDigest = requestedPhase == 'activity'
        ? await _cameraSourceDigest()
        : await digestFile.readAsString();
    expect(request, isNotNull);
    expect(request!.source, source);
    expect(request.targetId, draft.session.draftId);
    expect(request.targetRevision, draft.session.savedRevision);
    expect(request.returnedFiles, hasLength(1));
    expect(request.retainedAttachmentIds, hasLength(1));
    // Native copies may disappear only after the coordinator has retained its
    // own bytes. The later adoption/reopen digest checks prove those survive.
    for (final file in request.returnedFiles!) {
      expect(file.path, contains('/native_media_handoff/'));
      expect(await File(file.path).exists(), isFalse);
    }
    final retained = request;
    final adoption = EstimateMediaAdoption(work.repository, permissions);
    final photos = await adoption.adopt(
      request: retained,
      draft: draft.session,
    );
    expect(photos.photos, hasLength(1));
    expect(
      photos.photos.single.source,
      source == MediaPickerSource.camera
          ? WorkSitePhotoSource.camera
          : WorkSitePhotoSource.library,
    );
    expect(
      sha256
          .convert(await File(photos.photos.single.path).readAsBytes())
          .toString(),
      expectedDigest,
    );
    _expectRawInput(draft.recoveredInput!);
    await expectLater(
      adoption.adopt(request: retained, draft: draft.session),
      throwsA(isA<LocalRecordConflict>()),
    );
    expect(
      await coordinator.requests.findFor(
        organizationId: permissions.organizationId,
        ownerId: permissions.actorEmployeeId,
      ),
      isNull,
    );
    work.dispose();
    await persistence.close();
    persistence = await LocalPersistence.open(directory: root);
    work = await openUiLabWorkSession(persistence.database);
    final reopened = await work.openEstimateDraft(
      creatorId: 'alex',
      recoveryDraftId: draft.session.draftId,
    );
    _expectRawInput(reopened.recoveredInput!);
    final photo = reopened.recoveredInput!.pendingPhotos!.photos.single;
    expect(
      sha256.convert(await File(photo.path).readAsBytes()).toString(),
      expectedDigest,
    );
    expect(
      work.records.any((record) => record.id == 'native-estimate'),
      isFalse,
    );
    await persistence.database.verifyIntegrity();
    work.dispose();
    await persistence.close();
    await root.delete(recursive: true);
    // ignore: avoid_print
    print('UILAB_NATIVE_JOURNAL_RECOVERY_VERIFIED_$runId');
  });
}

Future<String> _cameraSourceDigest() async {
  final cache = await getTemporaryDirectory();
  final sources = <File>[];
  await for (final entry in cache.list(recursive: true, followLinks: false)) {
    if (entry is File &&
        entry.path.endsWith('.jpg') &&
        await entry.length() > 0) {
      sources.add(entry);
    }
  }
  // A fresh QA install and one capture provide an independent byte oracle.
  expect(
    sources,
    hasLength(1),
    reason: 'Require exactly one original capture.',
  );
  return sha256.convert(await sources.single.readAsBytes()).toString();
}

EstimateDraftInput _unfinishedEstimate() => EstimateDraftInput(
  creatorId: 'alex',
  number: 'QA-UNFINISHED',
  baseStorageRevision: 0,
  title: '  Interrupted site estimate  ',
  discount: '12.',
  tax: '.',
  terms: '  unfinished terms\n',
  client: null,
  pricing: WorkPricingModel.flatRate,
  template: 'standard',
  createdOn: DateTime(2030),
  items: const [],
  baseRecord: null,
  estimateId: 'native-estimate',
  scope: '  unfinished scope\n',
  expiresOn: DateTime(2030, 2),
  followUpOn: null,
  proposedServiceOn: null,
  pendingLineItems: const {},
  pendingPhotos: null,
  sitePhotos: const [],
);

void _expectRawInput(EstimateDraftInput input) {
  final expected = _unfinishedEstimate().toPayload();
  final actual = input.toPayload();
  // Adoption changes only the workflow's photo collection.
  actual.remove('photoEditor');
  expected.remove('photoEditor');
  expect(actual, expected);
}

List<int> _pngBytes() => base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOIqpgGRAwQCgAmfgWhCo6K7AAAAABJRU5ErkJggg==',
);
