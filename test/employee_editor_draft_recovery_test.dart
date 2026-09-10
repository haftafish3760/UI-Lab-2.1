import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/shell/employee_directory_screen.dart';
import 'package:ui_lab_2_1/src/shell/employee_editor_screen.dart';
import 'package:ui_lab_2_1/src/shell/operations_menu_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'new employee raw input recovers after reopen; failed confirmation retains input and retry saves once',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var directory = (await tester.runAsync(() => openUiLabDirectory(db)))!;
      var store = PrototypeOperationsStore(directorySession: directory);
      addTearDown(() async {
        store.dispose();
        directory.dispose();
        await harness.dispose();
      });
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      Future<void> mount() => tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const EmployeeDirectoryScreen(),
          ),
        ),
      );
      Future<void> open() async {
        await tester.tap(find.byKey(const ValueKey('add-employee-button')));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => field('Employee name').evaluate().isNotEmpty,
        );
      }

      Future<void> save() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('save-employee-button'));
        await tester.dragUntilVisible(
          button,
          find.byType(ListView).last,
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(button);
      }

      Future<List<dynamic>> drafts() => LocalDraftStore(db).list(
        organizationId: directory.permissions.organizationId,
        domain: 'directory/employee-editor',
        ownerId: directory.permissions.actorEmployeeId,
      );
      await mount();
      await open();
      await tester.enterText(field('Employee name'), '  New employee  ');
      await tester.enterText(field('Phone number'), '(555');
      await tester.enterText(field('Pay arrangement (private)'), r'$28.');
      final permission = find.byKey(
        const ValueKey('permission-record-expenses'),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final noExpenses = find.descendant(
        of: permission,
        matching: find.text('No'),
      );
      await tester.dragUntilVisible(
        noExpenses,
        find.byType(ListView).last,
        const Offset(0, -180),
      );
      await tester.ensureVisible(noExpenses);
      await tester.pumpAndSettle();
      await tester.tap(noExpenses);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await waitForNativeSave(
        tester,
        () => find.byType(EmployeeEditorScreen).evaluate().isEmpty,
      );
      expect(directory.employees, hasLength(3));
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      directory = (await tester.runAsync(() => openUiLabDirectory(db)))!;
      store = PrototypeOperationsStore(directorySession: directory);
      await mount();
      await open();
      expect(
        tester.widget<TextField>(field('Employee name')).controller!.text,
        '  New employee  ',
      );
      expect(
        tester.widget<TextField>(field('Phone number')).controller!.text,
        '(555',
      );
      expect(
        tester
            .widget<TextField>(field('Pay arrangement (private)'))
            .controller!
            .text,
        r'$28.',
      );
      await tester.runAsync(
        () => db.customStatement("""
      CREATE TRIGGER fail_employee_confirmation BEFORE INSERT ON local_records
      WHEN NEW.domain = 'directory/employees'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await save();
      await waitForNativeSave(tester, () => directory.failureMessage != null);
      expect(find.byType(EmployeeEditorScreen), findsOneWidget);
      expect(directory.employees, hasLength(3));
      expect(await tester.runAsync(drafts), hasLength(1));
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_employee_confirmation'),
      );
      await save();
      await waitForNativeSave(
        tester,
        () => find.byType(EmployeeEditorScreen).evaluate().isEmpty,
      );
      expect(directory.employees, hasLength(4));
      final employee = directory.employees.singleWhere(
        (e) => e.name == 'New employee',
      );
      expect(employee.canRecordExpenses, isFalse);
      expect(await tester.runAsync(drafts), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      directory = (await tester.runAsync(() => openUiLabDirectory(db)))!;
      store = PrototypeOperationsStore(directorySession: directory);
      expect(
        directory.employees.singleWhere((e) => e.id == employee.id).toJson(),
        employee.toJson(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'denied direct employee routes show no private profile or editor fields',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final db = (await tester.runAsync(harness.open))!;
      final owner = (await tester.runAsync(() => openUiLabDirectory(db)))!;
      final denied = (await tester.runAsync(
        () => DirectoryPersistenceSession.open(
          db,
          DirectoryPermissions(
            organizationId: owner.permissions.organizationId,
            actorEmployeeId: 'restricted',
            permissionRevision: 'denied',
          ),
        ),
      ))!;
      final store = PrototypeOperationsStore(directorySession: denied);
      addTearDown(() async {
        store.dispose();
        denied.dispose();
        owner.dispose();
        await harness.dispose();
      });
      Future<void> mount(Widget screen) => tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(theme: AppTheme.light, home: screen),
        ),
      );
      await mount(const OperationsMenuScreen());
      expect(find.byKey(const ValueKey('menu-employees')), findsNothing);
      await mount(const EmployeeDirectoryScreen());
      expect(find.text(owner.employees.first.name), findsNothing);
      expect(find.byKey(const ValueKey('add-employee-button')), findsNothing);
      await mount(EmployeeEditorScreen(initial: owner.employees.first));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text(owner.employees.first.pay), findsNothing);
      expect(
        find.text('You do not have permission to edit employee records.'),
        findsOneWidget,
      );
      expect(
        await tester.runAsync(
          () => LocalDraftStore(db).list(
            organizationId: denied.permissions.organizationId,
            domain: 'directory/employee-editor',
            ownerId: denied.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
