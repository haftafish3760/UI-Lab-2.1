import 'support/expense_setup_fixture.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/app.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/file_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_lab_policy.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_receipt_drafts_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expenses_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_intake_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets(
    'landing summary and exact draft route use authorized durable records',
    (tester) async {
      final fixture = await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp(
          'receipt-draft-ui-binding-',
        );
        final source = File('${root.path}/source.jpg');
        await source.writeAsBytes([9, 7, 5, 3]);
        final receipts = await FileReceiptDraftRepository.open(
          Directory('${root.path}/receipts'),
        );
        final service = AuthorizedReceiptDraftService(receipts);
        final permissions = receiptDraftUiLabOwnerPermissions();
        await service.create(
          draft: StoredReceiptDraft(
            draftId: 'draft-exact-route',
            organizationId: permissions.organizationId,
            ownerEmployeeId: permissions.actorEmployeeId,
            title: 'Exact retained receipt',
            expenseDate: DateTime(2026, 9, 1),
            evidence: const [],
            lifecycle: ReceiptDraftLifecycle(
              revision: 1,
              createdAtUtc: DateTime.utc(2026, 9, 1, 12),
              updatedAtUtc: DateTime.utc(2026, 9, 1, 12),
            ),
          ),
          evidence: [
            ReceiptEvidenceImport(
              sourcePath: source.path,
              originalName: 'source.jpg',
              kind: ReceiptDraftEvidenceKind.photo,
            ),
          ],
          permissions: permissions,
          occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
        );
        final controller = ReceiptDraftUiController(service, permissions);
        await controller.load();
        return (root: root, controller: controller);
      });
      final root = fixture!.root;
      final controller = fixture.controller;
      addTearDown(() => root.delete(recursive: true));
      addTearDown(controller.dispose);
      final operationalScope = OperationalScopeController();
      final store = PrototypeOperationsStore();
      addTearDown(operationalScope.dispose);
      addTearDown(store.dispose);
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ReceiptDraftUiScope(
          controller: controller,
          child: PrototypeOperationsScope(
            store: store,
            child: OperationalScope(
              controller: operationalScope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: const ExpensesScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final summary = find.byKey(
        const ValueKey('expense-receipt-drafts-summary'),
      );
      expect(summary, findsOneWidget);
      expect(find.descendant(of: summary, matching: find.text('1')), findsOne);
      await tester.tap(summary);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final exactCard = find.byKey(
        const ValueKey('expense-receipt-draft-draft-exact-route'),
      );
      expect(exactCard, findsOneWidget);
      await tester.tap(exactCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Continue receipt'), findsOneWidget);
      expect(
        tester
            .widget<ReceiptIntakeScreen>(find.byType(ReceiptIntakeScreen))
            .draftId,
        'draft-exact-route',
      );
      expect(
        controller.recordById('draft-exact-route')!.title,
        'Exact retained receipt',
      );
      expect(find.text('source.jpg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('app boundary binds the supplied Receipt Draft repository', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp(
        'receipt-draft-app-binding-',
      );
      final repository = await FileReceiptDraftRepository.open(
        Directory('${root.path}/receipts'),
      );
      final permissions = receiptDraftUiLabOwnerPermissions();
      await AuthorizedReceiptDraftService(repository).create(
        draft: StoredReceiptDraft(
          draftId: 'draft-app-boundary',
          organizationId: permissions.organizationId,
          ownerEmployeeId: permissions.actorEmployeeId,
          title: 'App-bound receipt',
          expenseDate: DateTime(2026, 9, 1),
          evidence: const [],
          lifecycle: ReceiptDraftLifecycle(
            revision: 1,
            createdAtUtc: DateTime.utc(2026, 9, 1, 12),
            updatedAtUtc: DateTime.utc(2026, 9, 1, 12),
          ),
        ),
        evidence: const [],
        permissions: permissions,
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      return (root: root, repository: repository);
    });
    addTearDown(() => fixture!.root.delete(recursive: true));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UiLabApp(receiptDraftRepository: fixture!.repository),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await useCompletedExpenseSetup(tester);
    await tester.tap(find.byKey(const ValueKey('app-destination-expenses')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.byKey(const ValueKey('expense-receipt-drafts-summary')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct draft route enforces receipt permission', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExpenseReceiptDraftsScreen(
          permissions: ExpensePermissions(
            canView: true,
            canViewAmounts: true,
            canCreate: false,
            canAttachReceipt: false,
            canEditOwn: false,
            canEditTeam: false,
            canReviewCompanyExpenses: false,
            canManageScheduledExpenses: false,
            canConfigureDisplay: false,
            actorEmployeeId: 'alex',
          ),
        ),
      ),
    );

    expect(
      find.text('You do not have permission to review receipts.'),
      findsOneWidget,
    );
  });

  testWidgets('receipt intake persists the exact reviewed evidence order', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp(
        'receipt-order-binding-',
      );
      final first = File('${root.path}/first.png');
      final second = File('${root.path}/second.png');
      await first.writeAsBytes(_onePixelPng);
      await second.writeAsBytes(_onePixelPng);
      final repository = await FileReceiptDraftRepository.open(
        Directory('${root.path}/receipts'),
      );
      final permissions = receiptDraftUiLabOwnerPermissions();
      final service = AuthorizedReceiptDraftService(repository);
      await service.create(
        draft: StoredReceiptDraft(
          draftId: 'draft-reviewed-order',
          organizationId: permissions.organizationId,
          ownerEmployeeId: permissions.actorEmployeeId,
          title: 'Ordered source receipt',
          expenseDate: DateTime(2026, 9, 1),
          evidence: const [],
          lifecycle: ReceiptDraftLifecycle(
            revision: 1,
            createdAtUtc: DateTime.utc(2026, 9, 1, 12),
            updatedAtUtc: DateTime.utc(2026, 9, 1, 12),
          ),
        ),
        evidence: [
          ReceiptEvidenceImport(
            sourcePath: first.path,
            originalName: 'first.png',
            kind: ReceiptDraftEvidenceKind.photo,
          ),
          ReceiptEvidenceImport(
            sourcePath: second.path,
            originalName: 'second.png',
            kind: ReceiptDraftEvidenceKind.photo,
          ),
        ],
        permissions: permissions,
        occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
      );
      final controller = ReceiptDraftUiController(service, permissions);
      await controller.load();
      return (root: root, controller: controller);
    });
    final root = fixture!.root;
    final controller = fixture.controller;
    addTearDown(() => root.delete(recursive: true));
    addTearDown(controller.dispose);
    final operationalScope = OperationalScopeController();
    final store = PrototypeOperationsStore();
    addTearDown(operationalScope.dispose);
    addTearDown(store.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ReceiptDraftUiScope(
        controller: controller,
        child: PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: operationalScope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: ReceiptIntakeScreen(
                draftId: 'draft-reviewed-order',
                draftTitle: 'Ordered source receipt',
                expenseDate: DateTime(2026, 9, 1),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final review = find.byKey(
      const ValueKey('review-selected-receipt-evidence'),
    );
    await tester.ensureVisible(review);
    await tester.pumpAndSettle();
    await tester.tap(review);
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('receipt-evidence-review-screen')),
    );
    final firstLater = find.widgetWithText(TextButton, 'Later').first;
    await tester.ensureVisible(firstLater);
    await tester.pump();
    await tester.tap(firstLater);
    await tester.pump();
    final saveOrder = find.widgetWithText(OutlinedButton, 'Save order');
    await tester.ensureVisible(saveOrder);
    await tester.pump();
    await tester.tap(saveOrder);
    await tester.pump();
    await _pumpUntil(
      tester,
      () =>
          find
              .byKey(const ValueKey('receipt-evidence-review-screen'))
              .evaluate()
              .isEmpty &&
          controller
                  .recordById('draft-reviewed-order')
                  ?.activeEvidence
                  .first
                  .originalName ==
              'second.png',
    );

    expect(
      controller
          .recordById('draft-reviewed-order')!
          .activeEvidence
          .map((item) => item.originalName),
      ['second.png', 'first.png'],
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) =>
    _pumpUntil(tester, () => finder.evaluate().isNotEmpty);

Future<void> _pumpUntil(WidgetTester tester, bool Function() predicate) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (predicate()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('The expected widget state did not appear within 3 seconds.');
}

const _onePixelPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0xF0,
  0x1F,
  0x00,
  0x05,
  0x00,
  0x01,
  0xFF,
  0x89,
  0x99,
  0x3D,
  0x1D,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
