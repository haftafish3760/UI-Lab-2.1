import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpJob(
  WidgetTester tester,
  PrototypeOperationsStore store,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController();
  addTearDown(scope.dispose);
  final job = store.workRecords.firstWhere((record) => record.id == 'job-1038');
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(
            workRecord: job,
            onWorkRecordUpdated: store.updateWorkRecord,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openReceiptIntake(WidgetTester tester) async {
  final action = find.byKey(const ValueKey('job-attach-receipt'));
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('receipt-intake-screen')), findsOneWidget);
}

void main() {
  testWidgets('Job receipt intake carries the exact owning Job ID', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    await _pumpJob(tester, store);
    await _openReceiptIntake(tester);

    await tester.tap(find.byKey(const ValueKey('manual-receipt-entry')));
    await tester.pumpAndSettle();

    final editor = tester.widget<ExpenseEditorScreen>(
      find.byType(ExpenseEditorScreen),
    );
    expect(editor.initialJobId, 'job-1038');
    expect(editor.initialJobLabel, 'JOB-1038 · Replace kitchen faucet');
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('expense-job-field')),
          )
          .controller
          ?.text,
      'JOB-1038 · Replace kitchen faucet',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved receipt Expense links back to the exact Job record', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    await _pumpJob(tester, store);
    await _openReceiptIntake(tester);

    final expense = ExpenseRecord(
      id: 'EXP-JOB-RECEIPT',
      vendor: 'Verified Supply House',
      category: ExpenseCategory.materials,
      amount: 84.25,
      date: DateTime(2026, 8, 30),
      owner: 'Alex Morgan',
      job: 'JOB-1038 · Replace kitchen faucet',
      jobId: 'job-1038',
      receiptStatus: 'Receipt attached',
      receiptImageCount: 1,
    );
    await store.addExpense(expense);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('receipt-intake-screen'))),
    ).pop(expense);
    await tester.pumpAndSettle();

    final savedJob = store.workRecords.firstWhere(
      (record) => record.id == 'job-1038',
    );
    expect(savedJob.linkedExpenseIds, contains('EXP-JOB-RECEIPT'));
    expect(find.textContaining('Verified Supply House'), findsOneWidget);
    expect(find.text('New receipt attachment'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Job photo action never creates a placeholder attachment', (
    tester,
  ) async {
    final store = PrototypeOperationsStore();
    addTearDown(store.dispose);
    await _pumpJob(tester, store);

    final action = find.byKey(const ValueKey('job-attach-photo'));
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture job photo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No job photo was attached.'), findsOneWidget);
    expect(find.text('New job photo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
