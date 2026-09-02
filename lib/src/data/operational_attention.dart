import '../screens/dashboard/dashboard_models.dart';
import '../screens/expenses/expense_models.dart';
import '../screens/inventory/inventory_models.dart';
import '../screens/work/estimate_models.dart';
import '../screens/work/work_models.dart';
import '../shared/app_view_mode.dart';

enum OperationalAttentionModule { dashboard, work, expenses, inventory }

enum OperationalAttentionResourceKind {
  estimate,
  job,
  invoice,
  expense,
  inventoryStock,
}

enum OperationalAttentionCapability {
  reviewOwnWork,
  reviewEstimates,
  approveEstimates,
  assignJobs,
  reviewInvoices,
  correctOwnExpenses,
  approveExpenses,
  reviewInventoryStock,
}

/// Explicit capabilities used by the UI Lab attention projection.
///
/// These development fixtures demonstrate permission-aware behavior. A later
/// production adapter must supply the authenticated 5.7 capability snapshot;
/// a role label alone must never grant one of these capabilities.
class OperationalAttentionAccess {
  const OperationalAttentionAccess(this.capabilities);

  const OperationalAttentionAccess.technicianDevelopment()
    : capabilities = const {
        OperationalAttentionCapability.reviewOwnWork,
        OperationalAttentionCapability.reviewEstimates,
        OperationalAttentionCapability.reviewInvoices,
        OperationalAttentionCapability.correctOwnExpenses,
        OperationalAttentionCapability.reviewInventoryStock,
      };

  const OperationalAttentionAccess.adminDevelopment()
    : capabilities = const {
        OperationalAttentionCapability.reviewOwnWork,
        OperationalAttentionCapability.reviewEstimates,
        OperationalAttentionCapability.approveEstimates,
        OperationalAttentionCapability.assignJobs,
        OperationalAttentionCapability.reviewInvoices,
        OperationalAttentionCapability.approveExpenses,
        OperationalAttentionCapability.reviewInventoryStock,
      };

  final Set<OperationalAttentionCapability> capabilities;

  bool allows(OperationalAttentionCapability capability) =>
      capabilities.contains(capability);
}

class OperationalAttentionQuery {
  const OperationalAttentionQuery({
    required this.panelId,
    required this.module,
    required this.view,
    required this.access,
    this.selectedEmployeeId,
    this.selectedVehicleId,
    this.selectedDay,
    this.resourceKinds,
  });

  final String panelId;
  final OperationalAttentionModule module;
  final AppViewMode view;
  final OperationalAttentionAccess access;
  final String? selectedEmployeeId;
  final String? selectedVehicleId;
  final DateTime? selectedDay;
  final Set<OperationalAttentionResourceKind>? resourceKinds;

  bool includes(OperationalAttentionResourceKind kind) =>
      resourceKinds == null || resourceKinds!.contains(kind);

  String get dismissalKey {
    final day = selectedDay;
    final date = day == null
        ? 'all-dates'
        : '${day.year}-${day.month}-${day.day}';
    final kinds = resourceKinds?.map((kind) => kind.name).toList();
    kinds?.sort();
    return [
      panelId,
      module.name,
      view.name,
      selectedEmployeeId ?? 'company',
      selectedVehicleId ?? 'fleet',
      date,
      kinds?.join(',') ?? 'all-kinds',
    ].join('|');
  }
}

class OperationalAttentionItem {
  const OperationalAttentionItem({
    required this.id,
    required this.module,
    required this.resourceKind,
    required this.sourceId,
    required this.title,
    required this.reason,
  });

  final String id;
  final OperationalAttentionModule module;
  final OperationalAttentionResourceKind resourceKind;
  final String sourceId;
  final String title;
  final String reason;
}

/// Builds permission- and scope-filtered attention projections from source
/// records. It does not own a second copy of a Work, Expense, or Inventory
/// record and dismissing a panel never resolves its underlying business state.
class PrototypeAttentionCenter {
  PrototypeAttentionCenter({
    required this._workRecords,
    required this._expenses,
    required this._inventoryStock,
    required this._onChanged,
  });

  final List<WorkRecord> Function() _workRecords;
  final List<ExpenseRecord> Function() _expenses;
  final List<InventoryStockRecord> Function() _inventoryStock;
  final void Function() _onChanged;
  final Map<String, String> _dismissedFingerprints = {};

