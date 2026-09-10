import 'local_record_command.dart';

/// A selected recovery checkpoint, not a permission grant. The owning factory
/// still authorizes its workflow and validates the recovered domain identity.
class DraftRecoverySelection {
  const DraftRecoverySelection({
    required this.domain,
    required this.draftId,
    required this.revision,
  });
  final String domain;
  final String draftId;
  final int revision;
  void verify({
    required String openedDomain,
    required String openedDraftId,
    required int openedRevision,
    required bool hasInput,
  }) {
    if (revision < 1 ||
        domain != openedDomain ||
        draftId != openedDraftId ||
        revision != openedRevision ||
        !hasInput) {
      throw const LocalRecordConflict(
        'Selected recovery changed; refresh the recovery list.',
      );
    }
  }
}
