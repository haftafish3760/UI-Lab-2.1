import 'device_feature_capabilities.dart';

enum DeviceEvidenceConfidence { unknown, low, medium, high }

/// The audited 5.7 score and grade, using public capability evidence only.
/// These are heuristics, never a benchmark or an independent permission to work.
class DeviceHardwareAssessment {
  const DeviceHardwareAssessment._(this.score, this.measuredSignals);
  final int score, measuredSignals;

  factory DeviceHardwareAssessment.fromEvidence({
    int? ramMiB,
    int? cores,
    int? heapMiB,
    int? mediaPerformanceClass,
    DeviceExtendedCapabilities extended = const DeviceExtendedCapabilities(),
  }) {
    var score = 0;
    var signals = 0;
    if (ramMiB != null && ramMiB > 0) {
      signals++;
      score += switch (ramMiB) {
        <= 3072 => -2,
        <= 4096 => 0,
        <= 6144 => 2,
        <= 8192 => 4,
        <= 12288 => 5,
        _ => 6,
      };
    }
    if (cores != null && cores > 0) {
      signals++;
      score += switch (cores) {
        <= 4 => -1,
        <= 6 => 1,
        <= 8 => 2,
        _ => 3,
      };
    }
    if (heapMiB != null && heapMiB > 0) {
      signals++;
      score += switch (heapMiB) {
        < 192 => -1,
        >= 512 => 2,
        >= 256 => 1,
        _ => 0,
      };
    }
    if (mediaPerformanceClass != null && mediaPerformanceClass > 0) {
      signals++;
      score += switch (mediaPerformanceClass) {
        >= 35 => 5,
        >= 34 => 4,
        >= 33 => 3,
        >= 31 => 2,
        _ => 0,
      };
    }
    if (extended.graphics.supportsCompute == true &&
        extended.media.hardwareDecodeTypes.isNotEmpty) {
      signals++;
      score++;
      if (extended.media.canHardwareDecode('av1') &&
          extended.media.canHardwareEncode('hevc')) {
        score++;
      }
    }
    return DeviceHardwareAssessment._(score, signals);
  }

  DeviceEvidenceConfidence get confidence => switch (measuredSignals) {
    0 => DeviceEvidenceConfidence.unknown,
    1 => DeviceEvidenceConfidence.low,
    2 => DeviceEvidenceConfidence.medium,
    _ => DeviceEvidenceConfidence.high,
  };

  /// Unknown evidence stays ungraded rather than inventing an entry-level phone.
  int? get grade => measuredSignals == 0
      ? null
      : switch (score) {
          <= -3 => 1,
          <= -1 => 2,
          <= 1 => 3,
          <= 3 => 4,
          <= 5 => 5,
          <= 7 => 6,
          <= 9 => 7,
          <= 11 => 8,
          <= 13 => 9,
          _ => 10,
        };

  int? gradeCappedToTier(int tierIndex) {
    final value = grade;
    if (value == null) return null;
    return value.clamp(1, const [2, 3, 5, 6, 8, 10][tierIndex.clamp(0, 5)]);
  }
}
