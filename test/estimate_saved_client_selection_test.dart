import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_edit_screen.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/saved_clients_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_contact_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/document_form_navigation.dart';

void main() {
  for (final width in [360.0, 1200.0]) {
    testWidgets('estimate client selection and cancellation at $width', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final clients = [demoWorkCustomers.first, demoWorkCustomers.last];
      final store = PrototypeOperationsStore(
        customers: clients,
        workRecords: [],
      );
      final scope = OperationalScopeController();
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: EstimateEditorScreen(
                initialDay: DateTime(2026, 9, 28),
                initialCustomer: clients.first,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openDocumentSection(tester, 'estimate-customer');
      final saved = find.byKey(const ValueKey('estimate-saved-clients'));
      final add = find.byKey(const ValueKey('estimate-add-client'));
      expect(tester.getTopLeft(saved).dy, tester.getTopLeft(add).dy);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.byKey(const ValueKey('saved-client-search')), findsNothing);
      await tester.tap(saved);
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('saved-client-search'));
      await tester.enterText(search, clients.last.name);
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('saved-client-${clients.first.id}')),
        findsNothing,
      );
      final row = find.byKey(ValueKey('saved-client-${clients.last.id}'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(SavedClientsScreen), findsNothing);
      expect(find.byType(DocumentSectionEditor), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('estimate-selected-client')),
            )
            .data,
        clients.last.name,
      );
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(find.byType(CustomerEditScreen), findsOneWidget);
      expect(
        tester
            .widget<CustomerEditScreen>(find.byType(CustomerEditScreen))
            .embedded,
        isTrue,
      );
      expect(find.byType(DocumentSectionEditor), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('client-name-field')),
        'Alex Rivera',
      );
      final nameField = tester.widget<TextField>(
        find.byKey(const ValueKey('client-name-field')),
      );
      expect(nameField.textInputAction, TextInputAction.next);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      final companyInput = find.descendant(
        of: find.byKey(const ValueKey('client-company-field')),
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(companyInput).focusNode.hasFocus,
        isTrue,
      );
      // Native Back returns to the saved list, not the estimate overview.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DocumentSectionEditor), findsOneWidget);
      expect(find.byKey(const ValueKey('saved-client-search')), findsOneWidget);
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('client-name-field')))
            .controller!
            .text,
        'Alex Rivera',
      );
      // The visible Back arrow follows the same inline history.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentSectionEditor), findsOneWidget);
      expect(find.byKey(const ValueKey('saved-client-search')), findsOneWidget);
      await tester.ensureVisible(add);
      await tester.tap(add);
      await tester.pumpAndSettle();
      // Switching the in-page choices must keep unfinished form input.
      await tester.ensureVisible(saved);
      await tester.tap(saved);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('client-name-field')))
            .controller!
            .text,
        'Alex Rivera',
      );
      final save = find.byKey(const ValueKey('save-client-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        store.customers.where((c) => c.name == 'Alex Rivera'),
        hasLength(1),
      );
      expect(find.byType(DocumentSectionEditor), findsOneWidget);
      expect(find.byType(CustomerEditScreen), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('estimate-selected-client')),
            )
            .data,
        'Alex Rivera',
      );
      await closeDocumentSection(tester);
      await openDocumentSection(tester, 'estimate-customer');
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('estimate-selected-client')),
            )
            .data,
        'Alex Rivera',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
