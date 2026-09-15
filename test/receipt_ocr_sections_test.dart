import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_ocr_sections.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_reader.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_field_proposals.dart';

void main() {
  test('long narrow image retains original horizontal resolution', () {
    final sections = planReceiptOcrSections(640, 8000, 1000000);
    expect(sections.length, greaterThan(1));
    expect(sections.first.top, 0);
    expect(sections.last.bottom, 8000);
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      expect(section.sampleSize, 1);
      expect(section.decodedWidth, 640);
      expect(
        section.decodedWidth * section.decodedHeight,
        lessThanOrEqualTo(1000000),
      );
      if (i > 0) {
        expect(section.top, lessThan(sections[i - 1].bottom));
        expect(section.bottom, greaterThan(sections[i - 1].bottom));
      }
    }
  });

  test('odd dimensions and all budgets cover the source within bounds', () {
    for (final width in [1, 641, 1599, 1601, 4001, 10001]) {
      for (final height in [1, 921, 7999]) {
        for (final budget in [1000000, 2000000, 3000000]) {
          // Extremely narrow/tall inputs deliberately exceed the section cap.
          if (height > width * 40) continue;
          final sections = planReceiptOcrSections(width, height, budget);
          expect(sections.first.top, 0);
          expect(sections.last.bottom, height);
          for (final section in sections) {
            expect(
              section.decodedWidth * section.decodedHeight,
              lessThanOrEqualTo(budget),
            );
            expect(section.sampleSize & (section.sampleSize - 1), 0);
            expect(section.bottom, lessThanOrEqualTo(height));
          }
        }
      }
    }
  });

  test('extreme dimensions and excessive sections fail without truncation', () {
    for (final size in [(0, 8000), (640, 30001), (20000, 20000), (10, 20000)]) {
      expect(
        () => planReceiptOcrSections(size.$1, size.$2, 1000000),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
    }
  });

  ReceiptPhotoText text(List<ReceiptTextLine> lines) =>
      ReceiptPhotoText(text: '', lines: lines);
  test('same physical overlap collapses; repeated purchases remain', () {
    final result = mergeReceiptSectionText([
      text([
        const ReceiptTextLine('COPPER ELBOW 3.49', 20, 700, 300, 730),
        const ReceiptTextLine('COPPER ELBOW 3.49', 20, 750, 300, 780),
      ]),
      text([
        const ReceiptTextLine('COPPER ELBOW 3.49', 21, 751, 301, 781),
        const ReceiptTextLine('COPPER ELBOW 3.49', 20, 800, 300, 830),
      ]),
    ]);
    expect(result.lines, hasLength(3));
    expect(result.warnings, isEmpty);
  });

  test(
    'disagreeing overlap stays visible and cannot silently pick a total',
    () {
      final result = mergeReceiptSectionText([
        text([const ReceiptTextLine('TOTAL 83.40', 20, 1000, 300, 1030)]),
        text([const ReceiptTextLine('TOTAL 88.40', 21, 1001, 301, 1031)]),
      ]);
      expect(result.lines, hasLength(2));
      expect(result.warnings.single, contains('disagree'));
      final proposal = proposeReceiptFields(result);
      expect(proposal.totalMinor, isNull);
      expect(proposal.warnings, contains(result.warnings.single));
    },
  );

  test('side-by-side identical prices are not overlapping duplicates', () {
    final result = mergeReceiptSectionText([
      text([const ReceiptTextLine('3.49', 20, 700, 80, 730)]),
      text([const ReceiptTextLine('3.49', 300, 700, 360, 730)]),
    ]);
    expect(result.lines, hasLength(2));
  });
}
