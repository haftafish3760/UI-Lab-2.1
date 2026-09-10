import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_database.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/native_device_media_gateway.dart';

class _Gateway extends NativeDeviceMediaGateway {
  _Gateway(this.events) : super(useAndroidJournal: true);
  final List<String> events;
  @override
  Future<List<MediaPickerReturnedFile>> pick(
    MediaPickerSource source,
    MediaPickerDestination destination,
  ) async {
    events.add('pick');
    return [];
  }

  @override
  Future<List<MediaPickerReturnedFile>> recover() async {
    events.add('legacy');
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('maintainiac/native_media_journal');
  late LocalDatabase database;
  late LocalMediaPickerRequest request;
  late List<String> events;
  late _Gateway gateway;
  setUp(() async {
    database = LocalDatabase(NativeDatabase.memory());
    request = await LocalMediaPickerRequestStore(database).begin(
      organizationId: 'business',
      ownerId: 'owner',
      destination: MediaPickerDestination.estimate,
      targetId: 'estimate-input',
      targetRevision: 1,
      source: MediaPickerSource.camera,
    );
    events = [];
    gateway = _Gateway(events);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await database.close();
  });
  void handle(Future<Object?> Function(MethodCall) callback) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, callback);
  }

  test(
    'native intent is acknowledged before launching; failure stops launch',
    () async {
      handle((call) async {
        expect(call.arguments, request.requestId);
        events.add(call.method);
        return null;
      });
      await gateway.pickForRequest(request);
      expect(events, ['begin', 'pick']);
      events.clear();
      handle((call) async {
        throw PlatformException(code: 'disk_failure');
      });
      await expectLater(
        gateway.pickForRequest(request),
        throwsA(isA<PlatformException>()),
      );
      expect(events, isEmpty);
    },
  );

  test(
    'replay and terminal acknowledgement never consume unrelated legacy cache',
    () async {
      handle((call) async {
        expect(call.method, 'recover');
        expect(call.arguments, request.requestId);
        return {
          'paths': ['/private/retained.image'],
          'needsLegacyRecovery': false,
        };
      });
      expect(
        (await gateway.recoverForRequest(request)).single.path,
        '/private/retained.image',
      );
      expect(events, isEmpty);
      handle((call) async => {'paths': [], 'needsLegacyRecovery': false});
      expect(await gateway.recoverForRequest(request), isEmpty);
      expect(events, isEmpty);
      handle((call) async => {'paths': [], 'needsLegacyRecovery': true});
      await gateway.recoverForRequest(request);
      expect(events, ['legacy']);
    },
  );

  test(
    'malformed native response and premature acknowledgement fail closed',
    () async {
      handle((call) async => {'paths': []});
      await expectLater(gateway.recoverForRequest(request), throwsStateError);
      await expectLater(gateway.acknowledgeRetained(request), throwsStateError);
      expect(events, isEmpty);
    },
  );
}
