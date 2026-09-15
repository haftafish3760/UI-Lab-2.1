import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_job_attention.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';

void main() {
  final now = DateTime(2026, 9, 14, 14);
  WorkRecord job({
    WorkRecordStatus status = WorkRecordStatus.scheduled,
    DateTime? start,
    DateTime? end,
    List<String> employees = const [],
  }) => WorkRecord(
    id: 'job',
    kind: WorkRecordKind.job,
    number: 'Job 1',
    title: 'Repair',
    client: 'Test customer',
    detail: '',
    pricing: WorkPricingModel.flatRate,
    status: status,
    scheduledStart: start,
    scheduledEnd: end,
    assignedEmployeeIds: employees,
  );

  test('one primary queue retains all job issues', () {
    final facts = WorkJobAttention(
      job(
        status: WorkRecordStatus.needsReturnVisit,
        start: DateTime(2026, 9, 12),
      ),
      now,
    );
    expect(facts.primaryQueue, 'Overdue jobs');
    expect(facts.issues, [
      'Scheduled work date has passed',
      'Needs a return visit',
      'No employees assigned',
    ]);
  });
  test('drafts and completed jobs are never active or overdue', () {
    for (final status in [WorkRecordStatus.draft, WorkRecordStatus.completed]) {
      final facts = WorkJobAttention(
        job(status: status, start: DateTime(2025)),
        now,
      );
      expect(facts.primaryQueue, isNull);
      expect(facts.issues, isEmpty);
      expect(facts.overdue, isFalse);
    }
  });
  test('today is not past due; finish date wins for multi-day jobs', () {
    expect(
      WorkJobAttention(job(start: DateTime(2026, 9, 14)), now).overdue,
      isFalse,
    );
    expect(
      WorkJobAttention(
        job(start: DateTime(2026, 9, 12), end: DateTime(2026, 9, 15)),
        now,
      ).overdue,
      isFalse,
    );
    expect(WorkJobAttention(job(), now).overdue, isFalse);
    expect(
      WorkJobAttention(job(employees: ['employee-1']), now).primaryQueue,
      'Needs a work date',
    );
    expect(
      WorkJobAttention(
        job(start: DateTime(2026, 9, 15), employees: ['employee-1']),
        now,
      ).primaryQueue,
      'Other active jobs',
    );
  });
}
