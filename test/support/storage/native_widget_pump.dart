import 'package:flutter_test/flutter_test.dart';

/// Advances both widget frames and native SQLite I/O, with a bounded deadline.
Future<void> waitForNativeSave(
  WidgetTester tester,
  bool Function() ready,
) async {
  for (var attempt = 0; attempt < 200 && !ready(); attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(ready(), isTrue);
  await tester.pumpAndSettle();
}

/// Waits for lifecycle operations that involve both native I/O and callbacks
/// registered on Flutter's test clock. Blocking runAsync alone cannot advance
/// those callbacks (for example, stream closure initiated by widget disposal).
Future<void> finishNativeOperation(
  WidgetTester tester,
  Future<void> Function() action,
) async {
  var done = false;
  Object? failure;
  StackTrace? trace;
  await tester.runAsync(() async {
    action().then<void>(
      (_) {
        done = true;
      },
      onError: (Object error, StackTrace stack) {
        failure = error;
        trace = stack;
        done = true;
      },
    );
  });
  await waitForNativeSave(tester, () => done);
  if (failure != null) Error.throwWithStackTrace(failure!, trace!);
}
