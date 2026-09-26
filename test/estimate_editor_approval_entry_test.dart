import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_editor_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_approval_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_signature_screen.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final signInPerson in [false, true]) {
    testWidgets(
      'approval cancellation and saving return to the same editable estimate signing=$signInPerson',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final database = (await tester.runAsync(harness.open))!;
        final work = (await tester.runAsync(
          () => openUiLabWorkSession(database),
        ))!;
        final store = PrototypeOperationsStore(workSession: work);
        final scope = OperationalScopeController();
        addTearDown(() async {
          store.dispose();
          work.dispose();
          scope.dispose();
          await harness.dispose();
        });
        const estimate = WorkRecord(
          id: 'approval-entry-test',
          kind: WorkRecordKind.estimate,
          number: 'EST-ENTRY',
          title: 'Build test shelf',
          client: 'Test customer',
          detail: 'Build shelf',
          createdByEmployeeId: 'alex',
          pricing: WorkPricingModel.flatRate,
          total: 100,
          items: [
            WorkLineItem(
              id: 'labor',
              type: WorkLineItemType.labor,
              name: 'Build shelf',
              quantity: 1,
              unit: 'job',
              customerPrice: 100,
            ),
          ],
        );
        expect(await tester.runAsync(() => work.create(estimate)), isTrue);
        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: EstimateEditorScreen(
                  initialDay: DateTime(2026, 9, 24),
                  initialRecord: estimate,
                ),
              ),
            ),
          ),
        );
        final approval = find.byKey(
          const ValueKey('estimate-customer-approval'),
        );
        await waitForNativeSave(
          tester,
          () =>
              approval.evaluate().isNotEmpty &&
              tester.widget<DocumentFormSection>(approval).onTap != null,
        );
        expect(find.byKey(const ValueKey('estimate-close')), findsOneWidget);
        expect(find.text('Not approved — Add approval'), findsOneWidget);
        await tester.ensureVisible(approval);
        await tester.pumpAndSettle();
        await tester.tap(approval);
        await waitForNativeSave(
          tester,
          () => find.byType(EstimateApprovalScreen).evaluate().isNotEmpty,
        );
        await tester.pageBack();
        await waitForNativeSave(
          tester,
          () =>
              find.byType(EstimateApprovalScreen).evaluate().isEmpty &&
              tester.widget<DocumentFormSection>(approval).onTap != null,
        );
        expect(find.byType(EstimateEditorScreen), findsOneWidget);
        expect(find.text('Kitchen faucet replacement'), findsNothing);
        expect(find.text('Build test shelf'), findsOneWidget);
        expect(
          work.records
              .firstWhere((r) => r.id == estimate.id)
              .hasCurrentCustomerApproval,
          isFalse,
        );
        await tester.ensureVisible(approval);
        await tester.pumpAndSettle();
        await tester.tap(approval);
        await waitForNativeSave(
          tester,
          () => find.byType(EstimateApprovalScreen).evaluate().isNotEmpty,
        );
        if (signInPerson) {
          await tester.tap(
            find.byKey(const ValueKey('approval-sign-in-person')),
          );
          await waitForNativeSave(
            tester,
            () => find
                .byKey(const ValueKey('signature-customer-name'))
                .evaluate()
                .isNotEmpty,
          );
          await tester.ensureVisible(find.byKey(const ValueKey('tap-to-sign')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('tap-to-sign')));
          await tester.pumpAndSettle();
          final pad = find.byKey(const ValueKey('estimate-signature-pad'));
          await tester.ensureVisible(pad);
          await tester.pumpAndSettle();
          await tester.drag(pad, const Offset(80, 30));
          await tester.ensureVisible(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(CheckboxListTile));
          await tester.pumpAndSettle();
          final save = find.byKey(const ValueKey('save-customer-signature'));
          await tester.ensureVisible(save);
          await tester.pumpAndSettle();
          await tester.tap(save);
        } else {
          await tester.tap(
            find.byType(DropdownButtonFormField<CustomerApprovalMethod>),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text(CustomerApprovalMethod.verbal.label).last);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Record approval'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Record approval'));
        }
        await waitForNativeSave(
          tester,
          () => work.records
              .firstWhere((r) => r.id == estimate.id)
              .hasCurrentCustomerApproval,
        );
        await waitForNativeSave(
          tester,
          () =>
              find.byType(EstimateApprovalScreen).evaluate().isEmpty &&
              tester.widget<DocumentFormSection>(approval).onTap != null,
        );
        expect(find.byType(EstimateEditorScreen), findsOneWidget);
        expect(find.text('Approved — View approval'), findsOneWidget);
        // The editor must own a new usable recovery session after approval.
        await tester.ensureVisible(
          find.byKey(const ValueKey('estimate-information')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('estimate-information')));
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
        final reopened = (await tester.runAsync(
          () => openUiLabWorkSession(database),
        ))!;
        final saved = reopened.records.firstWhere((r) => r.id == estimate.id);
        if (signInPerson) {
          expect(saved.customerSignature!.ink!.hasInk, isTrue);
          expect(saved.customerSignature!.signedRevision, saved.revision);
          expect(find.byType(EstimateSignatureScreen), findsNothing);
        } else {
          expect(
            saved.customerApprovals.single.method,
            CustomerApprovalMethod.verbal,
          );
          expect(saved.customerApprovals.single.revision, saved.revision);
        }
        reopened.dispose();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }
}
