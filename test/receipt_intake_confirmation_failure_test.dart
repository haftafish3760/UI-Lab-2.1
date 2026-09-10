import 'dart:io';
import 'dart:convert';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_editor_screen.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'receipt intake atomically rolls back Expense when receipt closure fails',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('dashboard-expense-save-'),
      ))!;
      var persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      await tester.runAsync(() async {
        final photo = File('${directory.path}/receipt.png');
        await photo.writeAsBytes(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
          ),
        );
        final seed = ReceiptDraftUiController(
          AuthorizedReceiptDraftService(persistence.receiptDrafts),
          receiptDraftUiLabOwnerPermissions(),
        );
        await seed.load();
        final created = await seed.create(
          draftId: 'intake-test',
          title: 'Receipt',
          expenseDate: DateTime(2030, 1, 2),
          evidence: [
            ReceiptEvidenceImport(
              sourcePath: photo.path,
              originalName: 'receipt.png',
              kind: ReceiptDraftEvidenceKind.photo,
            ),
            ReceiptEvidenceImport(
              sourcePath: photo.path,
              originalName: 'receipt-page-two.png',
              kind: ReceiptDraftEvidenceKind.photo,
            ),
          ],
          occurredAtUtc: DateTime.utc(2030, 1, 2),
        );
        expect(created, isNotNull);
        seed.dispose();
      });
      await tester.pumpWidget(
        UiLabApp(
          expenseRepository: persistence.expenses,
          receiptDraftRepository: persistence.receiptDrafts,
          draftStore: persistence.drafts,
        ),
      );
      await tester.pumpAndSettle();
      var controller = ExpenseUiScope.maybeOf(
        tester.element(find.byType(AppShell)),
      )!;
      await waitForNativeSave(
        tester,
        () => controller.phase == ExpenseRepositoryControllerPhase.ready,
      );
      final appContext = tester.element(find.byType(AppShell));
      var receiptController = ReceiptDraftUiScope.maybeOf(appContext)!;
      await waitForNativeSave(
        tester,
        () => receiptController.recordById('intake-test') != null,
      );
      Navigator.of(appContext).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptIntakeScreen(
            expenseDate: DateTime(2030, 1, 2),
            draftId: 'intake-test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-receipt-entry')));
      final vendor = find.byKey(const ValueKey('expense-vendor-field'));
      await waitForNativeSave(tester, () => vendor.evaluate().isNotEmpty);
      await tester.enterText(vendor, 'Receipt supplier');
      await tester.tap(find.byKey(const ValueKey('receipt-total-only-choice')));
      await tester.pumpAndSettle();
      final amount = find.widgetWithText(TextFormField, 'Final amount paid');
      await tester.ensureVisible(amount);
      await tester.enterText(amount, '7.');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-expense-button'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      final receiptRevision = receiptController
          .recordById('intake-test')!
          .lifecycle
          .revision;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() => persistence.close());
      persistence = (await tester.runAsync(
        () => LocalPersistence.open(directory: directory),
      ))!;
      await tester.pumpWidget(
        UiLabApp(
          expenseRepository: persistence.expenses,
          receiptDraftRepository: persistence.receiptDrafts,
          draftStore: persistence.drafts,
        ),
      );
      await tester.pumpAndSettle();
      final reopenedContext = tester.element(find.byType(AppShell));
      controller = ExpenseUiScope.maybeOf(reopenedContext)!;
      receiptController = ReceiptDraftUiScope.maybeOf(reopenedContext)!;
      await waitForNativeSave(
        tester,
        () =>
            controller.phase == ExpenseRepositoryControllerPhase.ready &&
            receiptController.recordById('intake-test') != null,
      );
      Navigator.of(reopenedContext).push(
        MaterialPageRoute<void>(
          builder: (_) => ReceiptIntakeScreen(
            expenseDate: DateTime(2030, 1, 2),
            draftId: 'intake-test',
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('manual-receipt-entry')));
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      expect(
        tester.widget<TextFormField>(vendor).controller!.text,
        'Receipt supplier',
      );
      expect(tester.widget<TextFormField>(amount).controller!.text, '7.');
      expect(
        receiptController.recordById('intake-test')!.lifecycle.revision,
        receiptRevision,
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.enterText(amount, '7.50');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      await tester.runAsync(
        () => persistence.database.customStatement(
          "CREATE TRIGGER fail_receipt_expense BEFORE UPDATE ON local_records WHEN NEW.domain = 'receipt-drafts/records' BEGIN SELECT RAISE(ABORT, 'injected receipt close failure'); END",
        ),
      );
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find
            .text(
              'The expense was not saved. Your input is still here. Retry saving.',
            )
            .evaluate()
            .isNotEmpty,
      );
      expect(controller.records, isEmpty);
      expect(
        tester.widget<TextFormField>(vendor).controller!.text,
        'Receipt supplier',
      );
      expect(receiptController.recordById('intake-test'), isNotNull);
      await tester.runAsync(
        () => persistence.database.customStatement(
          'DROP TRIGGER fail_receipt_expense',
        ),
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await waitForNativeSave(
        tester,
        () => find.byType(ExpenseEditorScreen).evaluate().isEmpty,
      );
      expect(find.byType(ReceiptIntakeScreen), findsNothing);
      expect(receiptController.recordById('intake-test'), isNull);
      expect(controller.records.single.vendor, 'Receipt supplier');
      expect(controller.records.single.receiptImageCount, 2);
      expect(controller.failure, isNull);
      expect(controller.revisionForId(controller.records.single.id), 1);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await persistence.close();
        await directory.delete(recursive: true);
      });
      expect(tester.takeException(), isNull);
    },
  );
}
