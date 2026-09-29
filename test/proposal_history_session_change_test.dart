import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/proposal_approval_history_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('changing session removes previously loaded approval history', (
    tester,
  ) async {
    final harness = (await tester.runAsync(DatabaseHarness.create))!;
    final db = (await tester.runAsync(harness.open))!;
    final owner = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
    final quote = buildConfirmedEstimate(
      quoteInput(owner.permissions.actorEmployeeId),
      now: DateTime.now(),
    );
    expect(await tester.runAsync(() => owner.create(quote)), isTrue);
    expect(
      await tester.runAsync(
        () => owner.update(
          quote.recordCustomerApproval(
            WorkCustomerApproval(
              method: CustomerApprovalMethod.verbal,
              customerName: quote.client,
              recordedByEmployeeId: owner.permissions.actorEmployeeId,
              recordedOn: DateTime.now().toUtc(),
              revision: quote.revision,
            ),
          ),
        ),
      ),
      isTrue,
    );
    final denied = (await tester.runAsync(
      () => WorkPersistenceSession.open(
        owner.repository,
        WorkSessionPermissions(
          organizationId: owner.permissions.organizationId,
          actorEmployeeId: 'other',
          permissionRevision: 'restricted',
          visibleCreatorIds: {'other'},
          editableKinds: {},
        ),
      ),
    ))!;
    final first = PrototypeOperationsStore(workSession: owner);
    final second = PrototypeOperationsStore(workSession: denied);
    final scope = OperationalScopeController();
    addTearDown(() async {
      first.dispose();
      second.dispose();
      scope.dispose();
      owner.dispose();
      denied.dispose();
      await finishNativeOperation(tester, harness.dispose);
    });
    Widget app(PrototypeOperationsStore store) => PrototypeOperationsScope(
      store: store,
      child: OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ProposalApprovalHistoryScreen(recordId: quote.id),
        ),
      ),
    );
    await tester.pumpWidget(app(first));
    await waitForNativeSave(
      tester,
      () => find
          .byKey(const ValueKey('approved-version-1'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpWidget(app(second));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('approved-version-1')), findsNothing);
    expect(find.text('This document is unavailable.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
