import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/quote_detail_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final toInvoice in [false, true]) {
    testWidgets(
      'quote terms and approval then ${toInvoice ? 'invoice' : 'job'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 850));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        final quote = buildConfirmedEstimate(
          quoteInput(work.permissions.actorEmployeeId),
          now: DateTime.now(),
        );
        expect(await tester.runAsync(() => work.create(quote)), isTrue);
        final store = PrototypeOperationsStore(workSession: work);
        final scope = OperationalScopeController();
        addTearDown(() async {
          store.dispose();
          scope.dispose();
          work.dispose();
          await finishNativeOperation(tester, harness.dispose);
        });
        Future<void> tap(Finder finder) async {
          if (finder.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              finder,
              250,
              scrollable: find.byType(Scrollable).first,
            );
          }
          await tester.ensureVisible(finder);
          await tester.pumpAndSettle();
          await tester.tap(finder);
          await tester.pump(const Duration(milliseconds: 300));
        }

        await tester.pumpWidget(
          PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: QuoteDetailScreen(recordId: quote.id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('quote-delivery-action')));
        await waitForNativeSave(
          tester,
          () => find.text('Send quote').evaluate().isNotEmpty,
        );
        expect(find.text('Send estimate'), findsNothing);
        await tap(find.byTooltip('Back to Work'));
        await waitForNativeSave(
          tester,
          () =>
              find.byKey(const ValueKey('quote-review')).evaluate().isNotEmpty,
        );
        await tester.pumpAndSettle();
        await tap(find.byKey(const ValueKey('quote-customer-approval')));
        await waitForNativeSave(
          tester,
          () =>
              find
                  .byKey(const ValueKey('approval-terms-accepted'))
                  .evaluate()
                  .isNotEmpty &&
              tester
                      .widget<CheckboxListTile>(
                        find.byKey(const ValueKey('approval-terms-accepted')),
                      )
                      .onChanged !=
                  null,
        );
        expect(find.text('Quote total: \$245.00'), findsOneWidget);
        expect(
          find.text('Fixed price for the work described.'),
          findsOneWidget,
        );
        await tap(find.byKey(const ValueKey('approval-terms-accepted')));
        await tap(find.byType(DropdownButtonFormField<CustomerApprovalMethod>));
        await tap(find.text(CustomerApprovalMethod.verbal.label).last);
        await tap(find.text('Record approval'));
        await waitForNativeSave(
          tester,
          () => work.records.single.hasCurrentCustomerApproval,
        );
        expect(work.records.single.customerSignature, isNull);
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('quote-add-to-jobs'))
              .evaluate()
              .isNotEmpty,
        );
        await tap(find.text('Approved versions'));
        await waitForNativeSave(
          tester,
          () => find
              .byKey(const ValueKey('approved-version-1'))
              .evaluate()
              .isNotEmpty,
        );
        await tap(find.byKey(const ValueKey('approved-version-1')));
        await tester.pumpAndSettle();
        expect(
          find.text('Fixed price for the work described.'),
          findsOneWidget,
        );
        expect(
          find.text('Approval recorded without a signature'),
          findsOneWidget,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        if (toInvoice) {
          await tap(
            find.byKey(ValueKey('proposal-create-invoice-${quote.id}')),
          );
          await waitForNativeSave(
            tester,
            () => work.records.any((r) => r.kind == WorkRecordKind.invoice),
          );
          final invoice = work.records.singleWhere(
            (r) => r.kind == WorkRecordKind.invoice,
          );
          await waitForNativeSave(
            tester,
            () => find
                .byKey(ValueKey('invoice-detail-${invoice.id}'))
                .evaluate()
                .isNotEmpty,
          );
          expect(invoice.status, WorkRecordStatus.draft);
          expect(invoice.total, quote.total);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('proposal-open-invoice-${quote.id}')),
            findsOneWidget,
          );
          expect(
            find.byKey(ValueKey('proposal-create-invoice-${quote.id}')),
            findsNothing,
          );
        } else {
          await tap(find.byKey(const ValueKey('quote-add-to-jobs')));
          await tester.pumpAndSettle();
          await waitForNativeSave(
            tester,
            () => find.text('Approved quote Quote 1').evaluate().isNotEmpty,
          );
          expect(find.text('Approved quote Quote 1'), findsOneWidget);
          expect(find.text('Replace kitchen tap'), findsWidgets);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
