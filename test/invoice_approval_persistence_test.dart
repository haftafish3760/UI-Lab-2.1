import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_financial_models.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_approval_content.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'support/storage/database_harness.dart';

void main() {
  test(
    'approval survives reopening; bypass, history rewrite and changed content fail',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final database = await harness.open();
      final repository = SqliteWorkRepository(database);
      WorkSessionPermissions grants(bool approver) => WorkSessionPermissions(
        organizationId: 'business',
        actorEmployeeId: 'owner',
        permissionRevision: 'v1',
        visibleCreatorIds: {'owner'},
        editableKinds: {WorkRecordKind.invoice},
        canIssueInvoices: true,
        canApproveInvoices: approver,
        requiresInvoiceApproval: true,
      );
      var session = await WorkPersistenceSession.open(
        repository,
        grants(false),
      );
      var record = WorkRecord(
        id: 'invoice-approval',
        kind: WorkRecordKind.invoice,
        number: 'INV-1',
        title: 'Replace faucet',
        client: 'Taylor Smith',
        detail: 'Kitchen faucet',
        pricing: WorkPricingModel.flatRate,
        createdByEmployeeId: 'owner',
        total: 100,
        issuedOn: DateTime(2026, 9, 28),
        dueOn: DateTime(2026, 10, 12),
        requiresInvoiceApproval: true,
      );
      expect(await session.create(record), isTrue);
      Future<bool> issue() => session.save(
        records: [record.copyWith(status: WorkRecordStatus.due)],
        financialEntries: [
          PrototypeFinancialEntry(
            id: 'issue',
            kind: PrototypeFinancialKind.invoiceIssued,
            occurredOn: record.issuedOn!,
            amountCents: 10000,
            sourceId: record.id,
          ),
        ],
      );
      expect(await issue(), isFalse);
      expect(session.financialEntries, isEmpty);
      expect(
        await session.recordInvoiceApproval(
          record,
          InvoiceApprovalDecision.submitted,
        ),
        isTrue,
      );
      record = session.records.single;
      expect(
        await session.recordInvoiceApproval(
          record,
          InvoiceApprovalDecision.approved,
        ),
        isFalse,
      );
      expect(session.records.single.invoiceApprovalHistory, hasLength(1));
      session.dispose();
      session = await WorkPersistenceSession.open(repository, grants(true));
      record = session.records.single;
      expect(
        await session.recordInvoiceApproval(
          record,
          InvoiceApprovalDecision.approved,
        ),
        isTrue,
      );
      record = session.records.single;
      expect(invoiceHasCurrentApproval(record), isTrue);
      expect(
        await session.update(record.copyWith(invoiceApprovalHistory: [])),
        isFalse,
      );
      expect(
        await session.update(record.copyWith(requiresInvoiceApproval: false)),
        isFalse,
      );
      expect(
        await session.update(record.copyWith(dueOn: DateTime(2026, 10, 15))),
        isTrue,
      );
      record = session.records.single;
      expect(invoiceHasCurrentApproval(record), isFalse);
      expect(await issue(), isFalse);
      expect(
        await session.recordInvoiceApproval(
          record,
          InvoiceApprovalDecision.approved,
        ),
        isFalse,
      );
      expect(
        await session.recordInvoiceApproval(
          record,
          InvoiceApprovalDecision.submitted,
        ),
        isTrue,
      );
      record = session.records.single;
      expect(
        await session.recordInvoiceApproval(
          record,
          InvoiceApprovalDecision.approved,
        ),
        isTrue,
      );
      session.dispose();
      session = await WorkPersistenceSession.open(repository, grants(true));
      addTearDown(session.dispose);
      record = session.records.single;
      expect(record.invoiceApprovalHistory, hasLength(4));
      expect(invoiceHasCurrentApproval(record), isTrue);
      expect(await issue(), isTrue);
      expect(session.financialEntries, hasLength(1));
      expect(await issue(), isTrue); // Exact retry is idempotent.
      expect(session.financialEntries, hasLength(1));
    },
  );
}
