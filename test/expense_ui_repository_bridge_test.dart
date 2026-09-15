import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  late Directory directory;
  late FileExpenseRepository repository;
  late ExpenseUiRepositoryBridge bridge;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'ui-lab-expense-ui-bridge-',
    );
    repository = await FileExpenseRepository.open(directory);
    bridge = _bridge(repository);
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'manual create and reload preserve explicit employee identity',
    () async {
      final created = await bridge.create(
        record: _manualExpense(id: 'expense-bridge-create'),
        permissions: _technicianPermissions(),
        paidByEmployeeId: 'alex',
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );

      final reopened = _bridge(await FileExpenseRepository.open(directory));
      final loaded = await reopened.load(permissions: _technicianPermissions());

      expect(created.paidByEmployeeId, 'alex');
      expect(loaded.single.id, 'expense-bridge-create');
      expect(loaded.single.owner, 'Alex Morgan');
      expect(loaded.single.amount, 48.72);
      expect(loaded.single.receiptImageCount, 0);
      expect(loaded.single.receiptStatus, isNull);
    },
  );

  test(
    'visible owner label never overrides explicit employee identity',
    () async {
      final ui = _manualExpense(
        id: 'expense-explicit-identity',
        owner: 'A label that is not an identity',
      );

      await bridge.create(
        record: ui,
        permissions: _technicianPermissions(),
        paidByEmployeeId: 'alex',
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      final stored = await repository.query(
        ExpenseQuery(
          access: ExpenseAccess.company(
            organizationId: 'company-1',
            employeeId: 'owner',
          ),
        ),
      );

      expect(stored.single.paidByEmployeeId, 'alex');
      expect(stored.single.createdByEmployeeId, 'alex');
    },
  );

  test(
    'receipt claims are rejected without creating a partial record',
    () async {
      final receiptBacked = _manualExpense(id: 'expense-unconnected-receipt')
          .copyWith(
            receiptType: ExpenseReceiptType.detailed,
            receiptImageCount: 1,
            lineItems: const [
              ExpenseLineItem(
                id: 'line-1',
                description: 'PEX-A coupling',
                category: ExpenseCategory.materials,
                quantity: 1,
                unit: 'each',
                unitPrice: 7.49,
              ),
            ],
          );

      await expectLater(
        bridge.create(
          record: receiptBacked,
          permissions: _technicianPermissions(),
          paidByEmployeeId: 'alex',
          occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
        ),
        throwsA(
          isA<ExpenseUiBridgeException>().having(
            (error) => error.kind,
            'kind',
            ExpenseUiBridgeFailureKind.unsupportedReceiptData,
          ),
        ),
      );
      expect(
        await repository.query(
          ExpenseQuery(
            access: ExpenseAccess.company(
              organizationId: 'company-1',
              employeeId: 'owner',
            ),
          ),
        ),
        isEmpty,
      );
    },
  );

  test('manual itemization and tax survive the authorized bridge', () async {
    final itemized = _manualExpense(id: 'expense-manual-lines').copyWith(
      amount: 16.03,
      receiptType: ExpenseReceiptType.detailed,
      receiptSubtotal: 14.98,
      salesTax: 1.05,
      lineItems: const [
        ExpenseLineItem(
          id: 'line-1',
          description: 'PEX-A coupling',
          category: ExpenseCategory.materials,
          quantity: 2,
          unit: 'each',
          unitPrice: 7.49,
          confirmedLineTotal: 14.98,
        ),
      ],
    );

    await bridge.create(
      record: itemized,
      permissions: _technicianPermissions(),
      paidByEmployeeId: 'alex',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );
    final reopened = _bridge(await FileExpenseRepository.open(directory));
    final restored = (await reopened.load(
      permissions: _technicianPermissions(),
    )).single;

    expect(restored.receiptType, ExpenseReceiptType.detailed);
    expect(restored.receiptImageCount, 0);
    expect(restored.receiptSubtotal, 14.98);
    expect(restored.salesTax, 1.05);
    expect(restored.lineItems.single.id, 'line-1');
    expect(restored.lineItems.single.total, 14.98);
  });

  test(
    'receipt correction preserves evidence and resets prior approval',
    () async {
      final stored = await repository.create(
        StoredExpenseRecord(
          expenseId: 'expense-existing-receipt',
          organizationId: 'company-1',
          createdByEmployeeId: 'alex',
          paidByEmployeeId: 'alex',
          expenseDate: DateTime(2026, 9, 1),
          vendorName: 'Central Supply',
          categoryId: ExpenseCategory.materials.name,
          categoryLabelSnapshot: ExpenseCategory.materials.label,
          total: const ExpenseMoney(minorUnits: 1603),
          receiptId: 'receipt-1',
          receiptImageCount: 1,
          approval: const ExpenseApproval.pending(),
          itemization: ExpenseItemization(
            mode: ExpenseItemizationMode.itemized,
            lineItems: [
              StoredExpenseLineItem(
                lineItemId: 'line-1',
                description: 'PEX-A coupling',
                categoryId: ExpenseCategory.materials.name,
                categoryLabelSnapshot: ExpenseCategory.materials.label,
                packagesPurchased: ExpenseDecimalValue.fromDecimalString('2'),
                packageStyleCode: 'each',
                pricePerPackage: ExpenseUnitPrice.fromDecimalString('7.49'),
                extendedTotal: const ExpenseMoney(minorUnits: 1498),
              ),
            ],
            subtotal: const ExpenseMoney(minorUnits: 1498),
            salesTax: const ExpenseMoney(minorUnits: 105),
          ),
          lifecycle: ExpenseLifecycle(
            revision: 1,
            createdAtUtc: DateTime.utc(2026, 9, 1, 12),
            updatedAtUtc: DateTime.utc(2026, 9, 1, 12),
          ),
        ),
        context: ExpenseMutationContext(
          actorEmployeeId: 'alex',
          occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
          permissionRevision: 'expense-permissions-v1',
        ),
      );
      expect(stored.receiptId, 'receipt-1');
      final loaded = (await bridge.load(
        permissions: _technicianPermissions(canApprove: true),
      )).single;

      final approved = await bridge.update(
        record: loaded.copyWith(approvalStatus: ExpenseApprovalStatus.approved),
        permissions: _technicianPermissions(canApprove: true),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      );
      final updated = await bridge.update(
        record: approved.copyWith(
          lineItems: [
            approved.lineItems.single.copyWith(
              description: 'PEX-A coupling 1/2',
            ),
          ],
        ),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
        auditNote: 'Corrected the item description from the receipt.',
      );

      expect(updated.approvalStatus, ExpenseApprovalStatus.pending);
      expect(updated.receiptImageCount, 1);
      expect(updated.lineItems.single.description, 'PEX-A coupling 1/2');
      final persisted = await repository.findById(
        expenseId: updated.id,
        access: ExpenseAccess.company(
          organizationId: 'company-1',
          employeeId: 'alex',
        ),
      );
      expect(persisted?.receiptId, 'receipt-1');
      expect(persisted?.auditTrail.last.action, ExpenseAuditAction.corrected);
      expect(
        persisted?.auditTrail.last.note,
        'Corrected the item description from the receipt.',
      );
      expect(
        persisted?.priorVersions.last.approval.state,
        ExpenseApprovalState.approved,
      );
    },
  );

  test('ordinary update cannot attach new receipt evidence', () async {
    await bridge.create(
      record: _manualExpense(id: 'expense-no-receipt'),
      permissions: _technicianPermissions(),
      paidByEmployeeId: 'alex',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );
    final loaded = (await bridge.load(
      permissions: _technicianPermissions(),
    )).single;

    await expectLater(
      bridge.update(
        record: loaded.copyWith(receiptImageCount: 1),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      ),
      throwsA(
        isA<ExpenseUiBridgeException>().having(
          (error) => error.kind,
          'kind',
          ExpenseUiBridgeFailureKind.unsupportedReceiptData,
        ),
      ),
    );
  });

  test(
    'projection preserves exact total, time, vehicle, and revision',
    () async {
      await repository.create(
        StoredExpenseRecord(
          expenseId: 'expense-projection-metadata',
          organizationId: 'company-1',
          createdByEmployeeId: 'alex',
          paidByEmployeeId: 'alex',
          expenseDate: DateTime(2026, 9, 1),
          expenseTimeMinutes: 615,
          vendorName: 'Fuel Stop',
          categoryId: ExpenseCategory.fuel.name,
          categoryLabelSnapshot: ExpenseCategory.fuel.label,
          total: const ExpenseMoney(minorUnits: 1099),
          vehicleId: 'truck-12',
          approval: const ExpenseApproval.notRequired(),
          lifecycle: ExpenseLifecycle(
            revision: 1,
            createdAtUtc: DateTime.utc(2026, 9, 1, 10, 15),
            updatedAtUtc: DateTime.utc(2026, 9, 1, 10, 15),
          ),
        ),
        context: ExpenseMutationContext(
          actorEmployeeId: 'alex',
          occurredAtUtc: DateTime.utc(2026, 9, 1, 10, 15),
          permissionRevision: 'expense-permissions-v1',
        ),
      );

      var projection = (await bridge.loadProjection(
        permissions: _technicianPermissions(),
      )).active.single;
      expect(projection.exactTotal?.minorUnits, 1099);
      expect(projection.expenseTimeMinutes, 615);
      expect(projection.vehicleId, 'truck-12');
      expect(projection.revision, 1);

      await bridge.update(
        record: projection.record.copyWith(vendor: 'Updated Fuel Stop'),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 11),
      );
      projection = bridge.projectionForId(projection.record.id)!;
      expect(projection.record.vendor, 'Updated Fuel Stop');
      expect(projection.expenseTimeMinutes, 615);
      expect(projection.vehicleId, 'truck-12');
      expect(projection.revision, 2);
    },
  );

  test('two open editors return a recoverable revision conflict', () async {
    await bridge.create(
      record: _manualExpense(id: 'expense-stale-editor'),
      permissions: _technicianPermissions(),
      paidByEmployeeId: 'alex',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );
    final secondBridge = _bridge(repository);
    final first = (await bridge.load(
      permissions: _technicianPermissions(),
    )).single;
    final second = (await secondBridge.load(
      permissions: _technicianPermissions(),
    )).single;

    await bridge.update(
      record: first.copyWith(vendor: 'First saved change'),
      permissions: _technicianPermissions(),
      occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
    );
    await expectLater(
      secondBridge.update(
        record: second.copyWith(vendor: 'Stale change'),
        permissions: _technicianPermissions(),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
      ),
      throwsA(
        isA<ExpenseUiBridgeException>()
            .having(
              (error) => error.kind,
              'kind',
              ExpenseUiBridgeFailureKind.conflict,
            )
            .having(
              (error) => error.userMessage,
              'message',
              contains('Reload'),
            ),
      ),
    );
  });

  test('service permissions still deny a cross-employee create', () async {
    await expectLater(
      bridge.create(
        record: _manualExpense(
          id: 'expense-cross-employee',
          paidByEmployeeId: 'jordan',
        ),
        permissions: _technicianPermissions(),
        paidByEmployeeId: 'jordan',
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      ),
      throwsA(
        isA<ExpenseUiBridgeException>().having(
          (error) => error.kind,
          'kind',
          ExpenseUiBridgeFailureKind.permission,
        ),
      ),
    );
  });
}

