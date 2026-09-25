import 'dart:io';
import 'package:crypto/crypto.dart';
import '../device_capabilities/device_workload_service.dart';
import '../storage/local_attachment_store.dart';
import '../storage/local_draft_store.dart';
import 'receipt_evidence_draft_workflow.dart';
import 'receipt_stitch_draft_state.dart';
import 'receipt_stitch_service.dart';

/// Connects processing to the existing authorized SQLite review draft. Files
/// precede the draft reference; failed publication leaves retained artifacts.
class ReceiptStitchDraftWorkflow {
  ReceiptStitchDraftWorkflow(
    this.review, {
    ReceiptStitchService? stitcher,
    this.authorize,
  }) : stitcher = stitcher ?? ReceiptStitchService();
  final ReceiptEvidenceDraftController review;
  final ReceiptStitchService stitcher;
  final Future<void> Function()? authorize;
  bool _busy = false;

  Future<void> process({List<bool>? manualZeroOverlapPairs}) async {
    if (_busy) throw StateError('Receipt stitching is already running.');
    final store = review.session.store;
    if (store is! LocalDraftStore) {
      throw StateError('SQLite receipt storage is required.');
    }
    final initial = review.input;
    final sources = [
      for (final id in initial.orderedEvidenceIds)
        review.source.activeEvidence.firstWhere(
          (item) => item.evidenceId == id,
        ),
    ];
    final processing = ReceiptStitchDraftState(
      evidenceIds: sources.map((item) => item.evidenceId),
      sourceHashes: sources.map((item) => item.sha256),
      stage: ReceiptStitchDraftStage.processing,
    );
    bool changed() =>
        review.session.isClosed ||
        review.input.sourceRevision != initial.sourceRevision ||
        review.input.orderedEvidenceIds.join('\u0000') !=
            initial.orderedEvidenceIds.join('\u0000');
    _busy = true;
    try {
      await authorize?.call();
      review.updateInput(initial.withStitchState(processing));
      await review.session.flush();
      for (final source in sources) {
        final file = File(source.localPath);
        if (await file.length() != source.byteLength ||
            (await sha256.bind(file.openRead()).first).toString() !=
                source.sha256) {
          throw StateError('A receipt source is missing or damaged.');
        }
      }
      final result = await stitcher.stitch(
        paths: sources.map((item) => item.localPath).toList(),
        manualZeroOverlapPairs: manualZeroOverlapPairs,
        cancelled: changed,
      );
      if (changed()) return;
      await authorize?.call();
      String? attachmentId;
      if (result.didStitch) {
        final retained = await stitcher.workloads.run(
          (_) async {
            if (changed()) throw StateError('Receipt sections changed.');
            return LocalAttachmentStore(store.database).retain(
              source: File(result.stitchedPath!),
              organizationId: review.session.organizationId,
              ownerId: review.session.ownerId,
            );
          },
          request: const DeviceWorkloadRequest(storageBytes: 16 * 1024 * 1024),
        );
        attachmentId = retained.uri.pathSegments.last.split('.').first;
      }
      if (changed()) return;
      await authorize?.call();
      review.updateInput(
        review.input.withStitchState(
          ReceiptStitchDraftState(
            evidenceIds: processing.evidenceIds,
            sourceHashes: processing.sourceHashes,
            stage: result.didStitch
                ? ReceiptStitchDraftStage.ready
                : ReceiptStitchDraftStage.review,
            attachmentId: attachmentId,
            reasonCode: result.fallbackReasonCode,
          ),
        ),
      );
      await review.session.flush();
    } catch (error) {
      if (!changed()) {
        review.updateInput(
          review.input.withStitchState(
            ReceiptStitchDraftState(
              evidenceIds: processing.evidenceIds,
              sourceHashes: processing.sourceHashes,
              stage: ReceiptStitchDraftStage.failed,
              reasonCode: error is DeviceWorkloadUnavailable
                  ? _resourceFailure(error.reasons)
                  : 'processing_or_storage_failed',
            ),
          ),
        );
        await review.session.flush();
      }
      rethrow;
    } finally {
      _busy = false;
    }
  }

  // Store only known codes, never exception text or device/file identifiers.
  static String _resourceFailure(List<String> reasons) {
    for (final reason in const [
      'probeUnavailable',
      'storageUnknown',
      'storageReserve',
      'storageBudget',
      'thermalPressure',
      'batteryUnsafe',
      'batteryCritical',
      'memoryCritical',
      'memoryPressure',
      'memoryBudget',
    ]) {
      if (reasons.contains(reason)) return 'resource_$reason';
    }
    return 'resource_unavailable';
  }
}
