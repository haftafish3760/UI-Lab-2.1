part of 'receipt_capture_models.dart';

enum ReceiptPhotoCoverageStatus {
  likelyComplete,
  maybeContinues,
  likelyCutOff,
  unknown,
}

class ReceiptPhotoCoverageDecision {
  const ReceiptPhotoCoverageDecision({
    required this.status,
    required this.reasonCode,
    required this.title,
    required this.guidance,
  });

  factory ReceiptPhotoCoverageDecision.fromSignals({
    ReceiptPhotoQualityCheck? quality,
    Map<String, Object?>? diagnostics,
  }) => _receiptPhotoCoverageDecisionFromSignals(
    quality: quality,
    diagnostics: diagnostics,
  );

  final ReceiptPhotoCoverageStatus status;
  final String reasonCode;
  final String title;
  final String guidance;
}
