import 'package:ui_lab_2_1/src/data/receipts/atomic_receipt_evidence_review.dart';
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
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final width in [390.0, 1400.0]) {
    testWidgets(
      'evidence review restores removal and undo; failed confirmation retries once at $width LP',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final directory = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('dashboard-expense-save-'),
        ))!;
        var persistence = (await tester.runAsync(
          () => LocalPersistence.open(directory: directory),
        ))!;
        addTearDown(() async {
          await tester.runAsync(() async {
            await persistence.close();
            if (await directory.exists()) {
              await directory.delete(recursive: true);
            }
          });
        });
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

        Future<ReceiptDraftUiController> openReview() async {
          await tester.pumpWidget(
            UiLabApp(
              expenseRepository: persistence.expenses,
              receiptDraftRepository: persistence.receiptDrafts,
              draftStore: persistence.drafts,
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(AppShell));
          final controller = ReceiptDraftUiScope.maybeOf(context)!;
          await waitForNativeSave(
            tester,
            () => controller.recordById('intake-test') != null,
          );
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ReceiptIntakeScreen(
                expenseDate: DateTime(2030, 1, 2),
                draftId: 'intake-test',
              ),
            ),
          );
          await tester.pumpAndSettle();
          final review = find.text('Review photos and order');
          await tester.ensureVisible(review);
          await tester.pumpAndSettle();
          await tester.tap(review);
          await waitForNativeSave(
            tester,
            () => find.text('Draft saved on this device').evaluate().isNotEmpty,
          );
          return controller;
        }

        Future<void> press(String text) async {
          final target = find.text(text).first;
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await tester.pumpAndSettle();
          await waitForNativeSave(
            tester,
            () => find.text('Draft saved on this device').evaluate().isNotEmpty,
          );
        }

        var controller = await openReview();
        final original = controller.recordById('intake-test')!;
        final originalIds = original.activeEvidence
            .map((e) => e.evidenceId)
            .toList();
        await press('Later');
        await press('Remove');
        expect(find.text('Undo last removal'), findsOneWidget);
        expect(
          controller.recordById('intake-test')!.lifecycle.revision,
          original.lifecycle.revision,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() => persistence.close());
        persistence = (await tester.runAsync(
          () => LocalPersistence.open(directory: directory),
        ))!;
        controller = await openReview();
        expect(find.text('Undo last removal'), findsOneWidget);
        expect(find.text('Remove'), findsOneWidget);
        await press('Undo last removal');
        expect(find.text('Remove'), findsNWidgets(2));
        await press('Remove');
        await tester.runAsync(
          () => persistence.database.customStatement(
            "CREATE TRIGGER fail_review BEFORE DELETE ON local_drafts BEGIN SELECT RAISE(ABORT, 'injected review failure'); END",
          ),
        );
        await press('Save order');
        await waitForNativeSave(
          tester,
          () => find
              .textContaining('The evidence review was not applied.')
              .evaluate()
              .isNotEmpty,
        );
        expect(
          find.textContaining('The evidence review was not applied.'),
          findsOneWidget,
        );
        expect(
          controller.recordById('intake-test')!.lifecycle.revision,
          original.lifecycle.revision,
        );
        await tester.runAsync(
          () =>
              persistence.database.customStatement('DROP TRIGGER fail_review'),
        );
        await tester.ensureVisible(find.text('Save order'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save order'));
        await waitForNativeSave(
          tester,
          () => find.text('Save order').evaluate().isEmpty,
        );
        final committed = controller.recordById('intake-test')!;
        expect(committed.lifecycle.revision, original.lifecycle.revision + 1);
        expect(committed.activeEvidence.map((e) => e.evidenceId), [
          originalIds.first,
        ]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final rows = await persistence.database
              .customSelect(
                "SELECT * FROM local_drafts WHERE domain = 'receipts/evidence-review'",
              )
              .get();
          expect(rows, isEmpty);
          for (final item in original.evidence) {
            expect(await File(item.localPath).exists(), isTrue);
          }
        });
        final permissions = receiptDraftUiLabOwnerPermissions();
        final recoveryId = AtomicReceiptEvidenceReview.draftIdFor(
          permissions.actorEmployeeId,
          'intake-test',
        );
        final staleInput = <String, Object?>{
          'sourceId': 'intake-test',
          'sourceRevision': original.lifecycle.revision,
          'orderedEvidenceIds': originalIds,
          'selectedId': originalIds.last,
          'undoId': null,
          'undoIndex': null,
        };
        await tester.runAsync(
          () => persistence.drafts.save(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            domain: AtomicReceiptEvidenceReview.draftDomain,
            draftId: recoveryId,
            expectedRevision: 0,
            payload: staleInput,
            occurredAt: DateTime.now(),
          ),
        );
        controller = await openReview();
        expect(
          find.textContaining('Saved evidence review could not be opened'),
          findsOneWidget,
        );
        expect(find.text('Save order'), findsNothing);
        final back = find.widgetWithText(TextButton, 'Back to receipt');
        expect(back, findsOneWidget);
        await tester.tap(back);
        await waitForNativeSave(
          tester,
          () => find
              .textContaining('Saved evidence review could not be opened')
              .evaluate()
              .isEmpty,
        );
        await tester.runAsync(() async {
          final retained = await persistence.drafts.find(
            organizationId: permissions.organizationId,
            ownerId: permissions.actorEmployeeId,
            domain: AtomicReceiptEvidenceReview.draftDomain,
            draftId: recoveryId,
          );
          expect(retained, isNotNull);
          expect(persistence.drafts.decode(retained!), staleInput);
        });
        final review = find.text('Review photos and order');
        await tester.ensureVisible(review);
        await tester.pumpAndSettle();
        await tester.tap(review);
        await waitForNativeSave(
          tester,
          () => find.text('Discard unfinished input').evaluate().isNotEmpty,
        );
        await tester.tap(find.text('Discard unfinished input'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Discard input'));
        await waitForNativeSave(
          tester,
          () => find
              .textContaining('Saved evidence review could not be opened')
              .evaluate()
              .isEmpty,
        );
        expect(
          controller.recordById('intake-test')!.lifecycle.revision,
          committed.lifecycle.revision,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          expect(
            await persistence.drafts.find(
              organizationId: permissions.organizationId,
              ownerId: permissions.actorEmployeeId,
              domain: AtomicReceiptEvidenceReview.draftDomain,
              draftId: recoveryId,
            ),
            isNull,
          );
        });
      },
    );
  }
}
