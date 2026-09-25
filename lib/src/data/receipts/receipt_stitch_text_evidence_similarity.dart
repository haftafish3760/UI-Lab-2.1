part of 'receipt_stitch_text_evidence.dart';

Map<String, int> _receiptLineCounts(List<String> lines) {
  final counts = <String, int>{};
  for (final line in lines) {
    counts.update(line, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

double _receiptStitchLineSimilarity(String left, String right) {
  if (left == right) return 1;
  if (left.isEmpty || right.isEmpty) return 0;
  final leftTokens = left.split(' ').where((token) => token.length > 1).toSet();
  final rightTokens = right
      .split(' ')
      .where((token) => token.length > 1)
      .toSet();
  if (leftTokens.isEmpty || rightTokens.isEmpty) return 0;
  final shared = leftTokens.intersection(rightTokens).length;
  final union = leftTokens.union(rightTokens).length;
  final tokenScore = union == 0 ? 0.0 : shared / union;
  final leftBigrams = _receiptStitchBigrams(left);
  final rightBigrams = _receiptStitchBigrams(right);
  final sharedBigrams = leftBigrams.intersection(rightBigrams).length;
  final bigramUnion = leftBigrams.union(rightBigrams).length;
  final bigramScore = bigramUnion == 0 ? 0.0 : sharedBigrams / bigramUnion;
  final score = (tokenScore * .62 + bigramScore * .38).clamp(0.0, 1.0);
  final leftNumbers = RegExp(
    r'\d+(?:[.,]\d+)?',
  ).allMatches(left).map((match) => match.group(0)).toSet();
  final rightNumbers = RegExp(
    r'\d+(?:[.,]\d+)?',
  ).allMatches(right).map((match) => match.group(0)).toSet();
  if (leftNumbers.isNotEmpty &&
      rightNumbers.isNotEmpty &&
      !_sameReceiptNumberTokens(leftNumbers, rightNumbers)) {
    return score.clamp(0.0, .44);
  }
  return score;
}

Set<String> _receiptStitchBigrams(String value) {
  final compact = value.replaceAll(' ', '');
  if (compact.length < 2) return {compact};
  return {
    for (var index = 0; index < compact.length - 1; index++)
      compact.substring(index, index + 2),
  };
}

bool _isDistinctiveReceiptLine(String value) {
  if (value.length < 6) return false;
  final tokens = value.split(' ').where((token) => token.length > 1).length;
  return tokens >= 2 || RegExp(r'\d').hasMatch(value);
}

bool _isUniqueReceiptOverlapLine(String value) {
  if (!_isDistinctiveReceiptLine(value) || value.length < 12) return false;
  const genericTerms = [
    'subtotal',
    'total',
    'tax',
    'balance',
    'amount due',
    'payment',
    'thank you',
  ];
  return !genericTerms.any(value.startsWith);
}

bool _sameReceiptNumberTokens(Set<String?> left, Set<String?> right) {
  if (left.length != right.length) return false;
  return left.every(right.contains);
}

String _normalizeReceiptStitchLine(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}
