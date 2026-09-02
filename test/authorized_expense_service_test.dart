import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';

void main() {
  late Directory directory;
  late AuthorizedExpenseService service;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'ui-lab-authorized-expense-',
    );
    service = AuthorizedExpenseService(
      await FileExpenseRepository.open(directory),
    );
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'technician creates and reads an own Expense with audit evidence',
    () async {
      final created = await service.create(
        record: _record(id: 'expense-own', employeeId: 'alex'),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );

      final records = await service.query(
        permissions: _technicianPermissions(),
      );
      expect(records.single.expenseId, created.expenseId);
      expect(created.auditTrail.single.action, ExpenseAuditAction.created);
      expect(created.auditTrail.single.actorEmployeeId, 'alex');
      expect(
        created.auditTrail.single.permissionRevision,
        'permissions-technician-1',
      );
    },
  );

  test('technician cannot create or mutate another employee Expense', () async {
    await expectLater(
      service.create(
        record: _record(id: 'expense-other-create', employeeId: 'jamie'),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      ),
      throwsA(isA<ExpensePermissionDeniedException>()),
    );

    final teamRecord = await service.create(
      record: _record(
        id: 'expense-other-edit',
        employeeId: 'jamie',
        creatorEmployeeId: 'owner',
      ),
      permissions: _ownerPermissions(),
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );
    await expectLater(
      service.update(
        record: teamRecord.copyWith(vendorName: 'Hidden edit'),
        expectedRevision: teamRecord.lifecycle.revision,
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      ),
      throwsA(isA<ExpensePermissionDeniedException>()),
    );
  });

  test(
    'approval requires permission and records the approval action',
    () async {
      final pending = await service.create(
        record: _record(
          id: 'expense-approval',
          employeeId: 'alex',
          approval: const ExpenseApproval.pending(),
        ),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );

      await expectLater(
        service.update(
          record: pending.copyWith(
            approval: ExpenseApproval(
              state: ExpenseApprovalState.approved,
              decidedByEmployeeId: 'alex',
              decidedAtUtc: DateTime.utc(2026, 9, 1, 13),
            ),
          ),
          expectedRevision: pending.lifecycle.revision,
          permissions: _technicianPermissions(),
          occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
        ),
        throwsA(isA<ExpensePermissionDeniedException>()),
      );

      final approved = await service.update(
        record: pending.copyWith(
          approval: ExpenseApproval(
            state: ExpenseApprovalState.approved,
            decidedByEmployeeId: 'owner',
            decidedAtUtc: DateTime.utc(2026, 9, 1, 14),
          ),
        ),
        expectedRevision: pending.lifecycle.revision,
        permissions: _ownerPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
        note: 'Approved under company expense policy.',
      );

      expect(approved.approval.state, ExpenseApprovalState.approved);
      expect(
        approved.auditTrail.last.action,
        ExpenseAuditAction.approvalChanged,
      );
      expect(approved.auditTrail.last.actorEmployeeId, 'owner');
    },
  );

  test(
    'receipt correction requires a reason and returns approval to review',
    () async {
      final approved = await service.create(
        record: _record(
          id: 'expense-receipt-correction',
          employeeId: 'alex',
          creatorEmployeeId: 'owner',
          receiptId: 'receipt-1',
          approval: ExpenseApproval(
            state: ExpenseApprovalState.approved,
            decidedByEmployeeId: 'owner',
            decidedAtUtc: DateTime.utc(2026, 9, 1, 12),
          ),
        ),
        permissions: _ownerPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );

      await expectLater(
        service.update(
          record: approved.copyWith(
            vendorName: 'Corrected Supply',
            approval: const ExpenseApproval.pending(),
          ),
          expectedRevision: approved.lifecycle.revision,
          permissions: _technicianPermissions(),
          occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
        ),
        throwsA(isA<ExpenseCorrectionReasonRequiredException>()),
      );
      await expectLater(
        service.update(
          record: approved.copyWith(vendorName: 'Corrected Supply'),
          expectedRevision: approved.lifecycle.revision,
          permissions: _technicianPermissions(),
          occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
          note: 'Corrected the vendor from the retained receipt.',
        ),
        throwsA(isA<ExpenseApprovalResetRequiredException>()),
      );

      final corrected = await service.update(
        record: approved.copyWith(
          vendorName: 'Corrected Supply',
          approval: const ExpenseApproval.pending(),
        ),
        expectedRevision: approved.lifecycle.revision,
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
        note: 'Corrected the vendor from the retained receipt.',
      );

      expect(corrected.approval.state, ExpenseApprovalState.pending);
      expect(corrected.auditTrail.last.action, ExpenseAuditAction.corrected);
      expect(
        corrected.auditTrail.last.note,
        'Corrected the vendor from the retained receipt.',
      );
      expect(corrected.priorVersions.single.vendorName, 'Test Supply');
      expect(
        corrected.priorVersions.single.approval.state,
        ExpenseApprovalState.approved,
      );
      expect(corrected.priorVersions.single.receiptId, 'receipt-1');
    },
  );

  test('no read permission blocks records and totals', () async {
    final denied = ExpenseCommandPermissions(
      organizationId: 'company-1',
      actorEmployeeId: 'alex',
      permissionRevision: 'permissions-denied-1',
      readScope: null,
    );

    await expectLater(
      service.query(permissions: denied),
      throwsA(isA<ExpensePermissionDeniedException>()),
    );
    await expectLater(
      service.approvedTotalMinorUnits(
        permissions: denied,
        fromInclusive: DateTime(2026, 9, 1),
        toExclusive: DateTime(2026, 9, 2),
      ),
      throwsA(isA<ExpensePermissionDeniedException>()),
    );
  });
}

StoredExpenseRecord _record({
  required String id,
  required String employeeId,
  String? creatorEmployeeId,
  String? receiptId,
  ExpenseApproval approval = const ExpenseApproval.notRequired(),
}) {
  final timestamp = DateTime.utc(2026, 9, 1, 12);
  return StoredExpenseRecord(
    expenseId: id,
    organizationId: 'company-1',
    createdByEmployeeId: creatorEmployeeId ?? employeeId,
    paidByEmployeeId: employeeId,
    expenseDate: DateTime(2026, 9, 1),
    vendorName: 'Test Supply',
    categoryId: 'materials',
    categoryLabelSnapshot: 'Materials',
    total: ExpenseMoney.fromDecimalString('48.72'),
    receiptId: receiptId,
    approval: approval,
    lifecycle: ExpenseLifecycle(
      revision: 1,
      createdAtUtc: timestamp,
      updatedAtUtc: timestamp,
    ),
  );
}

ExpenseCommandPermissions _technicianPermissions() => ExpenseCommandPermissions(
  organizationId: 'company-1',
  actorEmployeeId: 'alex',
  permissionRevision: 'permissions-technician-1',
  readScope: ExpenseReadScope.own,
  canCreate: true,
  canEdit: true,
  canDelete: true,
);

ExpenseCommandPermissions _ownerPermissions() => ExpenseCommandPermissions(
  organizationId: 'company-1',
  actorEmployeeId: 'owner',
  permissionRevision: 'permissions-owner-1',
  readScope: ExpenseReadScope.company,
  canCreate: true,
  canEdit: true,
  canDelete: true,
  canRestore: true,
  canApprove: true,
  canManageOtherEmployees: true,
);
