import 'support/visible_control.dart';
import 'support/load_material_test_font.dart';
import 'package:flutter/material.dart';
import 'package:ui_lab_2_1/src/shared/operational_summary_strip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/layout/app_layout_engine.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'package:ui_lab_2_1/src/shell/app_menu_scope.dart';
import 'package:ui_lab_2_1/src/shell/operations_menu_screen.dart';

part 'work_calendar_routing_test_part.dart';

Future<void> _pumpWork(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  AppViewMode view = AppViewMode.technician,
  List<WorkRecord>? records,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController(view: view);
  final store = PrototypeOperationsStore(workRecords: records);
  addTearDown(scope.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Builder(
              builder: (context) => AppMenuScope(
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const OperationsMenuScreen(),
                  ),
                ),
                child: const WorkScreen(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadMaterialTestFont);
  registerWorkCalendarRoutingTests();

  testWidgets('Work exposes its six destinations above dated records', (
    tester,
  ) async {
    for (final size in [const Size(320, 844), const Size(1440, 900)]) {
      await _pumpWork(tester, size);
      for (final label in [
        'Jobs',
        'Payments',
        'Scheduling',
        'Quotes',
        'Estimates',
        'Invoices',
      ]) {
        expect(find.text(label), findsWidgets);
      }
      for (final destination in [
        'jobs',
        'payments',
        'scheduling',
        'quotes',
        'estimates',
        'invoices',
      ]) {
        expect(
          tester.getSize(
            find.byKey(ValueKey('work-shortcut-icon-$destination')),
          ),
          const Size(62, 62),
        );
      }
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Entries'), findsOneWidget);
      expect(find.text('Drafts'), findsNothing);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      final action = find.byKey(
        ValueKey(size.width < 884 ? 'work-add-button' : 'work-actions-inline'),
      );
      expect(action, findsOneWidget);
      expect(tester.getTopLeft(action).dy, greaterThan(size.height / 2));
      final viewport = find
          .descendant(
            of: find.byKey(const ValueKey('work-module-screen')),
            matching: find.byType(ListView),
          )
          .first;
      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('work-module-screen')),
      );
      expect(scaffold.bottomSheet, isNull);
      expect(scaffold.bottomNavigationBar, isNull);
      final actionBounds = tester.getRect(action);
      final scrolling = tester.state<ScrollableState>(
        find.descendant(of: viewport, matching: find.byType(Scrollable)).first,
      );
      final offset = scrolling.position.pixels;
      await tester.dragFrom(
        tester.getRect(viewport).bottomLeft + const Offset(8, -160),
        const Offset(0, -240),
      );
      await tester.pumpAndSettle();
      if (scrolling.position.maxScrollExtent > 0) {
        expect(scrolling.position.pixels, greaterThan(offset));
      }
      expect(tester.getRect(action), actionBounds);
      // Invoice money cards belong to Invoices, not Work.
      expect(find.byType(OperationalSummaryStrip), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Jobs Estimates and Invoices open separate workspaces', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    const workspaceKeys = {
      'quick-jobs': 'job',
      'quick-estimates': 'estimate',
      'quick-invoices': 'invoice',
      'quick-quotes': 'quote',
    };
    for (final actionKey in workspaceKeys.keys) {
      await _tapVisible(tester, find.byKey(ValueKey(actionKey)));
      expect(
        find.byKey(ValueKey('work-${workspaceKeys[actionKey]}-workspace')),
        findsOneWidget,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work calendar badges come from scoped Work records', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    expect(find.bySemanticsLabel(RegExp(r'5 work records\.')), findsOneWidget);

    await _tapVisible(tester, find.byKey(const ValueKey('quick-estimates')));
    expect(find.bySemanticsLabel(RegExp(r'2 estimates\.')), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('My Info and Saved Clients open real record screens', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('menu-company-profile')),
    );
    expect(find.text('Blue Ridge Service Company'), findsWidgets);
    expect(
      find.byKey(const ValueKey('edit-company-profile-button')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.byKey(const ValueKey('menu-customers')));
    expect(find.text('Saved clients'), findsWidgets);
    expect(find.text('Elena Garcia'), findsOneWidget);
    expect(find.text('Jordan Miller'), findsOneWidget);
    expect(find.text('Maya Thompson'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Payments calendar selects a day in the same ledger', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    await _tapVisible(tester, find.byKey(const ValueKey('quick-payments')));

    expect(find.byKey(const ValueKey('payments-screen')), findsOneWidget);
    expect(find.text('Payments received'), findsOneWidget);
    expect(find.text('Payments calendar'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -1000));
    await tester.pumpAndSettle();
    final now = DateTime.now();
    await tester.tap(
      find.byKey(
        ValueKey('work-calendar-day-${now.year}-${now.month}-${now.day}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('payments-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('payment-day-screen')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Admin defaults to Company Overview and can choose an employee', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(412, 915));
    await tester.tap(find.byKey(const ValueKey('work-view-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();

    expect(find.text('Company Overview'), findsWidgets);
    expect(find.byKey(const ValueKey('employee-status-strip')), findsOneWidget);
    expect(find.byKey(const ValueKey('employee-jordan')), findsOneWidget);
    expect(find.byKey(const ValueKey('work-scope-heading')), findsNothing);

    await _tapVisible(tester, find.byKey(const ValueKey('employee-jordan')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('work-context-selector')),
        matching: find.text('Jordan Lee'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('estimate rows do not repeat their status', (tester) async {
    await _pumpWork(tester, const Size(390, 844));
    await tester.tap(find.text('Estimates').first);
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Create a job when the company is ready'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Estimate list settings visibly change that workspace', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    await _tapVisible(tester, find.byKey(const ValueKey('quick-estimates')));
    expect(find.text('Approved'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('work-settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Estimates settings'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('show-work-record-status-details')),
    );
    await tester.tap(find.byKey(const ValueKey('save-work-record-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Create a job when the company is ready'), findsNothing);
    expect(find.text('Maya Thompson'), findsOneWidget);
    expect(find.text('Replace kitchen faucet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact Work header keeps View on the left', (tester) async {
    await _pumpWork(tester, const Size(390, 844));

    final header = tester.getRect(
      find.byKey(const ValueKey('work-view-selector')),
    );
    final screen = tester.getRect(
      find.byKey(const ValueKey('work-module-screen')),
    );

    expect(header.left, lessThan(screen.center.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work settings visibly update only Work home presentation', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Work Calendar'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('work-settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Choose what appears on Work home'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('show-work-daily-summaries')));
    await tester.tap(find.byKey(const ValueKey('save-work-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Plan'), findsNothing);
    expect(find.text('Jobs'), findsWidgets);
    expect(find.text('Work Calendar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'accepted estimate opens linked job creation with carried-over details',
    (tester) async {
      await _pumpWork(tester, const Size(390, 844), view: AppViewMode.admin);
      await _tapVisible(tester, find.byKey(const ValueKey('quick-estimates')));

      expect(
        find.byKey(const ValueKey('work-estimate-workspace')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('estimate-selected-date')),
        findsOneWidget,
      );
      final estimate = find.byKey(const ValueKey('estimate-row-est-1042'));
      await tester.tap(estimate);
      await tester.pumpAndSettle();

      final plan = find.byKey(const ValueKey('estimate-primary-job'));
      await _tapVisible(tester, plan);
      await tester.pumpAndSettle();
      expect(find.text('Create Job'), findsWidgets);
      await revealControl(tester, find.byKey(const ValueKey('save-job')));
      expect(find.text('Create Linked Job'), findsOneWidget);
      expect(find.text('Replace kitchen faucet'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('estimate opens a customer preview with retained line items', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844), view: AppViewMode.admin);
    await _tapVisible(tester, find.byKey(const ValueKey('quick-estimates')));
    final estimate = find.byKey(const ValueKey('estimate-row-est-1042'));
    await tester.tap(estimate);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('document-preview-est-1042')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Remove and install kitchen faucet'),
      findsOneWidget,
    );
    expect(find.textContaining('Single-handle kitchen faucet'), findsOneWidget);
    expect(find.textContaining('Braided faucet supply line'), findsOneWidget);
    expect(find.byKey(const ValueKey('estimate-actions-fab')), findsNothing);
    expect(find.text('Customer approval is current'), findsOneWidget);

    expect(find.byKey(const ValueKey('estimate-primary-job')), findsOneWidget);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('estimate-primary-send')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Email PDF to customer'), findsOneWidget);
    expect(find.text('Share from this device'), findsOneWidget);
    expect(find.text('Save PDF copy'), findsOneWidget);
    expect(find.text('Print customer copy'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estimate items expose real line entry and evidence links', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    await tester.tap(find.text('Add work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('work-action-createEstimate')));
    await tester.pumpAndSettle();
    final items = find.byKey(const ValueKey('estimate-items'));
    await tester.ensureVisible(items);
    await tester.pumpAndSettle();
    await tester.tap(items);
    await tester.pumpAndSettle();

    expect(find.text('Labor and materials'), findsWidgets);
    expect(find.byKey(const ValueKey('add-estimate-material')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('estimate-more-item-options')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('link-receipt-expense')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-estimate-material')));
    await tester.pumpAndSettle();
    expect(find.text('Material name'), findsOneWidget);
    final nameField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Material name'),
    );
    expect(nameField.textInputAction, TextInputAction.next);
    final description = find.widgetWithText(TextField, 'Description');
    expect(
      tester.widget<TextField>(description).decoration?.hintText,
      contains('½-inch elbow'),
    );
    await tester.tap(find.widgetWithText(TextField, 'Material name'));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: description,
              matching: find.byType(EditableText),
            ),
          )
          .focusNode
          .hasFocus,
      isTrue,
    );
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Unit of measure'), findsOneWidget);
    expect(find.text('Price per item'), findsOneWidget);
    expect(find.text('Your cost per item (optional)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estimate items import verified costs through review screens', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(390, 844));
    await tester.tap(find.text('Add work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('work-action-createEstimate')));
    await tester.pumpAndSettle();
    final items = find.byKey(const ValueKey('estimate-items'));
    await tester.ensureVisible(items);
    await tester.pumpAndSettle();
    await tester.tap(items);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('estimate-more-item-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add from materials'));
    await tester.pumpAndSettle();
    expect(find.text('Braided faucet supply line'), findsOneWidget);
    await tester.tap(find.text('Braided faucet supply line'));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(
      fields
          .firstWhere((field) => field.decoration?.labelText == 'Material name')
          .controller
          ?.text,
      'Braided faucet supply line',
    );
    expect(
      fields
          .firstWhere(
            (field) =>
                field.decoration?.labelText == 'Your cost per each (optional)',
          )
          .controller
          ?.text,
      '18.75',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Price per each'),
      '42.00',
    );
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Save item changes?'), findsOneWidget);
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Braided faucet supply line'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('estimate-more-item-options')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('link-receipt-expense')));
    await tester.pumpAndSettle();
    expect(find.text('Use a receipt item'), findsWidgets);
    expect(find.text('Central Supply'), findsOneWidget);
    expect(find.textContaining('Receipt reviewed'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('document and job forms remain bounded on a wide screen', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(1440, 900));
    await tester.tap(find.text('Add work'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('work-action-createEstimate')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('estimate-information'))).width,
      lessThanOrEqualTo(620),
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [390.0, 1440.0]) {
    testWidgets('Estimate information reflows labeled fields at $width LP', (
      tester,
    ) async {
      await _pumpWork(tester, Size(width, 900));
      await tester.tap(find.text('Add work'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('work-action-createEstimate')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('estimate-information')));
      await tester.pumpAndSettle();

      final number = tester.getTopLeft(find.text('Estimate number'));
      final purchaseOrder = tester.getTopLeft(
        find.text('Purchase order number (optional)'),
      );
      if (width < 600) {
        expect(purchaseOrder.dy, greaterThan(number.dy));
      } else {
        expect(purchaseOrder.dy, number.dy);
      }
      final workFinder = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.keyboardType == TextInputType.multiline,
      );
      final workField = tester.widget<TextField>(workFinder);
      expect(workField.maxLines, isNull);
      expect(workField.minLines, 4);
      final titleField = find.byKey(const ValueKey('estimate-title'));
      expect(
        tester.widget<TextField>(titleField).textInputAction,
        TextInputAction.next,
      );
      await tester.tap(titleField);
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const ValueKey('estimate-document-number')),
                matching: find.byType(EditableText),
              ),
            )
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Work preserves content at large accessibility text', (
    tester,
  ) async {
    await _pumpWork(tester, const Size(320, 844), textScale: 2);
    expect(find.text('Jobs'), findsOneWidget);
    expect(find.text('Scheduling'), findsOneWidget);
    expect(find.text('Estimates'), findsWidgets);
    expect(find.text('Invoices'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide Work rows separate identity from timing and narrow rows stack',
    (tester) async {
      final now = DateTime.now();
      final record = WorkRecord(
        id: 'wide-row',
        kind: WorkRecordKind.job,
        number: 'J-WIDE',
        title: 'Replace damaged kitchen fittings',
        client: 'Customer identity',
        detail: '',
        pricing: WorkPricingModel.flatRate,
        status: WorkRecordStatus.scheduled,
        scheduledStart: DateTime(now.year, now.month, now.day, 9),
        scheduledEnd: DateTime(now.year, now.month, now.day, 11),
      );
      for (final width in [390.0, 1440.0]) {
        await _pumpWork(tester, Size(width, 1000), records: [record]);
        final row = find.byKey(const ValueKey('work-plan-row-wide-row'));
        final title = find.descendant(
          of: row,
          matching: find.text(record.title),
        );
        final metadata = find.descendant(
          of: row,
          matching: find.textContaining('J-WIDE ·'),
        );
        if (width > 1000) {
          expect(
            tester.getTopLeft(metadata).dx,
            greaterThan(tester.getTopRight(title).dx),
          );
        } else {
          expect(
            tester.getTopLeft(metadata).dy,
            greaterThan(tester.getTopLeft(title).dy),
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  test('shared Work layouts keep lanes and shortcuts bounded', () {
    expect(AppLayoutEngine.workFor(390).columns, 1);
    expect(AppLayoutEngine.workFor(800).columns, 2);
    expect(AppLayoutEngine.workFor(1200).columns, 3);
    expect(
      AppLayoutEngine.workLandingFor(1800).laneWidth,
      lessThanOrEqualTo(760),
    );
    expect(AppLayoutEngine.workShortcutsFor(304).columns, 3);
    expect(AppLayoutEngine.workShortcutsFor(900).columns, 6);
    expect(AppLayoutEngine.workShortcutsFor(900).iconExtent, 62);
  });

  test('multi-day jobs appear on every scheduled date', () {
    final record = WorkRecord(
      id: 'multi-day',
      kind: WorkRecordKind.job,
      number: 'JOB-1',
      title: 'Three-day project',
      client: 'Customer',
      detail: 'Scheduled',
      pricing: WorkPricingModel.timeAndMaterials,
      scheduledStart: DateTime(2026, 8, 25),
      scheduledEnd: DateTime(2026, 8, 27),
      status: WorkRecordStatus.inProgress,
    );
    expect(record.occursOn(DateTime(2026, 8, 24)), isFalse);
    expect(record.occursOn(DateTime(2026, 8, 25)), isTrue);
    expect(record.occursOn(DateTime(2026, 8, 26)), isTrue);
    expect(record.occursOn(DateTime(2026, 8, 27)), isTrue);
    expect(record.occursOn(DateTime(2026, 8, 28)), isFalse);
  });
}
