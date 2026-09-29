import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/shared/editor_draft_status.dart';
import 'package:ui_lab_2_1/src/screens/work/work_drafts_screen.dart';
import 'support/document_form_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'valid estimate recovers beside an unsupported draft, which remains intact',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var database = (await tester.runAsync(harness.open))!;
      var session = (await tester.runAsync(
        () => openUiLabWorkSession(database),
      ))!;
      var store = PrototypeOperationsStore(workSession: session);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        session.dispose();
        scope.dispose();
        await harness.dispose();
      });
      Future<void> openEditor({bool drafts = false}) async {
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => drafts
                              ? const WorkDraftsScreen()
                              : EstimateEditorScreen(
                                  initialDay: DateTime(2026, 9, 9),
                                ),
                        ),
                      ),
                      child: const Text('New estimate'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('New estimate'));
        if (drafts) {
          await waitForNativeSave(
            tester,
            () => find
                .textContaining('Interrupted pump repair')
                .evaluate()
                .isNotEmpty,
          );
        } else {
          await tester.pumpAndSettle();
        }
      }

      await openEditor();
      await openDocumentSection(tester, 'estimate-information');
      await tester.enterText(
        find.byKey(const ValueKey('estimate-title')),
        'Interrupted pump repair',
      );
      await closeDocumentSection(tester);
      final discount = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Discount',
      );
      await openDocumentSection(tester, 'estimate-discount');
      await tester.enterText(discount, '12.');
      await closeDocumentSection(tester);
      await waitForNativeSave(
        tester,
        () => find
            .byWidgetPredicate(
              (widget) =>
                  widget is EditorDraftStatus &&
                  widget.state == DraftSaveState.savedLocally,
            )
            .evaluate()
            .isNotEmpty,
      );
      final permissions = session.permissions;
      final draftStore = LocalDraftStore(database);
      final before = (await tester.runAsync(
        () => draftStore.list(
          organizationId: permissions.organizationId,
          domain: 'work/estimate-editor',
          ownerId: permissions.actorEmployeeId,
        ),
      ))!;
      expect(draftStore.decode(before.single)['discount'], '12.');
      expect(
        store.workRecords.where(
          (record) => record.title == 'Interrupted pump repair',
        ),
        isEmpty,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Keep your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save draft'));
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('estimate-editor-screen'))
            .evaluate()
            .isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 16));
      store.dispose();
      session.dispose();
      await tester.runAsync(() async {
        await LocalDraftStore(database).save(
          organizationId: permissions.organizationId,
          domain: 'work/estimate-editor',
          draftId: 'future-estimate-input',
          ownerId: permissions.actorEmployeeId,
          expectedRevision: 0,
          payload: {'title': 'Future draft', 'baseRecord': null},
          occurredAt: DateTime.utc(2030),
        );
        await database.customStatement(
          "UPDATE local_drafts SET payload_version = 2 WHERE draft_id = 'future-estimate-input'",
        );
      });
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      session = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
      store = PrototypeOperationsStore(workSession: session);
      await openEditor(drafts: true);
      await waitForNativeSave(
        tester,
        () => find
            .textContaining('Interrupted pump repair')
            .evaluate()
            .isNotEmpty,
      );
      expect(
        find.textContaining('Saved input unavailable — kept on this device'),
        findsOneWidget,
      );
      expect(find.text('Continue an unfinished estimate?'), findsNothing);
      await tester.tap(find.textContaining('Interrupted pump repair'));
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('estimate-information'))
            .evaluate()
            .isNotEmpty,
      );
      await openDocumentSection(tester, 'estimate-information');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('estimate-title')))
            .controller!
            .text,
        'Interrupted pump repair',
      );
      await openDocumentSection(tester, 'estimate-discount');
      expect(tester.widget<TextField>(discount).controller!.text, '12.');
      await closeDocumentSection(tester);
      // Discard is a separate explicit decision; route disposal above retained it.
      await tester.ensureVisible(find.text('Discard unfinished input'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard unfinished input'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard input'));
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('estimate-editor-screen'))
            .evaluate()
            .isEmpty,
      );
      final remaining = await tester.runAsync(
        () => LocalDraftStore(database).list(
          organizationId: permissions.organizationId,
          domain: 'work/estimate-editor',
          ownerId: permissions.actorEmployeeId,
        ),
      );
      expect(remaining, hasLength(1));
      expect(remaining!.single.draftId, 'future-estimate-input');
      expect(remaining.single.payloadVersion, 2);
      expect(
        remaining.single.payload,
        '{"baseRecord":null,"title":"Future draft"}',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
