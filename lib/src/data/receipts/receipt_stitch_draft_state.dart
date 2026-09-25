/// Recoverable processing intent and derived-preview identity. Original receipt
/// evidence remains authoritative; a preview is never a replacement purchase.
enum ReceiptStitchDraftStage { pending, processing, review, ready, failed }

class ReceiptStitchDraftState {
  ReceiptStitchDraftState({
    required Iterable<String> evidenceIds,
    required Iterable<String> sourceHashes,
    required this.stage,
    this.attachmentId,
    this.reasonCode,
  }) : evidenceIds = List.unmodifiable(evidenceIds),
       sourceHashes = List.unmodifiable(sourceHashes) {
    if (this.evidenceIds.length < 2 ||
        this.evidenceIds.length > 8 ||
        this.evidenceIds.toSet().length != this.evidenceIds.length ||
        this.evidenceIds.any((id) => id.trim().isEmpty) ||
        this.sourceHashes.length != this.evidenceIds.length ||
        this.sourceHashes.any(
          (hash) => !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash),
        )) {
      throw const FormatException('Invalid receipt stitching sources.');
    }
    if ((attachmentId != null &&
            !RegExp(r'^attachment-[a-f0-9]+$').hasMatch(attachmentId!)) ||
        (stage == ReceiptStitchDraftStage.ready && attachmentId == null)) {
      throw const FormatException('Invalid retained stitch preview.');
    }
  }

  final List<String> evidenceIds, sourceHashes;
  final ReceiptStitchDraftStage stage;
  final String? attachmentId, reasonCode;

  // A saved "processing" marker is an interrupted operation, never proof that
  // a worker is still running after restart. The UI must offer an explicit retry.
  bool get needsRetry =>
      stage == ReceiptStitchDraftStage.processing ||
      stage == ReceiptStitchDraftStage.failed;

  String get retryGuidance => switch (reasonCode) {
    'resource_probeUnavailable' || 'resource_storageUnknown' =>
      'The app could not check available device storage. Combining is paused; your saved photos can still be reviewed separately.',
    'resource_storageReserve' || 'resource_storageBudget' =>
      'There is not enough free storage to combine these photos safely. Choose what to remove from your device, then retry. The app has not deleted your photos.',
    'resource_thermalPressure' || 'resource_batteryUnsafe' =>
      'Combining is paused to protect your device. Let it cool down before retrying. Your photos are saved.',
    'resource_batteryCritical' =>
      'Charge your device before retrying. Your photos are saved.',
    'resource_memoryCritical' ||
    'resource_memoryPressure' ||
    'resource_memoryBudget' =>
      'There is not enough available memory to combine these photos safely. Close other apps before retrying, or review the saved photos separately.',
    'resource_unavailable' =>
      'Combining is waiting for device resources. Your photos are saved; retry when other processing has finished.',
    _ =>
      'Combining was interrupted or could not finish. Your photos are saved; you can retry.',
  };

  Map<String, Object?> toJson() => {
    'evidenceIds': evidenceIds,
    'sourceHashes': sourceHashes,
    'stage': stage.name,
    'attachmentId': attachmentId,
    'reasonCode': reasonCode,
  };

  factory ReceiptStitchDraftState.fromJson(Map<String, Object?> json) =>
      ReceiptStitchDraftState(
        evidenceIds: (json['evidenceIds'] as List).cast<String>(),
        sourceHashes: (json['sourceHashes'] as List).cast<String>(),
        stage: ReceiptStitchDraftStage.values.byName(json['stage'] as String),
        attachmentId: json['attachmentId'] as String?,
        reasonCode: json['reasonCode'] as String?,
      );
}
