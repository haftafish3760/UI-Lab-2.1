import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;

void main() {
  for (final receipt in [true, false]) {
    test(
      'discard setup preserves its destination across reopen, receipt: $receipt',
      () async {
        final root = await Directory.systemTemp.createTemp('setup-discard-');
        var persistence = await LocalPersistence.open(directory: root);
        try {
          final session = await openEvidenceSession(persistence);
          late String id;
          late ExpenseEntrySetupWorkflow setup;
          Object? before;
          if (receipt) {
            final target = await seedEvidence(session, root);
            id = target.draftId;
            before = target.toJson();
            setup = await session.returnToReceiptSetup(id);
          } else {
            final start = await session.expenses.openEntrySetup(
              initial: ExpenseEntrySetupInput(
                date: DateTime(2030),
                category: ExpenseCategory.fuel,
                receiptType: ExpenseReceiptType.basic,
              ),
            );
            id = await start.continueManually(ownerLabel: 'Owner');
            await start.session.close();
            setup = (await session.expenses.returnToManualSetup(id))!;
            final target = (await persistence.drafts.find(
              organizationId: session.expenses.organizationId,
              ownerId: session.expenses.actorEmployeeId,
              domain: 'expenses/manual-entry',
              draftId: id,
            ))!;
            before = persistence.drafts.decode(target);
          }
          final recovery = ExpenseDraftRecovery(session.expenses).setup;
          final stale = (await recovery.list()).single;
          setup.chooseDetail(ExpenseReceiptType.detailed);
          await setup.session.close();
          await expectLater(recovery.discard(stale), throwsA(anything));
          final selected = (await recovery.list()).single;
          await persistence.database.customStatement(
            "CREATE TRIGGER fail_discard_setup BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
          );
          await expectLater(recovery.discard(selected), throwsA(anything));
          expect(await recovery.list(), hasLength(1));
          await persistence.database.customStatement(
            'DROP TRIGGER fail_discard_setup',
          );
          await recovery.discard(selected);
          expect(await recovery.list(), isEmpty);
          await persistence.close();
          persistence = await LocalPersistence.open(directory: root);
          final reopened = await openEvidenceSession(persistence);
          expect(
            await ExpenseDraftRecovery(reopened.expenses).setup.list(),
            isEmpty,
          );
          if (receipt) {
            final target = (await reopened.receipts.findById(
              draftId: id,
            )).record!;
            expect(target.toJson(), before);
            for (final evidence in target.activeEvidence) {
              expect(await File(evidence.localPath).exists(), isTrue);
            }
          } else {
            final target = (await persistence.drafts.find(
              organizationId: reopened.expenses.organizationId,
              ownerId: reopened.expenses.actorEmployeeId,
              domain: 'expenses/manual-entry',
              draftId: id,
            ))!;
            expect(persistence.drafts.decode(target), before);
          }
          expect(reopened.expenses.records, isEmpty);
        } finally {
          await persistence.close();
          await root.delete(recursive: true);
        }
      },
    );
  }
}
