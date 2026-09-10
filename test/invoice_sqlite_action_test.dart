import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_actions_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/invoice_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';

void main() {
  for (final failWrite in [false, true]) {
    testWidgets(
      'invoice action awaits SQLite ${failWrite ? 'failure' : 'commit'}',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final database = (await tester.runAsync(harness.open))!;
        final session = (await tester.runAsync(
          () => openUiLabWorkSession(database),
        ))!;
        final store = PrototypeOperationsStore(workSession: session);
        final scope = OperationalScopeController();
        const invoice = WorkRecord(
          id: 'sqlite-action-invoice',
          kind: WorkRecordKind.invoice,
          number: 'INV-SQLITE-ACTION',
          title: 'Repair',
          client: 'Customer',
          detail: 'Repair completed',
          pricing: WorkPricingModel.flatRate,
          total: 125,
        );
        expect(
          await tester.runAsync(() => store.addWorkRecord(invoice)),
          isTrue,
        );
        if (failWrite) {
          await tester.runAsync(
            () => database.customStatement('''
          CREATE TRIGGER fail_invoice_ledger BEFORE INSERT ON local_records
          WHEN NEW.domain = 'work/ledger'
          BEGIN SELECT RAISE(ABORT, 'injected write failure'); END
        '''),
          );
        }
        addTearDown(() async {
          store.dispose();
          session.dispose();
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
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => const InvoiceActionsScreen(
                            invoice: invoice,
                            balanceCents: 12500,
                            permissions: InvoicePermissions.development(),
                          ),
                        ),
                      ),
                      child: const Text('Open actions'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open actions'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('issue-invoice')));
        await tester.pumpAndSettle();
        final completed = Completer<void>();
        var started = false;
        void observeSave() {
          started |= session.isSaving;
          if (started && !session.isSaving && !completed.isCompleted) {
            completed.complete();
          }
        }

        session.addListener(observeSave);
        await tester.tap(find.byKey(const ValueKey('confirm-issue-invoice')));
        await tester.pump();
        // Native SQLite runs outside the widget test's fake clock. Drain both
        // real I/O and scheduled widget microtasks until the command settles.
        for (
          var attempt = 0;
          attempt < 200 && !completed.isCompleted;
          attempt++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        expect(completed.isCompleted, isTrue);
        session.removeListener(observeSave);
        await tester.pumpAndSettle();
        expect(
          store.workRecords.singleWhere((r) => r.id == invoice.id).status,
          failWrite ? WorkRecordStatus.draft : WorkRecordStatus.due,
        );
        expect(
          store.financialEntries.where((e) => e.sourceId == invoice.number),
          hasLength(failWrite ? 0 : 1),
        );
        expect(
          find.byKey(const ValueKey('invoice-actions-screen')),
          failWrite ? findsOneWidget : findsNothing,
        );
        if (failWrite) {
          expect(find.text(session.failureMessage!), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
