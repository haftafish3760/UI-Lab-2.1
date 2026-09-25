part of 'receipt_capture_models.dart';

extension ReceiptAttachmentRecordSerialization on ReceiptAttachmentRecord {
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'kind': kind.name,
      'dataSaverLevel': dataSaverLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'displayName': displayName,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'importedText': importedText,
      'byteSize': byteSize,
      'fileHash': fileHash,
      'pageCount': pageCount,
      'pageCountStatus': pageCountStatus.name,
      'validationStatus': validationStatus.name,
      'riskFlags': riskFlags,
      'documentSignals': documentSignals,
      'sourceLabel': sourceLabel,
      'linkedModule': linkedModule,
      'linkedRecordId': linkedRecordId,
      'isOriginalImmutable': isOriginalImmutable,
      'storageState': storageState.name,
      'promotedAt': promotedAt?.toIso8601String(),
      'cleanedUpAt': cleanedUpAt?.toIso8601String(),
      'readState': readState.name,
      'photoQualityScore': photoQualityScore,
      'photoQualityIssueLabel': photoQualityIssueLabel,
      'photoQualityWarnings': photoQualityWarnings,
      'photoWidth': photoWidth,
      'photoHeight': photoHeight,
      'photoBrightness': photoBrightness,
      'photoContrast': photoContrast,
      'photoFocusScore': photoFocusScore,
      'photoCropScore': photoCropScore,
      'photoTextBandScore': photoTextBandScore,
    };
  }
}
