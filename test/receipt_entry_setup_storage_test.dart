import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_workflow_models.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_record_adapter.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_entry_setup.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';

void main() {
  test(
    'every legacy receipt category survives an actual SQLite expense reopen',
    () async {
      final labels =
          (jsonDecode(
                    await File(
                      'test/fixtures/legacy_receipt_categories.json',
                    ).readAsString(),
                  )
                  as List)
              .cast<String>();
      expect(labels.length, 51);
      expect(receiptCategories.map((c) => c.label), unorderedEquals(labels));
      final root = await Directory.systemTemp.createTemp('receipt-categories-');
      var db = await LocalPersistence.open(directory: root);
      addTearDown(() async {
        await db.close();
        await root.delete(recursive: true);
      });
      for (final label in labels) {
        final category = ExpenseCategory.values.singleWhere(
          (c) => c.label == label,
        );
        final record = ExpenseRecordAdapter.fromUiRecord(
          record: ExpenseRecord(
            id: category.name,
            vendor: 'Test business',
            category: category,
            amount: 12.34,
            date: DateTime(2026, 9, 15),
            owner: 'Alex',
            paidByEmployeeId: 'alex',
          ),
          organizationId: expenseUiLabOrganizationId,
          createdByEmployeeId: 'alex',
          paidByEmployeeId: 'alex',
          nowUtc: DateTime.utc(2026, 9, 15),
        );
        await db.expenses.create(
          record,
          context: ExpenseMutationContext(
            actorEmployeeId: 'alex',
            occurredAtUtc: DateTime.utc(2026, 9, 15),
            permissionRevision: 'test',
          ),
        );
      }
      await db.close();
      db = await LocalPersistence.open(directory: root);
      for (final label in labels) {
        final category = ExpenseCategory.values.singleWhere(
          (c) => c.label == label,
        );
        final saved = (await db.expenses.findById(
          expenseId: category.name,
          access: expenseUiLabOwnerPermissions().readAccess!,
        ))!;
        expect(saved.categoryLabelSnapshot, label);
        expect(
          ExpenseRecordAdapter.toUiRecord(
            record: saved,
            ownerDisplayName: 'Alex',
          ).category,
          category,
        );
        expect(saved.total!.minorUnits, 1234);
      }
    },
  );

  test(
    'receipt category, detail and pasted source survive draft reopen and unrelated updates',
    () async {
      final root = await Directory.systemTemp.createTemp('receipt-setup-');
      var db = await LocalPersistence.open(directory: root);
      final access = receiptDraftUiLabOwnerPermissions();
      var controller = ReceiptDraftUiController(
        AuthorizedReceiptDraftService(db.receiptDrafts),
        access,
      );
      addTearDown(() async {
        controller.dispose();
        await db.close();
        await root.delete(recursive: true);
      });
      const setup = ReceiptEntrySetup(
        category: ExpenseCategory.receiptParking,
        type: ExpenseReceiptType.detailed,
        pastedText: 'Parking\nTOTAL 12.34',
      );
      final created = (await controller.create(
        draftId: 'setup',
        title: 'Receipt',
        expenseDate: DateTime(2026),
        evidence: [],
        occurredAtUtc: DateTime.utc(2026),
        entrySetup: setup,
      ))!;
      controller.dispose();
      await db.close();
      db = await LocalPersistence.open(directory: root);
      controller = ReceiptDraftUiController(
        AuthorizedReceiptDraftService(db.receiptDrafts),
        access,
      );
      await controller.load();
      expect(
        controller.recordById('setup')!.entrySetup!.toJson(),
        setup.toJson(),
      );
      final updated = await controller.update(
        draftId: 'setup',
        title: 'Updated receipt',
        expenseDate: DateTime(2026),
        retainedEvidenceIds: [],
        addedEvidence: [],
        occurredAtUtc: DateTime.utc(2026),
        expectedRevision: created.lifecycle.revision,
      );
      expect(updated!.entrySetup!.toJson(), setup.toJson());
      expect(
        () => ReceiptEntrySetup.fromJson({
          'category': null,
          'type': 'bad',
          'pastedText': '',
        }),
        throwsArgumentError,
      );
    },
  );
}
