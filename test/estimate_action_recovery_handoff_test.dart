import 'package:ui_lab_2_1/src/data/work/estimate_action_draft_recovery.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_action_recovery_routes.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_signature_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_delivery_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_signature_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_delivery_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final signature in [false, true]) {
    for (final mismatch in [false, true]) {
      testWidgets(
        'estimate action signature=$signature mismatch=$mismatch retains unconfirmed input',
        (tester) async {
          final harness = (await tester.runAsync(DatabaseHarness.create))!;
          final work = (await tester.runAsync(
            () async => openUiLabWorkSession(await harness.open()),
          ))!;
          final base = work.records.singleWhere((r) => r.id == 'est-1040');
          final signing = signature
              ? (await tester.runAsync(
                  () => work.openEstimateSignatureDraft(base.id),
                ))!
              : null;
          final delivery = signature
              ? null
              : (await tester.runAsync(
                  () => work.openEstimateDeliveryDraft(base.id, customers: []),
                ))!;
          final draft = signing?.session ?? delivery!.session;
          await tester.runAsync(() async {
            signing?.updateName('Unfinished name');
            delivery?.updateRecipient('unfinished@');
            await draft.flush();
          });
          final revision = work.storageRevisionFor(base.id);
          final target = mismatch
              ? work.records.firstWhere((r) => r.id != base.id)
              : base;
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
                                onPressed: () =>
                                    route = openEstimateActionRecovery(
                                      context,
                                      signature
                                          ? ResumedEstimateSignature(signing!)
                                          : ResumedEstimateDelivery(delivery!),
                                      reviewPermissions:
                                          const EstimatePermissions.development(),
                                    ),
                                child: const Text('Resume estimate action'),
                              ),
                            ),
                          )
                        : signature
                        ? EstimateSignatureScreen(
                            record: target,
                            recoveredWorkflow: signing,
                          )
                        : EstimateDeliveryScreen(
                            record: target,
                            recoveredWorkflow: delivery,
                          ),
                  ),
                ),
              ),
            );
            if (!mismatch) {
              await tester.tap(find.text('Resume estimate action'));
            }
            await tester.pumpAndSettle();
            if (mismatch) {
              await waitForNativeSave(
                tester,
                () => find
                    .textContaining('could not be opened')
                    .evaluate()
                    .isNotEmpty,
              );
            } else {
              final field = find.byKey(
                ValueKey(
                  signature
                      ? 'signature-customer-name'
                      : 'estimate-delivery-recipient',
                ),
              );
              expect(
                tester.widget<TextField>(field).controller!.text,
                signature ? 'Unfinished name' : 'unfinished@',
              );
              await tester.enterText(
                field,
                signature ? 'Continued name' : 'continued@',
              );
              await finishNativeOperation(tester, draft.flush);
            }
            if (!mismatch) {
              await tester.ensureVisible(find.byTooltip('Back to Work'));
              await tester.pumpAndSettle();
              await tester.tap(find.byTooltip('Back to Work'));
              await finishNativeOperation(tester, () => route!);
              expect(find.text('Resume estimate action'), findsOneWidget);
            }
            await tester.pumpWidget(const SizedBox.shrink());
            await finishNativeOperation(tester, draft.close);
            final saved = await tester.runAsync(
              () => work.drafts.find(
                organizationId: draft.organizationId,
                domain: draft.domain,
                draftId: draft.draftId,
                ownerId: draft.ownerId,
              ),
            );
            final raw = jsonDecode(saved!.payload);
            expect(
              signature ? raw['name'] : raw['recipients']['email'],
              mismatch
                  ? (signature ? 'Unfinished name' : 'unfinished@')
                  : (signature ? 'Continued name' : 'continued@'),
            );
            expect(work.storageRevisionFor(base.id), revision);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await finishNativeOperation(tester, draft.close);
            store.dispose();
            scope.dispose();
            work.dispose();
            await tester.runAsync(harness.dispose);
          }
        },
      );
    }
  }
}
