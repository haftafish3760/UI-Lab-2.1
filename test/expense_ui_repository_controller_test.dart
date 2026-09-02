import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_projection.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'ui-lab-expense-controller-',
    );
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  test(
    'load exposes only authorized records in immutable projections',
    () async {
      final repository = await FileExpenseRepository.open(directory);
      await repository.create(
        _storedExpense(id: 'alex-expense', employeeId: 'alex'),
        context: _mutation('alex'),
      );
      await repository.create(
        _storedExpense(id: 'jordan-expense', employeeId: 'jordan'),
        context: _mutation('jordan'),
      );
      final controller = _controller(repository, _permissions());

      expect(await controller.load(), isTrue);
      expect(controller.records.map((record) => record.id), ['alex-expense']);
      expect(controller.projection.active.single.paidByEmployeeId, 'alex');
      expect(
        controller.projection
            .recordedTotal(const ExpenseUiProjectionQuery())
            .minorUnits,
        4872,
      );
      expect(
        () => controller.records.add(_manualExpense(id: 'not-allowed')),
        throwsUnsupportedError,
      );
    },
  );

  test('create edit delete and restore survive process restart', () async {
    var repository = await FileExpenseRepository.open(directory);
    var controller = _controller(repository, _permissions());
    expect(await controller.load(), isTrue);

    final created = await controller.create(
      record: _manualExpense(id: 'expense-lifecycle'),
      paidByEmployeeId: 'alex',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );
    expect(created, isNotNull);
    final updated = await controller.update(
      record: created!.copyWith(vendor: 'Updated Supply'),
      occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
    );
    expect(updated?.vendor, 'Updated Supply');
    expect(
      await controller.softDelete(
        expenseId: created.id,
        occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
      ),
      isTrue,
    );
    expect(controller.records, isEmpty);
    expect(controller.deletedRecords.single.vendor, 'Updated Supply');

    repository = await FileExpenseRepository.open(directory);
    controller = _controller(repository, _permissions());
    expect(await controller.load(), isTrue);
    expect(controller.records, isEmpty);
    expect(controller.deletedRecords.single.id, created.id);

    final restored = await controller.restore(
      expenseId: created.id,
      occurredAtUtc: DateTime.utc(2026, 9, 1, 15),
    );
    expect(restored?.vendor, 'Updated Supply');
    expect(controller.deletedRecords, isEmpty);
    expect(controller.records.single.id, created.id);

    final restarted = _controller(
      await FileExpenseRepository.open(directory),
      _permissions(),
    );
    expect(await restarted.load(), isTrue);
    expect(restarted.records.single.vendor, 'Updated Supply');
    expect(restarted.deletedRecords, isEmpty);
  });

  test(
    'stale edit refreshes current record and retains conflict guidance',
    () async {
      final repository = await FileExpenseRepository.open(directory);
      final first = _controller(repository, _permissions());
      final second = _controller(repository, _permissions());
      await first.load();
      final created = await first.create(
        record: _manualExpense(id: 'expense-conflict'),
        paidByEmployeeId: 'alex',
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      expect(created, isNotNull);
      await first.load();
      await second.load();

      final firstSaved = await first.update(
        record: first.records.single.copyWith(vendor: 'First saved change'),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
      );
      expect(firstSaved, isNotNull);
      final staleResult = await second.update(
        record: second.records.single.copyWith(vendor: 'Stale change'),
        occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
      );

      expect(staleResult, isNull);
      expect(second.failure?.kind, ExpenseUiBridgeFailureKind.conflict);
      expect(second.failure?.requiresReload, isTrue);
      expect(second.records.single.vendor, 'First saved change');
    },
  );

  test('storage pressure keeps the last good UI and disk record', () async {
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
    final controller = _controller(repository, _permissions());
    await controller.load();
    final created = await controller.create(
      record: _manualExpense(id: 'expense-storage'),
      paidByEmployeeId: 'alex',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );
    expect(created, isNotNull);

    final result = await controller.update(
      record: created!.copyWith(vendor: 'Unsaved change'),
      occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
    );

    expect(result, isNull);
    expect(controller.failure?.kind, ExpenseUiBridgeFailureKind.storage);
    expect(controller.records.single.vendor, 'Central Supply');
    final restarted = _controller(
      await FileExpenseRepository.open(directory),
      _permissions(),
    );
    await restarted.load();
    expect(restarted.records.single.vendor, 'Central Supply');
  });

  test('damaged snapshot recovery remains visible until dismissed', () async {
    final repository = await FileExpenseRepository.open(directory);
    final created = await repository.create(
      _storedExpense(id: 'expense-recovered', employeeId: 'alex'),
      context: _mutation('alex'),
    );
    await repository.update(
      created.copyWith(vendorName: 'Newest value'),
      expectedRevision: created.lifecycle.revision,
      context: _mutation('alex', DateTime.utc(2026, 9, 1, 13)),
    );
    await File.fromUri(
      directory.uri.resolve('expenses-1.json'),
    ).writeAsString('damaged');
    final recovered = await FileExpenseRepository.open(directory);
    final controller = _controller(
      recovered,
      _permissions(),
      recoveredFromDamagedSnapshot: recovered.recoveredFromDamagedSnapshot,
    );

    expect(await controller.load(), isTrue);
    expect(controller.records.single.vendor, 'Central Supply');
    expect(controller.showRecoveryNotice, isTrue);
    controller.dismissRecoveryNotice();
    expect(controller.showRecoveryNotice, isFalse);
  });

  test('denied cross-employee create leaves controller unchanged', () async {
    final repository = await FileExpenseRepository.open(directory);
    final controller = _controller(repository, _permissions());
    await controller.load();

    final denied = await controller.create(
      record: _manualExpense(id: 'expense-denied', paidByEmployeeId: 'jordan'),
      paidByEmployeeId: 'jordan',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
    );

    expect(denied, isNull);
    expect(controller.records, isEmpty);
    expect(controller.failure?.kind, ExpenseUiBridgeFailureKind.permission);
  });

  test('denied load exposes no records or totals to the controller', () async {
    final repository = await FileExpenseRepository.open(directory);
    await repository.create(
      _storedExpense(id: 'private-expense', employeeId: 'alex'),
      context: _mutation('alex'),
    );
    final deniedPermissions = ExpenseCommandPermissions(
      organizationId: 'company-1',
      actorEmployeeId: 'alex',
      permissionRevision: 'denied-expense-read-v1',
      readScope: null,
    );
    final controller = _controller(repository, deniedPermissions);

    expect(await controller.load(), isFalse);
    expect(controller.phase, ExpenseRepositoryControllerPhase.failed);
    expect(controller.records, isEmpty);
    expect(controller.deletedRecords, isEmpty);
    expect(controller.failure?.kind, ExpenseUiBridgeFailureKind.permission);
  });
}

