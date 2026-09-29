import 'support/visible_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/work_contact_codec.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/saved_clients_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_contact_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'invoice_service_price_test.dart' as fixtures;
import 'support/document_form_navigation.dart';

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets('invoice selects by client ID and preserves work at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      WorkCustomerProfile client(String id, String phone) =>
          WorkCustomerProfile(
            id: id,
            name: 'Alex Morgan',
            companyName: '',
            phone: phone,
            email: '',
            preferredContact: '',
            billingAddress: '',
            locations: [
              WorkServiceLocation(label: 'Home', address: '$id Test Lane'),
            ],
            notes: '',
            linkedRecordCount: 0,
          );
      final clients = [
        client('first', '2025550101'),
        client('second', '2025550102'),
      ];
      final original = buildConfirmedInvoice(
        InvoiceDraftInput.fromPayload({
          ...fixtures.priceInput('245.50').toPayload(),
          'client': clients.first.name,
          'customerSnapshot': encodeWorkCustomerProfile(clients.first),
        }),
      );
      final store = PrototypeOperationsStore(
        customers: clients,
        workRecords: [],
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
                    child: const Text('Open invoice'),
                    onPressed: () async {
                      saved = await Navigator.of(context).push<WorkRecord>(
                        MaterialPageRoute(
                          builder: (_) => InvoiceEditorScreen(
                            initialDay: DateTime(2026, 9, 28),
                            initialRecord: original,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open invoice'));
      await tester.pumpAndSettle();
      await openDocumentSection(tester, 'invoice-customer');
      final savedClients = find.byKey(const ValueKey('invoice-saved-clients'));
      final add = find.byKey(const ValueKey('invoice-add-client'));
      expect(tester.getTopLeft(savedClients).dy, tester.getTopLeft(add).dy);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      await tester.tap(savedClients);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('saved-client-search')),
        'Alex',
      );
      await tester.pumpAndSettle();
      final second = find.byKey(const ValueKey('saved-client-second'));
      await tester.ensureVisible(second);
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(find.byType(CustomerDetailScreen), findsOneWidget);
      // Reading a client and backing out must not change the invoice.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('2025550101'), findsOneWidget);
      expect(find.text('2025550102'), findsNothing);
      await tester.tap(savedClients);
      await tester.pumpAndSettle();
      await tester.ensureVisible(second);
      await tester.tap(second);
      await tester.pumpAndSettle();
      final use = find.byKey(const ValueKey('select-client-for-document'));
      await tester.ensureVisible(use);
      await tester.tap(use);
      await tester.pumpAndSettle();
      expect(find.byType(SavedClientsScreen), findsNothing);
      expect(find.text('2025550102'), findsOneWidget);
      expect(find.text('second Test Lane'), findsOneWidget);
      await closeDocumentSection(tester);
      final save = find.byKey(const ValueKey('save-invoice-draft'));
      await tapVisibleControl(tester, save);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.customerSnapshot!.id, 'second');
      expect(saved!.serviceLocation, 'second Test Lane');
      expect(saved!.title, original.title);
      expect(saved!.detail, original.detail);
      expect(saved!.total, original.total);
      expect(saved!.items.single.id, original.items.single.id);
      // Adding a client uses the same directory save and must not insert twice.
      await tester.tap(find.text('Open invoice'));
      await tester.pumpAndSettle();
      await openDocumentSection(tester, 'invoice-customer');
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('client-name-field')),
        'Taylor Newclient',
      );
      final saveClient = find.byKey(const ValueKey('save-client-button'));
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(tester.element(saveClient), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(saveClient);
      await tester.pumpAndSettle();
      expect(find.text('Taylor Newclient'), findsOneWidget);
      expect(
        store.customers.where((client) => client.name == 'Taylor Newclient'),
        hasLength(1),
      );
      await closeDocumentSection(tester);
      await tapVisibleControl(tester, save);
      await tester.pumpAndSettle();
      expect(saved!.customerSnapshot!.name, 'Taylor Newclient');
      expect(saved!.title, original.title);
      expect(saved!.total, original.total);
      expect(tester.takeException(), isNull);
    });
  }
}
