import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_items_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';

void main() {
  Finder field(String label) => find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == label,
  );
  Future<void> open(
    WidgetTester t, {
    List<WorkLineItem> items = const [],
    ValueChanged<WorkItemsDraftInput>? changed,
    TargetPlatform? platform,
  }) async {
    await t.binding.setSurfaceSize(const Size(500, 1100));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    await t.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light.copyWith(platform: platform),
          home: EstimateItemsScreen(
            initialItems: items,
            pricing: WorkPricingModel.flatRate,
            onDraftChanged: changed,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> add(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('add-estimate-material')));
    await t.pumpAndSettle();
  }

  testWidgets('labor save follows the items instead of covering them', (
    t,
  ) async {
    await open(
      t,
      items: [
        for (var i = 0; i < 12; i++)
          WorkLineItem(
            id: 'labor-$i',
            type: WorkLineItemType.labor,
            name: 'Inspection stage $i',
            quantity: 1,
            unit: 'hour',
            customerPrice: 75,
          ),
      ],
    );
    final save = find.byKey(const ValueKey('save-estimate-items'));
    expect(save.hitTestable(), findsNothing);
    await t.ensureVisible(save);
    await t.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    await t.drag(find.byType(ListView).first, const Offset(0, 3000));
    await t.pumpAndSettle();
    expect(save.hitTestable(), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'untouched new form leaves no unfinished input and another item opens',
    (t) async {
      WorkItemsDraftInput? saved;
      await open(t, changed: (input) => saved = input);
      await add(t);
      await t.pump();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.byType(WorkLineItemEditor), findsNothing);
      expect(saved?.pendingItems ?? [], isEmpty);
      await add(t);
      expect(find.byType(WorkLineItemEditor), findsOneWidget);
    },
  );
  testWidgets(
    'multiple incomplete entries survive independently and do not block adding',
    (t) async {
      WorkItemsDraftInput? saved;
      await open(t, changed: (input) => saved = input);
      for (final name in ['Timber', 'Fasteners']) {
        await add(t);
        await t.enterText(field('Material name'), name);
        await t.pump();
        await t.binding.handlePopRoute();
        await t.pumpAndSettle();
        expect(find.text('Save item changes?'), findsOneWidget);
        await t.tap(find.text('Save unfinished item'));
        await t.pumpAndSettle();
      }
      expect(saved!.pendingItems.map((e) => e.name), ['Timber', 'Fasteners']);
      await add(t);
      expect(find.byType(WorkLineItemEditor), findsOneWidget);
    },
  );
  testWidgets('reopening unfinished input and backing out preserves it', (
    t,
  ) async {
    WorkItemsDraftInput? saved;
    await open(t, changed: (input) => saved = input);
    await add(t);
    await t.enterText(field('Material name'), 'Saved unfinished timber');
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await t.tap(find.text('Save unfinished item'));
    await t.pumpAndSettle();
    final id = saved!.pendingItems.single.lineId;
    await t.tap(find.text('Saved unfinished timber'));
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Save item changes?'), findsNothing);
    expect(saved!.pendingItems.single.lineId, id);
    expect(saved!.pendingItems.single.name, 'Saved unfinished timber');
    await add(t);
    expect(find.byType(WorkLineItemEditor), findsOneWidget);
  });
  testWidgets('discarding edits preserves existing material and its quantity', (
    t,
  ) async {
    final item = WorkLineItem(
      id: 'wood',
      type: WorkLineItemType.material,
      name: '2x4x16',
      quantity: 12,
      unit: 'piece',
      customerPrice: 10,
    );
    WorkItemsDraftInput? saved;
    await open(t, items: [item], changed: (input) => saved = input);
    await t.ensureVisible(find.text('2x4x16'));
    await t.pumpAndSettle();
    await t.tap(find.text('2x4x16'));
    await t.pumpAndSettle();
    await t.enterText(field('Quantity'), '99');
    await t.pump();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    await t.tap(find.text('Discard changes'));
    await t.pumpAndSettle();
    expect(saved!.items.single.quantity, 12);
    expect(saved!.pendingItems, isEmpty);
    expect(find.byType(EstimateItemsScreen), findsOneWidget);
  });
  testWidgets('iOS edge swipe asks before leaving modified item', (t) async {
    await open(t, platform: TargetPlatform.iOS);
    await add(t);
    await t.enterText(field('Material name'), 'Unfinished timber');
    t.testTextInput.hide();
    await t.pumpAndSettle();
    await t.dragFrom(const Offset(2, 220), const Offset(180, 0));
    await t.pumpAndSettle();
    expect(find.text('Save item changes?'), findsOneWidget);
    await t.tap(find.text('Keep editing'));
    await t.pumpAndSettle();
    expect(find.byType(WorkLineItemEditor), findsOneWidget);
  });
}
