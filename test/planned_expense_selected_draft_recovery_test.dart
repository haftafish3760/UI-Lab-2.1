import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_input.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession, seed;

void main() {
  for (final correction in [false, true]) {
    test(
      'selected planned expense correction=$correction preserves input and refuses stale or consumed selections',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'plan-selection-',
        );
        var persistence = await LocalPersistence.open(directory: directory);
        addTearDown(() async {
          await persistence.close();
          await directory.delete(recursive: true);
        });
        var app = await openSession(persistence);
        String? recordId;
        if (correction) {
          await seed(app);
          recordId = 'plan';
        }
        final original = await app.recurringExpenses.openPlannedDraft(
          existingRecordId: recordId,
        );
        original.updateInput(
          RecurringPlanDraftInput.fromPayload(
            original.input.toPayload()
              ..['amount'] = '-'
              ..['title'] = 'Interrupted plan',
          ),
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
        final resumed = await app.recurringExpenses.openPlannedDraft(
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
            app.recurringExpenses.openPlannedDraft(
              existingRecordId: recordId,
              recoverySelection: wrong,
            ),
            throwsA(isA<LocalRecordConflict>()),
          );
        }
        final discard = await app.recurringExpenses.openPlannedDraft(
          existingRecordId: recordId,
          recoverySelection: selected,
        );
        await discard.session.discard();
        await discard.session.close();
        await expectLater(
          app.recurringExpenses.openPlannedDraft(
            existingRecordId: recordId,
            recoverySelection: selected,
          ),
          throwsA(isA<LocalRecordConflict>()),
        );
        expect(
          await app.recurringExpenses.drafts!.find(
            organizationId: app.recurringExpenses.organizationId,
            ownerId: app.recurringExpenses.actorEmployeeId,
            domain: selected.domain,
            draftId: selected.draftId,
          ),
          isNull,
        );
        expect(app.recurringExpenses.records, hasLength(correction ? 1 : 0));
        if (correction) {
          expect(
            app.recurringExpenses.records.single.title,
            isNot('Interrupted plan'),
          );
        }
      },
    );
  }
}
