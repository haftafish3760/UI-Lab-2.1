import 'dart:math' as math;

// Adapted from read-only Maintainiac 5.7; split by responsibility.
part 'receipt_stitch_text_matching.dart';
part 'receipt_stitch_text_positions.dart';
part 'receipt_stitch_order_solver.dart';
part 'receipt_stitch_text_evidence_similarity.dart';

class ReceiptStitchTextEvidence {
  const ReceiptStitchTextEvidence({
    required this.path,
    required this.lines,
    this.positionedLines = const <ReceiptStitchTextLineEvidence>[],
  });

  final String path;
  final List<String> lines;
  final List<ReceiptStitchTextLineEvidence> positionedLines;

  bool get hasPositionedLines => positionedLines.isNotEmpty;

  List<String> get normalizedLines => [
    for (final line
        in positionedLines.isEmpty
            ? lines
            : positionedLines.map((item) => item.text))
      if (_normalizeReceiptStitchLine(line).isNotEmpty)
        _normalizeReceiptStitchLine(line),
  ];
}

class ReceiptStitchTextLineEvidence {
  const ReceiptStitchTextLineEvidence({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.angleDegrees = 0,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double angleDegrees;

  double get centerX => ((left + right) / 2).clamp(0.0, 1.0);
  double get centerY => ((top + bottom) / 2).clamp(0.0, 1.0);
  double get width => (right - left).clamp(0.0, 1.0);
  double get height => (bottom - top).clamp(0.0, 1.0);
}

class ReceiptStitchTextPairEvidence {
  const ReceiptStitchTextPairEvidence({
    required this.confidence,
    required this.matchedLineCount,
    required this.previousTailOffset,
    required this.nextHeadOffset,
    this.positionalConfidence = 0,
    this.hasPositionalEvidence = false,
    this.previousOverlapStart = 0,
    this.nextOverlapEnd = 0,
    this.nextContinuationStart = 0,
    this.nextContinuationEnd = 0,
    this.previousAnchorCenters = const <double>[],
    this.nextAnchorCenters = const <double>[],
    this.previousAnchorCentersX = const <double>[],
    this.nextAnchorCentersX = const <double>[],
    this.previousAnchorWidths = const <double>[],
    this.nextAnchorWidths = const <double>[],
    this.previousAnchorAngles = const <double>[],
    this.nextAnchorAngles = const <double>[],
    this.usesSparsePositionAnchors = false,
  });

  const ReceiptStitchTextPairEvidence.none()
    : confidence = 0,
      matchedLineCount = 0,
      previousTailOffset = 0,
      nextHeadOffset = 0,
      positionalConfidence = 0,
      hasPositionalEvidence = false,
      previousOverlapStart = 0,
      nextOverlapEnd = 0,
      nextContinuationStart = 0,
      nextContinuationEnd = 0,
      previousAnchorCenters = const <double>[],
      nextAnchorCenters = const <double>[],
      previousAnchorCentersX = const <double>[],
      nextAnchorCentersX = const <double>[],
      previousAnchorWidths = const <double>[],
      nextAnchorWidths = const <double>[],
      previousAnchorAngles = const <double>[],
      nextAnchorAngles = const <double>[],
      usesSparsePositionAnchors = false;

  final double confidence;
  final int matchedLineCount;
  final int previousTailOffset;
  final int nextHeadOffset;
  final double positionalConfidence;
  final bool hasPositionalEvidence;
  final double previousOverlapStart;
  final double nextOverlapEnd;
  final double nextContinuationStart;
  final double nextContinuationEnd;
  final List<double> previousAnchorCenters;
  final List<double> nextAnchorCenters;
  final List<double> previousAnchorCentersX;
  final List<double> nextAnchorCentersX;
  final List<double> previousAnchorWidths;
  final List<double> nextAnchorWidths;
  final List<double> previousAnchorAngles;
  final List<double> nextAnchorAngles;
  final bool usesSparsePositionAnchors;

  bool get isStrong =>
      confidence >= .66 && (matchedLineCount >= 2 || confidence >= .94);
}

class ReceiptStitchOrderPlan {
  const ReceiptStitchOrderPlan({
    required this.originalPaths,
    required this.orderedPaths,
    required this.confidence,
    required this.changed,
    required this.requiresReview,
    required this.reasonCode,
  });

  final List<String> originalPaths;
  final List<String> orderedPaths;
  final double confidence;
  final bool changed;
  final bool requiresReview;
  final String reasonCode;

  static ReceiptStitchOrderPlan fromEvidence(
    List<ReceiptStitchTextEvidence> evidence,
  ) {
    final original = [for (final item in evidence) item.path];
    if (evidence.length <= 1) {
      return ReceiptStitchOrderPlan(
        originalPaths: original,
        orderedPaths: original,
        confidence: 1,
        changed: false,
        requiresReview: false,
        reasonCode: 'single_section',
      );
    }
    if (evidence.length > 8 ||
        evidence.any((item) => item.normalizedLines.isEmpty)) {
      return ReceiptStitchOrderPlan(
        originalPaths: original,
        orderedPaths: original,
        confidence: 0,
        changed: false,
        requiresReview: true,
        reasonCode: 'insufficient_text_evidence',
      );
    }

    final pairEvidence = <String, ReceiptStitchTextPairEvidence>{};
    ReceiptStitchTextPairEvidence pair(int from, int to) {
      return pairEvidence.putIfAbsent(
        '$from:$to',
        () => matchReceiptStitchTextOverlap(evidence[from], evidence[to]),
      );
    }

    final indexes = List<int>.generate(evidence.length, (index) => index);
    final candidates = _bestReceiptStitchOrders(evidence, pair);
    final selected = candidates.isEmpty ? indexes : candidates.first.order;
    final bestScore = candidates.isEmpty ? -1.0 : candidates.first.score;
    final secondScore = candidates.length < 2 ? -1.0 : candidates[1].score;
    final pairConfidences = <double>[
      for (var index = 0; index < selected.length - 1; index++)
        pair(selected[index], selected[index + 1]).confidence,
    ];
    final weakestPair = pairConfidences.reduce(
      (current, value) => current < value ? current : value,
    );
    final margin = bestScore - secondScore;
    final isClear = weakestPair >= .66 && margin >= .18;
    final changed =
        isClear &&
        List.generate(
          selected.length,
          (index) => selected[index] != index,
        ).any((value) => value);
    final ordered = changed
        ? [for (final index in selected) evidence[index].path]
        : original;
    return ReceiptStitchOrderPlan(
      originalPaths: original,
      orderedPaths: ordered,
      confidence: weakestPair.clamp(0.0, 1.0),
      changed: changed,
      requiresReview: !isClear,
      reasonCode: changed
          ? 'ocr_overlap_order_corrected'
          : isClear
          ? 'ocr_overlap_order_confirmed'
          : 'ocr_overlap_order_ambiguous',
    );
  }
}

bool receiptStitchTextSafelyAcceleratesGeometry(
  ReceiptStitchTextEvidence previous,
  ReceiptStitchTextEvidence next,
  ReceiptStitchTextPairEvidence match,
) {
  if (!match.isStrong || match.matchedLineCount < 2) return false;
  if (match.usesSparsePositionAnchors) return true;
  final previousLines = previous.normalizedLines;
  final nextLines = next.normalizedLines;
  final previousEnd = previousLines.length - match.previousTailOffset;
  final previousStart = previousEnd - match.matchedLineCount;
  final nextStart = match.nextHeadOffset;
  final nextEnd = nextStart + match.matchedLineCount;
  if (previousStart < 0 ||
      previousEnd > previousLines.length ||
      nextStart < 0 ||
      nextEnd > nextLines.length) {
    return false;
  }
  return previousLines.sublist(previousStart, previousEnd).toSet().length >=
          2 &&
      nextLines.sublist(nextStart, nextEnd).toSet().length >= 2;
}

double _receiptHeaderHint(ReceiptStitchTextEvidence evidence) {
  final text = evidence.normalizedLines.take(6).join(' ');
  const terms = ['store', 'address', 'phone', 'tel', 'receipt', 'invoice'];
  final matches = terms.where(text.contains).length;
  return (matches / 2).clamp(0.0, 1.0);
}

double _receiptFooterHint(ReceiptStitchTextEvidence evidence) {
  final lines = evidence.normalizedLines;
  final text = lines.skip(lines.length > 8 ? lines.length - 8 : 0).join(' ');
  const terms = [
    'subtotal',
    'total',
    'amount due',
    'balance',
    'thank you',
    'importe',
    'gracias',
  ];
  final matches = terms.where(text.contains).length;
  return (matches / 2).clamp(0.0, 1.0);
}

int _minInt(int left, int right) => left < right ? left : right;
