import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/work_screen.dart';
import 'package:ui_lab_2_1/src/shared/app_view_mode.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

Future<void> _pumpWorkHome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final scope = OperationalScopeController(view: AppViewMode.admin);
  final store = PrototypeOperationsStore();
  addTearDown(scope.dispose);
  addTearDown(store.dispose);
  await tester.pumpWidget(
    PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.noScaling),
          child: MaterialApp(theme: AppTheme.light, home: const WorkScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Work home keeps date above destinations and scoped records', (
    tester,
  ) async {
    await _pumpWorkHome(tester, const Size(390, 844));

    final date = find.byKey(const ValueKey('work-date-heading'));
    final attention = find.byKey(const ValueKey('work-attention-section'));
    final employees = find.byKey(const ValueKey('employee-status-strip'));
    final firstAction = find.byKey(const ValueKey('quick-jobs'));

    expect(
      tester.getTopLeft(date).dy,
      lessThan(tester.getTopLeft(attention).dy),
    );
    expect(
      tester.getTopLeft(attention).dy,
      lessThan(tester.getTopLeft(employees).dy),
    );
    expect(
      tester.getTopLeft(date).dy,
      lessThan(tester.getTopLeft(firstAction).dy),
    );
    expect(
      find.text(
        'Select an employee to carry that person’s context across the app.',
      ),
      findsNothing,
    );
    expect(
      find.text(
        'Jobs, estimates, invoices, customers, and payments for this date.',
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work home separates the daily plan, entries, and drafts', (
    tester,
  ) async {
    await _pumpWorkHome(tester, const Size(390, 844));

    const rowKeys = [
      'work-plan-row-job-1038',
      'work-entry-row-est-1042',
      'work-entry-row-inv-2088',
    ];
    for (final key in rowKeys) {
      final row = find.byKey(ValueKey(key));
      expect(row, findsOneWidget);
      expect(
        tester.getSize(row).height,
        lessThanOrEqualTo(130),
        reason: '$key must remain a readable phone record',
      );
    }
    expect(find.byKey(const ValueKey('open-work-drafts')), findsNothing);
    expect(find.byKey(const ValueKey('work-entry-row-est-1040')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work home rows open the exact job estimate and invoice', (
    tester,
  ) async {
    await _pumpWorkHome(tester, const Size(390, 844));

    final attention = find.byKey(const ValueKey('work-attention-est-1039'));
    await tester.ensureVisible(attention);
    await tester.pumpAndSettle();
    await tester.tap(attention);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('estimate-detail-est-1039')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final job = find.byKey(const ValueKey('work-plan-row-job-1038'));
    await tester.ensureVisible(job);
    await tester.pumpAndSettle();
    await tester.tap(job);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('job-workspace-job-1038')),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final invoice = find.byKey(const ValueKey('work-entry-row-inv-2088'));
    await tester.ensureVisible(invoice);
    await tester.pumpAndSettle();
    await tester.tap(invoice);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('invoice-detail-inv-2088')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('invoice-primary-preview')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Show all attention opens a real list of exact records', (
    tester,
  ) async {
    await _pumpWorkHome(tester, const Size(390, 844));

    final section = find.byKey(const ValueKey('work-attention-section'));
    final showAll = find.descendant(
      of: section,
      matching: find.text('Show all 1'),
    );
    await tester.tap(showAll);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('work-attention-list')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('work-attention-list-est-1039')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Add work opens a full-screen labeled action directory', (
    tester,
  ) async {
    await _pumpWorkHome(tester, const Size(390, 844));

    await tester.tap(find.text('Add work'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('work-actions-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('work-action-createJob')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('work-action-createEstimate')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('work-action-createInvoice')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('work-action-recordPayment')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('work-action-addContact')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Work groups records beside a bounded calendar on desktop', (
    tester,
  ) async {
    await _pumpWorkHome(tester, const Size(1200, 900));

    final attention = find.byKey(const ValueKey('work-attention-section'));
    final plan = find.byKey(const ValueKey('work-plan-section'));
    final entries = find.byKey(const ValueKey('work-entries-section'));
    expect(find.byKey(const ValueKey('work-1-column-queues')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('work-2-column-attention')),
      findsOneWidget,
    );
    expect(tester.getSize(attention).width, tester.getSize(plan).width);
    expect(tester.getTopLeft(attention).dx, tester.getTopLeft(plan).dx);
    final jobsX = tester.getTopLeft(plan).dx;
    expect(jobsX, tester.getTopLeft(entries).dx);
    expect(
      tester.getTopLeft(find.text('Work Calendar')).dx,
      greaterThan(jobsX),
    );
    expect(find.byKey(const ValueKey('work-actions-inline')), findsOneWidget);
    expect(find.byKey(const ValueKey('work-actions-fab')), findsNothing);
    expect(find.byKey(const ValueKey('quick-jobs')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-estimates')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-invoices')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
