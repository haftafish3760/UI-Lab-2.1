import 'support/visible_control.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_line_item_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_drafts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'support/storage/seeded_work_fixture.dart';
import 'package:ui_lab_2_1/src/screens/work/work_job_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'unfinished nested item survives Back and database reopen with its job',
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
      Future<void> openJob({bool restoring = false}) async {
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
                              : WorkJobEditor(initialDay: DateTime(2026, 9, 9)),
                        ),
                      ),
                      child: const Text('New job'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('New job'));
        if (restoring) {
          await waitForNativeSave(
            tester,
            () => find.textContaining('Nested draft').evaluate().isNotEmpty,
          );
          await tester.tap(find.textContaining('Nested draft'));
        } else {
          await tester.pumpAndSettle();
        }
      }

      Future<void> openItems() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const ValueKey('job-items-section')),
          find.byType(ListView).first,
          const Offset(0, -240),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('job-items-section')));
        await tester.pumpAndSettle();
      }

      Future<void> backUntilGone(Type type) async {
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.byType(type).evaluate().isEmpty,
        );
      }

      await openJob();
      await waitForNativeSave(
        tester,
        () =>
            find.byKey(const ValueKey('job-title-field')).evaluate().isNotEmpty,
      );
      await tester.enterText(
        find.byKey(const ValueKey('job-title-field')),
        'Nested draft',
      );
      await openItems();
      await tester.tap(find.text('Add line item'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<WorkLineItemType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Labor').last);
      await tester.pumpAndSettle();
      await tester.enterText(field('Labor name'), 'Valve replacement');
      await tester.enterText(field('Quantity'), '2.');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save unfinished item'));
      await waitForNativeSave(
        tester,
        () => find.byType(WorkLineItemEditor).evaluate().isEmpty,
      );
      expect(find.textContaining('Unfinished item'), findsWidgets);
      expect(find.text('Save progress'), findsOneWidget);
      await backUntilGone(WorkItemsEditor);
      await tapVisibleControl(tester, find.byKey(const ValueKey('save-job')));
      await tester.pumpAndSettle();
      expect(
        find.text('Review and save the unfinished job items first.'),
        findsOneWidget,
      );
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
        () => find.byType(WorkJobEditor).evaluate().isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      work.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      work = (await tester.runAsync(
        () => openSeededTestWorkSession(database),
      ))!;
      store = PrototypeOperationsStore(workSession: work);
      await openJob(restoring: true);
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('job-items-section'))
            .evaluate()
            .isNotEmpty,
      );
      await openItems();
      await tester.tap(find.textContaining('Unfinished item'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(field('Labor name')).controller!.text,
        'Valve replacement',
      );
      expect(
        tester.widget<TextField>(field('Quantity')).controller!.text,
        '2.',
      );
      await tester.enterText(field('Price per item'), '25');
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Save item'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save item'));
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
        () => find.byType(WorkJobEditor).evaluate().isEmpty,
      );
      final drafts = LocalDraftStore(database);
      final saved = (await tester.runAsync(
        () => drafts.list(
          organizationId: work.permissions.organizationId,
          domain: 'work/job-editor',
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
