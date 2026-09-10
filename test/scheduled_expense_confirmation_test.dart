import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/scheduled_expense_editor_screen.dart';

void main() {
  testWidgets('planned expense waits for confirmation and retains failed input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pending = Completer<ScheduledExpenseRecord?>();
    final attempts = <ScheduledExpenseRecord>[];
    ScheduledExpenseRecord? returned;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                returned = await Navigator.of(context)
                    .push<ScheduledExpenseRecord>(
                      MaterialPageRoute(
                        builder: (_) => ScheduledExpenseEditorScreen(
                          onConfirm: (record) async {
                            attempts.add(record);
                            if (attempts.length == 1) return pending.future;
                            return record;
                          },
                        ),
                      ),
                    );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final title = find.byKey(const ValueKey('scheduled-expense-title'));
    final amount = find.byKey(const ValueKey('scheduled-expense-amount'));
    await tester.enterText(title, 'Monthly supplies');
    await tester.enterText(amount, '12.50');
    FocusManager.instance.primaryFocus?.unfocus();
    final save = find.byKey(const ValueKey('save-scheduled-expense'));
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pump();
    expect(attempts, hasLength(1));
    expect(returned, isNull);
    expect(find.text('Saving…'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ScheduledExpenseEditorScreen), findsOneWidget);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The planned expense was not saved. Your input is still here. Retry saving.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<TextFormField>(title).controller!.text,
      'Monthly supplies',
    );
    expect(tester.widget<TextFormField>(amount).controller!.text, '12.50');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(ScheduledExpenseEditorScreen), findsNothing);
    expect(attempts, hasLength(2));
    expect(attempts.last.id, attempts.first.id);
    expect(returned!.title, 'Monthly supplies');
    expect(tester.takeException(), isNull);
  });
}
