import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'expense_draft_workflow_test.dart' show initialExpense, change;
import 'recurring_payment_draft_workflow_test.dart' show openSession;

void main() {
  for (final correction in [false, true]) {
    test(
      'selected expense correction=$correction preserves input and refuses stale or consumed selections',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'expense-selection-',
        );
        var persistence = await LocalPersistence.open(directory: directory);
        addTearDown(() async {
          await persistence.close();
          await directory.delete(recursive: true);
        });
        var app = await openSession(persistence);
        String? recordId;
        if (correction) {
          final create = await app.expenses.openExpenseDraft(
            initial: initialExpense(),
          );
          create.updateInput(change(create.input, {'amount': '12.50'}));
          recordId = (await create.confirm())!.id;
          await create.session.close();
        }
        final original = await app.expenses.openExpenseDraft(
          initial: initialExpense(),
          existingRecordId: recordId,
        );
        original.updateInput(
          change(original.input, {
            'amount': '-',
            'vendor': 'Interrupted supplier',
          }),
        );
        await original.session.close();
        final selected = DraftRecoverySelection(
          domain: original.session.domain,
          draftId: original.session.draftId,
          revision: original.session.savedRevision,
        );
        final raw = original.session.input;
        await persistence.close();
        persistence = await LocalPersistence.open(directory: directory);
        app = await openSession(persistence);
        final resumed = await app.expenses.openExpenseDraft(
          initial: initialExpense(),
          existingRecordId: recordId,
          recoverySelection: selected,
        );
        expect(resumed.session.input, raw);
        expect(resumed.session.savedRevision, selected.revision);
        await resumed.session.close();
        for (final wrong in [
          DraftRecoverySelection(
            domain: 'other',
            draftId: selected.draftId,
            revision: selected.revision,
          ),
          DraftRecoverySelection(
            domain: selected.domain,
            draftId: selected.draftId,
            revision: selected.revision + 1,
          ),
          DraftRecoverySelection(
            domain: selected.domain,
            draftId: 'missing',
            revision: selected.revision,
          ),
        ]) {
          await expectLater(
            app.expenses.openExpenseDraft(
              initial: initialExpense(),
              existingRecordId: recordId,
              recoverySelection: wrong,
            ),
            throwsA(isA<LocalRecordConflict>()),
          );
        }
        final discard = await app.expenses.openExpenseDraft(
          initial: initialExpense(),
          existingRecordId: recordId,
          recoverySelection: selected,
        );
        await discard.session.discard();
        await discard.session.close();
        await expectLater(
          app.expenses.openExpenseDraft(
            initial: initialExpense(),
            existingRecordId: recordId,
            recoverySelection: selected,
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(
          await app.expenses.drafts!.find(
            organizationId: app.expenses.organizationId,
            ownerId: app.expenses.actorEmployeeId,
            domain: selected.domain,
            draftId: selected.draftId,
          ),
          isNull,
        );
        expect(app.expenses.records, hasLength(correction ? 1 : 0));
        if (correction) expect(app.expenses.records.single.vendor, 'Supplier');
      },
    );
  }
}
