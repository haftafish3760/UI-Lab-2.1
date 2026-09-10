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
}
