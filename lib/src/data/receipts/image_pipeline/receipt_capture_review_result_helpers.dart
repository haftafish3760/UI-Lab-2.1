part of 'receipt_capture_models.dart';

Map<String, Map<String, Object?>> _withReviewExitDiagnostics(
  Map<String, Map<String, Object?>> diagnosticsByPath,
  List<String> photoPaths,
) {
  final mapped = <String, Map<String, Object?>>{};
  for (final path in photoPaths) {
    final existing = diagnosticsByPath[path] ?? const <String, Object?>{};
    mapped[path] = {
      ...existing,
      'receiptReviewExitAction': 'kept_for_later',
      'receiptReviewKeptForLater': true,
      'receiptReviewOcrDeferred': true,
      'receiptReviewReaderAccepted': false,
      'receiptReviewReaderOutcome': 'not_accepted_for_receipt_details_yet',
      'receiptReviewResumeRequiredBeforeOcr': true,
      'receiptReviewBackActionOutcome': 'kept_for_later_no_receipt_details',
      'receiptReviewNextAction': 'resume_saved_photo_review',
      'receiptReviewKeptPhotoCount': photoPaths.length,
    };
  }
  return Map.unmodifiable(mapped);
}
