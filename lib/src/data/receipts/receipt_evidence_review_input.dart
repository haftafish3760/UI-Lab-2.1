import 'receipt_stitch_draft_state.dart';
import 'receipt_selected_details.dart';
import 'receipt_item_read.dart';

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
    this.selectedDetails,
    this.stitchState,
    List<ReceiptItemRead> itemReads = const [],
  }) : orderedEvidenceIds = List.unmodifiable(orderedEvidenceIds),
       itemReads = List.unmodifiable(itemReads);
  final String sourceId;
  final int sourceRevision;
  final List<String> orderedEvidenceIds;
  final String? selectedId, undoId;
  final int? undoIndex;
  final ReceiptSelectedDetails? selectedDetails;
  final ReceiptStitchDraftState? stitchState;
  final List<ReceiptItemRead> itemReads;
  int get selectedIndex =>
      selectedId == null ? 0 : orderedEvidenceIds.indexOf(selectedId!);

  void validate({
    required String receiptId,
    required int revision,
    required Set<String> availableIds,
  }) {
    final stitch = stitchState;
    if (stitch != null &&
        (stitch.evidenceIds.length != orderedEvidenceIds.length ||
            List.generate(
              orderedEvidenceIds.length,
              (i) => stitch.evidenceIds[i] != orderedEvidenceIds[i],
            ).any((changed) => changed))) {
      throw StateError(
        'Stitch preview does not match the selected section order.',
      );
    }
    if (sourceId != receiptId || sourceRevision != revision) {
      throw StateError('Receipt source changed.');
    }
    if (itemReads.map((read) => read.evidenceId).toSet().length !=
            itemReads.length ||
        itemReads.any((read) => !availableIds.contains(read.evidenceId))) {
      throw StateError('The item reading source is unavailable or repeated.');
    }
    if (selectedDetails != null &&
        !availableIds.contains(selectedDetails!.evidenceId)) {
      throw StateError('The suggestion source is unavailable.');
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

  ReceiptEvidenceReviewInput withStitchState(ReceiptStitchDraftState? state) =>
      ReceiptEvidenceReviewInput(
        sourceId: sourceId,
        sourceRevision: sourceRevision,
        orderedEvidenceIds: orderedEvidenceIds,
        selectedId: selectedId,
        undoId: undoId,
        undoIndex: undoIndex,
        selectedDetails: selectedDetails,
        itemReads: itemReads,
        stitchState: state,
      );

  ReceiptEvidenceReviewInput select(int index) => ReceiptEvidenceReviewInput(
    sourceId: sourceId,
    sourceRevision: sourceRevision,
    orderedEvidenceIds: orderedEvidenceIds,
    selectedId: orderedEvidenceIds[index],
    undoId: undoId,
    undoIndex: undoIndex,
    selectedDetails: selectedDetails,
    itemReads: itemReads,
    stitchState: stitchState,
  );
  ReceiptEvidenceReviewInput useDetails(ReceiptSelectedDetails? details) =>
      ReceiptEvidenceReviewInput(
        sourceId: sourceId,
        sourceRevision: sourceRevision,
        orderedEvidenceIds: orderedEvidenceIds,
        selectedId: selectedId,
        undoId: undoId,
        undoIndex: undoIndex,
        selectedDetails: details,
        itemReads: itemReads,
        stitchState: stitchState,
      );
  ReceiptEvidenceReviewInput recordItems(ReceiptItemRead read) =>
      ReceiptEvidenceReviewInput(
        sourceId: sourceId,
        sourceRevision: sourceRevision,
        orderedEvidenceIds: orderedEvidenceIds,
        selectedId: selectedId,
        undoId: undoId,
        undoIndex: undoIndex,
        selectedDetails: selectedDetails,
        stitchState: stitchState,
        itemReads: [
          for (final existing in itemReads)
            if (existing.evidenceId != read.evidenceId) existing,
          read,
        ],
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
      selectedDetails: selectedDetails,
      itemReads: itemReads,
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
      selectedDetails: selectedDetails,
      itemReads: itemReads,
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
      selectedDetails: selectedDetails,
      itemReads: itemReads,
    );
  }

  Map<String, Object?> toPayload() => {
    'stitchState': stitchState?.toJson(),
    'itemReads': itemReads.map((read) => read.toJson()).toList(),
    'selectedDetails': selectedDetails?.toJson(),
    'sourceId': sourceId,
    'sourceRevision': sourceRevision,
    'orderedEvidenceIds': orderedEvidenceIds,
    'selectedId': selectedId,
    'undoId': undoId,
    'undoIndex': undoIndex,
  };
  factory ReceiptEvidenceReviewInput.fromPayload(Map<String, Object?> input) =>
      ReceiptEvidenceReviewInput(
        stitchState: input['stitchState'] == null
            ? null
            : ReceiptStitchDraftState.fromJson(
                (input['stitchState'] as Map).cast<String, Object?>(),
              ),
        itemReads: decodeReceiptItemReads(input),
        selectedDetails: input['selectedDetails'] == null
            ? null
            : ReceiptSelectedDetails.fromJson(
                (input['selectedDetails'] as Map).cast<String, Object?>(),
              ),
        sourceId: input['sourceId'] as String,
        sourceRevision: input['sourceRevision'] as int,
        orderedEvidenceIds: (input['orderedEvidenceIds'] as List)
            .cast<String>(),
        selectedId: input['selectedId'] as String?,
        undoId: input['undoId'] as String?,
        undoIndex: input['undoIndex'] as int?,
      );
}
