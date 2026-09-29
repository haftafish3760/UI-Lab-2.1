import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/work/direct_payment_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/direct_payment_draft_workflow.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  test(
    'unfinished payment is recoverable and is consumed when recorded',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var database = await harness.open();
      var work = await openSeededTestWorkSession(database);
      final initial = await work.openDirectPaymentDraft(
        initialDay: DateTime(2026, 9, 26),
      );
      expect(await DirectPaymentDraftRecovery(work).list(), isEmpty);
      initial.updateInput(
        initial.input.copyWith(amount: '12.50', description: 'Lawn service'),
      );
      await initial.session.close();
      work.dispose();
      await harness.close(database);

      database = await harness.open();
      work = await openSeededTestWorkSession(database);
      addTearDown(work.dispose);
      final recovery = DirectPaymentDraftRecovery(work);
      final entry = (await recovery.list()).single;
      expect(entry.preview.availability, DraftRecoveryAvailability.recoverable);
      final resumed = await recovery.resume(entry);
      expect(resumed.input.amount, '12.50');
      final saved = await resumed.confirm();
      expect(saved?.description, 'Lawn service');
      await expectLater(resumed.confirm(), throwsStateError);
      expect(
        work.financialEntries.where((payment) => payment.id == saved?.id),
        hasLength(1),
      );
      expect(await recovery.list(), isEmpty);
      await resumed.session.close();
    },
  );
}
