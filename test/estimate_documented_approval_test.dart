import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_demo_data.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_customer_approval.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';

void main() {
  test(
    'verbal approval persists separately from signature and expires on revision',
    () {
      final source = prototypeDemoWorkRecords().firstWhere(
        (record) =>
            record.kind == WorkRecordKind.estimate &&
            record.customerSignature == null,
      );
      final approval = WorkCustomerApproval(
        method: CustomerApprovalMethod.verbal,
        customerName: 'Customer',
        recordedByEmployeeId: 'alex',
        recordedOn: DateTime(2026, 9, 24),
        revision: source.revision,
        note: 'Customer said go ahead by phone.',
      );
      final approved = source.recordCustomerApproval(approval);
      final restored = decodeWorkRecord(encodeWorkRecord(approved));
      expect(restored.resolvedEstimateStage, EstimateStage.approved);
      expect(restored.hasCurrentCustomerApproval, isTrue);
      expect(
        restored.customerApprovals.single.method,
        CustomerApprovalMethod.verbal,
      );
      expect(restored.customerSignature, isNull);
      final revised = restored.reviseItems([
        ...restored.items,
        const WorkLineItem(
          id: 'extra',
          type: WorkLineItemType.material,
          name: 'Extra wood',
          description: '',
          quantity: 1,
          unit: 'each',
          customerPrice: 4,
        ),
      ], changedOn: DateTime(2026, 9, 25));
      expect(revised.hasCurrentCustomerApproval, isFalse);
      expect(revised.customerApprovals.single.revision, source.revision);
      expect(revised.resolvedEstimateStage, EstimateStage.readyToSend);
    },
  );

  test('approval for another revision is rejected', () {
    final source = prototypeDemoWorkRecords().firstWhere(
      (record) =>
          record.kind == WorkRecordKind.estimate &&
          record.customerSignature == null,
    );
    expect(
      () => source.recordCustomerApproval(
        WorkCustomerApproval(
          method: CustomerApprovalMethod.email,
          customerName: 'Customer',
          recordedByEmployeeId: 'alex',
          recordedOn: DateTime(2026, 9, 24),
          revision: source.revision + 1,
        ),
      ),
      throwsStateError,
    );
  });
}
