/// Presentation-facing restore operations. No database, filesystem, widget or
/// navigation types cross this boundary. The application owns its lifetime.
abstract interface class LocalRestoreController {
  bool get isBusy;
  bool get canRetryOpening;
  Future<List<LocalCheckpointSummary>> listCheckpoints();
  Future<LocalRestoreReview> reviewCheckpoint(String checkpointId);
  void cancelReview(LocalRestoreReview review);
  Future<void> confirm(LocalRestoreReview review);
  Future<void> retryOpening();
}

/// Review facts only. Implementing/copying these facts does not grant authority:
/// confirmation accepts only the exact outstanding review issued by its owner.
abstract interface class LocalRestoreReview {
  String get checkpointId;
  int get databaseBytes;
  int get attachmentCount;
}

/// Selection facts only. A listing is neither a restore review nor permission
/// to activate it; confirmation always revalidates the chosen checkpoint.
class LocalCheckpointSummary {
  const LocalCheckpointSummary({
    required this.checkpointId,
    required this.isVerified,
    this.databaseBytes,
    this.attachmentCount,
  });
  final String checkpointId;
  final bool isVerified;
  final int? databaseBytes;
  final int? attachmentCount;
}
