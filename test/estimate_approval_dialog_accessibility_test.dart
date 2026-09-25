import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_customer_approval_dialog.dart';
import 'package:ui_lab_2_1/src/screens/work/work_models.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('verbal approval is usable at 320 LP and text scale $scale', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final record = prototypeDemoWorkRecords().firstWhere(
        (r) => r.kind == WorkRecordKind.estimate,
      );
      WorkCustomerApproval? result;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<WorkCustomerApproval>(
                    context: context,
                    builder: (_) => EstimateCustomerApprovalDialog(
                      record: record,
                      actorId: 'alex',
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Open'));
      await t.pumpAndSettle();
      await t.tap(find.byType(DropdownButtonFormField<CustomerApprovalMethod>));
      await t.pumpAndSettle();
      await t.ensureVisible(
        find.text(CustomerApprovalMethod.verbal.label).last,
      );
      await t.tap(find.text(CustomerApprovalMethod.verbal.label).last);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.tap(find.text('Record approval'));
      await t.pumpAndSettle();
      expect(result?.method, CustomerApprovalMethod.verbal);
      expect(result?.recordedByEmployeeId, 'alex');
      expect(result?.revision, record.revision);
      expect(t.takeException(), isNull);
    });
  }
}
