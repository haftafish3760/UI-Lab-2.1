import 'dart:async';
import 'dart:io';
import 'package:ui_lab_2_1/src/data/expenses/local_recurring_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/local_receipt_draft_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_seed.dart';

void main() {
  late Directory root;
  late LocalPersistence persistence;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('persistence-pause-');
    persistence = await LocalPersistence.open(directory: root);
  });
  tearDown(() async {
    await persistence.close();
    await root.delete(recursive: true);
  });

  test(
    'admitted cross-domain work finishes before dependent queues pause',
    () async {
      final entered = Completer<void>();
      final proceed = Completer<void>();
      final stages = <String>[];
      final running = persistence.expenses.withStagedWrites((_) async {
        stages.add('expense');
        entered.complete();
        await proceed.future;
        await persistence.recurringExpenses.withStagedWrites((_) async {
          stages.add('recurring');
          await persistence.receiptDrafts.withStagedSubmission((_) async {
            stages.add('receipt');
          });
        });
      });
      await entered.future;
      var drained = false;
      final pending = persistence.pauseOperations().then((lease) {
        drained = true;
        return lease;
      });
      await expectLater(
        persistence.expenses.withStagedWrites((_) async {}),
        throwsStateError,
      );
      expect(drained, isFalse);
      proceed.complete();
      await running;
      final lease = await pending;
      expect(stages, ['expense', 'recurring', 'receipt']);
      await expectLater(
        persistence.receiptDrafts.withStagedSubmission((_) async {}),
        throwsStateError,
      );
      await expectLater(
        persistence.notifications.pauseOperations(),
        throwsStateError,
      );
      lease.release();
      await seedExpenseUiLabDemoDataIfEmpty(persistence.expenses);
      expect(
        await persistence.database
            .select(persistence.database.localRecords)
            .get(),
        isNotEmpty,
      );
      await persistence.database.verifyIntegrity();
    },
  );

  test(
    'failed partial pause releases only queues acquired by that request',
    () async {
      final existing = await persistence.recurringExpenses.pauseOperations();
      await expectLater(persistence.pauseOperations(), throwsStateError);
      // Expense was acquired then released. Another caller still owns recurring.
      await persistence.expenses.withStagedWrites((_) async {});
      await expectLater(
        persistence.recurringExpenses.withStagedWrites((_) async {}),
        throwsStateError,
      );
      existing.release();
      final complete = await persistence.pauseOperations();
      complete.release();
      await persistence.recurringExpenses.withStagedWrites((_) async {});
      await persistence.database.verifyIntegrity();
    },
  );
}
