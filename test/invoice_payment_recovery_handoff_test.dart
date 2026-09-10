import 'package:ui_lab_2_1/src/screens/work/invoice_payment_recovery_route.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_payment_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_payment_entry_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final mismatch in [false, true]) {
    testWidgets(
      'selected invoice payment mismatch=$mismatch retains unposted input',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final work = (await tester.runAsync(
          () async => openUiLabWorkSession(await harness.open()),
        ))!;
        final invoice = work.records.firstWhere(
          (r) =>
              r.kind == WorkRecordKind.invoice &&
              r.status == WorkRecordStatus.due,
        );
        final workflow = (await tester.runAsync(
          () => work.openInvoicePaymentDraft(
            invoiceId: invoice.id,
            initialDay: DateTime(2026, 9, 10),
          ),
        ))!;
        await tester.runAsync(() async {
          workflow.updateInput(
            workflow.input.withValues(
              amount: '12.',
              note: 'unfinished',
              method: 'Check',
              receivedOn: DateTime(2026, 9, 10),
            ),
          );
          await workflow.session.flush();
        });
        final ledgerCount = work.financialEntries.length;
        final balance = workflow.balanceCents;
        final store = PrototypeOperationsStore(workSession: work);
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
                  home: !mismatch
                      ? Builder(
                          builder: (context) => Scaffold(
                            body: TextButton(
                              onPressed: () => route =
                                  openInvoicePaymentRecovery(context, workflow),
                              child: const Text('Resume payment'),
                            ),
                          ),
                        )
                      : InvoicePaymentEntryScreen(
                          invoice: mismatch
                              ? work.records.firstWhere(
                                  (record) => record.id != invoice.id,
                                )
                              : invoice,
                          balanceCents: balance,
                          initialDay: DateTime(2030),
                          recoveredWorkflow: workflow,
                        ),
                ),
              ),
            ),
          );
          if (!mismatch) await tester.tap(find.text('Resume payment'));
          await tester.pumpAndSettle();
          if (mismatch) {
            await waitForNativeSave(
              tester,
              () => find
                  .text('The selected payment is unavailable in this workflow.')
                  .evaluate()
                  .isNotEmpty,
            );
          } else {
            final amount = find.byKey(const ValueKey('invoice-payment-amount'));
            expect(tester.widget<TextField>(amount).controller!.text, '12.');
            await tester.enterText(amount, '34.');
            await finishNativeOperation(tester, workflow.session.flush);
          }
          if (!mismatch) {
            await tester.ensureVisible(find.byTooltip('Back to Work'));
            await tester.pumpAndSettle();
            await tester.tap(find.byTooltip('Back to Work'));
            await finishNativeOperation(tester, () => route!);
            expect(find.text('Resume payment'), findsOneWidget);
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          final saved = await tester.runAsync(
            () => work.drafts.find(
              organizationId: workflow.session.organizationId,
              domain: workflow.session.domain,
              draftId: workflow.session.draftId,
              ownerId: workflow.session.ownerId,
            ),
          );
          expect(
            jsonDecode(saved!.payload)['amount'],
            mismatch ? '12.' : '34.',
          );
          expect(work.financialEntries.length, ledgerCount);
          expect(workflow.balanceCents, balance);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, workflow.session.close);
          store.dispose();
          work.dispose();
          scope.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
