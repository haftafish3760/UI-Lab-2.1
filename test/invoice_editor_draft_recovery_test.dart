import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'support/document_form_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'raw unfinished invoice survives editor disposal and database reopen',
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
      InvoiceDraftController? recovered;
      Future<void> openEditor() async {
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
                          builder: (_) => InvoiceEditorScreen(
                            initialDay: DateTime(2026, 9, 9),
                            recoveredWorkflow: recovered,
                          ),
                        ),
                      ),
                      child: const Text('New invoice'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('New invoice'));
        await tester.pumpAndSettle();
      }

      await openEditor();
      await openDocumentSection(tester, 'invoice-information');
      await tester.enterText(
        find.byKey(const ValueKey('invoice-title')),
        'Interrupted pump repair',
      );
      await closeDocumentSection(tester);
      final discount = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Discount',
      );
      await openDocumentSection(tester, 'invoice-discount');
      await tester.enterText(discount, '12.');
      await closeDocumentSection(tester);
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      final permissions = session.permissions;
      final draftStore = LocalDraftStore(database);
      final before = (await tester.runAsync(
        () => draftStore.list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
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
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Save draft'),
        ),
      );
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('invoice-editor-screen'))
            .evaluate()
            .isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 16));
      store.dispose();
      session.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      session = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
      store = PrototypeOperationsStore(workSession: session);
      recovered = (await tester.runAsync(
        () => session.openInvoiceDraft(recoveryDraftId: before.single.draftId),
      ))!;
      await openEditor();

      await openDocumentSection(tester, 'invoice-information');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('invoice-title')))
            .controller!
            .text,
        'Interrupted pump repair',
      );
      await openDocumentSection(tester, 'invoice-discount');
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
            .byKey(const ValueKey('invoice-editor-screen'))
            .evaluate()
            .isEmpty,
      );
      final remaining = await tester.runAsync(
        () => LocalDraftStore(database).list(
          organizationId: permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: permissions.actorEmployeeId,
        ),
      );
      expect(remaining, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
