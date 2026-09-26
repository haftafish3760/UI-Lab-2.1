import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_signature_screen.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_models.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  testWidgets('in-person signature approves the exact estimate revision', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WorkRecord? updated;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                updated = await Navigator.of(context).push<WorkRecord>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EstimateSignatureScreen(record: _readyEstimate()),
                  ),
                );
              },
              child: const Text('Review and sign'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review and sign'));
    await tester.pumpAndSettle();

    expect(find.text('Approve estimate in person'), findsOneWidget);
    final save = find.byKey(const ValueKey('save-customer-signature'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.ensureVisible(find.byKey(const ValueKey('tap-to-sign')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tap-to-sign')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('estimate-signature-pad')),
    );
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('estimate-signature-pad')),
      const Offset(80, 30),
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(updated, isNotNull);
    expect(updated!.hasCurrentCustomerSignature, isTrue);
    expect(updated!.customerSignature?.signedRevision, 1);
    expect(updated!.resolvedEstimateStage, EstimateStage.approved);
    expect(tester.takeException(), isNull);
  });
}

WorkRecord _readyEstimate() => WorkRecord(
  id: 'signature-estimate',
  kind: WorkRecordKind.estimate,
  number: 'EST-SIGN',
  title: 'Replace bathroom faucet',
  client: 'Maya Thompson',
  detail: 'Replace the faucet and verify operation.',
  pricing: WorkPricingModel.flatRate,
  status: WorkRecordStatus.ready,
  total: 450,
  estimateStage: EstimateStage.readyToSend,
  createdOn: DateTime(2026, 8, 30),
  estimateDates: EstimateDates(
    createdOn: DateTime(2026, 8, 30),
    lastEditedOn: DateTime(2026, 8, 30),
  ),
);
