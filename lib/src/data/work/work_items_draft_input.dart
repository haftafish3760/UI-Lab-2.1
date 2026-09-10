import 'models/work_models.dart';
import 'work_line_item_draft_input.dart';
import 'work_record_detail_codec.dart';

/// A collection of confirmed lines plus a still-unfinished line. Neither the
/// collection's ordering nor its recovery requires a particular route or layout.
class WorkItemsDraftInput {
  WorkItemsDraftInput({required Iterable<WorkLineItem> items, this.pendingItem})
    : items = List.unmodifiable(items);
  final List<WorkLineItem> items;
  final WorkLineItemDraftInput? pendingItem;

  Map<String, Object?> toPayload() => {
    'items': items.map(encodeWorkLineItem).toList(),
    'pendingItem': pendingItem?.toPayload(),
  };
  factory WorkItemsDraftInput.fromPayload(Map<String, Object?> payload) =>
      WorkItemsDraftInput(
        items: (payload['items'] as List).map(
          (item) => decodeWorkLineItem((item as Map).cast<String, Object?>()),
        ),
        pendingItem: payload['pendingItem'] == null
            ? null
            : WorkLineItemDraftInput.fromPayload(
                (payload['pendingItem'] as Map).cast<String, Object?>(),
              ),
      );
}
