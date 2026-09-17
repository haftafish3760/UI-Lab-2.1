import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_choice_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_flow.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession;
import 'support/storage/native_widget_pump.dart';

Widget entryHost({ExpenseUiRepositoryController? owner}) {
  final child = MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => openExpenseEntryFlow(
            context,
            expenseDate: DateTime(2030),
            permissions: const ExpensePermissions.development(),
            onConfirm: (_) async => throw StateError('Must not confirm'),
          ),
          child: const Text('Start'),
        ),
      ),
    ),
  );
  return owner == null
      ? child
      : ExpenseUiScope(controller: owner, child: child);
}

void main() {
  const message = 'Expense entry could not open. Please try again.';
  testWidgets('missing storage reports failure without opening a form', (
    tester,
  ) async {
    await tester.pumpWidget(entryHost());
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text(message), findsOneWidget);
    expect(find.byType(ExpenseEntryChoiceScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draft read failure preserves input and opening can retry', (
    tester,
  ) async {
    final root = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('expense-open-failure-'),
    ))!;
    final persistence = (await tester.runAsync(
      () => LocalPersistence.open(directory: root),
    ))!;
    final session = (await tester.runAsync(() => openSession(persistence)))!;
    final scope = OperationalScopeController();
    try {
      await tester.runAsync(() async {
        await persistence.drafts.save(
          organizationId: session.expenses.organizationId,
          ownerId: session.expenses.actorEmployeeId,
          domain: 'expenses/manual-entry',
          draftId: 'retained-input',
          expectedRevision: 0,
          payload: {'amount': '12.', 'vendor': '  unfinished  '},
          occurredAt: DateTime.utc(2030),
        );
        // Fail the actual SQL read, then restore the same table and contents.
        await persistence.database.customStatement(
          'ALTER TABLE local_drafts RENAME TO unavailable_drafts',
        );
      });
      await tester.pumpWidget(
        OperationalScope(
          controller: scope,
          child: entryHost(owner: session.expenses),
        ),
      );
      await tester.tap(find.text('Start'));
      await waitForNativeSave(
        tester,
        () => find.text(message).evaluate().isNotEmpty,
      );
      expect(find.byType(ExpenseEntryChoiceScreen), findsNothing);
      await tester.runAsync(
        () => persistence.database.customStatement(
          'ALTER TABLE unavailable_drafts RENAME TO local_drafts',
        ),
      );
      final retained = (await tester.runAsync(
        () => persistence.drafts.find(
          organizationId: session.expenses.organizationId,
          ownerId: session.expenses.actorEmployeeId,
          domain: 'expenses/manual-entry',
          draftId: 'retained-input',
        ),
      ))!;
      expect(retained.revision, 1);
      expect(persistence.drafts.decode(retained), {
        'amount': '12.',
        'vendor': '  unfinished  ',
      });
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Start'));
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseEntryChoiceScreen).evaluate().isNotEmpty,
      );
      expect(session.expenses.records, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await finishNativeOperation(tester, persistence.close);
      scope.dispose();
      await tester.runAsync(() => root.delete(recursive: true));
    }
  });
}
