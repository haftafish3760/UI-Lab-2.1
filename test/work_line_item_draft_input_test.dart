import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/work_line_item_draft_input.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';

Map<String, Object?> payload() => {
  'lineId': 'stable-line',
  'original': null,
  'name': '  Valve  ',
  'description': '  Supply  ',
  'quantity': '3.',
  'price': '8.50',
  'cost': '4.',
  'type': 'material',
  'unit': 'item',
  'billingTreatment': 'nonBillable',
  'sourceExpenseId': 'expense',
  'sourceExpenseLineId': 'expense-line',
  'sourceReceiptId': 'receipt',
  'sourceStockId': 'stock',
  'initialCost': '4.25',
};
void main() {
  test(
    'legacy raw input round trips and confirms independently of widgets',
    () {
      final raw = payload();
      final input = WorkLineItemDraftInput.fromPayload(raw);
      expect(input.toPayload(), {...raw, 'workers': '1'});
      raw['name'] = 'Changed elsewhere';
      final item = input.confirmedItem(
        canSetCustomerPrice: true,
        canViewInternalCost: false,
        jobMaterialMode: false,
      );
      expect(item.id, 'stable-line');
      expect(item.name, 'Valve');
      expect(item.quantity, 3);
      expect(item.customerPrice, 8.5);
      expect(item.internalUnitCost, 4.25);
      expect(item.sourceExpenseId, 'expense');
      expect(item.sourceExpenseLineId, 'expense-line');
      expect(item.sourceReceiptId, 'receipt');
      expect(item.sourceStockId, 'stock');
      expect(input.quantity, '3.');
      expect(input.name, '  Valve  ');
    },
  );
  test(
    'invalid raw values stay recoverable and hidden prices are preserved',
    () {
      final raw = payload()..['quantity'] = '-';
      final input = WorkLineItemDraftInput.fromPayload(raw);
      expect(input.toPayload(), {...raw, 'workers': '1'});
      expect(
        () => input.confirmedItem(
          canSetCustomerPrice: true,
          canViewInternalCost: true,
          jobMaterialMode: false,
        ),
        throwsStateError,
      );
      final original = WorkLineItemDraftInput.fromPayload(payload())
          .confirmedItem(
            canSetCustomerPrice: true,
            canViewInternalCost: false,
            jobMaterialMode: false,
          );
      final edited = WorkLineItemDraftInput(
        lineId: original.id,
        original: original,
        name: 'Edited',
        description: '',
        quantity: '2',
        price: 'invalid',
        cost: 'invalid',
        type: WorkLineItemType.material,
        unit: 'item',
        billingTreatment: JobMaterialBillingTreatment.nonBillable,
      );
      final retained = edited.confirmedItem(
        canSetCustomerPrice: false,
        canViewInternalCost: false,
        jobMaterialMode: false,
      );
      expect(retained.customerPrice, original.customerPrice);
      expect(retained.internalUnitCost, original.internalUnitCost);
      final nonBillable = edited.confirmedItem(
        canSetCustomerPrice: true,
        canViewInternalCost: false,
        jobMaterialMode: true,
      );
      expect(nonBillable.customerPrice, 0);
      expect(
        nonBillable.jobMaterialBillingTreatment,
        JobMaterialBillingTreatment.nonBillable,
      );
    },
  );
}
