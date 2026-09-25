import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_ghost_geometry.dart';

void main() {
  test('previous bottom strip belongs at camera top; next top at bottom', () {
    for (final neighbour in ReceiptGhostNeighbour.values) {
      final result = ReceiptGhostGeometry.fit(
        uprightImage: const Size(1000, 2000),
        cameraContent: const Rect.fromLTWH(20, 60, 300, 600),
        neighbour: neighbour,
        sourceFraction: .2,
        maximumBandFraction: .25,
      );
      expect(
        result.source,
        neighbour == ReceiptGhostNeighbour.previous
            ? const Rect.fromLTWH(0, 1600, 1000, 400)
            : const Rect.fromLTWH(0, 0, 1000, 400),
      );
      expect(
        result.destination,
        neighbour == ReceiptGhostNeighbour.previous
            ? const Rect.fromLTWH(20, 60, 300, 120)
            : const Rect.fromLTWH(20, 540, 300, 120),
      );
    }
  });
  test('narrow long reference fits entirely without distortion or crop', () {
    final result = ReceiptGhostGeometry.fit(
      uprightImage: const Size(200, 4000),
      cameraContent: const Rect.fromLTWH(0, 0, 400, 800),
      neighbour: ReceiptGhostNeighbour.previous,
      sourceFraction: .25,
      maximumBandFraction: .25,
    );
    expect(result.destination, const Rect.fromLTWH(180, 0, 40, 200));
    expect(result.source, const Rect.fromLTWH(0, 3000, 200, 1000));
  });
  test('invalid source dimensions are rejected before rendering', () {
    for (final width in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => ReceiptGhostGeometry.fit(
          uprightImage: Size(width, 100),
          cameraContent: const Rect.fromLTWH(0, 0, 400, 800),
          neighbour: ReceiptGhostNeighbour.previous,
          sourceFraction: .2,
          maximumBandFraction: .25,
        ),
        throwsArgumentError,
      );
    }
  });
}
