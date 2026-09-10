import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  group('ExpenseMoney', () {
    test('parses cents without floating-point arithmetic', () {
      expect(ExpenseMoney.fromDecimalString('0.01').minorUnits, 1);
      expect(ExpenseMoney.fromDecimalString('19.9').minorUnits, 1990);
      expect(ExpenseMoney.fromDecimalString('1042').minorUnits, 104200);
      expect(
        () => ExpenseMoney.fromDecimalString('10.999'),
        throwsFormatException,
      );
    });
  });

  group('FileExpenseRepository', () {
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'ui-lab-expense-repository-',
      );
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('create survives repository restart with stable values', () async {
      final repository = await FileExpenseRepository.open(directory);
      final original = _record(
        id: 'expense-restart-1',
        employeeId: 'alex',
        amount: '42.07',
      );

      final created = await repository.create(original, context: _mutation());
      final reopened = await FileExpenseRepository.open(directory);
      final restored = await reopened.findById(
        expenseId: original.expenseId,
        access: _companyAccess(),
      );

      expect(restored, isNotNull);
      expect(restored!.toJson(), created.toJson());
      expect(restored.auditTrail.single.action, ExpenseAuditAction.created);
      expect(reopened.recoveredFromDamagedSnapshot, isFalse);
    });

    test('edit uses expected revision and rejects a stale save', () async {
      final repository = await FileExpenseRepository.open(directory);
      final original = await repository.create(
        _record(id: 'expense-edit-1', employeeId: 'alex', amount: '15.00'),
        context: _mutation(),
      );
      final changedAt = DateTime.utc(2026, 9, 1, 14);
      final updated = await repository.update(
        original.copyWith(vendorName: 'Updated Supply'),
        expectedRevision: original.lifecycle.revision,
        context: _mutation(changedAt),
      );

      expect(updated.vendorName, 'Updated Supply');
      expect(updated.lifecycle.revision, 2);
      expect(updated.priorVersions, hasLength(1));
      expect(updated.priorVersions.single.revision, 1);
      expect(updated.priorVersions.single.vendorName, original.vendorName);
      final reopened = await FileExpenseRepository.open(directory);
      final persisted = await reopened.findById(
        expenseId: original.expenseId,
        access: _companyAccess(),
      );
      expect(persisted?.priorVersions.single.vendorName, original.vendorName);
      await expectLater(
        repository.update(
          original.copyWith(vendorName: 'Stale edit'),
          expectedRevision: original.lifecycle.revision,
          context: _mutation(changedAt.add(const Duration(minutes: 1))),
        ),
        throwsA(isA<ExpenseRevisionConflictException>()),
      );
    });

    test('soft delete and restore retain the same record identity', () async {
      final repository = await FileExpenseRepository.open(directory);
      final original = await repository.create(
        _record(id: 'expense-delete-1', employeeId: 'alex', amount: '9.99'),
        context: _mutation(),
      );
      final deleted = await repository.softDelete(
        expenseId: original.expenseId,
        expectedRevision: original.lifecycle.revision,
        context: _mutation(DateTime.utc(2026, 9, 1, 15)),
      );

      expect(
        await repository.findById(
          expenseId: original.expenseId,
          access: _companyAccess(),
        ),
        isNull,
      );
      expect(deleted.lifecycle.isDeleted, isTrue);

      final restored = await repository.restore(
        expenseId: original.expenseId,
        expectedRevision: deleted.lifecycle.revision,
        context: _mutation(DateTime.utc(2026, 9, 1, 16)),
      );
      expect(restored.expenseId, original.expenseId);
      expect(restored.lifecycle.isDeleted, isFalse);
      expect(restored.lifecycle.revision, 3);
    });

    test('concurrent writes serialize without dropping records', () async {
      final repository = await FileExpenseRepository.open(directory);

      await Future.wait([
        repository.create(
          _record(id: 'expense-concurrent-a', employeeId: 'alex', amount: '1'),
          context: _mutation(),
        ),
        repository.create(
          _record(id: 'expense-concurrent-b', employeeId: 'alex', amount: '2'),
          context: _mutation(),
        ),
        repository.create(
          _record(id: 'expense-concurrent-c', employeeId: 'alex', amount: '3'),
          context: _mutation(),
        ),
      ]);

      final reopened = await FileExpenseRepository.open(directory);
      expect(
        await reopened.query(ExpenseQuery(access: _companyAccess())),
        hasLength(3),
      );
    });

    test('failed write preserves the last valid snapshot', () async {
      var writeCount = 0;
      final repository = await FileExpenseRepository.open(
        directory,
        snapshotWriter: (target, bytes) async {
          writeCount += 1;
          if (writeCount == 2) {
            throw const FileSystemException('Simulated storage pressure');
          }
          await target.writeAsBytes(bytes, flush: true);
        },
      );
      final original = await repository.create(
        _record(id: 'expense-pressure-1', employeeId: 'alex', amount: '20'),
        context: _mutation(),
      );

      await expectLater(
        repository.update(
          original.copyWith(vendorName: 'Unsaved vendor'),
          expectedRevision: 1,
          context: _mutation(DateTime.utc(2026, 9, 1, 17)),
        ),
        throwsA(isA<ExpenseStorageException>()),
      );

      final reopened = await FileExpenseRepository.open(directory);
      final restored = await reopened.findById(
        expenseId: original.expenseId,
        access: _companyAccess(),
      );
      expect(restored!.vendorName, original.vendorName);
      expect(restored.lifecycle.revision, 1);
    });

    test(
      'corrupt newest slot falls back to the prior valid snapshot',
      () async {
        final repository = await FileExpenseRepository.open(directory);
        final original = await repository.create(
          _record(id: 'expense-recovery-1', employeeId: 'alex', amount: '30'),
          context: _mutation(),
        );
        await repository.update(
          original.copyWith(vendorName: 'Newest value'),
          expectedRevision: 1,
          context: _mutation(DateTime.utc(2026, 9, 1, 18)),
        );
        await File.fromUri(
          directory.uri.resolve('expenses-1.json'),
        ).writeAsString('damaged');

        final recovered = await FileExpenseRepository.open(directory);
        final record = await recovered.findById(
          expenseId: original.expenseId,
          access: _companyAccess(),
        );
        expect(record!.vendorName, original.vendorName);
        expect(record.lifecycle.revision, 1);
        expect(recovered.recoveredFromDamagedSnapshot, isTrue);
      },
    );

    test('scope predicates protect records, counts, and totals', () async {
      final repository = await FileExpenseRepository.open(directory);
      await repository.create(
        _record(
          id: 'expense-scope-own',
          employeeId: 'alex',
          amount: '10',
          approval: const ExpenseApproval.notRequired(),
        ),
        context: _mutation(),
      );
      await repository.create(
        _record(
          id: 'expense-scope-team',
          employeeId: 'jamie',
          amount: '20',
          approval: const ExpenseApproval.pending(),
        ),
        context: _mutation(),
      );
      await repository.create(
        _record(
          id: 'expense-scope-other-org',
          employeeId: 'outsider',
          amount: '999',
          organizationId: 'other-company',
        ),
        context: _mutation(),
      );

      final own = ExpenseQuery(
        access: ExpenseAccess.own(
          organizationId: 'company-1',
          employeeId: 'alex',
        ),
      );
      final team = ExpenseQuery(
        access: ExpenseAccess.team(
          organizationId: 'company-1',
          employeeId: 'alex',
          teamEmployeeIds: {'jamie'},
        ),
      );
      final company = ExpenseQuery(access: _companyAccess());

      expect(await repository.query(own), hasLength(1));
      expect(await repository.query(team), hasLength(2));
      expect(await repository.query(company), hasLength(2));
      expect(await repository.approvedTotalMinorUnits(team), 1000);
    });
  });

  test('UI adapter requires explicit identity and preserves exact cents', () {
    final uiRecord = ExpenseRecord(
      id: 'expense-adapter-1',
      vendor: 'Central Supply',
      category: ExpenseCategory.materials,
      amount: 48.72,
      date: DateTime(2026, 9, 1),
      owner: 'Visible owner label',
      approvalStatus: ExpenseApprovalStatus.pending,
    );

    final stored = ExpenseRecordAdapter.fromUiRecord(
      record: uiRecord,
      organizationId: 'company-1',
      createdByEmployeeId: 'alex-id',
      paidByEmployeeId: 'alex-id',
      nowUtc: DateTime.utc(2026, 9, 1, 12),
    );

    expect(stored.createdByEmployeeId, 'alex-id');
    expect(stored.paidByEmployeeId, 'alex-id');
    expect(stored.total.minorUnits, 4872);
    expect(stored.approval.state, ExpenseApprovalState.pending);
  });

  test(
    'UI adapter does not invent receipt identity from presentation state',
    () {
      final uiRecord = ExpenseRecord(
        id: 'expense-adapter-no-evidence',
        vendor: 'Central Supply',
        category: ExpenseCategory.materials,
        amount: 48.72,
        date: DateTime(2026, 9, 1),
        owner: 'Alex Morgan',
        paidByEmployeeId: 'alex',
        receiptStatus: 'Receipt attached',
        receiptImageCount: 3,
      );

      final stored = ExpenseRecordAdapter.fromUiRecord(
        record: uiRecord,
        organizationId: 'company-1',
        createdByEmployeeId: 'alex',
        paidByEmployeeId: 'alex',
        nowUtc: DateTime.utc(2026, 9, 1, 12),
      );

      expect(stored.receiptId, isNull);
      expect(stored.receiptImageCount, 0);
    },
  );

  test('UI adapter rejects amounts with more than two decimals', () {
    final uiRecord = ExpenseRecord(
      id: 'expense-adapter-invalid-money',
      vendor: 'Central Supply',
      category: ExpenseCategory.materials,
      amount: 10.999,
      date: DateTime(2026, 9, 1),
      owner: 'Alex Morgan',
      paidByEmployeeId: 'alex',
    );

    expect(
      () => ExpenseRecordAdapter.fromUiRecord(
        record: uiRecord,
        organizationId: 'company-1',
        createdByEmployeeId: 'alex',
        paidByEmployeeId: 'alex',
        nowUtc: DateTime.utc(2026, 9, 1, 12),
      ),
      throwsFormatException,
    );
  });
}

