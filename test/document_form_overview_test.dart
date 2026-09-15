import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/document_form_navigation.dart';

void main() {
  for (final invoice in [true, false]) {
    final kind = invoice ? 'invoice' : 'estimate';
    for (final size in [const Size(320, 844), const Size(1440, 1000)]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('$kind overview and editors reflow at $size scale $scale', (
          tester,
        ) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final store = PrototypeOperationsStore();
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
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: invoice
                      ? InvoiceEditorScreen(initialDay: DateTime(2026, 9, 14))
                      : EstimateEditorScreen(initialDay: DateTime(2026, 9, 14)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(DocumentFormOverview), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          expect(find.byKey(ValueKey('$kind-information')), findsOneWidget);
          expect(find.byKey(ValueKey('$kind-customer')), findsOneWidget);
          expect(tester.takeException(), isNull);
          await openDocumentSection(tester, '$kind-information');
          final title = find.byKey(ValueKey('$kind-title'));
          await tester.enterText(
            title,
            'Repair a long customer project title without cutting off words',
          );
          expect(tester.takeException(), isNull);
          await closeDocumentSection(tester);
          expect(
            find.textContaining('Repair a long customer project'),
            findsOneWidget,
          );
          await openDocumentSection(tester, '$kind-discount');
          await tester.enterText(find.byType(TextField), '12.50');
          await closeDocumentSection(tester);
          expect(
            find.descendant(
              of: find.byKey(ValueKey('$kind-discount')),
              matching: find.text(r'$12.50'),
            ),
            findsOneWidget,
          );
          await openDocumentSection(tester, '$kind-discount');
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            '12.50',
          );
          await closeDocumentSection(tester);
          await openDocumentSection(tester, '$kind-customer');
          expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
          expect(tester.takeException(), isNull);
          await closeDocumentSection(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets(
    'section failure keeps input visible and retries without duplicate close',
    (tester) async {
      final changes = ValueNotifier(0);
      final input = TextEditingController(text: 'Retain this input');
      addTearDown(changes.dispose);
      addTearDown(input.dispose);
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => DocumentSectionEditor(
                    title: 'Terms',
                    changes: changes,
                    builder: (_) => TextField(controller: input),
                    beforeClose: () async {
                      attempts++;
                      if (attempts == 1) throw StateError('disk unavailable');
                    },
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DocumentSectionEditor), findsOneWidget);
      expect(find.text('Retain this input'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('document-section-done')));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentSectionEditor), findsNothing);
      expect(attempts, 2);
    },
  );
}
