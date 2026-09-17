import 'package:ui_lab_2_1/src/screens/work/work_drafts_screen.dart';
import 'support/document_form_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'unfinished nested item survives Back and database reopen with its invoice',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var database = (await tester.runAsync(harness.open))!;
      var work = (await tester.runAsync(
        () => openSeededTestWorkSession(database),
      ))!;
      var store = PrototypeOperationsStore(workSession: work);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        work.dispose();
        scope.dispose();
        await harness.dispose();
      });
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      Future<void> openInvoice({bool restoring = false}) async {
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
                          builder: (_) => restoring
                              ? const WorkDraftsScreen()
                              : InvoiceEditorScreen(
                                  initialDay: DateTime(2026, 9, 9),
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
        if (restoring) {
          await waitForNativeSave(
            tester,
            () => find.text('Nested draft').evaluate().isNotEmpty,
          );
          await tester.tap(find.text('Nested draft'));
        } else {
          await tester.pumpAndSettle();
        }
      }

      Future<void> openItems() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const ValueKey('invoice-items')),
          find.byType(ListView).first,
          const Offset(0, -240),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('invoice-items')));
        await tester.pumpAndSettle();
      }

      Future<void> backUntilGone(Type type) async {
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.byType(type).evaluate().isEmpty,
        );
      }

      await openInvoice();
      await openDocumentSection(tester, 'invoice-information');
      await tester.enterText(
        find.byKey(const ValueKey('invoice-title')),
        'Nested draft',
      );
      await closeDocumentSection(tester);
      await openItems();
      await tester.tap(find.text('Add line item'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Item name'), 'Valve replacement');
      await tester.enterText(field('Quantity'), '2.');
      await backUntilGone(WorkLineItemEditor);
      expect(find.text('Continue unfinished item'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save items'),
            )
            .onPressed,
        isNull,
      );
      await backUntilGone(WorkItemsEditor);
      await tester.tap(find.byKey(const ValueKey('save-invoice-draft')));
      await tester.pumpAndSettle();
      expect(
        find.text('Review and save the unfinished invoice items first.'),
        findsOneWidget,
      );
      await backUntilGone(InvoiceEditorScreen);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      work.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(
        () => openSeededTestWorkSession(database),
      ))!;
      store = PrototypeOperationsStore(workSession: work);
      await openInvoice(restoring: true);
      await waitForNativeSave(
        tester,
        () => find.byKey(const ValueKey('invoice-items')).evaluate().isNotEmpty,
      );
      await openItems();
      await tester.tap(find.text('Continue unfinished item'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Item name')).controller!.text,
        'Valve replacement',
      );
      expect(
        tester.widget<TextField>(field('Quantity')).controller!.text,
        '2.',
      );
      await tester.enterText(field('Price per item'), '25');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Add line item'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Add line item'));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkLineItemEditor).evaluate().isEmpty,
      );
      expect(find.text('Continue unfinished item'), findsNothing);
      await tester.tap(find.text('Save items'));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkItemsEditor).evaluate().isEmpty,
      );
      await backUntilGone(InvoiceEditorScreen);
      final drafts = LocalDraftStore(database);
      final saved = (await tester.runAsync(
        () => drafts.list(
          organizationId: work.permissions.organizationId,
          domain: 'work/invoice-editor',
          ownerId: work.permissions.actorEmployeeId,
        ),
      ))!;
      final input = drafts.decode(saved.single);
      expect(input['itemEditor'], isNull);
      final item = (input['items'] as List).single as Map;
      expect(item['name'], 'Valve replacement');
      expect(item['quantity'], '2.0');
      expect(item['customerPrice'], '25.0');
      expect(
        store.workRecords.where((record) => record.title == 'Nested draft'),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
