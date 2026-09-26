import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/work/work_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_schedule_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/seeded_directory_fixture.dart';

Future<void> pumpHome(
  WidgetTester tester,
  double width,
  double scale, {
  DirectoryPersistenceSession? directorySession,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = PrototypeOperationsStore(directorySession: directorySession);
  final scope = OperationalScopeController(view: AppViewMode.admin);
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
          home: const WorkScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Work home keeps Drafts and Employees on one phone row', (
    tester,
  ) async {
    final harness = await DatabaseHarness.create();
    addTearDown(harness.dispose);
    final directory = await openSeededTestDirectory(await harness.open());
    addTearDown(directory.dispose);

    await pumpHome(tester, 375, 1, directorySession: directory);
    final drafts = find.byKey(const ValueKey('open-work-drafts'));
    final employees = find.widgetWithText(OutlinedButton, 'Employees');
    expect(employees, findsOneWidget);
    expect(tester.getTopLeft(drafts).dy, tester.getTopLeft(employees).dy);
    expect(tester.getRect(drafts).right, lessThan(tester.getRect(employees).left));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 375.0, 600.0, 800.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Work $width LP and $scale text preserves destinations and calendar',
        (tester) async {
          await pumpHome(tester, width, scale);
          for (final name in [
            'jobs',
            'payments',
            'scheduling',
            'quotes',
            'estimates',
            'invoices',
          ]) {
            final tile = find.byKey(ValueKey('quick-$name'));
            expect(tile, findsOneWidget);
            expect(tester.getSize(tile).width, greaterThanOrEqualTo(62));
          }
          expect(find.byKey(const ValueKey('quick-customers')), findsNothing);
          expect(find.byKey(const ValueKey('quick-companyInfo')), findsNothing);
          expect(find.text('Work Calendar'), findsOneWidget);
          expect(find.text('Not connected'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('Scheduling opens and Back returns to Work', (tester) async {
    await pumpHome(tester, 375, 1);
    await tester.tap(find.byKey(const ValueKey('quick-scheduling')));
    await tester.pumpAndSettle();
    expect(find.byType(WorkScheduleScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('work-module-screen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('Work navigation responds to width, not height', () {
    // Widget tests use the unusually wide Ahem font; the measured-width
    // contract also proves the intended four-across normal-font SE layout.
    expect(
      AppLayoutEngine.workShortcutsFor(351, minimumLabelWidth: 72).columns,
      4,
    );
    expect(
      AppLayoutEngine.workShortcutsFor(351, minimumLabelWidth: 144).columns,
      2,
    );
    for (final height in [300.0, 450.0, 900.0]) {
      expect(
        AppLayoutEngine.navigationFor(Size(1024, height), work: true),
        AppNavigationMode.rail,
      );
      expect(
        AppLayoutEngine.navigationFor(Size(600, height), work: true),
        AppNavigationMode.bottom,
      );
    }
    expect(AppLayoutEngine.workLandingFor(723).columns, 1);
    expect(AppLayoutEngine.workLandingFor(724).columns, 2);
    expect(AppLayoutEngine.workLandingFor(2000).workspaceWidth, 824);
  });

  testWidgets('Work rail and bounded advertisement survive short window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const UiLabApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('desktop-destination-work')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1024, 350);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('desktop-destination-work')),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
    final ad = find.byKey(const ValueKey('prototype-ad-banner'));
    expect(tester.getSize(ad).width, 728);
    expect(tester.getRect(ad).bottom, lessThanOrEqualTo(350));
    expect(tester.takeException(), isNull);
  });
}
