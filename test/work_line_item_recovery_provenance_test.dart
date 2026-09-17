import 'package:ui_lab_2_1/src/data/work/work_line_item_draft_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets(
    'recovered imported item retains exact source identities and private cost',
    (tester) async {
      final scope = OperationalScopeController();
      addTearDown(scope.dispose);
      Map<String, Object?>? captured;
      WorkLineItem? result;
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      Future<void> open({Map<String, Object?>? recovery}) async {
        await tester.pumpWidget(
          OperationalScope(
            controller: scope,
            child: MaterialApp(
              key: UniqueKey(),
              theme: AppTheme.light,
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await Navigator.of(context).push<WorkLineItem>(
                        MaterialPageRoute(
                          builder: (_) => WorkLineItemEditor(
                            recoveryInput: recovery == null
                                ? null
                                : WorkLineItemDraftInput.fromPayload(recovery),
                            onDraftChanged: (input) =>
                                captured = input.toPayload(),
                            initialName: recovery == null ? 'Copper valve' : '',
                            initialCost: recovery == null ? 4.25 : null,
                            sourceExpenseId: recovery == null
                                ? 'expense-source'
                                : null,
                            sourceExpenseLineId: recovery == null
                                ? 'reviewed-line'
                                : null,
                            sourceReceiptId: recovery == null
                                ? 'receipt-source'
                                : null,
                            sourceStockId: recovery == null
                                ? 'stock-source'
                                : null,
                            canViewInternalCost: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open item'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open item'));
        await tester.pumpAndSettle();
      }

      await open();
      await tester.enterText(field('Quantity'), '3.');
      await tester.enterText(field('Price per item'), '8.50');
      final raw = Map<String, Object?>.of(captured!);
      await open(recovery: raw);
      expect(
        tester.widget<TextField>(field('Quantity')).controller!.text,
        '3.',
      );
      expect(field('Internal cost per unit (optional)'), findsNothing);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.dragUntilVisible(
        find.widgetWithText(FilledButton, 'Add line item'),
        find.byType(ListView).first,
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Add line item'));
      await tester.pumpAndSettle();
      expect(result!.id, raw['lineId']);
      expect(result!.quantity, 3);
      expect(result!.customerPrice, 8.50);
      expect(result!.internalUnitCost, 4.25);
      expect(result!.sourceExpenseId, 'expense-source');
      expect(result!.sourceExpenseLineId, 'reviewed-line');
      expect(result!.sourceReceiptId, 'receipt-source');
      expect(result!.sourceStockId, 'stock-source');
      expect(tester.takeException(), isNull);
    },
  );
}
