import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_projection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';

void main() {
  final date = DateTime(2026, 9, 15);
  final now = DateTime.utc(2026, 9, 15, 12);
  final access = expenseUiLabOwnerPermissions().readAccess!;
  final mutation = ExpenseMutationContext(
    actorEmployeeId: 'alex',
    occurredAtUtc: now,
    permissionRevision: 'test-1',
    note: 'Correct category',
  );
  ExpenseRecord ui({
    ExpenseCategory category = ExpenseCategory.uncategorized,
  }) => ExpenseRecord(
    id: 'expense-optional',
    vendor: '',
    category: category,
    amount: 12.34,
    date: date,
    owner: 'Alex',
    paidByEmployeeId: 'alex',
  );
  StoredExpenseRecord stored(ExpenseRecord record) =>
      ExpenseRecordAdapter.fromUiRecord(
        record: record,
        organizationId: expenseUiLabOrganizationId,
        createdByEmployeeId: 'alex',
        paidByEmployeeId: 'alex',
        nowUtc: now,
      );

  test(
    'blank merchant and unselected category survive SQLite restart and edits',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'optional-expense-header-',
      );
      var persistence = await LocalPersistence.open(directory: folder);
      addTearDown(() async {
        await persistence.close();
        await folder.delete(recursive: true);
      });
      final created = await persistence.expenses.create(
        stored(ui()),
        context: mutation,
      );
      expect(created.toJson()['categoryId'], isNull);
      expect(created.toJson()['categoryLabelSnapshot'], isNull);
      expect(created.vendorName, '');
      await persistence.close();
      persistence = await LocalPersistence.open(directory: folder);
      final reopened = (await persistence.expenses.findById(
        expenseId: created.expenseId,
        access: access,
      ))!;
      final visible = ExpenseRecordAdapter.toUiRecord(
        record: reopened,
        ownerDisplayName: 'Alex',
      );
      expect(visible.category, ExpenseCategory.uncategorized);
      expect(visible.vendor, '');
      expect(visible.displayVendor, 'Business expense');
      final categorized = await persistence.expenses.update(
        reopened.copyWith(categoryId: 'fuel', categoryLabelSnapshot: 'Fuel'),
        expectedRevision: 1,
        context: mutation,
      );
      final cleared = await persistence.expenses.update(
        categorized.copyWith(categoryId: null, categoryLabelSnapshot: null),
        expectedRevision: 2,
        context: mutation,
      );
      expect(cleared.priorVersions.first.categoryId, isNull);
      expect(cleared.priorVersions.last.categoryId, 'fuel');
      await persistence.close();
      persistence = await LocalPersistence.open(directory: folder);
      final finalRecord = (await persistence.expenses.findById(
        expenseId: created.expenseId,
        access: access,
      ))!;
      expect(finalRecord.categoryId, isNull);
      expect(finalRecord.priorVersions.map((entry) => entry.categoryId), [
        null,
        'fuel',
      ]);
      expect(finalRecord.total?.minorUnits, 1234);
    },
  );

  test(
    'missing/corrupt category keys are not silently accepted as a user clearing them',
    () {
      final record = stored(ui());
      expect(
        () => StoredExpenseRecord.fromJson(
          {...record.toJson()}..remove('categoryId'),
        ),
        throwsFormatException,
      );
      expect(() => record.copyWith(categoryId: 'fuel'), throwsFormatException);
      expect(
        () => record.copyWith(categoryId: '', categoryLabelSnapshot: ''),
        throwsFormatException,
      );
      expect(
        () => StoredExpenseRecord.fromJson(
          {...record.toJson()}..remove('vendorName'),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'uncategorized spending is queryable and counted without calling it Materials',
    () {
      final projection = ExpenseUiProjectionRecord(
        record: ui(),
        exactTotal: const ExpenseMoney(minorUnits: 1234),
        paidByEmployeeId: 'alex',
        expenseDate: date,
        categoryId: null,
        approvalState: ExpenseApprovalState.notRequired,
        revision: 1,
        isDeleted: false,
      );
      final snapshot = ExpenseUiProjectionSnapshot(active: [projection]);
      final query = ExpenseUiProjectionQuery(
        category: ExpenseCategory.uncategorized,
      );
      expect(snapshot.query(query), hasLength(1));
      expect(
        snapshot
            .recordedTotalsByCategory(query)[ExpenseCategory.uncategorized]!
            .minorUnits,
        1234,
      );
      expect(
        snapshot.query(
          const ExpenseUiProjectionQuery(category: ExpenseCategory.materials),
        ),
        isEmpty,
      );
    },
  );

  test(
    'unset item category round-trips without inventing a classification',
    () {
      final line = StoredExpenseLineItem(
        lineItemId: 'line',
        description: 'WASHER',
        categoryId: null,
        categoryLabelSnapshot: null,
        packagesPurchased: ExpenseDecimalValue.fromDecimalString('1'),
        packageStyleCode: 'each',
        pricePerPackage: ExpenseUnitPrice.fromDecimalString('1.23'),
        extendedTotal: const ExpenseMoney(minorUnits: 123),
      );
      expect(StoredExpenseLineItem.fromJson(line.toJson()), line);
      expect(line.toJson()['categoryId'], isNull);
    },
  );
}
