import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/payment_detail_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/payments_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/seeded_work_fixture.dart';

void main() {
  testWidgets('a viewer can see Payments without a Record payment action', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final owner = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final viewer = (await tester.runAsync(
      () => WorkPersistenceSession.open(
        SqliteWorkRepository(database),
        WorkSessionPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: owner.permissions.actorEmployeeId,
          permissionRevision: 'payment-view-only',
          visibleCreatorIds: owner.permissions.visibleCreatorIds,
          editableKinds: const <WorkRecordKind>{},
          canManageOtherCreators: true,
        ),
      ),
    ))!;
    final store = PrototypeOperationsStore(workSession: viewer);
    final scope = OperationalScopeController();
    addTearDown(() async {
      store.dispose();
      owner.dispose();
      viewer.dispose();
      scope.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: OperationalScope(
          controller: scope,
          child: MaterialApp(
            theme: AppTheme.light,
            home: PaymentsScreen(initialDay: DateTime(2026, 9, 26)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('You do not have permission to view payments.'),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('record-payment-fab')), findsNothing);
    expect(find.byKey(const ValueKey('record-payment-inline')), findsNothing);
  });

  testWidgets('a restricted Work session cannot read company payments', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final database = (await tester.runAsync(harness.open))!;
    final owner = (await tester.runAsync(
      () => openSeededTestWorkSession(database),
    ))!;
    final payment = owner.financialEntries.firstWhere(
      (entry) => entry.kind == PrototypeFinancialKind.paymentReceived,
    );
    final restricted = (await tester.runAsync(
      () => WorkPersistenceSession.open(
        SqliteWorkRepository(database),
        WorkSessionPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: 'jordan',
          permissionRevision: 'restricted-1',
          visibleCreatorIds: const {'jordan'},
          editableKinds: const <WorkRecordKind>{},
        ),
      ),
    ))!;
    final store = PrototypeOperationsStore(workSession: restricted);
    addTearDown(() async {
      store.dispose();
      owner.dispose();
      restricted.dispose();
      await harness.dispose();
    });
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(theme: AppTheme.light, home: const PaymentsScreen()),
      ),
    );
    expect(
      find.text('You do not have permission to view payments.'),
      findsOneWidget,
    );
    expect(find.textContaining('Payment received'), findsNothing);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: PaymentDetailScreen(payment: payment),
        ),
      ),
    );
    expect(find.text('This payment is unavailable.'), findsOneWidget);
    expect(
      find.text('\$${(payment.amountCents / 100).toStringAsFixed(2)}'),
      findsNothing,
    );
  });
}
