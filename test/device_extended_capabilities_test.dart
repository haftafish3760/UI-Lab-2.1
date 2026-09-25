import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_feature_capability_parser.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  const parser = DeviceFeatureCapabilityParser();
  test(
    'local diagnostic context excludes storage and unknown sensor claims',
    () {
      final profile = DeviceWorkloadProfile.fromMap({
        'probeAvailable': true,
        'physicalRamMb': 8192,
        'cpuCores': 8,
        'freeStorageBytes': 123456789,
        'descriptor': {'platform': 'android', 'model': 'Example'},
        'extended': {
          'sensors': {
            'types': ['private-sensor-name', 'type_65536'],
          },
        },
      });
      final context = profile.toLocalDiagnosticContext();
      expect(context['model'], 'Example');
      expect(context['physicalRamMiB'], 8192);
      expect(context.toString(), isNot(contains('123456789')));
      expect(context.toString(), isNot(contains('private-sensor-name')));
      expect(profile.extended.sensors.types, {'type_65536'});
      final unknown = const DeviceWorkloadProfile().toLocalDiagnosticContext();
      expect(unknown['sensorInventoryObserved'], isFalse);
      expect(unknown.containsKey('motionAvailable'), isFalse);
    },
  );
  test('missing facts never authorize network or Bluetooth', () {
    final empty = parser.parse({});
    expect(empty.connectivity.isConnected, isNull);
    expect(empty.connectivity.isMetered, isNull);
    expect(empty.connectivity.permitsLargeTransfer, isFalse);
    expect(empty.bluetooth.poweredOn, isNull);
    expect(empty.bluetooth.canObserveApprovedConnections, isFalse);
    expect(empty.graphics.supportsRayTracing, isNull);
    expect(empty.camera.available, isNull);
    expect(parser.parse({'cameraLenses': []}).camera.available, isFalse);
  });

  test('metadata retains paired dimensions and unknown camera features', () {
    final result = parser.parse({
      'cameraLenses': [
        {
          'position': 'rear',
          'lensType': 'wide',
          'maxStillWidth': 8000,
          'maxStillHeight': 3000,
          'supportsTorch': true,
          'supportsDepth': false,
          'maxZoomRatio': 10.0,
        },
        {'position': 'front', 'maxStillWidth': 4000, 'maxStillHeight': 6000},
      ],
    });
    expect(result.cameraLenses, hasLength(2));
    final lens = result.cameraLenses.first;
    expect(lens.maxStillMegapixels, 24);
    expect(lens.supportsTorch, isTrue);
    expect(lens.supportsDepth, isFalse);
    expect(lens.supportsRaw, isNull);
    expect(lens.maxZoomRatio, 10);
    expect(lens.maxOpticalOrSensorZoom, isNull);
    expect(lens.maxDigitalZoom, isNull);
    expect(result.camera.available, isTrue);
    expect(result.camera.supportsRaw, isNull);
    expect(result.camera.supportsTorch, isTrue);
    expect(result.camera.largestStillLens?.maxStillHeight, 3000);
    expect(() => result.cameraLenses.clear(), throwsUnsupportedError);
  });

  test('malformed numeric and boolean metadata fails closed', () {
    for (final value in <Object?>[
      double.nan,
      double.infinity,
      -1,
      2.5,
      '100',
      {},
      [],
      null,
    ]) {
      final result = parser.parse({
        'battery': {'levelPercent': value},
        'cameraLenses': [
          {'maxStillWidth': value, 'supportsRaw': value},
        ],
        'connectivity': {
          'isConnected': value,
          'isMetered': false,
          'isConstrained': false,
        },
      });
      expect(result.battery.levelPercent, isNull);
      expect(result.cameraLenses.first.maxStillWidth, 0);
      expect(result.cameraLenses.first.supportsRaw, isNull);
      expect(result.connectivity.permitsLargeTransfer, isFalse);
    }
    expect(
      parser
          .parse({
            'battery': {'levelPercent': 0},
          })
          .battery
          .levelPercent,
      0,
    );
  });

  test('codec and transport data are bounded immutable allowlists', () {
    final result = parser.parse({
      'media': {
        'hardwareEncodeTypes': ['hevc', 'serial-secret', 'h264'],
      },
      'connectivity': {
        'transports': ['wifi', 'home-network-name'],
      },
      'cameraLenses': List.generate(1000, (_) => {'position': 'rear'}),
    });
    expect(result.media.hardwareEncodeTypes, {'hevc', 'h264'});
    expect(result.connectivity.transports, {'wifi'});
    expect(result.cameraLenses, hasLength(64));
    expect(
      () => result.media.hardwareEncodeTypes.add('av1'),
      throwsUnsupportedError,
    );
  });

  test('permission and powered state are both needed for Bluetooth', () {
    for (final authorization in ['denied', 'unknown', 'authorized']) {
      for (final power in <bool?>[null, false, true]) {
        final result = parser.parse({
          'bluetooth': {
            'adapterAvailable': true,
            'poweredOn': power,
            'authorization': authorization,
            'supportsApprovedDeviceObservation': true,
          },
        });
        expect(
          result.bluetooth.canObserveApprovedConnections,
          authorization == 'authorized' && power == true,
        );
      }
    }
  });

  test('descriptor excludes owner and unique identifiers', () {
    final result = DeviceDiagnosticDescriptor.fromMap({
      'platform': 'android',
      'model': 'SM-S938U',
      'manufacturer': 'samsung',
      'osVersion': '16',
      'sdk': 36,
      'registeredOwner': 'private-owner',
      'serial': 'private-serial',
      'deviceId': 'private-id',
      'name': 'private-name',
    }).toLocalDiagnostics();
    expect(result['model'], 'SM-S938U');
    expect(
      result.keys,
      unorderedEquals([
        'platform',
        'model',
        'manufacturer',
        'osVersion',
        'sdk',
      ]),
    );
    expect(result.toString(), isNot(contains('private')));
  });

  test('policy rejects stale transfer advice and honors thermal stop', () {
    final now = DateTime.utc(2026, 9, 19);
    final extended = parser.parse({
      'media': {
        'hardwareEncodeTypes': ['hevc'],
      },
      'connectivity': {
        'isConnected': true,
        'isMetered': false,
        'isConstrained': false,
      },
    });
    for (final thermal in ['nominal', 'serious']) {
      final profile = DeviceWorkloadProfile(
        observedAt: now,
        thermal: thermal,
        extended: extended,
      );
      expect(
        profile.operationalPolicy.allowsLargeTransferAt(now),
        thermal == 'nominal',
      );
      expect(
        profile.operationalPolicy.allowsLargeTransferAt(
          now.add(const Duration(seconds: 11)),
        ),
        isFalse,
      );
      expect(profile.operationalPolicy.preferredHardwareVideoCodec, 'hevc');
      expect(profile.operationalPolicy.maxCameraProcessingPixels, isNull);
    }
  });

  test('native envelope feeds the existing profile, not another service', () {
    final profile = DeviceWorkloadProfile.fromMap({
      'probeAvailable': true,
      'physicalRamMb': 4096,
      'descriptor': {'platform': 'android', 'model': 'Example'},
      'extended': {
        'sensors': {
          'types': ['step_counter', 'barometer'],
        },
        'display': {'maxRefreshRateHz': 120},
      },
    });
    expect(profile.baselineTier, DeviceWorkloadTier.entry);
    expect(profile.extended.sensors.hasStepDetection, isTrue);
    expect(profile.extended.sensors.hasAltitudeContext, isTrue);
    expect(profile.extended.display.maxRefreshRateHz, 120);
    expect(profile.descriptor.model, 'Example');
  });
}
