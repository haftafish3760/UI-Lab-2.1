import 'dart:io';
import 'package:ui_lab_2_1/src/data/storage/local_record_command.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_plan_draft_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_occurrence_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/recurring_payment_draft_workflow.dart';
import 'recurring_payment_draft_workflow_test.dart' show openSession, seed;

void main() {
  test(
    'all recurring draft types reopen unchanged and stale parent changes are detected',
    () async {
      final dir = await Directory.systemTemp.createTemp('recurring-catalog-');
      var p = await LocalPersistence.open(directory: dir);
      addTearDown(() async {
        await p.close();
        await dir.delete(recursive: true);
      });
      var app = await openSession(p);
      final occurrenceId = await seed(app);
      final raw = <String, Object>{};
      for (final id in [null, 'plan']) {
        final editor = await app.recurringExpenses.openPlannedDraft(
          existingRecordId: id,
        );
        editor.updateInput(
          RecurringPlanDraftInput.fromPayload(
            editor.input.toPayload()
              ..['amount'] = '-'
              ..['title'] = 'Unfinished',
          ),
        );
        await editor.session.close();
        raw[editor.session.draftId] = editor.session.input;
      }
      final occurrence = await app.recurringExpenses.openOccurrenceDraft(
        templateId: 'plan',
        occurrenceId: occurrenceId,
      );
      occurrence.updateValues(amount: '-', dueOn: DateTime(2030, 1, 22));
      await occurrence.session.close();
      raw[occurrence.session.draftId] = occurrence.session.input;
      final payment = await app.openPaymentDraft(
        templateId: 'plan',
        occurrenceId: occurrenceId,
      );
      payment.updateAmount('12.');
      await payment.session.close();
      raw[payment.session.draftId] = payment.session.input;
      await p.close();
      p = await LocalPersistence.open(directory: dir);
      app = await openSession(p);
      final recovery = RecurringDraftRecovery(app);
      final entries = await recovery.list();
      expect(entries, hasLength(4));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final resumed = await recovery.resume(entry);
        final session = switch (resumed) {
          ResumedRecurringPlan(:final controller) => controller.session,
          ResumedRecurringOccurrence(:final controller) => controller.session,
          ResumedRecurringPayment(:final controller) => controller.session,
        };
        expect(session.input, raw[entry.draftId]);
        expect(session.savedRevision, entry.revision);
        await session.close();
      }
      expect(app.expenses.records, isEmpty);
      for (final entry in entries.where(
        (e) =>
            e.domain.endsWith('-payment') || e.domain.endsWith('-occurrence'),
      )) {
        final wrong = DraftRecoverySelection(
          domain: entry.domain,
          draftId: entry.draftId,
          revision: entry.revision + 1,
        );
        await expectLater(
          entry.domain.endsWith('-payment')
              ? app.openPaymentDraft(
                  templateId: 'plan',
                  occurrenceId: occurrenceId,
                  recoverySelection: wrong,
                )
              : app.recurringExpenses.openOccurrenceDraft(
                  templateId: 'plan',
                  occurrenceId: occurrenceId,
                  recoverySelection: wrong,
                ),
          throwsA(isA<LocalRecordConflict>()),
        );
      }
      final other = await openSession(p);
      final current = other.recurringExpenses.currentOccurrenceFor('plan')!;
      expect(
        await other.recurringExpenses.updateOccurrence(
          current.copyWith(expectedAmount: 150),
        ),
        isNotNull,
      );
      final refreshed = await recovery.list();
      expect(
        refreshed.where(
          (e) => e.preview.availability == DraftRecoveryAvailability.conflict,
        ),
        hasLength(3),
      );
      for (final entry in entries.where((e) => !e.domain.endsWith('-new'))) {
        await expectLater(recovery.resume(entry), throwsStateError);
      }
      expect(await other.recurringExpenses.skip('plan', occurrenceId), isTrue);
      expect(
        (await recovery.list()).where(
          (e) =>
              e.preview.availability ==
              DraftRecoveryAvailability.parentUnavailable,
        ),
        hasLength(2),
      );
      for (final entry in entries.where(
        (e) =>
            e.domain.endsWith('-payment') || e.domain.endsWith('-occurrence'),
      )) {
        final wrong = DraftRecoverySelection(
          domain: entry.domain,
          draftId: entry.draftId,
          revision: entry.revision + 1,
        );
        // This actor still has an old projection. Selection guards must reject
        // recovery even when the cached occurrence appears open.
        await expectLater(
          entry.domain.endsWith('-payment')
              ? app.openPaymentDraft(
                  templateId: 'plan',
                  occurrenceId: occurrenceId,
                  recoverySelection: wrong,
                )
              : app.recurringExpenses.openOccurrenceDraft(
                  templateId: 'plan',
                  occurrenceId: occurrenceId,
                  recoverySelection: wrong,
                ),
          throwsStateError,
        );
      }
      final newEntry = refreshed.singleWhere((e) => e.domain.endsWith('-new'));
      await recovery.discard(newEntry);
      await expectLater(recovery.resume(newEntry), throwsA(anything));
      expect(await recovery.list(), hasLength(3));
      expect(app.expenses.records, isEmpty);
    },
  );
}
