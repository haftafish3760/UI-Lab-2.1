/// Non-unique OS-provided product metadata. Never accepts a device/owner name,
/// serial, install ID, account or arbitrary native map for diagnostic export.
class DeviceDiagnosticDescriptor {
  const DeviceDiagnosticDescriptor({
    this.platform = 'unknown',
    this.osVersion,
    this.manufacturer,
    this.model,
    this.sdk,
    this.isPhysicalDevice,
  });
  final String platform;
  final String? osVersion, manufacturer, model;
  final int? sdk;
  final bool? isPhysicalDevice;

  factory DeviceDiagnosticDescriptor.fromMap(Object? raw) {
    final map = raw is Map ? raw : const {};
    String? label(String key) {
      final value = map[key];
      return value is String &&
              value.length <= 96 &&
              RegExp(r'^[a-zA-Z0-9 ._()+,/-]+$').hasMatch(value)
          ? value
          : null;
    }

    final platform = map['platform'];
    final sdk = map['sdk'];
    return DeviceDiagnosticDescriptor(
      platform:
          const {
            'android',
            'ios',
            'windows',
            'macos',
            'linux',
            'web',
          }.contains(platform)
          ? platform as String
          : 'unknown',
      osVersion: label('osVersion'),
      manufacturer: label('manufacturer'),
      model: label('model'),
      sdk: sdk is int && sdk > 0 && sdk < 1000 ? sdk : null,
      isPhysicalDevice: map['isPhysicalDevice'] is bool
          ? map['isPhysicalDevice'] as bool
          : null,
    );
  }

  /// Local context for a separately governed diagnostics system. Not an uploader.
  Map<String, Object> toLocalDiagnostics() => {
    'platform': platform,
    'osVersion': ?osVersion,
    'manufacturer': ?manufacturer,
    'model': ?model,
    'sdk': ?sdk,
    'physicalDevice': ?isPhysicalDevice,
  };
}
