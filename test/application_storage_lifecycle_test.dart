import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/application_storage_lifecycle.dart';

void main() {
  test(
    'partial pause unwinds in reverse and failed pause cannot authorize closure',
    () async {
      final calls = <String>[];
      final lifecycle = ApplicationStorageLifecycle(
        pauseDomainSources: () async {
          calls.add('domains');
          return () => calls.add('resume domains');
        },
        pauseDrafts: () async => throw StateError('draft write failed'),
        pauseStorage: () async {
          calls.add('storage');
          return () {};
        },
        closeStorage: () async {
          calls.add('closed');
        },
      );
      final detach = lifecycle.attach(() async {
        calls.add('services');
        return () => calls.add('resume services');
      });
      await expectLater(lifecycle.pauseAndFlush(), throwsStateError);
      expect(calls, [
        'services',
        'domains',
        'resume domains',
        'resume services',
      ]);
      detach();
      await expectLater(lifecycle.close(), throwsStateError);
      expect(calls, isNot(contains('closed')));
    },
  );
  test('never-mounted startup can close and cannot attach afterward', () async {
    var closes = 0;
    final lifecycle = ApplicationStorageLifecycle(
      pauseDomainSources: () async => () {},
      pauseDrafts: () async => () {},
      pauseStorage: () async => () {},
      closeStorage: () async {
        closes++;
      },
    );
    await lifecycle.close();
    await lifecycle.close();
    expect(closes, 1);
    expect(() => lifecycle.attach(() async => () {}), throwsStateError);
  });
  test('concurrent close drains storage once and blocks attachment', () async {
    final drained = Completer<void>();
    var closes = 0;
    final lifecycle = ApplicationStorageLifecycle(
      pauseDomainSources: () async => () {},
      pauseDrafts: () async => () {},
      pauseStorage: () async => () {},
      closeStorage: () async {
        closes++;
        await drained.future;
      },
    );
    final first = lifecycle.close();
    final second = lifecycle.close();
    try {
      expect(() => lifecycle.attach(() async => () {}), throwsStateError);
      expect(closes, 1);
    } finally {
      drained.complete();
      await Future.wait([first, second]);
    }
    await lifecycle.close();
    expect(closes, 1);
  });

  test(
    'failed shared closure reports failure and permits a later retry',
    () async {
      final failed = Completer<void>();
      var closes = 0;
      final lifecycle = ApplicationStorageLifecycle(
        pauseDomainSources: () async => () {},
        pauseDrafts: () async => () {},
        pauseStorage: () async => () {},
        closeStorage: () async {
          closes++;
          if (closes == 1) await failed.future;
        },
      );
      final first = expectLater(lifecycle.close(), throwsStateError);
      final second = expectLater(lifecycle.close(), throwsStateError);
      failed.completeError(StateError('injected close failure'));
      await Future.wait([first, second]);
      expect(closes, 1);
      await lifecycle.close();
      expect(closes, 2);
    },
  );
}