StoredExpenseRecord _record({
  required String id,
  required String employeeId,
  required String amount,
  String organizationId = 'company-1',
  ExpenseApproval approval = const ExpenseApproval.notRequired(),
}) {
  final timestamp = DateTime.utc(2026, 9, 1, 12);
  return StoredExpenseRecord(
    expenseId: id,
    organizationId: organizationId,
    createdByEmployeeId: employeeId,
    paidByEmployeeId: employeeId,
    expenseDate: DateTime(2026, 9, 1),
    expenseTimeMinutes: 12 * 60,
    vendorName: 'Test Supply',
    categoryId: 'materials',
    categoryLabelSnapshot: 'Materials',
    total: ExpenseMoney.fromDecimalString(amount),
    approval: approval,
    lifecycle: ExpenseLifecycle(
      revision: 1,
      createdAtUtc: timestamp,
      updatedAtUtc: timestamp,
    ),
  );
}

ExpenseAccess _companyAccess() =>
    ExpenseAccess.company(organizationId: 'company-1', employeeId: 'owner');

ExpenseMutationContext _mutation([DateTime? occurredAtUtc]) =>
    ExpenseMutationContext(
      actorEmployeeId: 'owner',
      occurredAtUtc: occurredAtUtc ?? DateTime.utc(2026, 9, 1, 12),
      permissionRevision: 'permission-revision-1',
    );
