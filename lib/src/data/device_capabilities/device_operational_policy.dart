import 'device_workload_profile.dart';

/// Shared whole-app advice. Admission still belongs to DeviceWorkloadService;
/// this value cannot authorize tracking, transfers, permissions or file writes.
class DeviceOperationalPolicy {
  const DeviceOperationalPolicy(this.profile);
  final DeviceWorkloadProfile profile;

  bool get deferNonEssentialWork =>
      profile.deferHeavyWork ||
      profile.powerSaving != false ||
      profile.thermal == 'unknown';

  bool allowsLargeTransferAt(DateTime now) =>
      profile.isFreshAt(now) &&
      !deferNonEssentialWork &&
      profile.extended.connectivity.permitsLargeTransfer;

  String get preferredHardwareVideoCodec {
    final codecs = profile.extended.media;
    if (codecs.canHardwareEncode('hevc')) return 'hevc';
    if (codecs.canHardwareEncode('h264')) return 'h264';
    return 'platformDefault';
  }

  int get maxVideoHeight =>
      const [720, 720, 1080, 1080, 2160, 2160][profile.tier.index];

  /// Processing budget, not capture resolution. A large sensor does not entitle
  /// its consumer to allocate a full-resolution bitmap. Unknown stays unknown.
  int? get maxCameraProcessingPixels {
    final lenses = profile.extended.cameraLenses;
    var supported = 0;
    for (final lens in lenses) {
      final pixels = lens.maxStillWidth * lens.maxStillHeight;
      if (pixels > supported) supported = pixels;
    }
    if (supported == 0) return null;
    return supported < profile.maxImagePixels
        ? supported
        : profile.maxImagePixels;
  }
}
