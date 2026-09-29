import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'invoice_service_price_test.dart' as fixtures;
import 'support/visible_control.dart';

void main() {
  testWidgets('invoice accepts one price without adding individual items', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final record = buildConfirmedInvoice(
      fixtures.priceInput(''),
      previewIncomplete: true,
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
                        builder: (_) => InvoiceEditorScreen(
                          initialDay: DateTime(2026, 9, 28),
                          initialRecord: saved ?? record,
                        ),
                      ),
                    );
                  },
                  child: const Text('Open invoice'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open invoice'));
    await tester.pumpAndSettle();
    Future<void> tapVisible(Finder finder) async {
      await tapVisibleControl(tester, finder);
      await tester.pumpAndSettle();
    }

    await tapVisible(find.byKey(const ValueKey('invoice-service-price')));
    await tester.enterText(find.byType(TextField), '245.50');
    await tester.pumpAndSettle();
    await tapVisible(find.text('Done'));
    await tapVisible(find.byKey(const ValueKey('save-invoice-draft')));
    expect(saved, isNotNull);
    expect(saved!.documentPresentation, WorkDocumentPresentation.summary);
    expect(saved!.items.single.type, WorkLineItemType.service);
    expect(saved!.total, 240.50);
    final customerCopy = workCustomerDocument(
      saved!,
      store.companyProfile,
      null,
    );
    expect(customerCopy.items, isEmpty);
    expect(customerCopy.subtotalCents, 24550);
    await tester.tap(find.text('Open invoice'));
    await tester.pumpAndSettle();
    expect(find.text('Add items (optional)'), findsOneWidget);
    expect(find.textContaining('1 item ·'), findsNothing);
    await tapVisible(find.byKey(const ValueKey('invoice-service-price')));
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '245.50',
    );
    await tester.enterText(find.byType(TextField), '');
    await tapVisible(find.text('Done'));
    await tapVisible(find.byKey(const ValueKey('save-invoice-draft')));
    expect(find.text('Enter the price for the work.'), findsOneWidget);
    await tapVisible(find.byKey(const ValueKey('invoice-service-price')));
    await tester.enterText(find.byType(TextField), '300');
    await tapVisible(find.text('Done'));
    await tapVisible(find.byKey(const ValueKey('save-invoice-draft')));
    expect(saved!.total, 295);
    expect(tester.takeException(), isNull);
  });
}
