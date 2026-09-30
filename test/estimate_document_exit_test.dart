import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'estimate_service_price_test.dart' as fixtures;
import 'support/document_form_navigation.dart';

void main() {
  for (final choice in ['Save changes', 'Discard changes']) {
    testWidgets('Back keeps editing, then $choice returns the correct record', (
      tester,
    ) async {
      final original = buildConfirmedEstimate(
        fixtures.priceInput('250'),
        now: DateTime(2026, 9, 29),
      );
      final store = PrototypeOperationsStore(
        workRecords: [original],
        financialEntries: [],
      );
      final scope = OperationalScopeController();
      addTearDown(store.dispose);
      addTearDown(scope.dispose);
      WorkRecord? returned;
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
                    child: const Text('Open'),
                    onPressed: () async {
                      returned = await Navigator.of(context).push<WorkRecord>(
                        MaterialPageRoute(
                          builder: (_) => EstimateEditorScreen(
                            initialDay: DateTime(2026, 9, 29),
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
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await openDocumentSection(tester, 'estimate-information');
      await tester.enterText(
        find.byKey(const ValueKey('estimate-title')),
        'Changed title',
      );
      await closeDocumentSection(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Save changes to this estimate?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Changed title'), findsOneWidget);
      expect(returned, isNull);
      final cancel = find.byKey(const ValueKey('estimate-close'));
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(
        returned?.title,
        choice == 'Save changes' ? 'Changed title' : original.title,
      );
      expect(original.title, 'Repair');
      expect(tester.takeException(), isNull);
    });
  }
}
