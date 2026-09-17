import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_input.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_entry_setup_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'returning setup preserves raw manual input and rejects stale continuation',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = LocalDraftStore(db);
      Future<ExpenseEntrySetupWorkflow> open(ExpenseEntrySetupInput input) =>
          ExpenseEntrySetupWorkflow.open(
            repository: repository,
            organizationId: 'company',
            ownerId: 'owner',
            initial: input,
            authorize: () {},
          );
      final first = await open(
        ExpenseEntrySetupInput(
          date: DateTime(2030, 2, 3),
          category: ExpenseCategory.uncategorized,
          receiptType: ExpenseReceiptType.basic,
        ),
      );
      final id = await first.continueManually(ownerLabel: 'Owner');
      await first.session.close();
      final saved = (await repository.find(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'expenses/manual-entry',
        draftId: id,
      ))!;
      final raw = {
        ...repository.decode(saved),
        'amount': '12.',
        'vendor': 'Half typed',
        'futureField': {'keep': true},
      };
      final revision = await repository.save(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'expenses/manual-entry',
        draftId: id,
        expectedRevision: saved.revision,
        payload: raw,
        occurredAt: DateTime.now(),
      );
      final input = ExpenseEntrySetupInput(
        date: DateTime(2030, 2, 3),
        category: ExpenseCategory.fuel,
        receiptType: ExpenseReceiptType.detailed,
        continuation: ExpenseSetupContinuation(
          destination: ExpenseSetupDestination.manual,
          id: id,
          revision: revision,
        ),
      );
      final returned = await open(input);
      final stale = await open(input);
      expect(
        await returned.continueManually(ownerLabel: 'Wrong replacement label'),
        id,
      );
      await returned.session.close();
      await expectLater(
        stale.continueManually(ownerLabel: 'Owner'),
        throwsStateError,
      );
      await stale.session.close();
      final updated = (await repository.find(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'expenses/manual-entry',
        draftId: id,
      ))!;
      expect(repository.decode(updated), {
        ...raw,
        'category': 'fuel',
        'receiptType': 'detailed',
      });
      expect(updated.revision, revision + 1);
      expect(
        await repository.find(
          organizationId: 'company',
          ownerId: 'owner',
          domain: ExpenseEntrySetupWorkflow.domain,
          draftId: stale.session.draftId,
        ),
        isNotNull,
      );
      expect(await db.select(db.localRecords).get(), isEmpty);
    },
  );
  final initial = ExpenseEntrySetupInput(
    date: DateTime(2030, 2, 3),
    category: ExpenseCategory.uncategorized,
    receiptType: ExpenseReceiptType.basic,
  );
  test(
    'setup and unfinished category survive database reopen without business effects',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      var db = await harness.open();
      var repository = LocalDraftStore(db);
      final setup = await ExpenseEntrySetupWorkflow.open(
        repository: repository,
        organizationId: 'company',
        ownerId: 'owner',
        initial: initial,
        authorize: () {},
      );
      setup.chooseDetail(ExpenseReceiptType.detailed);
      setup.proposeCategory(ExpenseCategory.fuel);
      await setup.session.flush();
      final id = setup.session.draftId;
      await setup.session.close();
      await harness.close(db);
      db = await harness.open();
      repository = LocalDraftStore(db);
      final restored = await ExpenseEntrySetupWorkflow.open(
        repository: repository,
        organizationId: 'company',
        ownerId: 'owner',
        initial: initial,
        recoveryDraftId: id,
        authorize: () {},
      );
      expect(restored.input.date, initial.date);
      expect(restored.input.receiptType, ExpenseReceiptType.detailed);
      expect(restored.input.category, ExpenseCategory.uncategorized);
      expect(restored.input.pendingCategory, ExpenseCategory.fuel);
      restored.acceptCategory();
      await restored.session.flush();
      expect(restored.input.category, ExpenseCategory.fuel);
      expect(restored.input.pendingCategory, isNull);
      expect(await db.select(db.localRecords).get(), isEmpty);
      await restored.discard();
      await restored.session.close();
      expect(await db.select(db.localDrafts).get(), isEmpty);
    },
  );

  test(
    'failed writes retain input; retry saves; stale and revoked edits cannot overwrite',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = LocalDraftStore(db);
      var allowed = true;
      void authorize() {
        if (!allowed) throw StateError('Access revoked');
      }

      final setup = await ExpenseEntrySetupWorkflow.open(
        repository: repository,
        organizationId: 'company',
        ownerId: 'owner',
        initial: initial,
        authorize: authorize,
      );
      await setup.session.flush();
      await db.customStatement(
        "CREATE TRIGGER fail_setup BEFORE UPDATE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      setup.chooseDetail(ExpenseReceiptType.detailed);
      await expectLater(setup.session.flush(), throwsA(anything));
      expect(setup.input.receiptType, ExpenseReceiptType.detailed);
      await db.customStatement('DROP TRIGGER fail_setup');
      setup.retry();
      await setup.session.flush();
      final stale = await ExpenseEntrySetupWorkflow.open(
        repository: repository,
        organizationId: 'company',
        ownerId: 'owner',
        initial: initial,
        recoveryDraftId: setup.session.draftId,
        authorize: authorize,
      );
      setup.proposeCategory(ExpenseCategory.fuel);
      await setup.session.flush();
      stale.proposeCategory(ExpenseCategory.tools);
      await expectLater(stale.session.flush(), throwsA(anything));
      final stored = await repository.find(
        organizationId: 'company',
        ownerId: 'owner',
        domain: ExpenseEntrySetupWorkflow.domain,
        draftId: setup.session.draftId,
      );
      expect(
        ExpenseEntrySetupInput.fromPayload(
          repository.decode(stored!),
        ).pendingCategory,
        ExpenseCategory.fuel,
      );
      allowed = false;
      expect(
        () => setup.chooseDetail(ExpenseReceiptType.basic),
        throwsStateError,
      );
      await expectLater(setup.discard(), throwsStateError);
      await expectLater(stale.session.close(), throwsA(anything));
      await setup.session.close();
    },
  );
  test(
    'unknown setup versions remain untouched and missing recovery never reseeds',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = LocalDraftStore(db);
      final raw = {...initial.toPayload(), 'version': 99};
      await repository.save(
        organizationId: 'company',
        ownerId: 'owner',
        domain: ExpenseEntrySetupWorkflow.domain,
        draftId: 'unknown',
        expectedRevision: 0,
        occurredAt: DateTime.now().toUtc(),
        payload: raw,
      );
      for (final id in ['unknown', 'missing']) {
        await expectLater(
          ExpenseEntrySetupWorkflow.open(
            repository: repository,
            organizationId: 'company',
            ownerId: 'owner',
            initial: initial,
            recoveryDraftId: id,
            authorize: () {},
          ),
          throwsA(anything),
        );
      }
      final retained = await repository.list(
        organizationId: 'company',
        ownerId: 'owner',
        domain: ExpenseEntrySetupWorkflow.domain,
      );
      expect(retained, hasLength(1));
      expect(repository.decode(retained.single), raw);
      expect(retained.single.revision, 1);
    },
  );
  test(
    'manual continuation moves accepted setup into one recoverable expense draft',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = LocalDraftStore(db);
      final setup = await ExpenseEntrySetupWorkflow.open(
        repository: repository,
        organizationId: 'company',
        ownerId: 'owner',
        initial: initial,
        authorize: () {},
      );
      setup.proposeCategory(ExpenseCategory.fuel);
      await expectLater(
        setup.continueManually(ownerLabel: 'Owner'),
        throwsStateError,
      );
      setup.acceptCategory();
      setup.chooseDetail(ExpenseReceiptType.detailed);
      final id = await setup.continueManually(ownerLabel: 'Owner');
      await expectLater(
        setup.continueManually(ownerLabel: 'Owner'),
        throwsStateError,
      );
      final target = await repository.find(
        organizationId: 'company',
        ownerId: 'owner',
        domain: 'expenses/manual-entry',
        draftId: id,
      );
      final input = repository.decode(target!);
      expect(input['category'], 'fuel');
      expect(input['receiptType'], 'detailed');
      expect(input['amount'], '');
      expect(input['ownerId'], 'owner');
      expect(await db.select(db.localDrafts).get(), hasLength(1));
      expect(await db.select(db.localRecords).get(), isEmpty);
      await setup.session.close();
    },
  );
}
