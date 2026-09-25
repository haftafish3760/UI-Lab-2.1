import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_edit_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final saveClient in [false, true]) {
    testWidgets('estimate customer directory choice: $saveClient', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final store = PrototypeOperationsStore();
      final scope = OperationalScopeController();
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      WorkCustomerProfile? result;
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
                    child: const Text('Open customer'),
                    onPressed: () async {
                      result = await Navigator.push<WorkCustomerProfile>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerEditScreen(
                            selectedDay: DateTime(2026, 9, 24),
                            offerEstimateOnly: true,
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
      await tester.tap(find.text('Open customer'));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.enterText(field('Client name'), 'TEST One-off customer');
      final phone = field('Phone');
      expect(tester.widget<TextField>(phone).keyboardType, TextInputType.phone);
      await tester.enterText(phone, '2025550101');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('save-client-button'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Save as a new client?'), findsOneWidget);
      await tester.tap(
        find.text(saveClient ? 'Save new client' : 'This estimate only'),
      );
      await tester.pumpAndSettle();
      expect(result?.name, 'TEST One-off customer');
      expect(result?.phone, '(202) 555-0101');
      expect(
        store.customers.any((c) => c.name == 'TEST One-off customer'),
        saveClient,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
