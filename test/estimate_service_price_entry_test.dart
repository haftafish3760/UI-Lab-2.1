import 'support/document_form_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_items_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'estimate_service_price_test.dart' as fixtures;

void main() {
  testWidgets('estimate accepts one price directly without a style selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final record = buildConfirmedEstimate(
      fixtures.priceInput(''),
      now: DateTime(2026, 9, 28),
    );
    final store = PrototypeOperationsStore(
      workRecords: [record],
      financialEntries: [],
    );
    final scope = OperationalScopeController();
    addTearDown(store.dispose);
    addTearDown(scope.dispose);
    WorkRecord? saved;
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
                  onPressed: () async {
                    saved = await Navigator.of(context).push<WorkRecord>(
                      MaterialPageRoute(
                        builder: (_) => EstimateEditorScreen(
                          initialDay: DateTime(2026, 9, 28),
                          initialRecord: record,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open estimate'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open estimate'));
    await tester.pumpAndSettle();
    Future<void> tapVisible(Finder finder) async {
      await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await openDocumentSection(tester, 'estimate-price-summary');
    final priceField = find.byKey(const ValueKey('estimate-service-price'));
    await tapVisible(priceField);
    await tester.enterText(priceField, '245.50');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('estimate-document-presentation')),
      findsNothing,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await closeDocumentSection(tester);
    await tapVisible(
      find
          .descendant(
            of: find.byKey(const ValueKey('estimate-items')),
            matching: find.byType(TextButton),
          )
          .first,
    );
    final itemsEditor = tester.widget<EstimateItemsScreen>(
      find.byType(EstimateItemsScreen),
    );
    expect(itemsEditor.initialItems.single.total, 245.50);
    await tapVisible(find.byKey(const ValueKey('save-estimate-items')));
    await openDocumentSection(tester, 'estimate-price-summary');
    expect(tester.widget<TextField>(priceField).controller!.text, '245.50');
    await closeDocumentSection(tester);
    await tapVisible(find.byKey(const ValueKey('save-estimate-changes')));
    expect(saved, isNotNull);
    expect(saved!.documentPresentation, WorkDocumentPresentation.summary);
    expect(saved!.items.single.type, WorkLineItemType.service);
    expect(saved!.total, 245.50);
    final customerCopy = workCustomerDocument(
      saved!,
      store.companyProfile,
      null,
    );
    expect(customerCopy.items, isEmpty);
    expect(customerCopy.subtotalCents, 24550);
    expect(tester.takeException(), isNull);
  });
}
