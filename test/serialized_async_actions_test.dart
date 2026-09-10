import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/serialized_async_actions.dart';

void main() {
  test(
    'pause drains admitted work in order and blocks new work until release',
    () async {
      final queue = SerializedAsyncActions();
      final firstResult = Completer<int>();
      final secondResult = Completer<int>();
      final calls = <int>[];
      final first = queue.run(() {
        calls.add(1);
        return firstResult.future;
      });
      final second = queue.run(() {
        calls.add(2);
        return secondResult.future;
      });
      var drained = false;
      final pending = queue.pauseAndDrain().then((lease) {
        drained = true;
        return lease;
      });
      await expectLater(
        queue.run(() async {
          calls.add(99);
          return 99;
        }),
        throwsStateError,
      );
      expect(calls, [1]);
      expect(drained, isFalse);
      firstResult.complete(1);
      expect(await first, 1);
      await Future<void>.delayed(Duration.zero);
      expect(calls, [1, 2]);
      expect(drained, isFalse);
      secondResult.complete(2);
      expect(await second, 2);
      final lease = await pending;
      await expectLater(queue.pauseAndDrain(), throwsStateError);
      lease.release();
      lease.release();
      expect(await queue.run(() async => 3), 3);
      expect(calls, [1, 2]);
    },
  );

  test(
    'failed admitted action still settles and does not replay after release',
    () async {
      final queue = SerializedAsyncActions();
      final outcome = Completer<void>();
      var calls = 0;
      final running = queue.run(() {
        calls++;
        return outcome.future;
      });
      final failure = expectLater(running, throwsStateError);
      final pending = queue.pauseAndDrain();
      outcome.completeError(StateError('native call failed'));
      await failure;
      final lease = await pending;
      lease.release();
      await queue.run(() async {
        calls++;
      });
      expect(calls, 2);
    },
  );
}
