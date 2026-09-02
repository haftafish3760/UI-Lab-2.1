import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/screens/work/job_workspace_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('Job details never invent missing customer or scope data', (
    tester,
  ) async {
    await _setPhoneSize(tester);
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    final record = _jobRecord(
      id: 'job-no-profile',
      client: 'Customer without a saved profile',
      title: 'Water heater safety inspection',
      detail: '',
      jobNotes: '',
    );

    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: JobWorkspaceScreen(workRecord: record),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Job description not recorded.'), findsOneWidget);
    expect(find.text('No job notes recorded.'), findsOneWidget);
    expect(find.text('Not recorded'), findsNWidgets(2));
    expect(find.text('Direct job'), findsOneWidget);
    expect(find.text('Water-heater diagnostic inspection'), findsNothing);
    expect(find.text('EST-1847'), findsNothing);
    expect(find.text('customer@example.com'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('linked Expense remains attached after reopening its Job', (
    tester,
  ) async {
    await _setPhoneSize(tester);
    final scope = OperationalScopeController();
    final store = PrototypeOperationsStore(
      workRecords: [
        _jobRecord(
          id: 'job-link-source',
          client: 'Maya Thompson',
          title: 'Replace kitchen faucet',
          detail: 'Replace the approved kitchen faucet.',
          jobNotes: 'Use the side driveway.',
        ),
      ],
    );
    addTearDown(scope.dispose);
    addTearDown(store.dispose);

    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: _JobOwnershipHarness(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open job'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('job-link-expense')));
    await tester.tap(find.byKey(const ValueKey('job-link-expense')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('QuickFuel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QuickFuel'));
    await tester.pumpAndSettle();

    expect(store.workRecords.single.linkedExpenseIds, contains('EXP-1047'));
    expect(find.textContaining('QuickFuel ·'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open job'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.textContaining('QuickFuel ·'));
    expect(find.textContaining('QuickFuel ·'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setPhoneSize(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

WorkRecord _jobRecord({
  required String id,
  required String client,
  required String title,
  required String detail,
  required String jobNotes,
}) => WorkRecord(
  id: id,
  kind: WorkRecordKind.job,
  number: id.toUpperCase(),
  title: title,
  client: client,
  detail: detail,
  pricing: WorkPricingModel.flatRate,
  serviceLocation: '212 Oak Street\nRoanoke, VA 24016',
  jobNotes: jobNotes,
  scheduledStart: DateTime(2026, 9, 1, 10, 30),
  status: WorkRecordStatus.scheduled,
);

class _JobOwnershipHarness extends StatelessWidget {
  const _JobOwnershipHarness({required this.store});

  final PrototypeOperationsStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => JobWorkspaceScreen(
              workRecord: store.workRecords.single,
              onWorkRecordUpdated: store.updateWorkRecord,
            ),
          ),
        ),
        child: const Text('Open job'),
      ),
    ),
  );
}
