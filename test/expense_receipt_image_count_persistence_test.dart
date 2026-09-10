import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  for (final count in <int?>[0, 2, null]) {
    test(
      'receipt count $count survives projection, correction, history and reopen',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'expense-count-',
        );
        var persistence = await LocalPersistence.open(directory: directory);
        addTearDown(() async {
          await persistence.close();
          await directory.delete(recursive: true);
        });
        final permissions = expenseUiLabOwnerPermissions();
        final record = ExpenseRecordAdapter.fromUiRecord(
          record: ExpenseRecord(
            id: 'count-test',
            vendor: 'Supplier',
            category: ExpenseCategory.office,
            amount: 5,
            date: DateTime(2030, 1, 2),
            owner: 'Alex Morgan',
            paidByEmployeeId: 'alex',
            receiptImageCount: count ?? 0,
          ),
          organizationId: permissions.organizationId,
          createdByEmployeeId: 'alex',
          paidByEmployeeId: 'alex',
          nowUtc: DateTime.utc(2030, 1, 2),
          receiptId: 'receipt-test',
        );
        final body = record.toJson();
        if (count == null) body.remove('receiptImageCount');
        await AuthorizedExpenseService(persistence.expenses).create(
          record: StoredExpenseRecord.fromJson(body),
          permissions: permissions,
          occurredAtUtc: DateTime.utc(2030, 1, 2),
        );
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        final controller = ExpenseUiRepositoryController(
          ExpenseUiRepositoryBridge(
            service: AuthorizedExpenseService(persistence.expenses),
            employeeLabelForId: expenseUiLabEmployeeLabel,
            jobLabelForId: (_) => null,
          ),
          permissions,
        );
        addTearDown(controller.dispose);
        expect(await controller.load(), isTrue);
        final projected = controller.records.single;
        expect(projected.receiptImageCount, count ?? 0);
        expect(
          projected.receiptStatus,
          count == null
              ? 'Receipt linked; image count unavailable'
              : count == 0
              ? 'Receipt recorded without an image'
              : 'Receipt attached',
        );
        expect(
          await controller.update(
            record: projected.copyWith(vendor: 'Corrected supplier'),
            expectedRevision: 1,
            occurredAtUtc: DateTime.utc(2030, 1, 3),
            auditNote: 'Corrected vendor',
          ),
          isNotNull,
        );
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        final saved = (await persistence.expenses.query(
          ExpenseQuery(access: permissions.readAccess!),
        )).single;
        expect(saved.receiptImageCount, count);
        expect(saved.priorVersions.single.receiptImageCount, count);
        expect(saved.lifecycle.revision, 2);
        expect(
          () => saved.copyWith(receiptImageCount: -1),
          throwsArgumentError,
        );
        expect(
          () => saved.copyWith(receiptId: null, receiptImageCount: 2),
          throwsArgumentError,
        );
      },
    );
  }
}
