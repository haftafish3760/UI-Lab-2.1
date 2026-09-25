import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_resource_monitor.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('memory warning while idle blocks the next admission until recovery', () async {
    var now = DateTime.utc(2026, 9, 19);
    final service = DeviceWorkloadService(now: () => now,
      probe: () async => const DeviceWorkloadProfile());
    addTearDown(service.dispose);
    service.signalMemoryPressure();
    await expectLater(service.run((_) async => fail('work after memory warning')),
      throwsA(isA<DeviceWorkloadUnavailable>()));
    now = now.add(const Duration(seconds: 11));
    expect(await service.run((_) async => 1), 1);
  });
  test('memory stop remains latched with its reason after a healthy refresh', () async {
    var now = DateTime.utc(2026, 9, 19);
    final service = DeviceWorkloadService(now: () => now,
      probe: () async => const DeviceWorkloadProfile());
    addTearDown(service.dispose);
    final started = Completer<void>();
    final native = Completer<int>();
    final running = service.run((_) { started.complete(); return native.future; });
    await started.future;
    service.signalMemoryPressure();
    now = now.add(const Duration(seconds: 11));
    await service.refresh();
    expect(service.stopRequested, isTrue);
    expect(service.status.reasons, contains('memoryPressure'));
    final completion = expectLater(running, throwsA(isA<DeviceWorkloadUnavailable>()));
    native.complete(1);
    await completion;
  });
  testWidgets('monitor refreshes on resume, listens once and detaches on dispose', (tester) async {
    var probes = 0;
    final events = StreamController<Object?>.broadcast();
    final service = DeviceWorkloadService(probe: () async {
      probes++;
      return const DeviceWorkloadProfile();
    });
    final monitor = DeviceResourceMonitor(service, events: events.stream);
    monitor.start();
    monitor.start();
    await tester.pump();
    expect(probes, 1);
    monitor.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(probes, 2);
    events.add('memory');
    await tester.pump();
    expect(service.status.reasons, contains('memoryPressure'));
    await monitor.dispose();
    final before = probes;
    events.add('thermal');
    await tester.pump(const Duration(seconds: 1));
    expect(probes, before);
    await events.close();
    await service.dispose();
  });
}