ExpenseUiRepositoryController _controller(
  FileExpenseRepository repository,
  ExpenseCommandPermissions permissions, {
  bool recoveredFromDamagedSnapshot = false,
}) => ExpenseUiRepositoryController(
  _bridge(repository),
  permissions,
  recoveredFromDamagedSnapshot: recoveredFromDamagedSnapshot,
);

ExpenseUiRepositoryBridge _bridge(FileExpenseRepository repository) =>
    ExpenseUiRepositoryBridge(
      service: AuthorizedExpenseService(repository),
      employeeLabelForId: (id) => switch (id) {
        'alex' => 'Alex Morgan',
        'jordan' => 'Jordan Lee',
        _ => 'Unknown employee',
      },
      jobLabelForId: (_) => null,
    );

ExpenseCommandPermissions _permissions() => ExpenseCommandPermissions(
  organizationId: 'company-1',
  actorEmployeeId: 'alex',
  permissionRevision: 'expense-controller-permissions-v1',
  readScope: ExpenseReadScope.own,
  canCreate: true,
  canEdit: true,
  canDelete: true,
  canRestore: true,
);

ExpenseRecord _manualExpense({
  required String id,
  String? paidByEmployeeId = 'alex',
}) => ExpenseRecord(
  id: id,
  vendor: 'Central Supply',
  category: ExpenseCategory.materials,
  amount: 48.72,
  date: DateTime(2026, 9, 1),
  owner: paidByEmployeeId == 'jordan' ? 'Jordan Lee' : 'Alex Morgan',
  paidByEmployeeId: paidByEmployeeId,
);

StoredExpenseRecord _storedExpense({
  required String id,
  required String employeeId,
}) => StoredExpenseRecord(
  expenseId: id,
  organizationId: 'company-1',
  createdByEmployeeId: employeeId,
  paidByEmployeeId: employeeId,
  expenseDate: DateTime(2026, 9, 1),
  vendorName: 'Central Supply',
  categoryId: 'materials',
  categoryLabelSnapshot: 'Materials',
  total: ExpenseMoney.fromDecimalString('48.72'),
  approval: const ExpenseApproval.notRequired(),
  lifecycle: ExpenseLifecycle(
    revision: 1,
    createdAtUtc: DateTime.utc(2026, 9, 1, 12),
    updatedAtUtc: DateTime.utc(2026, 9, 1, 12),
  ),
);

ExpenseMutationContext _mutation(String actor, [DateTime? occurredAtUtc]) =>
    ExpenseMutationContext(
      actorEmployeeId: actor,
      occurredAtUtc: occurredAtUtc ?? DateTime.utc(2026, 9, 1, 12),
      permissionRevision: 'expense-controller-permissions-v1',
    );
