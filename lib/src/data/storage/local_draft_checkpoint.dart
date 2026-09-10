/// Exact unconfirmed input revision consumed by a successful business command.
/// Organization and owner come from the authorized command, not this token.
class LocalDraftCheckpoint {
  const LocalDraftCheckpoint({
    required this.domain,
    required this.draftId,
    required this.revision,
  });
  final String domain;
  final String draftId;
  final int revision;
}