ExpenseUiRepositoryBridge _bridge(FileExpenseRepository repository) =>
    ExpenseUiRepositoryBridge(
      service: AuthorizedExpenseService(repository),
      employeeLabelForId: (id) => switch (id) {
        'alex' => 'Alex Morgan',
        'jordan' => 'Jordan Lee',
        _ => 'Unknown employee',
      },
      jobLabelForId: (id) => id == 'job-1' ? 'JOB-1 · Repair' : null,
    );

ExpenseRecord _manualExpense({
  required String id,
  String owner = 'Alex Morgan',
  String? paidByEmployeeId = 'alex',
}) => ExpenseRecord(
  id: id,
  vendor: 'Central Supply',
  category: ExpenseCategory.materials,
  amount: 48.72,
  date: DateTime(2026, 9, 1),
  owner: owner,
  paidByEmployeeId: paidByEmployeeId,
);

ExpenseCommandPermissions _technicianPermissions({bool canApprove = false}) =>
    ExpenseCommandPermissions(
      organizationId: 'company-1',
      actorEmployeeId: 'alex',
      permissionRevision: 'expense-permissions-v1',
      readScope: ExpenseReadScope.own,
      canCreate: true,
      canEdit: true,
      canDelete: true,
      canApprove: canApprove,
    );
