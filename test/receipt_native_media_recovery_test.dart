import 'dart:convert';
import 'dart:io';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/startup/application_media_coordinator.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_submission_session.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_entry_flow.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'support/storage/native_widget_pump.dart';

class _Gateway implements NativeMediaPickerGateway {
  Future<List<MediaPickerReturnedFile>> Function()? onPick;
  List<MediaPickerReturnedFile> lost = [];
  int recoveries = 0;
  bool failRecovery = false;
  Object? pickFailure;
  @override
  bool get supportsRecovery => true;
  @override
  Future<List<MediaPickerReturnedFile>> pick(
    MediaPickerSource source,
    MediaPickerDestination destination,
  ) async {
    try {
      return await onPick!();
    } catch (error) {
      pickFailure = error;
      rethrow;
    }
  }

  @override
  Future<List<MediaPickerReturnedFile>> recover() async {
    recoveries++;
    if (failRecovery) {
      failRecovery = false;
      throw StateError("Simulated native recovery failure");
    }
    final result = lost;
    lost = [];
    return result;
  }
}

void main() {
  for (final scenario in [
    "capture",
    "gallery",
    "recovery",
    "startup-failure",
    "file-capture",
    "file-recovery",
  ]) {
    final isFile = scenario.startsWith("file-");
    final isGallery = scenario == 'gallery';
    final recovering =
        scenario != "capture" && scenario != "file-capture" && !isGallery;
    final failsStartup = scenario == "startup-failure";
    testWidgets(
      isFile
          ? "receipt file ${recovering ? 'reselection' : 'capture'} retains PDF with its original draft"
          : isGallery
          ? 'gallery photos stay on the same receipt when setup is changed and SQLite reopens'
          : failsStartup
          ? 'native startup failure leaves app usable and original receipt retries recovery'
          : recovering
          ? 'startup retains interrupted camera result; original receipt adopts exactly once'
          : 'receipt capture saves destination before camera and adopts into that draft',
      (tester) async {
        final root = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('receipt-native-ui-'),
        ))!;
        var persistence = (await tester.runAsync(
          () => LocalPersistence.open(directory: root),
        ))!;
        final permissions = receiptDraftUiLabOwnerPermissions();
        final gateway = _Gateway();
        String? target;
        late MediaPickerReturnedFile photo;
        await tester.runAsync(() async {
          final file = File('${root.path}/original.png');
          await file.writeAsBytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII=',
            ),
          );
          if (isFile) {
            // Minimal valid one-page PDF, with no runtime generator dependency.
            await file.writeAsBytes(
              base64Decode(
                'JVBERi0xLjQKMSAwIG9iago8PCAvVHlwZSAvQ2F0YWxvZyAvUGFnZXMgMiAwIFIgPj4KZW5kb2JqCjIgMCBvYmoKPDwgL1R5cGUgL1BhZ2VzIC9LaWRzIFszIDAgUl0gL0NvdW50IDEgPj4KZW5kb2JqCjMgMCBvYmoKPDwgL1R5cGUgL1BhZ2UgL1BhcmVudCAyIDAgUiAvTWVkaWFCb3ggWzAgMCAyMDAgMjAwXSAvUmVzb3VyY2VzIDw8ID4+IC9Db250ZW50cyA0IDAgUiA+PgplbmRvYmoKNCAwIG9iago8PCAvTGVuZ3RoIDAgPj4Kc3RyZWFtCmVuZHN0cmVhbQplbmRvYmoKeHJlZgowIDUKMDAwMDAwMDAwMCA2NTUzNSBmIAowMDAwMDAwMDA5IDAwMDAwIG4gCjAwMDAwMDAwNTggMDAwMDAgbiAKMDAwMDAwMDExNSAwMDAwMCBuIAowMDAwMDAwMjE5IDAwMDAwIG4gCnRyYWlsZXIKPDwgL1NpemUgNSAvUm9vdCAxIDAgUiA+PgpzdGFydHhyZWYKMjY3CiUlRU9GCg==',
              ),
            );
          }
          photo = MediaPickerReturnedFile(
            path: file.path,
            name: isFile ? 'Original receipt.pdf' : 'Camera original.png',
          );
          if (recovering) {
            final seed = ReceiptDraftUiController(
              AuthorizedReceiptDraftService(persistence.receiptDrafts),
              permissions,
            );
            final receipt = (await seed.create(
              draftId: 'interrupted-receipt',
              title: 'Interrupted receipt',
              expenseDate: DateTime(2030),
              evidence: [],
              occurredAtUtc: DateTime.utc(2030),
            ))!;
            target = receipt.draftId;
            await LocalMediaPickerRequestStore(persistence.database).begin(
              organizationId: permissions.organizationId,
              ownerId: permissions.actorEmployeeId,
              destination: MediaPickerDestination.receipt,
              targetId: target!,
              targetRevision: receipt.lifecycle.revision,
              source: isFile
                  ? MediaPickerSource.files
                  : MediaPickerSource.camera,
            );
            seed.dispose();
            await persistence.close();
            persistence = await LocalPersistence.open(directory: root);
            gateway.lost = [photo];
            gateway.failRecovery = failsStartup;
          }
        });
        gateway.onPick = () async {
          final request =
              await LocalMediaPickerRequestStore(persistence.database).findFor(
                organizationId: permissions.organizationId,
                ownerId: permissions.actorEmployeeId,
              );
          expect(request, isNotNull);
          target = request!.targetId;
          final receipt = await AuthorizedReceiptDraftService(
            persistence.receiptDrafts,
          ).find(draftId: target!, permissions: permissions);
          expect(receipt, isNotNull);
          expect(receipt!.activeEvidence, isEmpty);
          expect(receipt.lifecycle.revision, request.targetRevision);
          if (isGallery) {
            expect(request.source, MediaPickerSource.library);
            expect(receipt.entrySetup!.category, ExpenseCategory.fuel);
            expect(receipt.entrySetup!.type, ExpenseReceiptType.detailed);
          }
          return [photo];
        };
        try {
          await tester.pumpWidget(
            UiLabApp(
              expenseRepository: persistence.expenses,
              receiptDraftRepository: persistence.receiptDrafts,
              draftStore: persistence.drafts,
              mediaCoordinator: createApplicationMediaCoordinator(
                database: persistence.database,
                gateway: gateway,
                receiptPermissions: receiptDraftUiLabOwnerPermissions(),
                receipts: persistence.receiptDrafts,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final appContext = tester.element(find.byType(AppShell));
          final receipts = ReceiptDraftUiScope.maybeOf(appContext)!;
          final media = ReceiptSubmissionScope.maybeOf(appContext)!.media!;
          await waitForNativeSave(
            tester,
            () => receipts.phase == ReceiptDraftUiPhase.ready && !media.busy,
          );
          if (recovering) {
            expect(gateway.recoveries, isFile ? 0 : 1);
            expect(
              media.pending!.retainedAttachmentIds,
              failsStartup || isFile ? isNull : hasLength(1),
            );
            if (failsStartup) expect(media.failure, isNotNull);
            expect(receipts.recordById(target!)!.activeEvidence, isEmpty);
            // Retained originals, not the temporary picker cache, drive adoption.
            if (!failsStartup && !isFile) {
              await tester.runAsync(() => File(photo.path).delete());
            }
          }
          // PDF import UI is on hold; keep its existing media-service contract
          // exercised without presenting a newly enabled PDF action.
          if (scenario == 'file-capture') {
            await finishNativeOperation(tester, () async {
              final draft = (await receipts.create(
                draftId: 'file-service-receipt',
                title: 'File service receipt',
                expenseDate: DateTime(2030),
                evidence: [],
                occurredAtUtc: DateTime.utc(2030),
              ))!;
              target = draft.draftId;
              await media.pick(
                receiptId: target!,
                revision: draft.lifecycle.revision,
                source: MediaPickerSource.files,
              );
            });
          }
          if (isGallery) {
            openExpenseEntryFlow(
              appContext,
              expenseDate: DateTime(2030),
              initialCategory: ExpenseCategory.fuel,
              permissions: const ExpensePermissions.development(),
              onConfirm: (record) async => record,
            );
            await waitForNativeSave(
              tester,
              () => find
                  .byKey(const ValueKey('receipt-every-item-choice'))
                  .evaluate()
                  .isNotEmpty,
            );
            await tester.tap(
              find.byKey(const ValueKey('receipt-every-item-choice')),
            );
            await tester.pump();
            await tester.tap(
              find.byKey(const ValueKey('continue-expense-setup')),
            );
          } else {
            Navigator.of(appContext).push(
              MaterialPageRoute<void>(
                builder: (_) => ReceiptIntakeScreen(
                  expenseDate: DateTime(2030),
                  draftId: target,
                ),
              ),
            );
          }
          await waitForNativeSave(
            tester,
            () => find.byType(ReceiptIntakeScreen).evaluate().isNotEmpty,
          );
          final action = recovering
              ? find.byKey(const ValueKey('recover-receipt-photos'))
              : find.byKey(
                  ValueKey(
                    isGallery
                        ? 'receipt-source-photos'
                        : 'receipt-source-camera',
                  ),
                );
          if (scenario != 'file-capture') {
            await tester.ensureVisible(action);
            await tester.tap(action);
          }
          await waitForNativeSave(
            tester,
            () =>
                !media.busy &&
                (gateway.pickFailure != null ||
                    (target != null &&
                        receipts.recordById(target!)?.activeEvidence.length ==
                            1)),
          );
          expect(gateway.pickFailure, isNull);
          expect(find.text(photo.name), findsOneWidget);
          expect(
            receipts.recordById(target!)!.activeEvidence.single.kind,
            isFile
                ? ReceiptDraftEvidenceKind.pdf
                : ReceiptDraftEvidenceKind.photo,
          );
          if (isFile) expect(gateway.recoveries, 0);
          expect(media.pending, isNull);
          expect(receipts.recordById(target!)!.lifecycle.revision, 2);
          if (isGallery) {
            final originalId = target!;
            await tester.pageBack();
            await waitForNativeSave(tester, () {
              final choice = find.byKey(
                const ValueKey('choose-receipt-category'),
              );
              return choice.evaluate().isNotEmpty &&
                  tester.widget<OutlinedButton>(choice).onPressed != null;
            });
            await tester.tap(
              find.byKey(const ValueKey('choose-receipt-category')),
            );
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byKey(const ValueKey('receipt-category-search')),
              'Parking',
            );
            await tester.pump();
            await tester.tap(
              find.byKey(const ValueKey('receipt-category-receiptParking')),
            );
            await tester.tap(
              find.byKey(const ValueKey('confirm-receipt-category')),
            );
            await waitForNativeSave(
              tester,
              () => find
                  .byKey(const ValueKey('continue-expense-setup'))
                  .evaluate()
                  .isNotEmpty,
            );
            await tester.tap(
              find.byKey(const ValueKey('continue-expense-setup')),
            );
            await waitForNativeSave(
              tester,
              () => find.byType(ReceiptIntakeScreen).evaluate().isNotEmpty,
            );
            expect(find.text(photo.name), findsOneWidget);
            // Opening the picker commits the changed setup first. Cancelling
            // must not lose the existing image or create another receipt.
            gateway.onPick = () async => [];
            await tester.tap(
              find.byKey(const ValueKey('receipt-source-photos')),
            );
            await waitForNativeSave(
              tester,
              () =>
                  !media.busy &&
                  receipts.recordById(originalId)!.entrySetup!.category ==
                      ExpenseCategory.receiptParking,
            );
            expect(target, originalId);
            expect(
              receipts.recordById(originalId)!.activeEvidence,
              hasLength(1),
            );
          }
          final savedId = target!;
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {
            await persistence.close();
            persistence = await LocalPersistence.open(directory: root);
            final receipt = await AuthorizedReceiptDraftService(
              persistence.receiptDrafts,
            ).find(draftId: savedId, permissions: permissions);
            expect(receipt!.activeEvidence, hasLength(1));
            if (isGallery) {
              expect(
                receipt.entrySetup!.category,
                ExpenseCategory.receiptParking,
              );
              expect(receipt.entrySetup!.type, ExpenseReceiptType.detailed);
            }
            expect(
              await File(receipt.activeEvidence.single.localPath).length(),
              greaterThan(0),
            );
            expect(
              await LocalMediaPickerRequestStore(persistence.database).findFor(
                organizationId: permissions.organizationId,
                ownerId: permissions.actorEmployeeId,
              ),
              isNull,
            );
          });
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {
            await persistence.close();
            await root.delete(recursive: true);
          });
        }
      },
    );
  }
}
