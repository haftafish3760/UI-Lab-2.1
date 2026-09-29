import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_approval_content.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_export_audit.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

WorkSessionPermissions _grants({
  bool issue = true,
  bool requireApproval = false,
}) => WorkSessionPermissions(
  organizationId: 'business',
  actorEmployeeId: 'owner',
  permissionRevision: '1',
  visibleCreatorIds: {'owner'},
  editableKinds: {WorkRecordKind.invoice},
  canApproveInvoices: true,
  canShareDocuments: true,
  canIssueInvoices: issue,
  canRecordPayments: true,
  requiresInvoiceApproval: requireApproval,
);

const _invoice = WorkRecord(
  id: 'invoice',
  kind: WorkRecordKind.invoice,
  number: 'INV-100',
  title: 'Faucet replacement',
  client: 'Taylor Smith',
  detail: 'Replace faucet',
  total: 200,
  pricing: WorkPricingModel.flatRate,
  createdByEmployeeId: 'owner',
);

void main() {
  test(
    'approved invoice remains exportable after partial and final payment',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      final work = await WorkPersistenceSession.open(repository, _grants());
      addTearDown(work.dispose);
      expect(
        await work.create(_invoice.copyWith(requiresInvoiceApproval: true)),
        isTrue,
      );
      for (final decision in [
        InvoiceApprovalDecision.submitted,
        InvoiceApprovalDecision.approved,
      ]) {
        expect(
          await work.recordInvoiceApproval(work.records.single, decision),
          isTrue,
        );
      }
      expect(
        await work.save(
          records: [work.records.single.copyWith(status: WorkRecordStatus.due)],
          financialEntries: [
            PrototypeFinancialEntry(
              id: 'issue',
              kind: PrototypeFinancialKind.invoiceIssued,
              occurredOn: DateTime(2026, 9, 28),
              amountCents: 20000,
              sourceId: _invoice.id,
            ),
          ],
        ),
        isTrue,
      );
      for (final (id, amount) in [('partial', 5000), ('final', 15000)]) {
        expect(
          await work.save(
            financialEntries: [
              PrototypeFinancialEntry(
                id: id,
                kind: PrototypeFinancialKind.paymentReceived,
                occurredOn: DateTime(2026, 9, 28),
                amountCents: amount,
                sourceId: _invoice.id,
              ),
            ],
          ),
          isTrue,
        );
        expect(invoiceHasCurrentApproval(work.records.single), isTrue);
        final audit = WorkExportAudit(work);
        final attempt = await audit.begin(
          _invoice.id,
          work.storageRevisionFor(_invoice.id),
          'share',
          expectedDocument: work.records.single,
        );
        await audit.finish(attempt, 'cancelled');
      }
      expect(work.records.single.status, WorkRecordStatus.paid);
      final reopened = await WorkPersistenceSession.open(repository, _grants());
      addTearDown(reopened.dispose);
      expect(invoiceHasCurrentApproval(reopened.records.single), isTrue);
      expect(await WorkExportAudit(reopened).read(_invoice.id), hasLength(2));
    },
  );
  test(
    'every export action requires current approval and exact saved contents',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final repository = SqliteWorkRepository(db);
      final work = await WorkPersistenceSession.open(repository, _grants());
      addTearDown(work.dispose);
      expect(
        await work.create(_invoice.copyWith(requiresInvoiceApproval: true)),
        isTrue,
      );
      final audit = WorkExportAudit(work);
      for (final action in ['share', 'save', 'print']) {
        await expectLater(
          audit.begin(_invoice.id, 1, action),
          throwsStateError,
        );
      }
      expect(await audit.read(_invoice.id), isEmpty);
      expect(
        await work.recordInvoiceApproval(
          work.records.single,
          InvoiceApprovalDecision.submitted,
        ),
        isTrue,
      );
      await expectLater(audit.begin(_invoice.id, 2, 'share'), throwsStateError);
      expect(
        await work.recordInvoiceApproval(
          work.records.single,
          InvoiceApprovalDecision.approved,
        ),
        isTrue,
      );
      final approved = work.records.single;
      final revision = work.storageRevisionFor(_invoice.id);
      // Caller supplies the same identity/revision but altered contents.
      await expectLater(
        audit.begin(
          _invoice.id,
          revision,
          'share',
          expectedDocument: approved.copyWith(dueOn: DateTime(2030)),
        ),
        throwsStateError,
      );
      expect(await audit.read(_invoice.id), isEmpty);
      for (final action in ['share', 'save', 'print']) {
        final attempt = await audit.begin(
          _invoice.id,
          revision,
          action,
          expectedDocument: approved,
        );
        await audit.finish(attempt, 'cancelled');
      }
      expect(await audit.read(_invoice.id), hasLength(3));
      final reopened = await WorkPersistenceSession.open(repository, _grants());
      addTearDown(reopened.dispose);
      final reopenedAudit = WorkExportAudit(reopened);
      expect(
        (await reopenedAudit.assertCurrent(_invoice.id, revision)).id,
        _invoice.id,
      );
      // Another open session changes the contents while a screen still has the old invoice.
      expect(
        await work.update(approved.copyWith(dueOn: DateTime(2031))),
        isTrue,
      );
      await expectLater(
        reopenedAudit.assertCurrent(_invoice.id, revision),
        throwsStateError,
      );
      await expectLater(
        audit.begin(_invoice.id, revision + 1, 'print'),
        throwsStateError,
      );
      expect(await audit.read(_invoice.id), hasLength(3));
      await db.verifyIntegrity();
    },
  );

  test(
    'actor approval policy and issue authority cannot be bypassed by export command',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final repository = SqliteWorkRepository(await harness.open());
      final owner = await WorkPersistenceSession.open(repository, _grants());
      addTearDown(owner.dispose);
      expect(await owner.create(_invoice), isTrue);
      for (final grants in [
        _grants(issue: false),
        _grants(requireApproval: true),
      ]) {
        final limited = await WorkPersistenceSession.open(repository, grants);
        addTearDown(limited.dispose);
        final audit = WorkExportAudit(limited);
        for (final action in ['share', 'save', 'print']) {
          await expectLater(
            audit.begin(_invoice.id, 1, action),
            throwsStateError,
          );
        }
        expect(await audit.read(_invoice.id), isEmpty);
      }
      final audit = WorkExportAudit(owner);
      // Exact content verification also applies when approval is not required.
      await expectLater(
        audit.begin(
          _invoice.id,
          1,
          'save',
          expectedDocument: _invoice.copyWith(dueOn: DateTime(2030)),
        ),
        throwsStateError,
      );
      final attempt = await audit.begin(
        _invoice.id,
        1,
        'save',
        expectedDocument: _invoice,
      );
      await audit.finish(attempt, 'cancelled');
      final ended = await WorkPersistenceSession.open(repository, _grants());
      final endedAudit = WorkExportAudit(ended);
      ended.dispose();
      await expectLater(
        endedAudit.assertCurrent(_invoice.id, 1),
        throwsStateError,
      );
    },
  );
}
