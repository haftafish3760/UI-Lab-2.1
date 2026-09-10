import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/application_storage_lifecycle.dart';
import 'package:ui_lab_2_1/src/startup/mounted_application_switch_runtime.dart';

void main() {
  for (final failureStage in ['block input', 'settle view']) {
    test(
      '$failureStage failure releases ownership and permits retry',
      () async {
        var pauses = 0;
        var closes = 0;
        final lifecycle = ApplicationStorageLifecycle(
          pauseDomainSources: () async => () {},
          pauseDrafts: () async => () {},
          pauseStorage: () async => () {},
          closeStorage: () async {
            closes++;
          },
        );
        final detach = lifecycle.attach(() async {
          pauses++;
          return () {};
        });
        final application = UiLabApp(storageLifecycle: lifecycle);
        var fail = true;
        var blocked = false;
        final failure = StateError('injected host failure');
        final runtime = MountedApplicationSwitchRuntime(
          currentApplication: () => application,
          presentApplication: (_) async => throw StateError('must not present'),
          loadApplication: () async => throw StateError('must not load'),
          blockEntryPoints: (value) {
            blocked = value;
            if (value && fail && failureStage == 'block input') throw failure;
          },
          settleView: () async {
            if (fail && failureStage == 'settle view') throw failure;
          },
        );
        await expectLater(runtime.pauseAndFlush(), throwsA(same(failure)));
        expect(blocked, isFalse);
        expect(pauses, 0);
        expect(closes, 0);
        expect(lifecycle.isAttached, isTrue);
        fail = false;
        final resume = await runtime.pauseAndFlush();
        expect(blocked, isTrue);
        expect(pauses, 1);
        resume();
        resume();
        expect(blocked, isFalse);
        await runtime.pauseAndFlush();
        detach();
        await lifecycle.close();
        expect(closes, 1);
      },
    );
  }
}
