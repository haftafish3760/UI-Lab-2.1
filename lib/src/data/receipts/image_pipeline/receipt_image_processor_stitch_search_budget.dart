part of 'receipt_image_processor.dart';

/// Bounds registration work using the comparison width already selected from
/// the device capability profile. This keeps low-tier phones from running the
/// flagship transform search while preserving the same evidence gates.
class _ReceiptStitchSearchBudget {
  const _ReceiptStitchSearchBudget({
    required this.scales,
    required this.rotations,
    required this.perspectiveCorrections,
    required this.rotationBaseCount,
    required this.perspectiveBaseCount,
    required this.continuityCandidateCount,
    required this.coarseOverlapStep,
    required this.refinedOverlapRadius,
    required this.refinedOverlapStep,
    required this.offsetRefinementRadius,
    required this.offsetRefinementStep,
    required this.horizontalOffsetMultiples,
    required this.nextTopOffsets,
  });

  factory _ReceiptStitchSearchBudget.forSampleWidth(int sampleWidth) {
    if (sampleWidth <= 320) {
      return const _ReceiptStitchSearchBudget(
        scales: [1, .94, 1.06],
        rotations: [-1.5, 1.5],
        perspectiveCorrections: [],
        rotationBaseCount: 1,
        perspectiveBaseCount: 0,
        continuityCandidateCount: 4,
        coarseOverlapStep: 36,
        refinedOverlapRadius: 18,
        refinedOverlapStep: 9,
        offsetRefinementRadius: 2,
        offsetRefinementStep: 2,
        horizontalOffsetMultiples: 2,
        nextTopOffsets: [0, 24, 72],
      );
    }
    if (sampleWidth <= 360) {
      return const _ReceiptStitchSearchBudget(
        scales: [1, .94, 1.06, .88, 1.12],
        rotations: [-1, 1, -2.5, 2.5],
        perspectiveCorrections: [],
        rotationBaseCount: 1,
        perspectiveBaseCount: 0,
        continuityCandidateCount: 6,
        coarseOverlapStep: 30,
        refinedOverlapRadius: 18,
        refinedOverlapStep: 6,
        offsetRefinementRadius: 2,
        offsetRefinementStep: 2,
        horizontalOffsetMultiples: 2,
        nextTopOffsets: [0, 16, 40, 80],
      );
    }
    return const _ReceiptStitchSearchBudget(
      // A flagship receives a little more comparison detail, not an
      // effectively unbounded transform matrix. Native registration and OCR
      // anchors are evaluated before this fallback; this list is the bounded
      // safety net when those signals are unavailable or inconclusive.
      scales: [1, .94, 1.06, .88, 1.12],
      rotations: [-1, 1, -2, 2, -4, 4],
      perspectiveCorrections: [-.05, .05],
      rotationBaseCount: 1,
      perspectiveBaseCount: 1,
      continuityCandidateCount: 8,
      coarseOverlapStep: 24,
      refinedOverlapRadius: 18,
      refinedOverlapStep: 6,
      offsetRefinementRadius: 2,
      offsetRefinementStep: 2,
      horizontalOffsetMultiples: 2,
      nextTopOffsets: [0, 12, 36, 72, 120],
    );
  }

  final List<double> scales;
  final List<double> rotations;
  final List<double> perspectiveCorrections;
  final int rotationBaseCount;
  final int perspectiveBaseCount;
  final int continuityCandidateCount;
  final int coarseOverlapStep;
  final int refinedOverlapRadius;
  final int refinedOverlapStep;
  final int offsetRefinementRadius;
  final int offsetRefinementStep;
  final int horizontalOffsetMultiples;
  final List<int> nextTopOffsets;
}
