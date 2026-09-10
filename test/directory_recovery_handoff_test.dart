import 'package:ui_lab_2_1/src/data/work/directory_draft_recovery.dart';
import 'package:ui_lab_2_1/src/shell/directory_recovery_routes.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_handoff.dart';
import 'package:ui_lab_2_1/src/data/work/directory_persistence_session.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/work/company_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/employee_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/vehicle_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/directory_draft_workflows.dart';
import 'package:ui_lab_2_1/src/data/work/customer_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/directory_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'directory_profile_draft_compatibility_test.dart' show legacyInput;
import 'customer_draft_workflow_test.dart' show inputFor;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final kind in ['company', 'customer', 'employee', 'vehicle']) {
    testWidgets(
      'selected $kind editor retains changes without confirming directory',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final directory = (await tester.runAsync(
          () async => openUiLabDirectory(await harness.open()),
        ))!;
        late DraftAutosaveSession draft;
        late ResumedDirectoryDraft selected;
        await tester.runAsync(() async {
          switch (kind) {
            case 'company':
              final workflow = await directory.openCompanyDraft();
              workflow.updateInput(
                CompanyDraftInput.fromPayload(legacyInput(kind)),
              );
              draft = workflow.session;
              selected = ResumedCompanyDraft(workflow);
            case 'customer':
              final workflow = await directory.openCustomerDraft();
              workflow.updateInput(
                inputFor(existing: false, name: 'Partial customer'),
              );
              expect(
                () =>
                    directory.validateCustomerHandoff(workflow, 'wrong-record'),
                throwsStateError,
              );
              draft = workflow.session;
              selected = ResumedCustomerDraft(workflow);
            case 'employee':
              final workflow = await directory.openEmployeeDraft();
              workflow.updateInput(
                EmployeeDraftInput.fromPayload({
                  ...legacyInput(kind),
                  'baseRevision': 0,
                }),
              );
              expect(
                () =>
                    directory.validateEmployeeHandoff(workflow, 'wrong-record'),
                throwsStateError,
              );
              draft = workflow.session;
              selected = ResumedEmployeeDraft(workflow);
            case 'vehicle':
              final workflow = await directory.openVehicleDraft();
              workflow.updateInput(
                VehicleDraftInput.fromPayload({
                  ...legacyInput(kind),
                  'baseRevision': 0,
                  'odometerRevision': 0,
                }),
              );
              expect(
                () =>
                    directory.validateVehicleHandoff(workflow, 'wrong-record'),
                throwsStateError,
              );
              draft = workflow.session;
              selected = ResumedVehicleDraft(workflow);
          }
          await draft.flush();
        });
        final counts = (
          directory.companyRevision,
          directory.customers.length,
          directory.employees.length,
          directory.vehicles.length,
        );
        final store = PrototypeOperationsStore(directorySession: directory);
        final scope = OperationalScopeController();
        Future<void>? route;
        try {
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
                        onPressed: () => route = openDirectoryRecovery(
                          context,
                          selected,
                          selectedDay: DateTime(2030),
                        ),
                        child: const Text('Resume profile'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Resume profile'));
          await tester.pumpAndSettle();
          final label = switch (kind) {
            'company' => 'Company name',
            'employee' => 'Employee name',
            'vehicle' => 'Vehicle name or unit number',
            _ => '',
          };
          final field = kind == 'customer'
              ? find.byKey(const ValueKey('client-name-field'))
              : find.byWidgetPredicate(
                  (w) => w is TextField && w.decoration?.labelText == label,
                );
          await waitForNativeSave(tester, () => field.evaluate().isNotEmpty);
          expect(draft.input['name'], 'Partial $kind');
          await tester.enterText(field, 'Continued $kind');
          await finishNativeOperation(tester, draft.flush);
          if (kind == 'company' || kind == 'customer') {
            await tester.ensureVisible(find.byTooltip('Back to Work'));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('Back to Work'));
          } else {
            await tester.pageBack();
          }
          await finishNativeOperation(tester, () => route!);
          expect(find.text('Resume profile'), findsOneWidget);
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, draft.close);
          final saved = await tester.runAsync(
            () => directory.drafts.find(
              organizationId: draft.organizationId,
              domain: draft.domain,
              draftId: draft.draftId,
              ownerId: draft.ownerId,
            ),
          );
          expect(jsonDecode(saved!.payload)['name'], 'Continued $kind');
          expect((
            directory.companyRevision,
            directory.customers.length,
            directory.employees.length,
            directory.vehicles.length,
          ), counts);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, draft.close);
          store.dispose();
          scope.dispose();
          directory.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
