import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  test('storage refusal explains user-controlled recovery', () async {
    for (final free in <int?>[0, null]) {
      final service = DeviceWorkloadService(
        probe: () async => DeviceWorkloadProfile(freeStorageBytes: free),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.run(
          (_) async => fail('storage refusal must not run the writer'),
          request: const DeviceWorkloadRequest(storageBytes: 1),
        ),
        throwsA(isA<DeviceWorkloadUnavailable>().having(
          (error) => error.message,
          'recovery message',
          free == null
              ? contains('could not be checked')
              : allOf(contains('Choose what to remove'),
                  contains('Nothing is deleted automatically')),
        )),
      );
    }
  });
  test('unknown native boolean observations remain unknown, not healthy', () {
    for (final invalid in [null, 'false', 0, [], {}]) {
      final profile = DeviceWorkloadProfile.fromMap({
        'probeAvailable': true,
        'physicalRamMb': 12288,
        'availableRamMb': 4096,
        'cpuCores': 8,
        'mediaPerformanceClass': 35,
        'applicationHeapMb': 512,
        'thermalState': 'nominal',
        'lowRam': invalid,
        'lowMemory': invalid,
        'powerSaving': invalid,
      });
      expect(profile.lowRam, isNull);
      expect(profile.lowMemory, isNull);
      expect(profile.powerSaving, isNull);
      expect(profile.tier.index, lessThanOrEqualTo(2));
    }
    final observed = DeviceWorkloadProfile.fromMap({
      'lowRam': false,
      'lowMemory': false,
      'powerSaving': false,
    });
    expect(observed.lowRam, isFalse);
    expect(observed.lowMemory, isFalse);
    expect(observed.powerSaving, isFalse);
  });
  test('exactly six tiers; no device identity in diagnostic output', () {
    expect(DeviceWorkloadTier.values.length, 6);
    final p = DeviceWorkloadProfile.fromMap({
      'probeAvailable': true,
      'physicalRamMb': 12000,
      'cpuCores': 8,
      'mediaPerformanceClass': 35,
      'applicationHeapMb': 512,
      'availableRamMb': 4000,
      'thermalState': 'nominal',
      'registeredOwner': 'secret-person',
      'deviceId': 'secret-device',
    });
    expect(p.baselineTier, DeviceWorkloadTier.flagship);
    expect(p.toSafeDiagnostics().toString(), isNot(contains('secret')));
    expect(p.toSafeDiagnostics().toString(), isNot(contains('12000')));
  });
  test('independent capacity bands and pressure never increase baseline', () {
    final cases = [
      (2048, 4, 0, 0),
      (4096, 4, 0, 1),
      (6144, 8, 0, 2),
      (8192, 8, 0, 3),
      (8192, 8, 31, 4),
      (12288, 8, 35, 5),
    ];
    for (final (ram, cores, media, tier) in cases) {
      final p = DeviceWorkloadProfile(
        physicalRamMb: ram,
        cpuCores: cores,
        mediaPerformanceClass: media,
        heapMb: 512,
        availableRamMb: 4000,
        thermal: 'nominal',
      );
      expect(p.baselineTier.index, tier);
      for (final heat in [
        'unknown',
        'nominal',
        'fair',
        'serious',
        'critical',
      ]) {
        final pressured = DeviceWorkloadProfile(
          physicalRamMb: ram,
          cpuCores: cores,
          mediaPerformanceClass: media,
          heapMb: 512,
          availableRamMb: 4000,
          thermal: heat,
          powerSaving: true,
        );
        expect(pressured.tier.index, lessThanOrEqualTo(tier));
      }
    }
  });
  test('malformed and nonfinite inputs never manufacture capacity', () {
    for (final bad in [double.nan, double.infinity, -1, 1.5, '8192', [], {}]) {
      final p = DeviceWorkloadProfile.fromMap({
        'physicalRamMb': bad,
        'availableRamMb': bad,
        'freeStorageBytes': bad,
        'cpuCores': bad,
      });
      expect(p.physicalRamMb, isNull);
      expect(p.availableRamMb, isNull);
      expect(p.freeStorageBytes, isNull);
      expect(p.tier, DeviceWorkloadTier.constrained);
    }
    final zero = DeviceWorkloadProfile.fromMap({
      'probeAvailable': true,
      'availableRamMb': 0,
      'freeStorageBytes': 0,
    });
    expect(zero.availableRamMb, 0);
    expect(zero.freeStorageBytes, 0);
    expect(zero.deferHeavyWork, isTrue);
  });
  test(
    '100 MiB reserve plus full scratch budget at exact byte boundary',
    () async {
      const reserve =
          104857600; // Independent owner requirement, conservative MiB.
      const scratch = 16777216;
      for (final free in [reserve + scratch - 1, reserve + scratch, 0]) {
        final service = DeviceWorkloadService(
          probe: () async => DeviceWorkloadProfile(freeStorageBytes: free),
        );
        addTearDown(service.dispose);
        var ran = false;
        final work = service.run((_) async {
          ran = true;
        }, request: const DeviceWorkloadRequest(storageBytes: scratch));
        if (free < reserve + scratch) {
          await expectLater(work, throwsA(isA<DeviceWorkloadUnavailable>()));
          expect(ran, isFalse);
        } else {
          await work;
          expect(ran, isTrue);
        }
      }
    },
  );
  test(
    'unknown storage refuses writes while allowing bounded memory work',
    () async {
      final service = DeviceWorkloadService(
        probe: () async => const DeviceWorkloadProfile(),
      );
      addTearDown(service.dispose);
      await expectLater(
        service.run(
          (_) async => 1,
          request: const DeviceWorkloadRequest(storageBytes: 1),
        ),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(await service.run((_) async => 2), 2);
    },
  );
  test(
    'heat while plugged in still blocks; critically low battery blocks',
    () async {
      for (final profile in [
        const DeviceWorkloadProfile(thermal: 'critical', externalPower: true),
        const DeviceWorkloadProfile(
          batteryTemperatureC: 46,
          externalPower: true,
        ),
        const DeviceWorkloadProfile(batteryPercent: 0),
      ]) {
        final service = DeviceWorkloadService(probe: () async => profile);
        addTearDown(service.dispose);
        await expectLater(
          service.run((_) async => fail('unsafe work executed')),
          throwsA(isA<DeviceWorkloadUnavailable>()),
        );
      }
    },
  );
  test(
    'live pressure suppresses result and retains slot through cleanup',
    () async {
      var hot = false;
      final native = Completer<int>();
      final service = DeviceWorkloadService(
        probe: () async =>
            DeviceWorkloadProfile(thermal: hot ? 'critical' : 'nominal'),
      );
      addTearDown(service.dispose);
      final started = Completer<void>();
      final work = service.run((_) {
        started.complete();
        return native.future;
      });
      await started.future;
      hot = true;
      await service.refresh();
      expect(service.stopRequested, isTrue);
      expect(service.busy, isTrue);
      final check = expectLater(
        work,
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      native.complete(1);
      await check;
      expect(service.busy, isFalse);
      hot = false;
      expect(await service.run((_) async => 2), 2);
    },
  );
  test(
    'coalesced refresh callers await fresh data and stale data is rejected',
    () async {
      final probe = Completer<DeviceWorkloadProfile>();
      final service = DeviceWorkloadService(
        probe: () => probe.future,
        now: () => DateTime.utc(2026, 9, 19, 12),
      );
      addTearDown(service.dispose);
      final first = service.refresh();
      final second = service.refresh();
      expect(identical(first, second), isTrue);
      probe.complete(
        DeviceWorkloadProfile(observedAt: DateTime.utc(2026, 9, 19, 11)),
      );
      expect((await second).probeAvailable, isFalse);
    },
  );
  test('capability availability is not permission or tracking opt-in', () {
    final facts = DeviceCapabilityFacts.fromMap({
      'stepCounter': {'availability': 'available', 'permission': 'denied'},
      'location': {
        'availability': 'available',
        'permission': 'granted',
        'serviceEnabled': false,
      },
    });
    expect(facts[DeviceFeature.stepCounter].technicallyUsable, isFalse);
    expect(facts[DeviceFeature.location].technicallyUsable, isFalse);
    expect(
      facts[DeviceFeature.gyroscope].availability,
      CapabilityAvailability.unknown,
    );
  });
}
