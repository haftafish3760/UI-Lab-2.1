import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/job_schedule_availability.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_record_item_revision.dart';

void main() {
  DateTime at(int hour, [int day = 1]) => DateTime(2030, 1, day, hour);
  WorkRecord job(
    String id,
    int start,
    int end, {
    List<String> employees = const ['a'],
    String? vehicle,
    int bufferMinutes = 0,
    WorkRecordStatus status = WorkRecordStatus.scheduled,
  }) => WorkRecord(
    id: id,
    kind: WorkRecordKind.job,
    number: id,
    title: id,
    client: 'Customer',
    detail: 'Service',
    pricing: WorkPricingModel.flatRate,
    scheduledStart: at(start),
    scheduledEnd: at(end),
    assignedEmployeeIds: employees,
    vehicle: vehicle,
    scheduleBufferMinutes: bufferMinutes,
    status: status,
  );
  test(
    'back-to-back is available; partial overlap blocks each shared employee',
    () {
      final engine = JobScheduleAvailability([
        job('busy', 9, 11, employees: ['a', 'b']),
      ]);
      expect(
        engine.conflicts(start: at(11), end: at(12), employeeIds: {'a'}),
        isEmpty,
      );
      expect(
        engine
            .conflicts(start: at(10), end: at(12), employeeIds: {'b'})
            .single
            .id,
        'busy',
      );
      expect(
        engine.conflicts(start: at(10), end: at(12), employeeIds: {'c'}),
        isEmpty,
      );
    },
  );
  test(
    'first opening advances through intersecting bookings for the whole crew',
    () {
      final engine = JobScheduleAvailability([
        job('a1', 9, 11),
        job('b1', 10, 13, employees: ['b']),
        job('a2', 13, 14),
      ]);
      final openings = engine.firstOpenings(
        windows: [JobScheduleWindow(at(9), at(17))],
        duration: const Duration(hours: 2),
        employeeIds: {'a', 'b'},
      );
      expect(openings.single.start, at(14));
      expect(openings.single.end, at(16));
    },
  );
  test(
    'vehicle conflict blocks a different employee and current job is excluded',
    () {
      final engine = JobScheduleAvailability([
        job('self', 9, 12),
        job('truck', 9, 11, employees: ['b'], vehicle: 'Truck'),
      ]);
      expect(
        engine
            .firstOpenings(
              windows: [JobScheduleWindow(at(9), at(17))],
              duration: const Duration(hours: 1),
              employeeIds: {'a'},
              vehicle: 'Truck',
              excludingJobId: 'self',
            )
            .single
            .start,
        at(11),
      );
    },
  );
  test(
    'never offers outside search hours or in the past; skips completed jobs',
    () {
      final engine = JobScheduleAvailability([
        job('done', 9, 17, status: WorkRecordStatus.completed),
      ]);
      expect(
        engine.firstOpenings(
          windows: [JobScheduleWindow(at(9), at(17))],
          duration: const Duration(hours: 2),
          employeeIds: {'a'},
          notBefore: at(16),
        ),
        isEmpty,
      );
      expect(
        engine
            .firstOpenings(
              windows: [JobScheduleWindow(at(9), at(17))],
              duration: const Duration(hours: 2),
              employeeIds: {'a'},
              notBefore: at(12),
            )
            .single
            .start,
        at(12),
      );
    },
  );
  test(
    'overnight booking blocks next morning and windows are searched chronologically',
    () {
      final engine = JobScheduleAvailability([job('overnight', 22, 34)]);
      final openings = engine.firstOpenings(
        windows: [
          JobScheduleWindow(at(9, 3), at(17, 3)),
          JobScheduleWindow(at(9, 2), at(17, 2)),
        ],
        duration: const Duration(hours: 1),
        employeeIds: {'a'},
      );
      expect(openings.first.start, at(10, 2));
      expect(openings.last.start, at(9, 3));
    },
  );
  test('incomplete booked duration never produces a false opening', () {
    final incomplete = WorkRecord(
      id: 'unknown',
      kind: WorkRecordKind.job,
      number: 'unknown',
      title: 'Repair',
      client: 'Customer',
      detail: 'Repair',
      pricing: WorkPricingModel.flatRate,
      assignedEmployeeIds: const ['a'],
      scheduledStart: at(9),
    );
    expect(
      () => JobScheduleAvailability([incomplete]).firstOpenings(
        windows: [JobScheduleWindow(at(9), at(17))],
        duration: const Duration(hours: 1),
        employeeIds: {'a'},
      ),
      throwsStateError,
    );
  });
  test('unassigned job cannot be presented as employee availability', () {
    final engine = JobScheduleAvailability([]);
    expect(
      () => engine.firstOpenings(
        windows: [],
        duration: const Duration(hours: 1),
        employeeIds: {},
      ),
      throwsArgumentError,
    );
    expect(
      () => engine.firstOpenings(
        windows: [],
        duration: Duration.zero,
        employeeIds: {'a'},
      ),
      throwsArgumentError,
    );
  });
  test('minimum gap blocks nearby bookings and moves suggested opening', () {
    final engine = JobScheduleAvailability([
      job('busy', 9, 11, bufferMinutes: 15),
    ]);
    expect(
      engine.conflicts(
        start: at(11),
        end: at(12),
        employeeIds: {'a'},
        bufferMinutes: 30,
      ),
      hasLength(1),
    );
    final openings = engine.firstOpenings(
      windows: [JobScheduleWindow(at(11), at(17))],
      duration: const Duration(hours: 1),
      employeeIds: {'a'},
      bufferMinutes: 30,
    );
    expect(openings.single.start, DateTime(2030, 1, 1, 11, 30));
    expect(
      engine.conflicts(
        start: openings.single.start,
        end: openings.single.end,
        employeeIds: {'a'},
        bufferMinutes: 30,
      ),
      isEmpty,
    );
  });
  test('updating job items preserves crew, vehicle and schedule gap', () {
    final base = job('busy', 9, 11, vehicle: 'Truck', bufferMinutes: 30);
    final updated = base.reviseItems(const [
      WorkLineItem(
        id: 'part',
        type: WorkLineItemType.material,
        name: 'Part',
        quantity: 1,
        unit: 'each',
        customerPrice: 25,
      ),
    ], changedOn: at(12));
    expect(updated.assignedEmployeeIds, ['a']);
    expect(updated.vehicle, 'Truck');
    expect(updated.scheduleBufferMinutes, 30);
  });
}
