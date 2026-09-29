import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'work_document_presentation_test.dart' as fixtures;

void main() {
  testWidgets(
    'existing itemized estimate retains its presentation and prices',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final record = buildConfirmedEstimate(
        fixtures.input(WorkDocumentPresentation.detailed),
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

      expect(
        find.byKey(const ValueKey('estimate-document-presentation')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('estimate-service-price')),
        findsNothing,
      );
      await tapVisible(find.byKey(const ValueKey('save-estimate-changes')));
      expect(saved, isNotNull);
      expect(saved!.documentPresentation, WorkDocumentPresentation.detailed);
      expect(saved!.items.single.name, '2 x 4 lumber');
      expect(saved!.total, record.total);
      final customerCopy = workCustomerDocument(
        saved!,
        store.companyProfile,
        null,
      );
      expect(customerCopy.items, hasLength(1));
      expect(customerCopy.subtotalCents, 4000);
      expect(tester.takeException(), isNull);
    },
  );
}
