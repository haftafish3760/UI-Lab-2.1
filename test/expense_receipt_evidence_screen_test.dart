import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/authorized_expense_service.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_repository.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_bridge.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_ui_repository_controller.dart';
import 'package:ui_lab_2_1/src/data/expenses/file_expense_repository.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/receipts/authorized_receipt_draft_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/file_receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_record.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_repository.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_submission_coordinator.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_draft_ui_controller.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_models.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_receipt_evidence_screen.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets(
    'confirmed expense opens its exact submitted receipt files responsively',
    (tester) async {
      final fixture = await tester.runAsync(_createConfirmedFixture);
      addTearDown(() => fixture!.dispose());
      await _pumpFixture(tester, fixture!, const Size(390, 844));

      await _pumpUntilFound(tester, find.text('first.png'));
      expect(find.text('second.png'), findsOneWidget);
      expect(find.text('Retained file 1 of 2'), findsOneWidget);
      expect(fixture.drafts.records, isEmpty);
      expect(
        find.byKey(const ValueKey('confirmed-receipt-preview-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('confirmed-receipt-file-list')),
        findsOneWidget,
      );
      final narrowPreview = tester.getTopLeft(
        find.byKey(const ValueKey('confirmed-receipt-preview-panel')),
      );
      final narrowFiles = tester.getTopLeft(
        find.byKey(const ValueKey('confirmed-receipt-file-list')),
      );
      expect(narrowFiles.dy, greaterThan(narrowPreview.dy));

      tester.view.physicalSize = const Size(1200, 900);
      await tester.pump(const Duration(milliseconds: 500));
      final widePreview = tester.getTopLeft(
        find.byKey(const ValueKey('confirmed-receipt-preview-panel')),
      );
      final wideFiles = tester.getTopLeft(
        find.byKey(const ValueKey('confirmed-receipt-file-list')),
      );
      expect((wideFiles.dy - widePreview.dy).abs(), lessThan(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unverified expense-to-draft link exposes no evidence', (
    tester,
  ) async {
    final fixture = await tester.runAsync(
      () => _createConfirmedFixture(mismatchedSubmission: true),
    );
    addTearDown(() => fixture!.dispose());
    await _pumpFixture(tester, fixture!, const Size(390, 844));

    await _pumpUntilFound(
      tester,
      find.text('Receipt link could not be verified'),
    );
    expect(find.text('first.png'), findsNothing);
    expect(find.text('second.png'), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied direct route exposes no receipt metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExpenseReceiptEvidenceScreen(
          expenseId: 'restricted-expense',
          permissions: ExpensePermissions(
            canView: false,
            canViewAmounts: false,
            canCreate: false,
            canAttachReceipt: false,
            canEditOwn: false,
            canEditTeam: false,
            canReviewCompanyExpenses: false,
            canManageScheduledExpenses: false,
            canConfigureDisplay: false,
          ),
        ),
      ),
    );

    expect(
      find.text('You do not have permission to view receipt evidence.'),
      findsOneWidget,
    );
    expect(find.textContaining('.png'), findsNothing);
    expect(find.textContaining('receipt-draft'), findsNothing);
  });

  testWidgets(
    'bound authorization never falls back to a prototype expense record',
    (tester) async {
      final fixture = await tester.runAsync(
        () => _createEmptyAuthorizedFixture('EXP-1048'),
      );
      addTearDown(() => fixture!.dispose());
      await _pumpFixture(tester, fixture!, const Size(390, 844));

      expect(
        find.byKey(const ValueKey('expense-evidence-unavailable-EXP-1048')),
        findsOneWidget,
      );
      expect(find.text('Central Supply'), findsNothing);
      expect(find.textContaining('.png'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<_ReceiptEvidenceFixture> _createEmptyAuthorizedFixture(
  String expenseId,
) async {
  final root = await Directory.systemTemp.createTemp(
    'expense-evidence-denied-',
  );
  final expenses = _expenseController(
    await FileExpenseRepository.open(Directory('${root.path}/expenses')),
  );
  final drafts = _receiptController(
    await FileReceiptDraftRepository.open(Directory('${root.path}/receipts')),
  );
  await expenses.load();
  await drafts.load();
  return _ReceiptEvidenceFixture(
    root: root,
    expenses: expenses,
    drafts: drafts,
    expenseId: expenseId,
  );
}

Future<_ReceiptEvidenceFixture> _createConfirmedFixture({
  bool mismatchedSubmission = false,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'expense-receipt-evidence-',
  );
  final first = File('${root.path}/first.png');
  final second = File('${root.path}/second.png');
  await first.writeAsBytes(_onePixelPng);
  await second.writeAsBytes(_onePixelPng);
  final drafts = _receiptController(
    await FileReceiptDraftRepository.open(Directory('${root.path}/receipts')),
  );
  final expenses = _expenseController(
    await FileExpenseRepository.open(Directory('${root.path}/expenses')),
  );
  await drafts.load();
  await expenses.load();
  final draft = await drafts.create(
    draftId: 'receipt-draft-exact',
    title: 'Central Supply retained receipt',
    expenseDate: DateTime(2026, 9, 1),
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
    occurredAtUtc: DateTime.utc(2026, 9, 1, 12),
  );
  if (draft == null) throw StateError('Receipt fixture draft was not created.');

  late final String expenseId;
  if (mismatchedSubmission) {
    final expense = await expenses.createFromReceiptDraft(
      record: _reviewedExpense('EXP-EVIDENCE-MISMATCH'),
      receiptDraftId: draft.draftId,
      paidByEmployeeId: 'alex',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
    );
    if (expense == null) throw StateError('Expense fixture was not created.');
    expenseId = expense.id;
    await drafts.submit(
      draftId: draft.draftId,
      expenseId: 'EXP-DIFFERENT-RECORD',
      occurredAtUtc: DateTime.utc(2026, 9, 1, 14),
    );
  } else {
    final result =
        await ReceiptDraftSubmissionCoordinator(
          expenses: expenses,
          receiptDrafts: drafts,
        ).submit(
          draftId: draft.draftId,
          reviewedRecord: _reviewedExpense('temporary-id'),
          paidByEmployeeId: 'alex',
          occurredAtUtc: DateTime.utc(2026, 9, 1, 13),
        );
    if (!result.succeeded || result.expense == null) {
      throw StateError(result.message ?? 'Receipt fixture was not submitted.');
    }
    expenseId = result.expense!.id;
  }
  return _ReceiptEvidenceFixture(
    root: root,
    expenses: expenses,
    drafts: drafts,
    expenseId: expenseId,
  );
}

Future<void> _pumpFixture(
  WidgetTester tester,
  _ReceiptEvidenceFixture fixture,
  Size size,
) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final store = PrototypeOperationsStore();
  final scope = OperationalScopeController();
  addTearDown(store.dispose);
  addTearDown(scope.dispose);
  await tester.pumpWidget(
    ExpenseUiScope(
      controller: fixture.expenses,
      child: ReceiptDraftUiScope(
        controller: fixture.drafts,
        child: PrototypeOperationsScope(
          store: store,
          child: OperationalScope(
            controller: scope,
            child: MaterialApp(
              theme: AppTheme.light,
              home: ExpenseReceiptEvidenceScreen(expenseId: fixture.expenseId),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  fail('The expected receipt evidence state did not appear within 3 seconds.');
}

ExpenseUiRepositoryController _expenseController(
  ExpenseRepository repository,
) => ExpenseUiRepositoryController(
  ExpenseUiRepositoryBridge(
    service: AuthorizedExpenseService(repository),
    employeeLabelForId: (_) => 'Alex Morgan',
    jobLabelForId: (_) => null,
  ),
  ExpenseCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'alex',
    permissionRevision: 'permissions-1',
    readScope: ExpenseReadScope.company,
    canCreate: true,
    canEdit: true,
    canDelete: true,
    canRestore: true,
    canApprove: true,
    canManageOtherEmployees: true,
  ),
);

ReceiptDraftUiController _receiptController(
  ReceiptDraftRepository repository,
) => ReceiptDraftUiController(
  AuthorizedReceiptDraftService(repository),
  ReceiptDraftCommandPermissions(
    organizationId: 'organization-1',
    actorEmployeeId: 'alex',
    permissionRevision: 'permissions-1',
    readScope: ReceiptDraftReadScope.company,
    canCreate: true,
    canEditOwn: true,
    canEditTeam: true,
    canSubmitOwn: true,
    canSubmitTeam: true,
    canDiscardOwn: true,
    canDiscardTeam: true,
  ),
);

ExpenseRecord _reviewedExpense(String id) => ExpenseRecord(
  id: id,
  vendor: 'Central Supply',
  category: ExpenseCategory.materials,
  amount: 48.72,
  date: DateTime(2026, 9, 1),
  owner: 'Alex Morgan',
  paidByEmployeeId: 'alex',
  receiptStatus: 'Receipt reviewed',
  receiptType: ExpenseReceiptType.detailed,
  receiptImageCount: 2,
  receiptSubtotal: 45,
  salesTax: 3.72,
  lineItems: const [
    ExpenseLineItem(
      id: 'line-1',
      description: 'PEX adapter',
      category: ExpenseCategory.materials,
      quantity: 2,
      unit: 'each',
      unitPrice: 22.50,
    ),
  ],
);

class _ReceiptEvidenceFixture {
  const _ReceiptEvidenceFixture({
    required this.root,
    required this.expenses,
    required this.drafts,
    required this.expenseId,
  });

  final Directory root;
  final ExpenseUiRepositoryController expenses;
  final ReceiptDraftUiController drafts;
  final String expenseId;

  Future<void> dispose() async {
    expenses.dispose();
    drafts.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const _onePixelPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  8,
  215,
  99,
  248,
  207,
  192,
  240,
  31,
  0,
  5,
  0,
  1,
  255,
  137,
  153,
  61,
  29,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];
