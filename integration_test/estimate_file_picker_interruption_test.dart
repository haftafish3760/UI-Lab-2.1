import 'dart:convert';
import 'dart:io';
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

/// Standalone QA APK, two launches around an external force-stop. Do not use
/// flutter test's uninstalling driver between phases. Select the documented
/// synthetic PNG through Android DocumentsUI during the resume phase.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const runId = String.fromEnvironment('STORAGE_INTERRUPTION_RUN');
  const phase = String.fromEnvironment('STORAGE_INTERRUPTION_PHASE');
  testWidgets('estimate native file selection interruption: $phase', (
    tester,
  ) async {
    if (!Platform.isAndroid ||
        !const bool.fromEnvironment('STORAGE_QA') ||
        !RegExp(r'^[a-zA-Z0-9_-]{8,64}$').hasMatch(runId) ||
        !['write', 'read'].contains(phase)) {
      throw ArgumentError('Requires isolated Android QA run ID and phase.');
    }
    final support = await getApplicationSupportDirectory();
    final root = Directory('${support.path}/estimate-picker-$runId');
    if ((await root.exists()) != (phase == 'read')) {
      throw StateError(
        'Write requires a fresh fixture; read requires it intact.',
      );
    }
    var persistence = await LocalPersistence.open(directory: root);
    var work = await openUiLabWorkSession(persistence.database);
    final permissions = work.permissions;
    final savedRequest = phase == 'read'
        ? await LocalMediaPickerRequestStore(persistence.database).findFor(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
          )
        : null;
    if (phase == 'read') expect(savedRequest, isNotNull);
    final draft = await work.openEstimateDraft(
      creatorId: 'alex',
      recoveryDraftId: savedRequest?.targetId,
    );
    final coordinator = createApplicationMediaCoordinator(
      database: persistence.database,
      gateway: NativeDeviceMediaGateway(),
      receiptPermissions: receiptDraftUiLabOwnerPermissions(),
      work: work,
    );
    if (phase == 'write') {
      draft.updateInput(_unfinishedEstimate());
      await draft.session.flush();
      expect(draft.session.savedRevision, 1);
      // The external harness must ALSO observe the native picker and the live QA PID
      // before killing. This marker alone does not prove the picker opened.
      // ignore: avoid_print
      print('UILAB_ESTIMATE_PICKER_START_$runId');
      await coordinator.start(
        organizationId: permissions.organizationId,
        ownerId: permissions.actorEmployeeId,
        destination: MediaPickerDestination.estimate,
        targetId: draft.session.draftId,
        targetRevision: draft.session.savedRevision,
        source: MediaPickerSource.files,
      );
      fail(
        'The write phase must be force-stopped while the native picker is open.',
      );
    }
    _expectRawInput(draft.recoveredInput!);
    final request = await coordinator.recover(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
    );
    expect(request, isNotNull);
    expect(request!.source, MediaPickerSource.files);
    expect(request.targetId, draft.session.draftId);
    expect(request.targetRevision, draft.session.savedRevision);
    expect(request.returnedFiles, isNull);
    // ignore: avoid_print
    print('UILAB_ESTIMATE_RESELECT_$runId');
    final retained = await coordinator.resumeFileSelection(
      organizationId: permissions.organizationId,
      ownerId: permissions.actorEmployeeId,
      requestId: request.requestId,
    );
    expect(retained, isNotNull);
    final adoption = EstimateMediaAdoption(work.repository, permissions);
    final photos = await adoption.adopt(
      request: retained!,
      draft: draft.session,
    );
    expect(photos.photos, hasLength(1));
    expect(photos.photos.single.source, WorkSitePhotoSource.file);
    expect(await File(photos.photos.single.path).readAsBytes(), _pngBytes());
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
    expect(await File(photo.path).readAsBytes(), _pngBytes());
    expect(
      work.records.any((record) => record.id == 'native-estimate'),
      isFalse,
    );
    await persistence.database.verifyIntegrity();
    work.dispose();
    await persistence.close();
    await root.delete(recursive: true);
    // ignore: avoid_print
    print('UILAB_ESTIMATE_FILE_RECOVERY_VERIFIED_$runId');
  });
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
