import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/storage_write_admission.dart';

void main() {
  const reserve = StorageWriteAdmission.reserveBytes;
  test(
    'exact reserve is protected, with warning independent of admission',
    () async {
      var free = StorageWriteAdmission.warningBytes;
      final guard = StorageWriteAdmission(readFreeBytes: () async => free);
      addTearDown(guard.close);
      expect((await guard.refresh()).level, StorageCapacityLevel.available);
      free--;
      expect((await guard.refresh()).level, StorageCapacityLevel.low);
      free = reserve + 10;
      final lease = await guard.acquire(peakBytes: 10);
      expect(guard.status.level, StorageCapacityLevel.reserveReached);
      await expectLater(
        guard.acquire(peakBytes: 1),
        throwsA(isA<StorageWriteDeferred>()),
      );
      lease.release();
      free = reserve;
      await expectLater(
        guard.acquire(peakBytes: 1),
        throwsA(isA<StorageWriteDeferred>()),
      );
    },
  );

  test(
    'concurrent requests cannot spend the same remaining capacity twice',
    () async {
      final reading = Completer<int?>();
      var reads = 0;
      final guard = StorageWriteAdmission(
        readFreeBytes: () {
          reads++;
          return reads == 1 ? reading.future : Future.value(reserve + 100);
        },
      );
      addTearDown(guard.close);
      final first = guard.acquire(peakBytes: 60);
      final second = guard.acquire(peakBytes: 60);
      final denied = expectLater(second, throwsA(isA<StorageWriteDeferred>()));
      reading.complete(reserve + 100);
      final lease = await first;
      await denied;
      expect(guard.status.reservedBytes, 60);
      lease.release();
      lease.release();
      expect(guard.status.reservedBytes, 0);
      final retry = await guard.acquire(peakBytes: 60);
      retry.release();
    },
  );

  for (final invalid in <int?>[null, -1]) {
    test(
      'unknown or invalid capacity refuses write callbacks: $invalid',
      () async {
        final guard = StorageWriteAdmission(readFreeBytes: () async => invalid);
        addTearDown(guard.close);
        var ran = false;
        await expectLater(
          guard.run(
            peakBytes: 1,
            write: (_) async {
              ran = true;
            },
          ),
          throwsA(isA<StorageWriteDeferred>()),
        );
        expect(ran, isFalse);
        expect(guard.status.level, StorageCapacityLevel.unknown);
      },
    );
  }

  test(
    'failed probe does not reuse a previous successful observation',
    () async {
      var failed = false;
      final guard = StorageWriteAdmission(
        readFreeBytes: () async {
          if (failed) throw StateError('probe failed');
          return reserve + 100;
        },
      );
      addTearDown(guard.close);
      await guard.refresh();
      failed = true;
      await expectLater(
        guard.acquire(peakBytes: 1),
        throwsA(isA<StorageWriteDeferred>()),
      );
      expect(guard.status.freeBytes, isNull);
    },
  );

  test(
    'external storage consumption defers the next unit without deleting anything',
    () async {
      var free = reserve + 100;
      final guard = StorageWriteAdmission(readFreeBytes: () async => free);
      addTearDown(guard.close);
      final lease = await guard.acquire(peakBytes: 80);
      free = reserve + 79;
      await expectLater(
        lease.checkpoint(),
        throwsA(isA<StorageWriteDeferred>()),
      );
      expect(guard.status.reservedBytes, 80);
      free = reserve + 100;
      await lease.checkpoint();
      lease.release();
      await expectLater(lease.checkpoint(), throwsStateError);
    },
  );

  test(
    'failed writer releases reservation and permits an explicit retry',
    () async {
      final guard = StorageWriteAdmission(
        readFreeBytes: () async => reserve + 100,
      );
      addTearDown(guard.close);
      await expectLater(
        guard.run(
          peakBytes: 100,
          write: (_) async {
            throw StateError('native write failed');
          },
        ),
        throwsStateError,
      );
      expect(guard.status.reservedBytes, 0);
      expect(
        await guard.run(peakBytes: 100, write: (_) async => 'committed'),
        'committed',
      );
    },
  );

  test(
    'closing during an unfinished probe cannot admit a late write',
    () async {
      final reading = Completer<int?>();
      final started = Completer<void>();
      final guard = StorageWriteAdmission(
        readFreeBytes: () {
          started.complete();
          return reading.future;
        },
      );
      final denied = expectLater(guard.acquire(peakBytes: 1), throwsStateError);
      await started.future;
      await guard.close();
      reading.complete(reserve + 100);
      await denied;
    },
  );
}
