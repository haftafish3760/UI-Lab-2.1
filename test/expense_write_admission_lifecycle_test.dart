import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'expense_draft_open_lifecycle_test.dart'
    show openExpenseLifecycleSession;
import 'expense_draft_workflow_test.dart' show initialExpense, change;
import 'recurring_payment_draft_workflow_test.dart' show seed;

void main() {
  for (final kind in ['create', 'update', 'plan']) {
    for (final admittedFirst in [false, true]) {
      test(
        '$kind ${admittedFirst ? 'finishes accepted' : 'rejects new'} mutation after disposal',
        () async {
          final root = await Directory.systemTemp.createTemp(
            'expense-write-admission-',
          );
          final persistence = await LocalPersistence.open(directory: root);
          final session = await openExpenseLifecycleSession(persistence);
          final record = change(initialExpense(), {
            'amount': '12.50',
          }).confirmedRecord();
          if (kind == 'update') {
            expect(
              await session.expenses.create(
                record: record,
                paidByEmployeeId: 'alex',
                occurredAtUtc: DateTime.now().toUtc(),
              ),
              isNotNull,
            );
          }
          if (kind == 'plan') await seed(session);
          final target = kind == 'plan'
              ? session.recurringExpenses
              : session.expenses;
          try {
            final before = await persistence.database
                .customSelect(
                  'SELECT * FROM local_records ORDER BY organization_id, domain, record_id',
                )
                .get();
            if (!admittedFirst) target.dispose();
            final pending = switch (kind) {
              'create' => session.expenses.create(
                record: record,
                paidByEmployeeId: 'alex',
                occurredAtUtc: DateTime.now().toUtc(),
              ),
              'update' => session.expenses.update(
                record: record,
                occurredAtUtc: DateTime.now().toUtc(),
              ),
              _ => session.recurringExpenses.update(
                session.recurringExpenses.recordById('plan')!,
              ),
            };
            if (admittedFirst) target.dispose();
            expect(await pending, admittedFirst ? isNotNull : isNull);
            if (!admittedFirst) {
              final after = await persistence.database
                  .customSelect(
                    'SELECT * FROM local_records ORDER BY organization_id, domain, record_id',
                  )
                  .get();
              expect(after.map((r) => r.data), before.map((r) => r.data));
            }
            await persistence.database.verifyIntegrity();
          } finally {
            session.dispose();
            if (kind == 'plan') {
              session.expenses.dispose();
            } else {
              session.recurringExpenses.dispose();
            }
            await persistence.close();
            await root.delete(recursive: true);
          }
        },
      );
    }
  }
}
