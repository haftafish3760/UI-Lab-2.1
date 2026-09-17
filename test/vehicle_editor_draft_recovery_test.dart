import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/local_draft_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'support/storage/seeded_directory_fixture.dart';
import 'package:ui_lab_2_1/src/shell/vehicle_directory_screen.dart';
import 'package:ui_lab_2_1/src/shell/vehicle_editor_screen.dart';
import 'package:ui_lab_2_1/src/shell/operations_menu_screen.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'new vehicle raw input recovers after reopen; failed confirmation retains input and retry saves once',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      var db = (await tester.runAsync(harness.open))!;
      var directory = (await tester.runAsync(
        () => openSeededTestDirectory(db),
      ))!;
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
            home: const VehicleDirectoryScreen(),
          ),
        ),
      );
      Future<void> open() async {
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('add-vehicle-button'))
              .evaluate()
              .isNotEmpty,
        );
        await tester.tap(find.byKey(const ValueKey('add-vehicle-button')));
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => field('Vehicle name or unit number').evaluate().isNotEmpty,
        );
      }

      Future<void> save() async {
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        final button = find.byKey(const ValueKey('save-vehicle-button'));
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
        domain: 'directory/vehicle-editor',
        ownerId: directory.permissions.actorEmployeeId,
      );
      await mount();
      await open();
      await tester.enterText(
        field('Vehicle name or unit number'),
        '  New vehicle  ',
      );
      await tester.enterText(field('Year, make, and model'), '(555');
      await tester.enterText(
        field('Confirmed odometer reading (mi)'),
        '42,116.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await waitForNativeSave(
        tester,
        () => find.byType(VehicleEditorScreen).evaluate().isEmpty,
      );
      expect(directory.vehicles, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      directory = (await tester.runAsync(() => openSeededTestDirectory(db)))!;
      store = PrototypeOperationsStore(directorySession: directory);
      await mount();
      await open();
      expect(
        tester
            .widget<TextField>(field('Vehicle name or unit number'))
            .controller!
            .text,
        '  New vehicle  ',
      );
      expect(
        tester
            .widget<TextField>(field('Year, make, and model'))
            .controller!
            .text,
        '(555',
      );
      expect(
        tester
            .widget<TextField>(field('Confirmed odometer reading (mi)'))
            .controller!
            .text,
        '42,116.',
      );
      await tester.enterText(
        field('Confirmed odometer reading (mi)'),
        '42,116.4',
      );
      await tester.pump();
      await waitForNativeSave(
        tester,
        () => find.text('Draft saved on this device').evaluate().isNotEmpty,
      );
      await tester.runAsync(
        () => db.customStatement("""
      CREATE TRIGGER fail_vehicle_confirmation BEFORE INSERT ON local_records
      WHEN NEW.domain = 'directory/vehicles'
      BEGIN SELECT RAISE(ABORT, 'injected failure'); END
    """),
      );
      await save();
      await waitForNativeSave(tester, () => directory.failureMessage != null);
      expect(find.byType(VehicleEditorScreen), findsOneWidget);
      expect(directory.vehicles, hasLength(2));
      expect(await tester.runAsync(drafts), hasLength(1));
      await tester.runAsync(
        () => db.customStatement('DROP TRIGGER fail_vehicle_confirmation'),
      );
      await save();
      await waitForNativeSave(
        tester,
        () => find.byType(VehicleEditorScreen).evaluate().isEmpty,
      );
      expect(directory.vehicles, hasLength(3));
      final vehicle = directory.vehicles.singleWhere(
        (e) => e.name == 'New vehicle',
      );
      expect(vehicle.active, isFalse);
      expect(directory.vehicleOdometer(vehicle.id)!.readingTenths, 421164);
      expect(await tester.runAsync(drafts), isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
      directory.dispose();
      await tester.runAsync(() => harness.close(db));
      db = (await tester.runAsync(harness.open))!;
      directory = (await tester.runAsync(() => openSeededTestDirectory(db)))!;
      store = PrototypeOperationsStore(directorySession: directory);
      expect(
        directory.vehicles.singleWhere((e) => e.id == vehicle.id).toJson(),
        vehicle.toJson(),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'denied direct vehicle routes show no private profile or editor fields',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final db = (await tester.runAsync(harness.open))!;
      final owner = (await tester.runAsync(() => openSeededTestDirectory(db)))!;
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
      expect(find.byKey(const ValueKey('menu-vehicles')), findsNothing);
      await mount(const VehicleDirectoryScreen());
      expect(find.text(owner.vehicles.first.name), findsNothing);
      expect(find.byKey(const ValueKey('add-vehicle-button')), findsNothing);
      await mount(VehicleEditorScreen(initial: owner.vehicles.first));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.text(owner.vehicles.first.assignment), findsNothing);
      expect(
        find.text('You do not have permission to edit vehicle records.'),
        findsOneWidget,
      );
      expect(
        await tester.runAsync(
          () => LocalDraftStore(db).list(
            organizationId: denied.permissions.organizationId,
            domain: 'directory/vehicle-editor',
            ownerId: denied.permissions.actorEmployeeId,
          ),
        ),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
