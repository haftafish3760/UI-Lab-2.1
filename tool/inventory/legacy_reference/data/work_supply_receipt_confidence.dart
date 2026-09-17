enum ReceiptConfidenceLevel { good, okay, poor }

ReceiptConfidenceLevel receiptConfidenceLevelFor(double confidence) {
  if (confidence >= 0.82) return ReceiptConfidenceLevel.good;
  if (confidence >= 0.62) return ReceiptConfidenceLevel.okay;
  return ReceiptConfidenceLevel.poor;
}

String receiptConfidenceLabel(ReceiptConfidenceLevel level) {
  return switch (level) {
    ReceiptConfidenceLevel.good => 'Good',
    ReceiptConfidenceLevel.okay => 'Review',
    ReceiptConfidenceLevel.poor => 'Poor',
  };
}

String receiptConfidenceGuidance(ReceiptConfidenceLevel level) {
  return switch (level) {
    ReceiptConfidenceLevel.good => 'Matched with strong confidence.',
    ReceiptConfidenceLevel.okay => 'Review this line before saving.',
    ReceiptConfidenceLevel.poor =>
      'Low confidence. Correct manually or retake the receipt photo.',
  };
}
