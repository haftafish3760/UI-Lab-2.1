/// Stable evidence identities and review actions, independent of file previews,
/// widget indices and responsive composition. Version-one wire keys are retained.
class ReceiptEvidenceReviewInput {
  ReceiptEvidenceReviewInput({
    required this.sourceId,
    required this.sourceRevision,
    required Iterable<String> orderedEvidenceIds,
    required this.selectedId,
    this.undoId,
    this.undoIndex,
  }) : orderedEvidenceIds = List.unmodifiable(orderedEvidenceIds);
  final String sourceId;
  final int sourceRevision;
  final List<String> orderedEvidenceIds;
  final String? selectedId, undoId;
  final int? undoIndex;
  int get selectedIndex =>
      selectedId == null ? 0 : orderedEvidenceIds.indexOf(selectedId!);

  void validate({
    required String receiptId,
    required int revision,
    required Set<String> availableIds,
  }) {
    if (sourceId != receiptId || sourceRevision != revision) {
      throw StateError('Receipt source changed.');
    }
    if (orderedEvidenceIds.toSet().length != orderedEvidenceIds.length ||
        orderedEvidenceIds.any((id) => !availableIds.contains(id))) {
      throw StateError('Saved evidence identities changed.');
    }
    if (orderedEvidenceIds.isEmpty
        ? selectedId != null
        : !orderedEvidenceIds.contains(selectedId)) {
      throw StateError('Invalid selection.');
    }
    if (undoId == null
        ? undoIndex != null
        : !availableIds.contains(undoId) ||
              orderedEvidenceIds.contains(undoId) ||
              undoIndex == null ||
              undoIndex! < 0 ||
              undoIndex! >= availableIds.length) {
      throw StateError('Invalid undo selection.');
    }
  }

  ReceiptEvidenceReviewInput select(int index) => ReceiptEvidenceReviewInput(
    sourceId: sourceId,
    sourceRevision: sourceRevision,
    orderedEvidenceIds: orderedEvidenceIds,
    selectedId: orderedEvidenceIds[index],
    undoId: undoId,
    undoIndex: undoIndex,
  );
  ReceiptEvidenceReviewInput move(int from, int to) {
    if (to < 0 || to >= orderedEvidenceIds.length || from == to) return this;
    final order = [...orderedEvidenceIds];
    final id = order.removeAt(from);
    order.insert(to, id);
    return ReceiptEvidenceReviewInput(
      sourceId: sourceId,
      sourceRevision: sourceRevision,
      orderedEvidenceIds: order,
      selectedId: id,
      undoId: undoId,
      undoIndex: undoIndex,
    );
  }

  ReceiptEvidenceReviewInput remove(int index) {
    final order = [...orderedEvidenceIds];
    final removed = order.removeAt(index);
    var selected = selectedIndex;
    if (order.isEmpty) {
      selected = 0;
    } else if (selected >= order.length) {
      selected = order.length - 1;
    } else if (index < selected) {
      selected--;
    }
    return ReceiptEvidenceReviewInput(
      sourceId: sourceId,
      sourceRevision: sourceRevision,
      orderedEvidenceIds: order,
      selectedId: order.isEmpty ? null : order[selected],
      undoId: removed,
      undoIndex: index,
    );
  }

  ReceiptEvidenceReviewInput undo() {
    if (undoId == null) return this;
    final order = [...orderedEvidenceIds];
    final index = (undoIndex ?? 0).clamp(0, order.length);
    order.insert(index, undoId!);
    return ReceiptEvidenceReviewInput(
      sourceId: sourceId,
      sourceRevision: sourceRevision,
      orderedEvidenceIds: order,
      selectedId: undoId,
    );
  }

  Map<String, Object?> toPayload() => {
    'sourceId': sourceId,
    'sourceRevision': sourceRevision,
    'orderedEvidenceIds': orderedEvidenceIds,
    'selectedId': selectedId,
    'undoId': undoId,
    'undoIndex': undoIndex,
  };
  factory ReceiptEvidenceReviewInput.fromPayload(Map<String, Object?> input) =>
      ReceiptEvidenceReviewInput(
        sourceId: input['sourceId'] as String,
        sourceRevision: input['sourceRevision'] as int,
        orderedEvidenceIds: (input['orderedEvidenceIds'] as List)
            .cast<String>(),
        selectedId: input['selectedId'] as String?,
        undoId: input['undoId'] as String?,
        undoIndex: input['undoIndex'] as int?,
      );
}
