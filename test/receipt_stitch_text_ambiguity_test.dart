import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_text_evidence.dart';

ReceiptStitchTextEvidence evidence(String path, List<String> lines) =>
    ReceiptStitchTextEvidence(
      path: path,
      lines: lines,
      positionedLines: [
        for (var i = 0; i < lines.length; i++)
          ReceiptStitchTextLineEvidence(
            text: lines[i],
            left: .1,
            right: .9,
            top: i / lines.length,
            bottom: (i + .8) / lines.length,
          ),
      ],
    );

void main() {
  test('blank OCR detections do not shift overlap coordinates', () {
    final a = evidence('a', ['', 'COPPER ELBOW 2.49', 'PVC TEE 1.20']);
    final b = evidence('b', [
      'COPPER ELBOW 2.49',
      '',
      'PVC TEE 1.20',
      'STEEL BOLT 0.30',
    ]);
    final match = matchReceiptStitchTextOverlap(a, b);
    expect(match.isStrong, isTrue);
    expect(match.previousOverlapStart, closeTo(1 / 3, .0001));
    expect(match.nextOverlapEnd, closeTo(2.8 / 4, .0001));
    expect(match.previousAnchorCenters.first, closeTo(1.4 / 3, .0001));
  });
  test('fifty identical printed rows cannot establish a unique overlap', () {
    final rows = List.filled(50, 'COPPER ELBOW 1/2 2.49');
    final a = evidence('a', rows);
    final b = evidence('b', rows);
    final match = matchReceiptStitchTextOverlap(a, b);
    expect(match.isStrong, isFalse);
    expect(receiptStitchTextSafelyAcceleratesGeometry(a, b, match), isFalse);
    expect(a.lines.length, 50);
    expect(b.lines.length, 50);
  });
  test('alternating repeated products cannot establish a unique overlap', () {
    final rows = [
      for (var i = 0; i < 25; i++) ...[
        'COPPER ELBOW 1/2 2.49',
        'PVC TEE 3/4 1.20',
      ],
    ];
    expect(
      matchReceiptStitchTextOverlap(
        evidence('a', rows),
        evidence('b', rows),
      ).isStrong,
      isFalse,
    );
  });
  test('distinct overlapping purchases remain usable text evidence', () {
    final a = ReceiptStitchTextEvidence(
      path: 'a',
      lines: const ['PAINT BRUSH 8.00', 'COPPER ELBOW 2.49', 'PVC TEE 1.20'],
    );
    final b = ReceiptStitchTextEvidence(
      path: 'b',
      lines: const ['COPPER ELBOW 2.49', 'PVC TEE 1.20', 'STEEL BOLT 0.30'],
    );
    final match = matchReceiptStitchTextOverlap(a, b);
    expect(match.isStrong, isTrue);
    expect(match.matchedLineCount, 2);
  });
}
