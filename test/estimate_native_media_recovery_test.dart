import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/shared/editor_draft_status.dart';
import 'package:ui_lab_2_1/src/screens/work/work_drafts_screen.dart';
import 'support/document_form_navigation.dart';
import 'dart:convert';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/startup/application_media_coordinator.dart';
import 'package:ui_lab_2_1/src/data/storage/local_media_picker_request.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/native_media_picker_coordinator.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_site_photos_screen.dart';
import 'package:ui_lab_2_1/src/shell/app_shell.dart';
import 'support/storage/native_widget_pump.dart';

class _Gateway implements NativeMediaPickerGateway {
  late Future<List<MediaPickerReturnedFile>> Function() onPick;
  List<MediaPickerReturnedFile> lost = [];
  int recoveries = 0;
  @override
  bool get supportsRecovery => true;
  @override
  Future<List<MediaPickerReturnedFile>> pick(
    MediaPickerSource source,
    MediaPickerDestination destination,
  ) => onPick();
  @override
  Future<List<MediaPickerReturnedFile>> recover() async {
    recoveries++;
    final files = lost;
    lost = [];
    return files;
  }
}

void main() {
  for (final scenario in [
    'camera',
    'camera-recovery',
    'files',
    'files-recovery',
  ]) {
    final interrupted = scenario.endsWith('recovery');
    final isFile = scenario.startsWith('files');
    testWidgets(
      'estimate $scenario ${interrupted ? "restart recovery" : "capture"} keeps raw parent input and confirms photos once',
      (tester) async {
        final root = (await tester.runAsync(
          () => Directory.systemTemp.createTemp('estimate-native-ui-'),
        ))!;
        var persistence = (await tester.runAsync(
          () => LocalPersistence.open(directory: root),
        ))!;
        var work = (await tester.runAsync(
          () => openSeededTestWorkSession(persistence.database),
        ))!;
        final gateway = _Gateway();
        final permissions = work.permissions;
        String? target;
        late MediaPickerReturnedFile photo;
        await tester.runAsync(() async {
          final source = File('${root.path}/native.png');
          await source.writeAsBytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOIqpgGRAwQCgAmfgWhCo6K7AAAAABJRU5ErkJggg==',
            ),
          );
          photo = MediaPickerReturnedFile(
            path: source.path,
            name: 'Site original.png',
          );
        });
        var picks = 0;
        gateway.onPick = () async {
          picks++;
          final request =
              (await LocalMediaPickerRequestStore(persistence.database).findFor(
                organizationId: permissions.organizationId,
                ownerId: permissions.actorEmployeeId,
              ))!;
          expect(request.destination, MediaPickerDestination.estimate);
          target = request.targetId;
          final row = (await persistence.drafts.find(
            organizationId: permissions.organizationId,
            domain: 'work/estimate-editor',
            draftId: target!,
            ownerId: permissions.actorEmployeeId,
          ))!;
          expect(row.revision, request.targetRevision);
          expect(
            persistence.drafts.decode(row)['title'],
            'Interrupted site estimate',
          );
          if (interrupted && picks == 1) {
            gateway.lost = [photo];
            throw StateError('Native activity interrupted');
          }
          return [photo];
        };
        Future<void> openApp() async {
          await tester.pumpWidget(
            UiLabApp(
              expenseRepository: persistence.expenses,
              receiptDraftRepository: persistence.receiptDrafts,
              workSession: work,
              draftStore: persistence.drafts,
              mediaCoordinator: createApplicationMediaCoordinator(
                database: persistence.database,
                gateway: gateway,
                receiptPermissions: receiptDraftUiLabOwnerPermissions(),
                receipts: persistence.receiptDrafts,
                work: work,
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> openEditor({bool restoring = false}) async {
          Navigator.of(tester.element(find.byType(AppShell))).push(
            MaterialPageRoute<void>(
              builder: (_) => restoring
                  ? const WorkDraftsScreen()
                  : EstimateEditorScreen(initialDay: DateTime(2030)),
            ),
          );
          if (!restoring) await tester.pumpAndSettle();
          if (restoring) {
            await waitForNativeSave(
              tester,
              () => find
                  .textContaining('Interrupted site estimate')
                  .evaluate()
                  .isNotEmpty,
            );
            await tester.tap(find.textContaining('Interrupted site estimate'));
          }
          await openDocumentSection(tester, 'estimate-information');
          if (!restoring) {
            await tester.enterText(
              find.byKey(const ValueKey('estimate-title')),
              'Interrupted site estimate',
            );
            await closeDocumentSection(tester);
            final discount = find.byWidgetPredicate(
              (widget) =>
                  widget is TextField &&
                  widget.decoration?.labelText == 'Discount',
            );
            await openDocumentSection(tester, 'estimate-discount');
            await tester.enterText(discount, '7.');
            await closeDocumentSection(tester);
          }
          if (restoring) await closeDocumentSection(tester);
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          final openPhotos = find.byKey(const ValueKey('estimate-site-photos'));
          await tester.ensureVisible(openPhotos);
          await tester.pumpAndSettle();
          await tester.tap(openPhotos);
          await tester.pumpAndSettle();
        }

        try {
          await openApp();
          await openEditor();
          await tester.tap(
            isFile
                ? find.text('Choose image file')
                : find.byKey(const ValueKey('take-estimate-photo')),
          );
          if (interrupted) {
            await waitForNativeSave(
              tester,
              () => find
                  .byKey(const ValueKey('recover-estimate-photos'))
                  .evaluate()
                  .isNotEmpty,
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.runAsync(() async {
              work.dispose();
              await persistence.close();
              persistence = await LocalPersistence.open(directory: root);
              work = await openSeededTestWorkSession(persistence.database);
            });
            await openApp();
            if (!isFile) {
              await waitForNativeSave(tester, () => gateway.recoveries == 1);
            }
            await openEditor(restoring: true);
            await waitForNativeSave(
              tester,
              () => find
                  .byKey(const ValueKey('recover-estimate-photos'))
                  .evaluate()
                  .isNotEmpty,
            );
            await tester.tap(
              find.byKey(const ValueKey('recover-estimate-photos')),
            );
          }
          await waitForNativeSave(
            tester,
            () => find.text('Site original.png').evaluate().isNotEmpty,
          );
          final save = find.byKey(const ValueKey('save-estimate-photos'));
          await waitForNativeSave(
            tester,
            () => tester.widget<FilledButton>(save).onPressed != null,
          );
          await tester.tap(save);
          await waitForNativeSave(
            tester,
            () =>
                find.byType(EstimateSitePhotosScreen).evaluate().isEmpty &&
                find
                    .byWidgetPredicate(
                      (widget) =>
                          widget is EditorDraftStatus &&
                          widget.state == DraftSaveState.savedLocally,
                    )
                    .evaluate()
                    .isNotEmpty,
          );
          expect(
            work.records.where(
              (record) => record.title == 'Interrupted site estimate',
            ),
            isEmpty,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.runAsync(() async {
            work.dispose();
            await persistence.close();
            persistence = await LocalPersistence.open(directory: root);
            work = await openSeededTestWorkSession(persistence.database);
            final row = (await persistence.drafts.find(
              organizationId: permissions.organizationId,
              domain: 'work/estimate-editor',
              draftId: target!,
              ownerId: permissions.actorEmployeeId,
            ))!;
            final input = persistence.drafts.decode(row);
            expect(input['title'], 'Interrupted site estimate');
            expect(input['discount'], '7.');
            expect(input['photoEditor'], isNull);
            expect(input['sitePhotos'], hasLength(1));
            expect(
              (input['sitePhotos'] as List).single['source'],
              isFile ? 'file' : 'camera',
            );
            if (isFile) expect(gateway.recoveries, 0);
            expect(
              (input['sitePhotos'] as List).single['name'],
              'Site original.png',
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
            work.dispose();
            await persistence.close();
            await root.delete(recursive: true);
          });
        }
      },
    );
  }
}
