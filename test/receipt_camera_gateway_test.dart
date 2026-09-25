import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/native_device_media_gateway.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_camera_gateway.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('maintainiac/receipt_camera');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const healthy = DeviceWorkloadProfile(
    physicalRamMb: 4096,
    availableRamMb: 2048,
    heapMb: 256,
    freeStorageBytes: 1024 * 1024 * 1024,
    thermal: 'nominal',
  );
  late DeviceWorkloadService service;
  late ReceiptCameraGateway camera;
  setUp(() {
    service = DeviceWorkloadService(probe: () async => healthy);
    camera = ReceiptCameraGateway(workloads: service);
  });
  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await service.dispose();
  });

  test('camera result must belong to the saved request', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'requestKey': 'different_request', 'paths': <String>[]},
    );
    await expectLater(camera.capture('receipt_expected'), throwsStateError);
    expect(service.busy, isFalse);
  });

  test(
    'receipt route begins native journal before opening transferred camera',
    () async {
      final db = LocalDatabase(NativeDatabase.memory());
      const journal = MethodChannel('maintainiac/native_media_journal');
      final events = <String>[];
      try {
        final request = await LocalMediaPickerRequestStore(db).begin(
          organizationId: 'business',
          ownerId: 'owner',
          destination: MediaPickerDestination.receipt,
          targetId: 'receipt-draft',
          targetRevision: 1,
          source: MediaPickerSource.camera,
        );
        messenger.setMockMethodCallHandler(journal, (call) async {
          expect(call.arguments, request.requestId);
          events.add(call.method);
          return null;
        });
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect((call.arguments as Map)['requestKey'], request.requestId);
          expect(service.busy, isTrue);
          events.add(call.method);
          return {'requestKey': request.requestId, 'paths': <String>[]};
        });
        final gateway = NativeDeviceMediaGateway(
          useAndroidJournal: true,
          receiptCamera: camera,
        );
        expect(await gateway.pickForRequest(request), isEmpty);
        expect(events, ['begin', 'capture']);
      } finally {
        messenger.setMockMethodCallHandler(journal, null);
        await db.close();
      }
    },
  );

  test(
    'valid camera result preserves photo order and waits for native completion',
    () async {
      final reply = Completer<Object?>();
      final launched = Completer<void>();
      final first =
          '${Directory.systemTemp.path}${Platform.pathSeparator}first.jpg';
      final second =
          '${Directory.systemTemp.path}${Platform.pathSeparator}second.jpg';
      messenger.setMockMethodCallHandler(channel, (call) {
        expect(call.method, 'capture');
        expect((call.arguments as Map)['requestKey'], 'receipt_expected');
        launched.complete();
        return reply.future;
      });
      final result = camera.capture('receipt_expected');
      await launched.future;
      expect(service.busy, isTrue);
      await expectLater(
        service.run((_) async {}),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      reply.complete({
        'requestKey': 'receipt_expected',
        'paths': [second, first],
      });
      expect((await result).map((file) => file.path), [second, first]);
      expect(service.busy, isFalse);
    },
  );

  test(
    'resource stop keeps lease until native activity actually settles',
    () async {
      final reply = Completer<Object?>();
      final launched = Completer<void>();
      final stopped = Completer<void>();
      messenger.setMockMethodCallHandler(channel, (call) {
        if (call.method == 'stop') {
          expect((call.arguments as Map)['requestKey'], 'receipt_expected');
          stopped.complete();
          return Future.value(null);
        }
        launched.complete();
        return reply.future;
      });
      final result = camera.capture('receipt_expected');
      final rejected = expectLater(
        result,
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      await launched.future;
      service.signalMemoryPressure();
      await stopped.future;
      expect(service.busy, isTrue);
      reply.complete({'requestKey': 'receipt_expected', 'paths': <String>[]});
      await rejected;
      expect(service.busy, isFalse);
    },
  );

  test('storage reserve prevents camera launch', () async {
    await service.dispose();
    service = DeviceWorkloadService(
      probe: () async => const DeviceWorkloadProfile(
        freeStorageBytes: 120 * 1024 * 1024,
        availableRamMb: 2048,
      ),
    );
    camera = ReceiptCameraGateway(workloads: service);
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return null;
    });
    await expectLater(
      camera.capture('receipt_expected'),
      throwsA(isA<DeviceWorkloadUnavailable>()),
    );
    expect(calls, 0);
  });

  test('duplicate and relative photo paths are rejected', () async {
    final path =
        '${Directory.systemTemp.path}${Platform.pathSeparator}photo.jpg';
    for (final paths in [
      [path, path],
      ['relative.jpg'],
    ]) {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'requestKey': 'receipt_expected', 'paths': paths},
      );
      await expectLater(camera.capture('receipt_expected'), throwsStateError);
    }
  });
}
