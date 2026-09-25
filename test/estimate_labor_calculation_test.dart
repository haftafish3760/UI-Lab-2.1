import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_line_item_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_detail_codec.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';

void main() {
  WorkLineItemDraftInput input(String workers, String price) =>
      WorkLineItemDraftInput(
        lineId: 'labor',
        name: 'Install shelves',
        description: '',
        quantity: '4',
        workers: workers,
        price: price,
        cost: '15',
        type: WorkLineItemType.labor,
        unit: 'hour',
        billingTreatment: JobMaterialBillingTreatment.nonBillable,
      );
  WorkLineItem confirm(WorkLineItemDraftInput value) => value.confirmedItem(
    canSetCustomerPrice: true,
    canViewInternalCost: true,
    jobMaterialMode: false,
  );
  test(
    'three workers for four hours retain 12 billable hours and correct totals',
    () {
      final saved = decodeWorkLineItem(
        encodeWorkLineItem(confirm(input('3', '25'))),
      );
      expect(saved.quantity, 12);
      expect(saved.workerCount, 3);
      expect(saved.total, 300);
      expect(saved.quantity * saved.internalUnitCost!, 180);
    },
  );
  test('blank rate stays unfinished while deliberate zero is valid', () {
    expect(() => confirm(input('1', '')), throwsStateError);
    expect(confirm(input('1', '0')).total, 0);
  });
  test('worker count must be a positive whole number', () {
    for (final value in ['0', '-1', '1.5', '']) {
      expect(() => confirm(input(value, '25')), throwsStateError);
    }
  });
}
