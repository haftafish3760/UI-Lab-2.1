import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_items_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final labor in [true, false]) {
    testWidgets(
      'unfinished ${labor ? 'labor' : 'material'} survives Back and database reopen with its estimate',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        var database = (await tester.runAsync(harness.open))!;
        var work = (await tester.runAsync(
          () => openUiLabWorkSession(database),
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
        Future<void> openEstimate() async {
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
                            builder: (_) => EstimateEditorScreen(
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
          await tester.pumpAndSettle();
        }

        Future<void> openItems() async {
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
          await tester.dragUntilVisible(
            find.byKey(
              ValueKey(
                labor ? 'estimate-labor-section' : 'estimate-materials-section',
              ),
            ),
            find.byType(ListView).first,
            const Offset(0, -240),
          );
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              ValueKey(
                labor ? 'estimate-labor-section' : 'estimate-materials-section',
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        Future<void> backUntilGone(Type type) async {
          await tester.binding.handlePopRoute();
          await waitForNativeSave(
            tester,
            () => find.byType(type).evaluate().isEmpty,
          );
        }

        await openEstimate();
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('estimate-title'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.enterText(
          find.byKey(const ValueKey('estimate-title')),
          'Nested draft',
        );
        await openItems();
        await tester.tap(
          find.byKey(
            ValueKey(labor ? 'add-estimate-labor' : 'add-estimate-material'),
          ),
        );
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
        await backUntilGone(EstimateItemsScreen);
        await tester.tap(find.byKey(const ValueKey('save-estimate-draft')));
        await tester.pumpAndSettle();
        expect(
          find.text('Review and save the unfinished estimate items first.'),
          findsOneWidget,
        );
        await backUntilGone(EstimateEditorScreen);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
        work.dispose();
        await tester.runAsync(() => harness.close(database));
        database = (await tester.runAsync(harness.open))!;
        work = (await tester.runAsync(() => openUiLabWorkSession(database)))!;
        store = PrototypeOperationsStore(workSession: work);
        await openEstimate();
        await waitForNativeSave(
          tester,
          () => find
              .text('Continue an unfinished estimate?')
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(find.text('Nested draft'));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find
              .byKey(
                ValueKey(
                  labor
                      ? 'estimate-labor-section'
                      : 'estimate-materials-section',
                ),
              )
              .evaluate()
              .isNotEmpty,
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
        await tester.enterText(field('Customer price per unit'), '25');
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
          () => find.byType(EstimateItemsScreen).evaluate().isEmpty,
        );
        await backUntilGone(EstimateEditorScreen);
        final drafts = LocalDraftStore(database);
        final saved = (await tester.runAsync(
          () => drafts.list(
            organizationId: work.permissions.organizationId,
            domain: 'work/estimate-editor',
            ownerId: work.permissions.actorEmployeeId,
          ),
        ))!;
        final input = drafts.decode(saved.single);
        expect(input['itemEditors'], isEmpty);
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
}
