import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';
import 'expense_draft_workflow_test.dart' show initialExpense;
import 'recurring_payment_draft_workflow_test.dart' show openSession;

void main() {
  for (final planned in [false, true]) {
    test(
      '${planned ? "planned" : "manual"} selected draft cannot be recreated after discard',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'missing-selected-expense-',
        );
        final persistence = await LocalPersistence.open(directory: root);
        addTearDown(() async {
          await persistence.close();
          await root.delete(recursive: true);
        });
        final session = await openSession(persistence);
        Future<DraftAutosaveSession> open(String? id) async => planned
            ? (await session.recurringExpenses.openPlannedDraft(
                recoveryDraftId: id,
              )).session
            : (await session.expenses.openExpenseDraft(
                initial: initialExpense(),
                recoveryDraftId: id,
              )).session;
        final original = await open(null);
        await original.flush();
        final selectedId = original.draftId;
        await original.discard();
        await original.close();
        await expectLater(open(selectedId), throwsStateError);
        await expectLater(open('never-existed'), throwsStateError);
        expect(
          await persistence.drafts.list(
            organizationId: original.organizationId,
            domain: original.domain,
            ownerId: original.ownerId,
          ),
          isEmpty,
        );
        expect(session.expenses.records, isEmpty);
        expect(session.recurringExpenses.records, isEmpty);
        final fresh = await open(null);
        await fresh.flush();
        expect(fresh.draftId, isNot(selectedId));
        expect(
          await persistence.drafts.list(
            organizationId: original.organizationId,
            domain: original.domain,
            ownerId: original.ownerId,
          ),
          hasLength(1),
        );
        await fresh.close();
      },
    );
  }
}
