import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  test(
    'timed-out native probe keeps ownership and late results are ignored',
    () async {
      final stalled = Completer<DeviceWorkloadProfile>();
      var calls = 0;
      final service = DeviceWorkloadService(
        probeTimeout: const Duration(milliseconds: 10),
        probe: () {
          calls++;
          return calls == 1
              ? stalled.future
              : Future.value(const DeviceWorkloadProfile(thermal: 'fair'));
        },
      );
      addTearDown(service.dispose);
      expect((await service.refresh()).probeAvailable, isFalse);
      for (var attempt = 0; attempt < 10; attempt++) {
        await expectLater(
          service.run((_) async => fail('stalled probe admitted work')),
          throwsA(isA<DeviceWorkloadUnavailable>()),
        );
      }
      expect(calls, 1);
      stalled.complete(const DeviceWorkloadProfile(thermal: 'nominal'));
      await Future<void>.delayed(Duration.zero);
      expect(service.latest.probeAvailable, isFalse);
      expect((await service.refresh()).thermal, 'fair');
      expect(calls, 2);
    },
  );

  test(
    'late probe failure is consumed and permits a subsequent fresh probe',
    () async {
      final stalled = Completer<DeviceWorkloadProfile>();
      var calls = 0;
      final service = DeviceWorkloadService(
        probeTimeout: const Duration(milliseconds: 10),
        probe: () => ++calls == 1
            ? stalled.future
            : Future.value(const DeviceWorkloadProfile()),
      );
      addTearDown(service.dispose);
      await service.refresh();
      stalled.completeError(StateError('native failure after deadline'));
      await Future<void>.delayed(Duration.zero);
      expect((await service.refresh()).probeAvailable, isTrue);
      expect(calls, 2);
    },
  );

  test(
    'concurrent refresh callers both await the pending observation',
    () async {
      final probe = Completer<DeviceWorkloadProfile>();
      var calls = 0;
      final service = DeviceWorkloadService(
        probe: () {
          calls++;
          return probe.future;
        },
      );
      addTearDown(service.dispose);
      var completed = 0;
      final first = service.refresh().then((_) => completed++);
      final second = service.refresh().then((_) => completed++);
      await Future<void>.delayed(Duration.zero);
      expect(calls, 1);
      expect(completed, 0);
      probe.complete(const DeviceWorkloadProfile(thermal: 'critical'));
      await Future.wait([first, second]);
      expect(completed, 2);
      expect(service.status.reasons, contains('thermalPressure'));
    },
  );

  test('disposal during an idle probe suppresses late publication', () async {
    final probe = Completer<DeviceWorkloadProfile>();
    final service = DeviceWorkloadService(probe: () => probe.future);
    final events = <DeviceWorkloadStatus>[];
    final subscription = service.changes.listen(events.add);
    final pending = service.refresh();
    await service.dispose();
    probe.complete(const DeviceWorkloadProfile());
    await pending;
    expect(events, isEmpty);
    expect(service.latest.probeAvailable, isFalse);
    await subscription.cancel();
  });

  test(
    'memory event preserves already published thermal stop evidence',
    () async {
      final service = DeviceWorkloadService(
        probe: () async => const DeviceWorkloadProfile(thermal: 'critical'),
      );
      addTearDown(service.dispose);
      await service.refresh();
      service.signalMemoryPressure();
      expect(
        service.status.reasons,
        containsAll(['thermalPressure', 'memoryPressure']),
      );
    },
  );

  test(
    'memory warning during preflight cannot vanish after cooldown',
    () async {
      var now = DateTime.utc(2026, 9, 19);
      final probe = Completer<DeviceWorkloadProfile>();
      final service = DeviceWorkloadService(
        now: () => now,
        probe: () => probe.future,
      );
      addTearDown(service.dispose);
      var ran = false;
      final running = service.run((_) async => ran = true);
      final rejected = expectLater(
        running,
        throwsA(
          isA<DeviceWorkloadUnavailable>().having(
            (error) => error.reasons,
            'reasons',
            contains('memoryPressure'),
          ),
        ),
      );
      service.signalMemoryPressure();
      now = now.add(const Duration(seconds: 11));
      probe.complete(const DeviceWorkloadProfile());
      await rejected;
      expect(ran, isFalse);
      expect(service.busy, isFalse);
    },
  );
}
