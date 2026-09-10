import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/job_materials_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_material_permissions.dart';
import 'package:ui_lab_2_1/src/data/work/work_items_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/job_materials_recovery_route.dart';
import 'package:ui_lab_2_1/src/screens/work/work_items_editor.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';
import 'work_draft_controller_compatibility_test.dart'
    show legacyItemsWorkspace;

void main() {
  test(
    'material handoff rejects replaced owner and changed capabilities',
    () async {
      final harness = await DatabaseHarness.create();
      addTearDown(harness.dispose);
      final db = await harness.open();
      final owner = await openUiLabWorkSession(db);
      final replacement = await openUiLabWorkSession(db);
      addTearDown(owner.dispose);
      addTearDown(replacement.dispose);
      final job = owner.records.firstWhere(
        (r) => r.kind == WorkRecordKind.job && owner.permissions.canEdit(r),
      );
      const allowed = JobWorkspacePermissions.development();
      const limited = JobWorkspacePermissions(
        canEditJob: true,
        canViewEstimate: true,
        canAddMaterials: true,
        canAttachReceipts: false,
        canChangeStatus: false,
        canContactCustomer: false,
      );
      final workflow = await owner.openJobMaterialsDraft(
        job.id,
        materialPermissions: allowed,
      );
      try {
        owner.validateJobMaterialsHandoff(
          workflow,
          job.id,
          materialPermissions: allowed,
        );
        expect(
          () => replacement.validateJobMaterialsHandoff(
            workflow,
            job.id,
            materialPermissions: allowed,
          ),
          throwsStateError,
        );
        expect(
          () => owner.validateJobMaterialsHandoff(
            workflow,
            job.id,
            materialPermissions: limited,
          ),
          throwsStateError,
        );
        await workflow.session.flush();
        expect(
          await owner.drafts.find(
            organizationId: workflow.session.organizationId,
            ownerId: workflow.session.ownerId,
            domain: workflow.session.domain,
            draftId: workflow.session.draftId,
          ),
          isNotNull,
        );
      } finally {
        await workflow.session.close();
      }
    },
  );

  testWidgets(
    'material recovery preserves nested input and stock through Back',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final work = (await tester.runAsync(
        () async => openUiLabWorkSession(await harness.open()),
      ))!;
      final job = work.records.firstWhere(
        (r) => r.kind == WorkRecordKind.job && work.permissions.canEdit(r),
      );
      const permissions = JobWorkspacePermissions.development();
      final workflow = (await tester.runAsync(
        () => work.openJobMaterialsDraft(
          job.id,
          materialPermissions: permissions,
        ),
      ))!;
      await tester.runAsync(() async {
        workflow.updateWorkspace(
          WorkItemsDraftInput.fromPayload(legacyItemsWorkspace()),
        );
        await workflow.session.flush();
      });
      final revision = work.storageRevisionFor(job.id);
      final store = PrototypeOperationsStore(workSession: work);
      final stock = {for (final r in store.inventoryStock) r.id: r.quantity};
      final scope = OperationalScopeController();
      Future<void>? route;
      try {
        expect(
          () => work.validateJobMaterialsHandoff(
            workflow,
            'wrong-job',
            materialPermissions: permissions,
          ),
          throwsStateError,
        );
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
                      onPressed: () => route = openJobMaterialsRecovery(
                        context,
                        workflow,
                        permissions: permissions,
                      ),
                      child: const Text('Resume materials'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Resume materials'));
        await waitForNativeSave(
          tester,
          () => find.byType(WorkItemsEditor).evaluate().isNotEmpty,
        );
        expect(
          tester
              .widget<WorkItemsEditor>(find.byType(WorkItemsEditor))
              .recoveryInput!
              .pendingItem!
              .quantity,
          '1.',
        );
        final back = find.byTooltip('Back to Work');
        await tester.ensureVisible(back);
        await tester.tap(back);
        await waitForNativeSave(
          tester,
          () => find.byType(WorkItemsEditor).evaluate().isEmpty,
        );
        await tester.ensureVisible(find.byTooltip('Back to Work'));
        await tester.tap(find.byTooltip('Back to Work'));
        await finishNativeOperation(tester, () => route!);
        expect(find.text('Resume materials'), findsOneWidget);
        final reopened = (await tester.runAsync(
          () => work.openJobMaterialsDraft(
            job.id,
            materialPermissions: permissions,
          ),
        ))!;
        expect(reopened.input.workspace.pendingItem!.quantity, '1.');
        expect(work.storageRevisionFor(job.id), revision);
        expect({for (final r in store.inventoryStock) r.id: r.quantity}, stock);
        await finishNativeOperation(tester, reopened.session.close);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await finishNativeOperation(tester, workflow.session.close);
        store.dispose();
        scope.dispose();
        work.dispose();
        await tester.runAsync(harness.dispose);
      }
    },
  );
}
