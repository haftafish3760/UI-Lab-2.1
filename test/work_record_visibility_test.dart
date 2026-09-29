import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_visibility.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';

void main() {
  final permissions = WorkSessionPermissions(
    organizationId: 'company',
    actorEmployeeId: 'technician-42',
    permissionRevision: '1',
    visibleCreatorIds: {'technician-42', 'dispatcher'},
    editableKinds: {},
  );
  WorkRecord record(String creator, {List<String> assigned = const []}) =>
      WorkRecord(
        id: 'record',
        kind: WorkRecordKind.job,
        number: 'J-1',
        title: 'Repair',
        client: 'Customer',
        detail: '',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: creator,
        assignedEmployeeIds: assigned,
      );

  test('technician scope uses active identity despite stale selection', () {
    expect(
      workRecordIsVisible(
        record('technician-42'),
        permissions: permissions,
        technicianView: true,
        selectedEmployeeId: 'alex',
      ),
      isTrue,
    );
    expect(
      workRecordIsVisible(
        record('dispatcher'),
        permissions: permissions,
        technicianView: true,
        selectedEmployeeId: 'dispatcher',
      ),
      isFalse,
    );
  });

  test('authorized assigned work is included for the actual technician', () {
    expect(
      workRecordIsVisible(
        record('dispatcher', assigned: ['technician-42']),
        permissions: permissions,
        technicianView: true,
      ),
      isTrue,
    );
  });

  test('assignment and admin view never bypass creator authorization', () {
    for (final technicianView in [true, false]) {
      expect(
        workRecordIsVisible(
          record('outsider', assigned: ['technician-42']),
          permissions: permissions,
          technicianView: technicianView,
        ),
        isFalse,
      );
    }
  });

  test(
    'company selection narrows authorized records without name matching',
    () {
      expect(
        workRecordIsVisible(
          record('dispatcher'),
          permissions: permissions,
          technicianView: false,
        ),
        isTrue,
      );
      expect(
        workRecordIsVisible(
          record('dispatcher'),
          permissions: permissions,
          technicianView: false,
          selectedEmployeeId: 'technician-42',
        ),
        isFalse,
      );
    },
  );
}
