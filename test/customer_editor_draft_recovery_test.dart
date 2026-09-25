import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/customer_edit_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'client input survives reopen and failed confirmation retains the form',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var database = (await tester.runAsync(harness.open))!;
      var directory = (await tester.runAsync(
        () => openUiLabDirectory(database),
      ))!;
      var store = PrototypeOperationsStore(directorySession: directory);
      final scope = OperationalScopeController();
      addTearDown(() async {
        store.dispose();
        directory.dispose();
        scope.dispose();
        await harness.dispose();
      });
      Finder field(String label) => find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      Future<void> open() async {
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
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => CustomerEditScreen(
                            selectedDay: DateTime(2026, 9, 9),
                          ),
                        ),
                      ),
                      child: const Text('New client'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('New client'));
        await tester.pumpAndSettle();
      }

      Future<void> save() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.byKey(const ValueKey('save-client-button')),
          find.byType(ListView).first,
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-client-button')));
      }

      await open();
      await waitForNativeSave(
        tester,
        () => field('Client name').evaluate().isNotEmpty,
      );
      await tester.enterText(field('Client name'), 'Recovered client');
      await tester.enterText(field('Phone'), '555-');
      await tester.binding.handlePopRoute();
      await waitForNativeSave(
        tester,
        () => find.byType(CustomerEditScreen).evaluate().isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(database));
      database = (await tester.runAsync(harness.open))!;
      directory = (await tester.runAsync(() => openUiLabDirectory(database)))!;
      store = PrototypeOperationsStore(directorySession: directory);
      await tester.runAsync(
        () => database.customStatement("""
      CREATE TRIGGER fail_client BEFORE INSERT ON local_records
      WHEN NEW.domain = 'directory/customers'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await open();
      await waitForNativeSave(
        tester,
        () => find.text('Continue an unfinished client?').evaluate().isNotEmpty,
      );
      await tester.tap(find.text('Recovered client'));
      await tester.pumpAndSettle();
      await waitForNativeSave(
        tester,
        () => field('Client name').evaluate().isNotEmpty,
      );
      expect(tester.widget<TextField>(field('Phone')).controller!.text, '(555');
      await tester.enterText(field('Phone'), '2025550101');
      await save();
      await waitForNativeSave(tester, () => directory.failureMessage != null);
      expect(find.byType(CustomerEditScreen), findsOneWidget);
      expect(
        store.customers.where((value) => value.name == 'Recovered client'),
        isEmpty,
      );
      final drafts = LocalDraftStore(database);
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: directory.permissions.organizationId,
            domain: 'directory/customer-editor',
            ownerId: directory.permissions.actorEmployeeId,
          ),
        ),
        hasLength(1),
      );
      await tester.runAsync(
        () => database.customStatement('DROP TRIGGER fail_client'),
      );
      await save();
      await waitForNativeSave(
        tester,
        () => find.byType(CustomerEditScreen).evaluate().isEmpty,
      );
      expect(
        store.customers
            .singleWhere((value) => value.name == 'Recovered client')
            .phone,
        '(202) 555-0101',
      );
      expect(
        await tester.runAsync(
          () => drafts.list(
            organizationId: directory.permissions.organizationId,
            domain: 'directory/customer-editor',
            ownerId: directory.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
