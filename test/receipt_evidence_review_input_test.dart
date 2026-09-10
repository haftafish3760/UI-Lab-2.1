import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_review_input.dart';

ReceiptEvidenceReviewInput initial() => ReceiptEvidenceReviewInput(
  sourceId: 'receipt',
  sourceRevision: 3,
  orderedEvidenceIds: ['a', 'b', 'c'],
  selectedId: 'b',
);
void main() {
  test(
    'reorder removal and undo round trip through stable legacy identities',
    () {
      final input = initial();
      final moved = input.move(2, 0);
      expect(moved.orderedEvidenceIds, ['c', 'a', 'b']);
      expect(moved.selectedId, 'c');
      final removed = moved.remove(1);
      expect(removed.orderedEvidenceIds, ['c', 'b']);
      expect(removed.selectedId, 'c');
      expect(removed.undoId, 'a');
      final raw = removed.toPayload();
      final restored = ReceiptEvidenceReviewInput.fromPayload(raw);
      restored.validate(
        receiptId: 'receipt',
        revision: 3,
        availableIds: {'a', 'b', 'c'},
      );
      expect(restored.toPayload(), raw);
      final undone = restored.undo();
      expect(undone.orderedEvidenceIds, ['c', 'a', 'b']);
      expect(undone.selectedId, 'a');
      expect(undone.undoId, isNull);
      expect(input.orderedEvidenceIds, ['a', 'b', 'c']);
      expect(() => input.orderedEvidenceIds.clear(), throwsUnsupportedError);
    },
  );
  test(
    'empty review keeps last removal recoverable and refuses stale or malformed identities',
    () {
      final input = ReceiptEvidenceReviewInput(
        sourceId: 'receipt',
        sourceRevision: 3,
        orderedEvidenceIds: ['a'],
        selectedId: 'a',
      ).remove(0);
      expect(input.selectedId, isNull);
      expect(input.selectedIndex, 0);
      input.validate(receiptId: 'receipt', revision: 3, availableIds: {'a'});
      expect(input.undo().selectedId, 'a');
      expect(
        () => input.validate(
          receiptId: 'receipt',
          revision: 4,
          availableIds: {'a'},
        ),
        throwsStateError,
      );
      for (final change in [
        {
          'orderedEvidenceIds': ['a', 'a'],
        },
        {'selectedId': 'missing'},
        {'undoIndex': 9},
        {'undoId': 'missing'},
      ]) {
        final invalid = ReceiptEvidenceReviewInput.fromPayload({
          ...input.toPayload(),
          ...change,
        });
        expect(
          () => invalid.validate(
            receiptId: 'receipt',
            revision: 3,
            availableIds: {'a'},
          ),
          throwsStateError,
        );
      }
    },
  );
}
