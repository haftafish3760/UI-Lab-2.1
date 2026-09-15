import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/startup/firebase_connection.dart';

void main() {
  test(
    'failed initialization retries only on a new explicit request',
    () async {
      var calls = 0;
      final connection = FirebaseConnection(
        initialize: (_) async {
          calls++;
          if (calls == 1) {
            throw StateError('Unavailable');
          }
        },
      );
      await connection.open(platform: TargetPlatform.android, web: false);
      expect(calls, 1);
      expect(connection.state.value, FirebaseConnectionState.failed);
      await connection.open(platform: TargetPlatform.android, web: false);
      expect(calls, 2);
      expect(connection.state.value, FirebaseConnectionState.ready);
      expect(connection.failure, isNull);
    },
  );
  test('Android initializes registered project once across reopen', () async {
    var calls = 0;
    final connection = FirebaseConnection(
      initialize: (options) async {
        calls++;
        expect(options.projectId, 'maintainiac-aafec');
      },
    );
    await connection.open(platform: TargetPlatform.android, web: false);
    await connection.open(platform: TargetPlatform.android, web: false);
    expect(calls, 1);
    expect(connection.state.value, FirebaseConnectionState.ready);
  });

  test(
    'failed SDK initialization preserves local startup and diagnostic',
    () async {
      final error = StateError('Native initialization failed');
      final connection = FirebaseConnection(
        initialize: (_) async {
          throw error;
        },
      );
      await connection.open(platform: TargetPlatform.iOS, web: false);
      expect(connection.state.value, FirebaseConnectionState.failed);
      expect(connection.failure, same(error));
    },
  );

  test(
    'Windows and storage QA do not connect to production Firebase',
    () async {
      for (final platform in [TargetPlatform.windows, TargetPlatform.android]) {
        final connection = FirebaseConnection(
          initialize: (_) async {
            fail('SDK must not initialize');
          },
        );
        await connection.open(
          platform: platform,
          web: false,
          storageQa: platform == TargetPlatform.android,
        );
        expect(connection.state.value, FirebaseConnectionState.unavailable);
      }
    },
  );
}
