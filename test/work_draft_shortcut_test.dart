import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/sqlite_work_repository.dart';
import 'package:ui_lab_2_1/src/data/work/work_persistence_session.dart';
import 'package:ui_lab_2_1/src/data/work/work_session_permissions.dart';
import 'package:ui_lab_2_1/src/screens/work/work_draft_shortcut.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets('saved invoice opens a clearly named Invoice drafts list', (
    tester,
  ) async {
    const invoice = WorkRecord(
      id: 'invoice-draft-1',
      kind: WorkRecordKind.invoice,
      number: 'Invoice 1001',
      title: 'Replace outlet',
      client: 'Alex Smith',
      detail: 'Replace damaged outlet',
      pricing: WorkPricingModel.flatRate,
      status: WorkRecordStatus.draft,
    );
    final store = PrototypeOperationsStore(workRecords: const [invoice]);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const WorkDraftShortcut(
              kind: WorkRecordKind.invoice,
              buttonKey: ValueKey('invoice-draft-shortcut'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Invoice drafts'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('invoice-draft-shortcut')));
    await tester.pumpAndSettle();
    expect(find.text('Invoice drafts'), findsOneWidget);
    expect(find.text('Invoice draft · Replace outlet'), findsOneWidget);
    expect(find.textContaining('Invoice 1001'), findsOneWidget);
    expect(find.textContaining('Alex Smith'), findsOneWidget);
  });

  testWidgets('an invoice draft does not show in Estimate drafts', (
    tester,
  ) async {
    const invoice = WorkRecord(
      id: 'invoice-draft-1',
      kind: WorkRecordKind.invoice,
      number: 'Invoice 1001',
      title: 'Replace outlet',
      client: 'Alex Smith',
      detail: 'Replace damaged outlet',
      pricing: WorkPricingModel.flatRate,
      status: WorkRecordStatus.draft,
    );
    final store = PrototypeOperationsStore(workRecords: const [invoice]);
    addTearDown(store.dispose);
    await tester.pumpWidget(
      PrototypeOperationsScope(
        store: store,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: const WorkDraftShortcut(
              kind: WorkRecordKind.estimate,
              buttonKey: ValueKey('estimate-draft-shortcut'),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('estimate-draft-shortcut')), findsNothing);
  });

  testWidgets(
    'unfinished invoice input remains reachable before a record exists',
    (tester) async {
      final harness = (await tester.runAsync(DatabaseHarness.create))!;
      final database = (await tester.runAsync(harness.open))!;
      final work = (await tester.runAsync(
        () => WorkPersistenceSession.open(
          SqliteWorkRepository(database),
          WorkSessionPermissions(
            organizationId: 'business',
            actorEmployeeId: 'owner',
            permissionRevision: 'owner-1',
            visibleCreatorIds: {'owner'},
            editableKinds: {WorkRecordKind.invoice},
          ),
        ),
      ))!;
      final now = DateTime.now();
      final draft = (await tester.runAsync(work.openInvoiceDraft))!;
      draft.updateInput(
        InvoiceDraftInput(
          creatorId: 'owner',
          number: '',
          baseStorageRevision: 0,
          title: 'Emergency outlet repair',
          discount: '',
          tax: '',
          terms: '',
          client: 'Alex Smith',
          pricing: WorkPricingModel.flatRate,
          template: 'classic',
          createdOn: now,
          items: const [],
          existingRecordId: null,
          recordId: 'unfinished-invoice-record',
          summary: '',
          issuedOn: now,
          dueOn: now,
          sourceJobId: null,
          location: null,
          paymentMethod: '',
          pendingLineItem: null,
        ),
      );
    await finishNativeOperation(tester, draft.session.close);
      final store = PrototypeOperationsStore(workSession: work);
      addTearDown(() async {
        store.dispose();
        work.dispose();
        await harness.dispose();
      });
      expect(work.records, isEmpty);
      await tester.pumpWidget(
        PrototypeOperationsScope(
          store: store,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: WorkDraftShortcut(
                kind: WorkRecordKind.invoice,
                buttonKey: ValueKey('invoice-draft-shortcut'),
              ),
            ),
          ),
        ),
      );
      await waitForNativeSave(
        tester,
        () => find
            .byKey(const ValueKey('invoice-draft-shortcut'))
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.byKey(const ValueKey('invoice-draft-shortcut')));
      await waitForNativeSave(
        tester,
        () => find
            .textContaining('Emergency outlet repair')
            .evaluate()
            .isNotEmpty,
      );
      expect(find.text('Invoice drafts'), findsOneWidget);
      expect(
        find.textContaining('Invoice draft · Emergency outlet repair'),
        findsOneWidget,
      );
    },
  );
}
