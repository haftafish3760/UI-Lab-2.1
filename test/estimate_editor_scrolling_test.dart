import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_price_summary.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/document_form_navigation.dart';

void main() {
  for (final width in [320.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('estimate actions scroll, $width / $scale / dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 760);
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
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: EstimateEditorScreen(initialDay: DateTime(2026, 9, 27)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('save-estimate-draft'));
          final actions = find.byKey(const ValueKey('estimate-editor-actions'));
          final photo = find.byKey(const ValueKey('estimate-site-photos'));
          expect(
            tester
                .widget<Scaffold>(
                  find.byKey(const ValueKey('estimate-editor-screen')),
                )
                .bottomNavigationBar,
            isNull,
          );
          expect(tester.widget<DocumentFormSection>(photo).title, 'Photos');
          expect(find.byType(EstimatePriceSummary), findsOneWidget);
          final originalY = tester.getTopLeft(actions).dy;
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          expect(save.hitTestable(), findsOneWidget);
          final position = Scrollable.of(tester.element(save)).position;
          if (position.maxScrollExtent > 0) {
            expect(tester.getTopLeft(actions).dy, lessThan(originalY));
            position.jumpTo(0);
            await tester.pumpAndSettle();
            expect(tester.getTopLeft(actions).dy, closeTo(originalY, 1));
          }
          expect(tester.takeException(), isNull);

          await openDocumentSection(tester, 'estimate-information');
          final section = find.byType(DocumentSectionEditor);
          final sectionScaffold = find.descendant(
            of: section,
            matching: find.byType(Scaffold),
          );
          expect(
            tester.widget<Scaffold>(sectionScaffold).bottomNavigationBar,
            isNull,
          );
          final done = find.byKey(const ValueKey('document-section-done'));
          final sectionScroll = Scrollable.of(tester.element(done)).position;
          final actionY = tester.getTopLeft(done).dy;
          await tester.ensureVisible(done);
          await tester.pumpAndSettle();
          expect(done.hitTestable(), findsOneWidget);
          if (sectionScroll.maxScrollExtent > 0) {
            expect(tester.getTopLeft(done).dy, lessThan(actionY));
          }
          sectionScroll.jumpTo(0);
          await tester.pumpAndSettle();
          final title = find.byKey(const ValueKey('estimate-title'));
          final number = find.byKey(const ValueKey('estimate-document-number'));
          expect(
            tester.getTopLeft(title).dy,
            lessThan(tester.getTopLeft(number).dy),
          );
          expect(find.text('Estimate number'), findsOneWidget);
          final description = find.byKey(
            const ValueKey('estimate-work-description'),
          );
          final field = tester.widget<TextField>(description);
          expect(
            field.decoration!.hintText,
            'Describe the work to be completed.',
          );
          expect(field.decoration!.helperText, isNull);
          await tester.ensureVisible(description);
          await tester.pumpAndSettle();
          await tester.enterText(
            description,
            'Replace the damaged outdoor fitting.',
          );
          await closeDocumentSection(tester);
          await openDocumentSection(tester, 'estimate-information');
          expect(
            tester.widget<TextField>(description).controller!.text,
            'Replace the damaged outdoor fitting.',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        });
      }
    }
  }
}
