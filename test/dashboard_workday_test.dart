import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';

Future<void> _pumpAt(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: const UiLabApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openStartWorkday(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('start-workday-button')));
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey('start-day-odometer-field')),
    findsOneWidget,
  );
}

Future<void> _confirmStartWorkday(WidgetTester tester) async {
  final confirm = find.byKey(const ValueKey('confirm-start-workday-button'));
  await tester.ensureVisible(confirm);
  await tester.pumpAndSettle();
  await tester.tap(confirm);
  await tester.pumpAndSettle();
}

Future<void> _startDefaultWorkday(WidgetTester tester) async {
  await _openStartWorkday(tester);
  await _confirmStartWorkday(tester);
  expect(find.byKey(const ValueKey('active-workday-overview')), findsOneWidget);
}

void main() {
  testWidgets(
    'Start Workday preserves vehicle context and validates odometer',
    (tester) async {
      await _pumpAt(tester, const Size(412, 915));

      await tester.tap(find.byKey(const ValueKey('active-vehicle-summary')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Service Van 4').last);
      await tester.pumpAndSettle();

      await _openStartWorkday(tester);
      expect(find.text('Service Van 4'), findsWidgets);
      expect(find.text('Work context'), findsOneWidget);
      expect(find.text('Starting odometer'), findsOneWidget);
      expect(find.text('Trip assistance'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('start-day-odometer-field')),
        '18,000.0',
      );
      await _confirmStartWorkday(tester);
      expect(
        find.textContaining('cannot be lower than the last confirmed value'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('active-workday-overview')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('active workday uses labeled full-screen actions and can pause', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await _startDefaultWorkday(tester);

    expect(find.byKey(const ValueKey('open-workday-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('dashboard-workday-actions-fab')),
      findsOneWidget,
    );
    expect(find.text('Active time'), findsOneWidget);
    expect(find.text('Miles today'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d{2}:\d{2}:\d{2}$')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('dashboard-workday-actions-fab')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Workday actions'), findsOneWidget);
    expect(find.text('Pause workday'), findsOneWidget);
    expect(find.text('Add receipt photos'), findsOneWidget);
    expect(find.text('Choose actions'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('workday-action-pauseOrResume')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard settings control the active action list', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(900, 900));

    await tester.tap(find.byKey(const ValueKey('dashboard-settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard settings'), findsOneWidget);
    expect(
      find.text(
        'These choices affect only the Dashboard. They do not change employee permissions.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('dashboard-action-setting-pauseOrResume')),
    );
    await tester.tap(
      find.byKey(const ValueKey('save-dashboard-settings-button')),
    );
    await tester.pumpAndSettle();

    await _startDefaultWorkday(tester);
    await tester.tap(
      find.byKey(const ValueKey('dashboard-workday-actions-fab')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pause workday'), findsNothing);
    expect(find.text('End workday'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workday receipt action opens the receipt intake workflow', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await _startDefaultWorkday(tester);

    await tester.tap(
      find.byKey(const ValueKey('dashboard-workday-actions-fab')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workday-action-addReceipt')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('receipt-intake-screen')), findsOneWidget);
    expect(find.text('Add receipt'), findsOneWidget);
    expect(find.text('Capture receipt photos'), findsOneWidget);
    expect(find.text('Choose existing photos'), findsOneWidget);
    expect(find.text('Choose a receipt file'), findsOneWidget);
    expect(find.textContaining('mapped to its owning module'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('End Workday requires a physical ending odometer', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(412, 915));
    await _startDefaultWorkday(tester);

    await tester.tap(
      find.byKey(const ValueKey('dashboard-workday-actions-fab')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workday-action-endDay')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('ending-odometer-field')),
      '40,000.0',
    );
    await tester.tap(find.byKey(const ValueKey('confirm-end-workday-button')));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter an ending odometer at or above the starting reading.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('active-workday-overview')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Start Workday remains bounded with large accessibility text', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(320, 844), textScale: 2);
    await _openStartWorkday(tester);
    final confirm = find.byKey(const ValueKey('confirm-start-workday-button'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    expect(confirm, findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('active-workday-overview')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workday action labels reflow at large accessibility text', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(320, 844), textScale: 2);
    await _startDefaultWorkday(tester);
    await tester.tap(
      find.byKey(const ValueKey('dashboard-workday-actions-fab')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add receipt photos'), findsOneWidget);
    expect(find.text('Choose actions'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Add receipt photos')).maxLines,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
