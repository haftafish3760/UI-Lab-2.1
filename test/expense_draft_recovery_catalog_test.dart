import 'dart:io';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_recovery_catalog.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_draft_recovery.dart';
import 'expense_draft_workflow_test.dart' show initialExpense, change;
import 'recurring_payment_draft_workflow_test.dart' show openSession;

void main() {
  test(
    'fresh lookup enforces read access and malformed owned input is retained',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'expense-access-catalog-',
      );
      final p = await LocalPersistence.open(directory: dir);
      addTearDown(() async {
        await p.close();
        await dir.delete(recursive: true);
      });
      await expectLater(
        () => AuthorizedExpenseService(p.expenses).findCurrent(
          expenseId: 'hidden',
          permissions: ExpenseCommandPermissions(
            organizationId: 'org',
            actorEmployeeId: 'alex',
            permissionRevision: 'test',
            readScope: null,
          ),
        ),
        throwsA(isA<ExpensePermissionDeniedException>()),
      );
      final app = await openSession(p);
      await app.expenses.drafts!.save(
        organizationId: app.expenses.organizationId,
        ownerId: app.expenses.actorEmployeeId,
        domain: 'expenses/manual-entry',
        draftId: 'malformed',
        expectedRevision: 0,
        payload: {'amount': '-'},
        occurredAt: DateTime.now().toUtc(),
      );
      final recovery = ExpenseDraftRecovery(app.expenses);
      final entry = (await recovery.list()).single;
      expect(entry.preview.availability, DraftRecoveryAvailability.unreadable);
      await expectLater(recovery.resume(entry), throwsStateError);
      expect((await recovery.list()).single.revision, 1);
    },
  );

  test(
    'manual and correction recovery survives reopen independently of list filters',
    () async {
      final dir = await Directory.systemTemp.createTemp('expense-catalog-');
      var p = await LocalPersistence.open(directory: dir);
      addTearDown(() async {
        await p.close();
        await dir.delete(recursive: true);
      });
      var app = await openSession(p);
      final create = await app.expenses.openExpenseDraft(
        initial: initialExpense(),
      );
      create.updateInput(change(create.input, {'amount': '12.50'}));
      final record = (await create.confirm())!;
      await create.session.close();
      final raw = <String, Object>{};
      for (final id in [null, record.id]) {
        final editor = await app.expenses.openExpenseDraft(
          initial: initialExpense(),
          existingRecordId: id,
        );
        editor.updateInput(
          change(editor.input, {'amount': '-', 'vendor': 'Unfinished'}),
        );
        await editor.session.close();
        raw[editor.session.draftId] = editor.session.input;
      }
      await p.close();
      p = await LocalPersistence.open(directory: dir);
      app = await openSession(p);
      await app.expenses.load(fromInclusive: DateTime(2040));
      expect(app.expenses.records, isEmpty);
      final recovery = ExpenseDraftRecovery(app.expenses);
      final entries = await recovery.list();
      expect(entries, hasLength(2));
      for (final entry in entries) {
        expect(
          entry.preview.availability,
          DraftRecoveryAvailability.recoverable,
        );
        final resumed = await recovery.resume(entry);
        expect(resumed.session.input, raw[entry.draftId]);
        expect(resumed.session.savedRevision, entry.revision);
        await resumed.session.close();
      }
      expect(app.expenses.records, isEmpty);
      await recovery.discard(entries.first);
      await expectLater(recovery.resume(entries.first), throwsA(anything));
      expect(await recovery.list(), hasLength(1));
    },
  );

  test(
    'fresh parent revision and deletion override stale projection without losing correction',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'expense-conflict-catalog-',
      );
      final p = await LocalPersistence.open(directory: dir);
      addTearDown(() async {
        await p.close();
        await dir.delete(recursive: true);
      });
      final app = await openSession(p);
      final create = await app.expenses.openExpenseDraft(
        initial: initialExpense(),
      );
      create.updateInput(change(create.input, {'amount': '12.50'}));
      final record = (await create.confirm())!;
      await create.session.close();
      final edit = await app.expenses.openExpenseDraft(
        initial: initialExpense(),
        existingRecordId: record.id,
      );
      edit.updateInput(change(edit.input, {'vendor': 'Unfinished correction'}));
      await edit.session.close();
      final recovery = ExpenseDraftRecovery(app.expenses);
      final selected = (await recovery.list()).single;
      final other = await openSession(p);
      expect(
        await other.expenses.update(
          record: record.copyWith(vendor: 'Newer'),
          occurredAtUtc: DateTime.now().toUtc(),
          expectedRevision: 1,
        ),
        isNotNull,
      );
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.conflict,
      );
      await expectLater(recovery.resume(selected), throwsStateError);
      expect(app.expenses.records.single.vendor, 'Supplier');
      expect(
        await other.expenses.softDelete(
          expenseId: record.id,
          occurredAtUtc: DateTime.now().toUtc(),
        ),
        isTrue,
      );
      expect(
        (await recovery.list()).single.preview.availability,
        DraftRecoveryAvailability.parentUnavailable,
      );
      final saved = (await app.expenses.drafts!.find(
        organizationId: app.expenses.organizationId,
        ownerId: app.expenses.actorEmployeeId,
        domain: edit.session.domain,
        draftId: edit.session.draftId,
      ))!;
      expect(saved.revision, edit.session.savedRevision);
      expect(app.expenses.drafts!.decode(saved), edit.session.input);
    },
  );
}
