import 'package:flutter/widgets.dart';
import '../../data/prototype_operations_store.dart';
import '../../data/work/work_record_visibility.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/operational_scope.dart';
import 'work_models.dart';

Iterable<WorkRecord> visibleWorkOverviewRecords(BuildContext context) {
  final store = PrototypeOperationsScope.of(context);
  final scope = OperationalScope.of(context);
  final grants = store.workSession?.permissions;
  return store.workRecords.where((record) {
    if (grants != null) {
      return workRecordIsVisible(
        record,
        permissions: grants,
        technicianView: scope.view == AppViewMode.technician,
        selectedEmployeeId: scope.selectedEmployeeId,
      );
    }
    final employee = scope.selectedEmployeeId;
    return employee == null ||
        record.createdByEmployeeId == employee ||
        record.assignedEmployeeIds.contains(employee);
  });
}