  List<OperationalAttentionItem> itemsFor(OperationalAttentionQuery query) {
    final items = <OperationalAttentionItem>[
      if (query.module
          case OperationalAttentionModule.dashboard ||
              OperationalAttentionModule.work)
        ..._workItems(query),
      if (query.module
          case OperationalAttentionModule.dashboard ||
              OperationalAttentionModule.expenses)
        ..._expenseItems(query),
      if (query.module
          case OperationalAttentionModule.dashboard ||
              OperationalAttentionModule.inventory)
        ..._inventoryItems(query),
    ];
    items.sort((left, right) {
      final module = left.module.index.compareTo(right.module.index);
      return module != 0 ? module : left.title.compareTo(right.title);
    });
    return List.unmodifiable(items);
  }

  bool shouldShow(
    OperationalAttentionQuery query,
    List<OperationalAttentionItem> items,
  ) =>
      items.isNotEmpty &&
      _dismissedFingerprints[query.dismissalKey] != _fingerprint(items);

  void dismiss(
    OperationalAttentionQuery query,
    List<OperationalAttentionItem> items,
  ) {
    if (items.isEmpty) return;
    _dismissedFingerprints[query.dismissalKey] = _fingerprint(items);
    _onChanged();
  }

  void clearDismissal(OperationalAttentionQuery query) {
    if (_dismissedFingerprints.remove(query.dismissalKey) != null) {
      _onChanged();
    }
  }

  List<OperationalAttentionItem> _workItems(OperationalAttentionQuery query) {
    final results = <OperationalAttentionItem>[];
    for (final record in _workRecords()) {
      if (!_workRecordIsInScope(record, query)) continue;
      if (query.selectedDay != null && !record.occursOn(query.selectedDay!)) {
        continue;
      }
      switch (record.kind) {
        case WorkRecordKind.estimate:
          if (!query.includes(OperationalAttentionResourceKind.estimate)) {
            continue;
          }
          final companyReview = record.estimateCompanyReviewStatus;
          if (companyReview == EstimateCompanyReviewStatus.pending) {
            if (query.access.allows(
              OperationalAttentionCapability.approveEstimates,
            )) {
              results.add(
                OperationalAttentionItem(
                  id: 'work-estimate:${record.id}',
                  module: OperationalAttentionModule.work,
                  resourceKind: OperationalAttentionResourceKind.estimate,
                  sourceId: record.id,
                  title: record.title,
                  reason: 'Approve estimate · ${record.client}',
                ),
              );
            }
            continue;
          }
          if (companyReview == EstimateCompanyReviewStatus.changesRequested) {
            if (query.access.allows(
              OperationalAttentionCapability.reviewEstimates,
            )) {
              results.add(
                OperationalAttentionItem(
                  id: 'work-estimate:${record.id}',
                  module: OperationalAttentionModule.work,
                  resourceKind: OperationalAttentionResourceKind.estimate,
                  sourceId: record.id,
                  title: record.title,
                  reason: 'Returned for changes · ${record.client}',
                ),
              );
            }
            continue;
          }
          if (!query.access.allows(
            OperationalAttentionCapability.reviewEstimates,
          )) {
            continue;
          }
          final stage = record.resolvedEstimateStage;
          if (stage != EstimateStage.changesRequested &&
              stage != EstimateStage.expired) {
            continue;
          }
          results.add(
            OperationalAttentionItem(
              id: 'work-estimate:${record.id}',
              module: OperationalAttentionModule.work,
              resourceKind: OperationalAttentionResourceKind.estimate,
              sourceId: record.id,
              title: record.title,
              reason: stage == EstimateStage.expired
                  ? 'Estimate expired · ${record.client}'
                  : 'Estimate changes requested · ${record.client}',
            ),
          );
        case WorkRecordKind.job:
          if (!query.includes(OperationalAttentionResourceKind.job)) {
            continue;
          }
          if (record.status == WorkRecordStatus.needsReturnVisit &&
              query.access.allows(
                OperationalAttentionCapability.reviewOwnWork,
              )) {
            results.add(
              OperationalAttentionItem(
                id: 'work-job:${record.id}',
                module: OperationalAttentionModule.work,
                resourceKind: OperationalAttentionResourceKind.job,
                sourceId: record.id,
                title: record.title,
                reason: 'Return visit needs scheduling · ${record.client}',
              ),
            );
            continue;
          }
          if (!query.access.allows(OperationalAttentionCapability.assignJobs) ||
              record.assignee != null ||
              record.status == WorkRecordStatus.completed) {
            continue;
          }
          results.add(
            OperationalAttentionItem(
              id: 'work-job:${record.id}',
              module: OperationalAttentionModule.work,
              resourceKind: OperationalAttentionResourceKind.job,
              sourceId: record.id,
              title: record.title,
              reason: 'Job needs assignment · ${record.client}',
            ),
          );
        case WorkRecordKind.invoice:
          if (!query.includes(OperationalAttentionResourceKind.invoice) ||
              !query.access.allows(
                OperationalAttentionCapability.reviewInvoices,
              ) ||
              record.status != WorkRecordStatus.due ||
              !_isBeforeToday(record.dueOn)) {
            continue;
          }
          results.add(
            OperationalAttentionItem(
              id: 'work-invoice:${record.id}',
              module: OperationalAttentionModule.work,
              resourceKind: OperationalAttentionResourceKind.invoice,
              sourceId: record.id,
              title: record.title,
              reason: 'Invoice is overdue · ${record.client}',
            ),
          );
      }
    }
    return results;
  }

