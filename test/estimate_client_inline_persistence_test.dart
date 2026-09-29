import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';
import 'support/document_form_navigation.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'empty directory creates and selects durable client inline at scale $scale',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final directory = (await tester.runAsync(
          () => openUiLabDirectory(db),
        ))!;
        final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        final store = PrototypeOperationsStore(
          directorySession: directory,
          workSession: work,
        );
        final scope = OperationalScopeController();
        addTearDown(() async {
          store.dispose();
          scope.dispose();
          work.dispose();
          directory.dispose();
          await finishNativeOperation(tester, harness.dispose);
        });
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
                home: EstimateEditorScreen(initialDay: DateTime(2026, 9, 28)),
              ),
            ),
          ),
        );
        await openDocumentSection(tester, 'estimate-customer');
        expect(find.text('No saved clients'), findsNothing);
        await tester.tap(find.byKey(const ValueKey('estimate-saved-clients')));
        await tester.pumpAndSettle();
        expect(find.byType(DocumentSectionEditor), findsOneWidget);
        expect(find.text('No saved clients'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('estimate-add-client')));
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('client-name-field'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.text('No saved clients').evaluate().isNotEmpty,
        );
        final emptyDrafts = await tester.runAsync(
          () => directory.customerDraftRecovery.list(),
        );
        expect(emptyDrafts, isEmpty);
        expect(directory.customers, isEmpty);
        await tester.tap(find.byKey(const ValueKey('estimate-add-client')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('client-name-field')),
          'Morgan Hayes',
        );
        final phone = find.widgetWithText(
          TextField,
          'Phone (including area code)',
        );
        await tester.ensureVisible(phone);
        await tester.enterText(phone, '5405550142');
        final email = find.widgetWithText(TextField, 'Email (optional)');
        await tester.ensureVisible(email);
        await tester.enterText(email, 'morgan@example.com');
        final address = find.widgetWithText(TextField, 'Service address');
        await tester.ensureVisible(address);
        await tester.enterText(address, '42 Example Lane, Roanoke, VA 24012');
        final save = find.byKey(const ValueKey('save-client-button'));
        FocusManager.instance.primaryFocus?.unfocus();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await waitForNativeSave(tester, () => directory.customers.length == 1);
        expect(find.byType(DocumentSectionEditor), findsOneWidget);
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('estimate-selected-client')),
              )
              .data,
          'Morgan Hayes',
        );
        final client = directory.customers.single;
        expect(client.email, 'morgan@example.com');
        expect(
          client.locations.single.address,
          '42 Example Lane, Roanoke, VA 24012',
        );
        await closeDocumentSection(tester);
        await openDocumentSection(tester, 'estimate-customer');
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('estimate-selected-client')),
              )
              .data,
          client.name,
        );
        final reopened = (await tester.runAsync(() => openUiLabDirectory(db)))!;
        expect(reopened.customers.single.id, client.id);
        expect(reopened.customers.single.phone, client.phone);
        reopened.dispose();
        // Ordinary unfinished entry survives leaving. New remains a fresh
        // form, and recovery is a separate explicit choice on this screen.
        await tester.tap(find.byKey(const ValueKey('estimate-add-client')));
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('client-name-field'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.enterText(
          find.byKey(const ValueKey('client-name-field')),
          'Unfinished customer',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        tester.testTextInput.hide();
        await closeDocumentSection(tester);
        await openDocumentSection(tester, 'estimate-customer');
        await waitForNativeSave(
          tester,
          () => find.text('Unfinished client forms').evaluate().isNotEmpty,
        );
        await tester.tap(find.byKey(const ValueKey('estimate-add-client')));
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('client-name-field'))
              .evaluate()
              .isNotEmpty,
        );
        expect(find.text('Continue an unfinished client?'), findsNothing);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('client-name-field')),
              )
              .controller!
              .text,
          isEmpty,
        );
        await tester.binding.handlePopRoute();
        await waitForNativeSave(
          tester,
          () => find.text('Unfinished client forms').evaluate().isNotEmpty,
        );
        await tester.ensureVisible(find.text('Unfinished client forms'));
        await tester.tap(find.text('Unfinished client forms'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Unfinished customer'));
        await tester.tap(find.text('Unfinished customer'));
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('client-name-field'))
              .evaluate()
              .isNotEmpty,
        );
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('client-name-field')),
              )
              .controller!
              .text,
          'Unfinished customer',
        );
        expect(directory.customers, hasLength(1));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
