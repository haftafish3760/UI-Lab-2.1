import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_evidence_review_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_source_picker.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  late Directory directory;
  late List<ReceiptEvidenceSelection> evidence;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'receipt-evidence-review-',
    );
    final first = File('${directory.path}/first.png');
    final second = File('${directory.path}/second.png');
    await first.writeAsBytes(_onePixelPng);
    await second.writeAsBytes(_onePixelPng);
    evidence = [
      ReceiptEvidenceSelection(
        path: first.path,
        name: 'first.png',
        kind: ReceiptEvidenceKind.photo,
        evidenceId: 'evidence-first',
      ),
      ReceiptEvidenceSelection(
        path: second.path,
        name: 'second.png',
        kind: ReceiptEvidenceKind.photo,
        evidenceId: 'evidence-second',
      ),
    ];
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  testWidgets('labeled reorder controls return the reviewed stable order', (
    tester,
  ) async {
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: _ReviewHarness(evidence: evidence),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-evidence-review')));
    await tester.pumpAndSettle();

    expect(find.text('Review receipt evidence'), findsOneWidget);
    expect(find.text('1. first.png'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    final laterButtons = find.widgetWithText(TextButton, 'Later');
    await tester.ensureVisible(laterButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(laterButtons.first);
    await tester.pump();
    expect(find.text('1. second.png'), findsOneWidget);
    expect(find.text('2. first.png'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Save order'));
    await tester.pumpAndSettle();
    expect(find.text('evidence-second,evidence-first|saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review reflows at 320 LP with 2x accessible text', (
    tester,
  ) async {
    final scope = OperationalScopeController();
    addTearDown(scope.dispose);
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      OperationalScope(
        controller: scope,
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: ReceiptEvidenceReviewScreen(
              evidence: evidence,
              permissions: const ExpensePermissions.development(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Review receipt evidence'), findsOneWidget);
    expect(find.text('Earlier'), findsWidgets);
    expect(find.text('Later'), findsWidgets);
    expect(find.text('Remove'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied direct route reveals no evidence names', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReceiptEvidenceReviewScreen(
          evidence: evidence,
          permissions: const ExpensePermissions(
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
      find.text('You do not have permission to review receipt evidence.'),
      findsOneWidget,
    );
    expect(find.textContaining('first.png'), findsNothing);
    expect(find.textContaining('second.png'), findsNothing);
  });
}

class _ReviewHarness extends StatefulWidget {
  const _ReviewHarness({required this.evidence});

  final List<ReceiptEvidenceSelection> evidence;

  @override
  State<_ReviewHarness> createState() => _ReviewHarnessState();
}

class _ReviewHarnessState extends State<_ReviewHarness> {
  String? _result;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _result == null
          ? FilledButton(
              key: const ValueKey('open-evidence-review'),
              onPressed: _open,
              child: const Text('Open review'),
            )
          : Text(_result!),
    ),
  );

  Future<void> _open() async {
    final result = await Navigator.of(context)
        .push<ReceiptEvidenceReviewResult>(
          MaterialPageRoute(
            builder: (_) => ReceiptEvidenceReviewScreen(
              evidence: widget.evidence,
              permissions: const ExpensePermissions.development(),
            ),
          ),
        );
    if (!mounted || result == null) return;
    setState(() {
      _result =
          '${result.orderedEvidence.map((item) => item.identity).join(',')}'
          '|${result.continueToDetails ? 'continue' : 'saved'}';
    });
  }
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
