part of 'local_receipt_draft_repository.dart';

List<StoredReceiptDraft> _decodeReceiptDrafts(Map<String, Object?> payload) {
  final values = payload['records'];
  if (values is! List) throw const FormatException('Invalid receipt drafts.');
  final records = values
      .map(
        (value) =>
            StoredReceiptDraft.fromJson((value as Map).cast<String, Object?>()),
      )
      .toList();
  if (records.map((item) => item.draftId).toSet().length != records.length) {
    throw const FormatException('Duplicate receipt draft identity.');
  }
  return List.unmodifiable(records);
}

int _compareDrafts(StoredReceiptDraft left, StoredReceiptDraft right) {
  final updated = right.lifecycle.updatedAtUtc.compareTo(
    left.lifecycle.updatedAtUtc,
  );
  return updated != 0 ? updated : left.draftId.compareTo(right.draftId);
}
