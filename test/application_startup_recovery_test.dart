import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/startup/application_startup_screen.dart';

void main() {
  for (final width in [320.0, 1400.0]) {
    testWidgets('startup failure and retry at $width LP', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      final first = Completer<Widget>();
      final second = Completer<Widget>();
      var attempts = 0;
      await tester.pumpWidget(
        ApplicationStartupScreen(
          load: () => ++attempts == 1 ? first.future : second.future,
        ),
      );
      expect(find.text('Tame Your Biz'), findsOneWidget);
      expect(find.text('Opening your saved work…'), findsNothing);
      first.completeError(StateError('PRIVATE RECORD CONTENT'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to open Tame Your Biz'), findsOneWidget);
      expect(find.textContaining('PRIVATE RECORD'), findsNothing);
      await tester.tap(find.text('Retry opening'));
      await tester.pump();
      expect(attempts, 2);
      expect(find.text('Retry opening'), findsNothing);
      second.complete(
        const MaterialApp(home: Scaffold(body: Text('Application ready'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Application ready'), findsOneWidget);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  testWidgets('a completed but never mounted application is released', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    var releases = 0;
    await tester.pumpWidget(
      ApplicationStartupScreen(
        load: () => pending.future,
        onAbandoned: (_) async {
          releases++;
        },
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete(const Text('Never mounted'));
    await tester.pump();
    expect(releases, 1);
    expect(find.text('Never mounted'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
