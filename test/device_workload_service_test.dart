import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  test(
    'in-task checkpoint stops on heat and keeps gate until cleanup',
    () async {
      var probes = 0;
      final service = DeviceWorkloadService(
        probe: () async => DeviceWorkloadProfile(
          thermal: ++probes > 1 ? 'serious' : 'nominal',
        ),
      );
      var cleanup = false;
      await expectLater(
        service.run((_) async {
          try {
            await service.checkpoint();
          } finally {
            expect(service.busy, isTrue);
            cleanup = true;
          }
        }),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(cleanup, isTrue);
      expect(service.busy, isFalse);
      await expectLater(service.checkpoint(), throwsStateError);
    },
  );
  test('unknown hardware is limited; RAM alone does not earn capable tier', () {
    expect(const DeviceWorkloadProfile().tier, DeviceWorkloadTier.limited);
    expect(
      const DeviceWorkloadProfile(physicalRamMb: 8192).tier,
      DeviceWorkloadTier.standard,
    );
    expect(
      const DeviceWorkloadProfile(
        physicalRamMb: 8192,
        availableRamMb: 4096,
      ).tier,
      DeviceWorkloadTier.balanced,
    );
    expect(
      const DeviceWorkloadProfile(
        physicalRamMb: 8192,
        availableRamMb: 4096,
        lowRam: true,
      ).tier,
      DeviceWorkloadTier.limited,
    );
  });
  test('power and thermal conditions reduce work; severe heat defers it', () {
    expect(
      const DeviceWorkloadProfile(physicalRamMb: 8192, powerSaving: true).tier,
      DeviceWorkloadTier.limited,
    );
    expect(
      const DeviceWorkloadProfile(thermal: 'serious').deferHeavyWork,
      isTrue,
    );
    expect(
      DeviceWorkloadProfile.fromMap({'availableRamMb': 0}).deferHeavyWork,
      isTrue,
    );
    expect(
      DeviceWorkloadProfile.fromMap({'physicalRamMb': -1}).tier,
      DeviceWorkloadTier.limited,
    );
  });
  test('timeout never releases the native work slot prematurely', () async {
    final service = DeviceWorkloadService(
      probe: () async => const DeviceWorkloadProfile(),
    );
    final native = Completer<int>();
    final running = service.run((_) => native.future);
    await expectLater(
      running.timeout(Duration.zero),
      throwsA(isA<TimeoutException>()),
    );
    expect(service.busy, isTrue);
    await expectLater(
      service.run((_) async => 2),
      throwsA(isA<DeviceWorkloadUnavailable>()),
    );
    native.complete(1);
    expect(await running, 1);
    expect(service.busy, isFalse);
  });
  test(
    'each admission refreshes conditions and a failed task releases resources',
    () async {
      var calls = 0;
      final service = DeviceWorkloadService(
        probe: () async {
          calls++;
          return DeviceWorkloadProfile(lowMemory: calls > 1);
        },
      );
      await expectLater(
        service.run((_) async => throw StateError('failure')),
        throwsStateError,
      );
      expect(service.busy, isFalse);
      var invoked = false;
      await expectLater(
        service.run((_) async {
          invoked = true;
        }),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(invoked, isFalse);
      expect(calls, 2);
      expect(service.busy, isFalse);
    },
  );
  test('probe failure does not reuse a stale capable profile', () async {
    final service = DeviceWorkloadService(
      probe: () async => throw StateError('probe'),
    );
    await expectLater(service.run((p) async => p.tier),
        throwsA(isA<DeviceWorkloadUnavailable>()));
  });
}