  List<OperationalAttentionItem> _expenseItems(
    OperationalAttentionQuery query,
  ) {
    final selectedEmployee = query.selectedEmployeeId == null
        ? null
        : dashboardEmployeeById(query.selectedEmployeeId!).name;
    final results = <OperationalAttentionItem>[];
    for (final expense in _expenses()) {
      if (selectedEmployee != null && expense.owner != selectedEmployee) {
        continue;
      }
      if (query.view == AppViewMode.admin) {
        if (!query.includes(OperationalAttentionResourceKind.expense) ||
            !query.access.allows(
              OperationalAttentionCapability.approveExpenses,
            ) ||
            expense.approvalStatus != ExpenseApprovalStatus.pending) {
          continue;
        }
        results.add(
          OperationalAttentionItem(
            id: 'expense-approval:${expense.id}',
            module: OperationalAttentionModule.expenses,
            resourceKind: OperationalAttentionResourceKind.expense,
            sourceId: expense.id,
            title: expense.vendor,
            reason:
                'Needs approval · ${expenseMoney(expense.amount)} · ${expense.owner}',
          ),
        );
        continue;
      }
      if (!query.includes(OperationalAttentionResourceKind.expense) ||
          !query.access.allows(
            OperationalAttentionCapability.correctOwnExpenses,
          ) ||
          !expense.requiresSubmitterAttention) {
        continue;
      }
      results.add(
        OperationalAttentionItem(
          id: 'expense-correction:${expense.id}',
          module: OperationalAttentionModule.expenses,
          resourceKind: OperationalAttentionResourceKind.expense,
          sourceId: expense.id,
          title: expense.vendor,
          reason:
              'Receipt details need finishing · ${expenseMoney(expense.amount)}',
        ),
      );
    }
    return results;
  }

  List<OperationalAttentionItem> _inventoryItems(
    OperationalAttentionQuery query,
  ) {
    if (!query.includes(OperationalAttentionResourceKind.inventoryStock) ||
        !query.access.allows(
          OperationalAttentionCapability.reviewInventoryStock,
        )) {
      return const [];
    }
    final results = <OperationalAttentionItem>[];
    for (final stock in _inventoryStock()) {
      if (query.selectedVehicleId != null &&
          stock.locationId != query.selectedVehicleId) {
        continue;
      }
      final staleUnknown =
          stock.confidence == InventoryStockConfidence.unknown &&
          DateTime.now().difference(stock.updatedOn).inDays >= 30;
      if (!stock.isLow && !staleUnknown) continue;
      results.add(
        OperationalAttentionItem(
          id: 'inventory-stock:${stock.id}',
          module: OperationalAttentionModule.inventory,
          resourceKind: OperationalAttentionResourceKind.inventoryStock,
          sourceId: stock.id,
          title: stock.materialName,
          reason: staleUnknown
              ? 'Count needs verification · ${stock.locationLabel}'
              : '${_quantity(stock.quantity)} ${stock.unitLabel} left · ${stock.locationLabel}',
        ),
      );
    }
    return results;
  }

  bool _workRecordIsInScope(
    WorkRecord record,
    OperationalAttentionQuery query,
  ) {
    if (query.view == AppViewMode.admin && query.selectedEmployeeId == null) {
      return true;
    }
    final employeeId = query.selectedEmployeeId ?? demoEmployees.first.id;
    final employee = dashboardEmployeeById(employeeId);
    return record.createdByEmployeeId == employee.id ||
        record.assignee == employee.name;
  }

  String _fingerprint(List<OperationalAttentionItem> items) {
    final ids = items.map((item) => item.id).toList()..sort();
    return ids.join('|');
  }
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

bool _isBeforeToday(DateTime? value) {
  if (value == null) return false;
  final due = DateTime(value.year, value.month, value.day);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return due.isBefore(today);
}
