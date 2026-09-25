part of 'receipt_stitch_text_evidence.dart';

List<_ReceiptStitchOrderCandidate> _bestReceiptStitchOrders(
  List<ReceiptStitchTextEvidence> evidence,
  ReceiptStitchTextPairEvidence Function(int from, int to) pair,
) {
  final count = evidence.length;
  if (count == 0 || count > 8) return const [];
  final states = <String, List<_ReceiptStitchPathState>>{};
  for (var index = 0; index < count; index++) {
    final state = _ReceiptStitchPathState(
      mask: 1 << index,
      last: index,
      allStrong: true,
      score:
          _receiptHeaderHint(evidence[index]) * .20 -
          _receiptFooterHint(evidence[index]) * .12,
      order: [index],
    );
    states[_receiptStitchStateKey(state)] = [state];
  }
  final fullMask = (1 << count) - 1;
  for (var used = 1; used < count; used++) {
    final currentStates = [
      for (final bucket in states.values)
        for (final state in bucket)
          if (_receiptBitCount(state.mask) == used) state,
    ];
    for (final state in currentStates) {
      for (var next = 0; next < count; next++) {
        if (state.mask & (1 << next) != 0) continue;
        final adjacent = pair(state.last, next);
        final nextPosition = state.order.length;
        final positionRatio = nextPosition / (count - 1);
        final previousPositionRatio = (nextPosition - 1) / (count - 1);
        final topologyAdjustment =
            -_receiptHeaderHint(evidence[next]) * .14 * positionRatio -
            _receiptFooterHint(evidence[state.last]) *
                .14 *
                (1 - previousPositionRatio);
        final candidate = _ReceiptStitchPathState(
          mask: state.mask | (1 << next),
          last: next,
          allStrong: state.allStrong && adjacent.isStrong,
          score: state.score + adjacent.confidence * 2 + topologyAdjustment,
          order: [...state.order, next],
        );
        final key = _receiptStitchStateKey(candidate);
        final bucket = states.putIfAbsent(key, () => []);
        bucket.add(candidate);
        bucket.sort((left, right) => right.score.compareTo(left.score));
        if (bucket.length > 2) bucket.removeRange(2, bucket.length);
      }
    }
  }
  final completed = <_ReceiptStitchOrderCandidate>[];
  for (final bucket in states.values) {
    for (final state in bucket) {
      if (state.mask != fullMask) continue;
      final score =
          state.score +
          _receiptFooterHint(evidence[state.last]) * .20 -
          (state.allStrong ? 0 : .45);
      completed.add(
        _ReceiptStitchOrderCandidate(order: state.order, score: score),
      );
    }
  }
  completed.sort((left, right) => right.score.compareTo(left.score));
  return completed.length <= 2
      ? completed
      : List.unmodifiable(completed.take(2));
}

String _receiptStitchStateKey(_ReceiptStitchPathState state) {
  return '${state.mask}:${state.last}:${state.allStrong ? 1 : 0}';
}

int _receiptBitCount(int value) {
  var remaining = value;
  var count = 0;
  while (remaining != 0) {
    count += remaining & 1;
    remaining >>= 1;
  }
  return count;
}

class _ReceiptStitchPathState {
  const _ReceiptStitchPathState({
    required this.mask,
    required this.last,
    required this.allStrong,
    required this.score,
    required this.order,
  });

  final int mask;
  final int last;
  final bool allStrong;
  final double score;
  final List<int> order;
}

class _ReceiptStitchOrderCandidate {
  const _ReceiptStitchOrderCandidate({
    required this.order,
    required this.score,
  });

  final List<int> order;
  final double score;
}
