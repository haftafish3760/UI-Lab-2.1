import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_projection.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';

void main() {
  test('recorded totals use exact cents and exclude pending costs', () {
    final snapshot = ExpenseUiProjectionSnapshot(
      active: [
        _projection(
          id: 'ten-cents',
          minorUnits: 10,
          category: ExpenseCategory.materials,
        ),
        _projection(
          id: 'twenty-cents',
          minorUnits: 20,
          category: ExpenseCategory.fuel,
          approvalState: ExpenseApprovalState.approved,
        ),
        _projection(
          id: 'pending',
          minorUnits: 99,
          category: ExpenseCategory.materials,
          approvalState: ExpenseApprovalState.pending,
        ),
      ],
    );

    expect(
      snapshot.recordedTotal(const ExpenseUiProjectionQuery()).decimalValue,
      '0.30',
    );
    expect(
      snapshot
          .query(const ExpenseUiProjectionQuery(recordedOnly: true))
          .map((projection) => projection.record.id),
      ['ten-cents', 'twenty-cents'],
    );
    final byCategory = snapshot.recordedTotalsByCategory(
      const ExpenseUiProjectionQuery(),
    );
    expect(byCategory[ExpenseCategory.materials]?.minorUnits, 10);
    expect(byCategory[ExpenseCategory.fuel]?.minorUnits, 20);
  });

  test('filters use stable IDs rather than visible labels', () {
    final matching = _projection(
      id: 'matching',
      minorUnits: 4872,
      employeeId: 'alex',
      ownerLabel: 'A display label that is not an identity',
      date: DateTime(2026, 8, 30),
      category: ExpenseCategory.materials,
      jobId: 'job-1',
      vehicleId: 'vehicle-1',
      approvalState: ExpenseApprovalState.approved,
      vendor: 'Central Supply',
    );
    final snapshot = ExpenseUiProjectionSnapshot(
      active: [
        matching,
        _projection(
          id: 'other',
          minorUnits: 100,
          employeeId: 'jordan',
          date: DateTime(2026, 8, 29),
        ),
      ],
    );
    const query = ExpenseUiProjectionQuery(
      paidByEmployeeId: 'alex',
      category: ExpenseCategory.materials,
      jobId: 'job-1',
      vehicleId: 'vehicle-1',
      approvalState: ExpenseApprovalState.approved,
      vendorContains: 'supply',
    );

    expect(snapshot.query(query), [matching]);
    expect(
      snapshot.query(
        ExpenseUiProjectionQuery(
          fromInclusive: DateTime(2026, 8, 30),
          toExclusive: DateTime(2026, 8, 31),
        ),
      ),
      [matching],
    );
    expect(
      snapshot.query(
        const ExpenseUiProjectionQuery(paidByEmployeeId: 'display label'),
      ),
      isEmpty,
    );
  });

  test('active and deleted records remain separate and immutable', () {
    final active = _projection(id: 'active', minorUnits: 100);
    final deleted = _projection(
      id: 'deleted',
      minorUnits: 200,
      isDeleted: true,
    );
    var snapshot = ExpenseUiProjectionSnapshot(
      active: [active],
      deleted: [deleted],
    );

    expect(snapshot.query(const ExpenseUiProjectionQuery()), [active]);
    expect(
      snapshot.query(const ExpenseUiProjectionQuery(), includeDeleted: true),
      [active, deleted],
    );
    expect(snapshot.queryDeleted(const ExpenseUiProjectionQuery()), [deleted]);
    expect(() => snapshot.active.add(active), throwsUnsupportedError);

    final moved = _projection(
      id: 'active',
      minorUnits: 100,
      isDeleted: true,
      revision: 2,
    );
    snapshot = snapshot.upsert(moved);
    expect(snapshot.records, isEmpty);
    expect(snapshot.deletedRecords.map((record) => record.id), [
      'active',
      'deleted',
    ]);
  });

  test('mixed currencies are rejected instead of silently combined', () {
    final snapshot = ExpenseUiProjectionSnapshot(
      active: [
        _projection(id: 'usd', minorUnits: 100),
        _projection(id: 'cad', minorUnits: 100, currencyCode: 'CAD'),
      ],
    );

    expect(
      () => snapshot.recordedTotal(const ExpenseUiProjectionQuery()),
      throwsStateError,
    );
  });

  test('records sort by date, then optional time, then stable ID', () {
    final snapshot = ExpenseUiProjectionSnapshot(
      active: [
        _projection(id: 'older', minorUnits: 100, date: DateTime(2026, 8, 29)),
        _projection(
          id: 'later',
          minorUnits: 100,
          date: DateTime(2026, 8, 30),
          expenseTimeMinutes: 600,
        ),
        _projection(
          id: 'earlier',
          minorUnits: 100,
          date: DateTime(2026, 8, 30),
          expenseTimeMinutes: 300,
        ),
      ],
    );

    expect(snapshot.records.map((record) => record.id), [
      'later',
      'earlier',
      'older',
    ]);
  });
}

ExpenseUiProjectionRecord _projection({
  required String id,
  required int minorUnits,
  String currencyCode = 'USD',
  String employeeId = 'alex',
  String ownerLabel = 'Alex Morgan',
  DateTime? date,
  int? expenseTimeMinutes,
  ExpenseCategory category = ExpenseCategory.materials,
  String? jobId,
  String? vehicleId,
  ExpenseApprovalState approvalState = ExpenseApprovalState.notRequired,
  String vendor = 'Vendor',
  bool isDeleted = false,
  int revision = 1,
}) {
  final resolvedDate = date ?? DateTime(2026, 8, 30);
  return ExpenseUiProjectionRecord(
    record: ExpenseRecord(
      id: id,
      vendor: vendor,
      category: category,
      amount: minorUnits / 100,
      date: resolvedDate,
      owner: ownerLabel,
      paidByEmployeeId: employeeId,
      jobId: jobId,
      approvalStatus: _uiApproval(approvalState),
    ),
    exactTotal: ExpenseMoney(
      minorUnits: minorUnits,
      currencyCode: currencyCode,
    ),
    paidByEmployeeId: employeeId,
    expenseDate: resolvedDate,
    expenseTimeMinutes: expenseTimeMinutes,
    categoryId: category.name,
    jobId: jobId,
    vehicleId: vehicleId,
    approvalState: approvalState,
    revision: revision,
    isDeleted: isDeleted,
  );
}

ExpenseApprovalStatus _uiApproval(ExpenseApprovalState state) =>
    switch (state) {
      ExpenseApprovalState.notRequired => ExpenseApprovalStatus.notRequired,
      ExpenseApprovalState.pending => ExpenseApprovalStatus.pending,
      ExpenseApprovalState.approved => ExpenseApprovalStatus.approved,
      ExpenseApprovalState.declined => ExpenseApprovalStatus.declined,
    };
