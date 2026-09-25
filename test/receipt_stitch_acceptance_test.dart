import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_acceptance.dart';

ReceiptStitchEvidenceDecision evaluate({
  double visual = .95,
  double geometry = .95,
  int matchingCells = 8,
  bool ambiguous = false,
}) => evaluateReceiptStitchEvidence(
  visualConfidence: visual,
  continuityCorrelation: .95,
  continuityDetailedBands: 5,
  continuityMatchingBands: 5,
  continuityProven: true,
  geometryCorrelation: geometry,
  geometryDetailedCells: 8,
  geometryMatchingCells: matchingCells,
  geometryProven: false,
  textConfidence: .99,
  matchedTextLineCount: 50,
  textStrong: true,
  hasTextPositionEvidence: true,
  textPositionalConfidence: .99,
  ambiguousPlacement: ambiguous,
);

void main() {
  test('corroborated image placement can produce a review candidate', () {
    expect(evaluate().accepted, isTrue);
  });
  test('non-finite confidence never becomes positive evidence', () {
    for (final value in [
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      expect(evaluate(visual: value).accepted, isFalse);
      expect(evaluate(geometry: value).accepted, isFalse);
    }
  });
  test('impossible matching-cell counts are rejected', () {
    expect(evaluate(matchingCells: 9).accepted, isFalse);
    expect(evaluate(matchingCells: -1).accepted, isFalse);
  });
  test('fifty matching text rows cannot replace image geometry', () {
    expect(evaluate(geometry: 0, matchingCells: 0).accepted, isFalse);
  });
  test('competing placements veto otherwise strong repeated-row evidence', () {
    expect(evaluate(ambiguous: true).accepted, isFalse);
  });
  test('an empty or single-pixel image has no removable overlap', () {
    for (final height in [0, 1]) {
      expect(
        receiptTextAwareSeamCropPixels(
          geometricOverlapPixels: 10,
          nextImageHeight: height,
          matchedTextEnd: .5,
          continuationTextStart: .6,
          continuationTextEnd: .7,
          hasHighTrustPositionedText: true,
        ),
        0,
      );
    }
  });
}
