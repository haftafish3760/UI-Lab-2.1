import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_review_examples.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'support/storage/database_harness.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';

void main() {
  test(
    'requested examples persist once with assignable employees and vehicles',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      await loadRequestedWorkExamples(db);
      final work = await openUiLabWorkSession(db);
      final directory = await openUiLabDirectory(db);
      expect(work.records, isNotEmpty);
      expect(
        work.records.map((record) => record.client).toSet(),
        hasLength(work.records.length),
      );
      expect(work.financialEntries.single.amountCents, 40000);
      expect(directory.employees, isNotEmpty);
      expect(directory.vehicles, isNotEmpty);
      for (final record in work.records) {
        for (final employee in record.assignedEmployeeIds) {
          expect(directory.employees.any((e) => e.id == employee), isTrue);
        }
      }
      final count = work.records.length;
      final ids = work.records.map((r) => r.id).toSet();
      work.dispose();
      directory.dispose();
      await harness.close(db);
      db = await harness.open();
      await loadRequestedWorkExamples(db);
      final reopened = await openUiLabWorkSession(db);
      expect(reopened.records, hasLength(count));
      expect(reopened.records.map((r) => r.id).toSet(), ids);
      await db.verifyIntegrity();
      reopened.dispose();
    },
  );

  test(
    'replacement removes old Work examples but preserves unrelated records and companies',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final records = LocalRecordStore(db);
      for (final company in [expenseUiLabOrganizationId, 'another-company']) {
        await records.commit(
          organizationId: company,
          commandId: 'mixed-before-reset',
          occurredAt: DateTime.now().toUtc(),
          writes: [
            LocalRecordWrite(
              domain: 'work/records',
              recordId: 'old-maya',
              ownerId: 'alex',
              expectedRevision: 0,
              payload: {'name': 'Maya Thompson'},
            ),
            LocalRecordWrite(
              domain: 'other-module/records',
              recordId: 'preserved',
              ownerId: 'alex',
              expectedRevision: 0,
              payload: {'evidence': 'preserve original'},
            ),
          ],
        );
      }
      await loadRequestedWorkExamples(db);
      expect(
        await records.read(
          organizationId: expenseUiLabOrganizationId,
          domain: 'work/records',
          ownerIds: {'alex'},
          recordIds: {'old-maya'},
        ),
        isEmpty,
      );
      expect(
        await records.read(
          organizationId: expenseUiLabOrganizationId,
          domain: 'other-module/records',
          ownerIds: {'alex'},
        ),
        hasLength(1),
      );
      expect(
        await records.read(
          organizationId: 'another-company',
          domain: 'work/records',
          ownerIds: {'alex'},
        ),
        hasLength(1),
      );
      await db.verifyIntegrity();
    },
  );
}
