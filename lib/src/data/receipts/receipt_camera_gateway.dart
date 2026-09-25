import 'dart:async';
import 'package:flutter/services.dart';
import '../device_capabilities/device_workload_service.dart';
import '../storage/local_media_picker_request.dart';
import 'package:path/path.dart' as paths;

/// Holds the shared workload lease until Android's activity result settles.
/// An interrupted return is recovered using the same SQLite request identity.
class ReceiptCameraGateway {
  ReceiptCameraGateway({
    DeviceWorkloadService? workloads,
    MethodChannel? channel,
  }) : _workloads = workloads ?? DeviceWorkloadService.instance,
       _channel = channel ?? const MethodChannel('maintainiac/receipt_camera');
  final DeviceWorkloadService _workloads;
  final MethodChannel _channel;

  Future<List<MediaPickerReturnedFile>> capture(
    String requestKey, {
    Future<Map<String, Object?>> Function()? resolveGuides,
  }) => _workloads.run(
    (profile) async {
      var stopSent = false;
      final events = _workloads.changes.listen((status) {
        if (!status.stopRequested || stopSent) return;
        stopSent = true;
        // A failed stop request cannot release the lease while native capture
        // is alive. The original capture future still owns that lease.
        unawaited(
          _channel
              .invokeMethod<void>('stop', {'requestKey': requestKey})
              .catchError((Object _) {}),
        );
      });
      try {
        final guides = await resolveGuides?.call() ?? const <String, Object?>{};
        _workloads.requireActive();
        final result = await _channel.invokeMapMethod<String, Object?>(
          'capture',
          {
            'requestKey': requestKey,
            'maxLocalPhotoBytes': 12 * 1024 * 1024,
            'maxLiveAnalysisPixels': profile.maxImagePixels,
            'analysisGapMs': (1000 ~/ profile.liveAnalysisFps).clamp(250, 2500),
            if (guides['previousGuide'] != null)
              'previousGuide': guides['previousGuide'],
          },
        );
        if (result == null ||
            result['requestKey'] != requestKey ||
            result['paths'] is! List) {
          throw StateError('Receipt camera returned an invalid result.');
        }
        final returned = (result['paths'] as List).cast<String>();
        if (returned.length > 8 ||
            returned.toSet().length != returned.length ||
            returned.any((path) => path.isEmpty || !paths.isAbsolute(path))) {
          throw StateError('Receipt camera returned invalid photo references.');
        }
        return [
          for (final path in returned)
            MediaPickerReturnedFile(path: path, name: paths.basename(path)),
        ];
      } finally {
        await events.cancel();
      }
    },
    request: const DeviceWorkloadRequest(
      storageBytes: 48 * 1024 * 1024,
      memoryBytes: 48 * 1024 * 1024,
    ),
  );
}
