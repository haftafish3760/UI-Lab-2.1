import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_item_parser.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_text.dart';

void main() {
  parse(String text) => proposeReceiptItems(
    ReceiptPhotoText(text: text, lines: []),
    sourceId: 'photo-A',
  );

  test('explicit quantities and wrapped descriptions retain source rows', () {
    final result = parse(
      'Unknown Trade Counter\nReceipt 84\n-----\n'
      'HEAVY DUTY\nCABLE TIES\n2 box x 15.00 30.00\n'
      'SUBTOTAL 30.00\nTAX 2.10\nTOTAL 32.10\nCARD 32.10',
    );
    final item = result.items.single;
    expect(item.description, 'HEAVY DUTY CABLE TIES');
    expect(item.quantity!.decimalValue, '2');
    expect(item.purchaseUnit, 'box');
    expect(item.unitPrice!.decimalValue, '15');
    expect(item.lineTotalMinor, 3000);
    expect(item.calculatedTotalMinor, 3000);
    expect(item.sourceRows.map((r) => r.index), [3, 4, 5]);
    expect(item.sourceRows.first.sourceLines, isEmpty);
  });

  test('package description numbers never become a purchase quantity', () {
    for (final description in [
      '100 PACK CABLE TIES',
      '12/2 CABLE',
      '10 FT PIPE',
    ]) {
      final item = parse('$description 8.99\nTOTAL 8.99').items.single;
      expect(item.description, description);
      expect(item.quantity, isNull);
      expect(item.purchaseUnit, isNull);
      expect(item.unitPrice, isNull);
      expect(item.lineTotalMinor, 899);
      expect(item.warnings, isNotEmpty);
    }
  });

  test('trade items sharing administrative words are not discarded', () {
    final result = parse(
      'TERMINAL STRIP 4.99\nRETURN AIR GRILLE 12.99\n'
      'PUMP 5 HP 250.00\nTIP CLEANER 7.99\nCARD STOCK 8.99\nTOTAL 284.96',
    );
    expect(result.items.map((item) => item.description), [
      'TERMINAL STRIP',
      'RETURN AIR GRILLE',
      'PUMP 5 HP',
      'TIP CLEANER',
      'CARD STOCK',
    ]);
  });

  test(
    'duplicate purchases survive; totals, payment and change are not items',
    () {
      final result = parse(
        'WASHER 1.25\nWASHER 1.25\nSUBTOTAL 2.50\n'
        'TAX 0.00\nTOTAL 2.50\nCASH 10.00\nCHANGE 7.50',
      );
      expect(result.items, hasLength(2));
      expect(result.items[0].id, isNot(result.items[1].id));
      expect(result.items.map((i) => i.lineTotalMinor), [125, 125]);
      expect(result.unresolvedRows, isEmpty);
    },
  );

  test(
    'discounts and negative rows stay unresolved, never positive inventory',
    () {
      final result = parse(
        'BOLT 2.50\nDISCOUNT 0.50\nRETURN BOLT -2.50\n'
        'COUPON -1.00\n-2.00\nTOTAL 1.00',
      );
      expect(result.items, hasLength(1));
      expect(result.unresolvedRows, hasLength(4));
    },
  );

  test('inconsistent printed amount is retained and flagged', () {
    final item = parse('PIPE 3 ea @ 2.00 7.00').items.single;
    expect(item.quantity!.decimalValue, '3');
    expect(item.lineTotalMinor, 700);
    expect(item.calculatedTotalMinor, 600);
    expect(item.warnings.single, contains('do not match'));
  });

  test('unlabeled amount columns and decimal commas are not guessed', () {
    for (final text in [
      'PIPE 2.00 4.00',
      'PIPE 4,99',
      'PIPE 12,34.56',
      'PIPE 0 ea x 2.00 0.00',
      'PIPE 999999999999999 ea x 1.00 3.00',
    ]) {
      final result = parse(text);
      expect(result.items, isEmpty, reason: text);
      expect(result.unresolvedRows, isNotEmpty, reason: text);
    }
  });

  test(
    'fuel retains measured quantity and fractional price without copying total',
    () {
      final item = parse(
        'Fictional Fuel Stop\nReceipt 5\nPUMP 3\n'
        'REGULAR UNLEADED\nGallons 16.810\nPrice per gallon 3.499\n'
        'TOTAL 70.00',
      ).items.single;
      expect(item.description, 'REGULAR UNLEADED');
      expect(item.quantity!.decimalValue, '16.81');
      expect(item.purchaseUnit, 'gallon');
      expect(item.unitPrice!.decimalValue, '3.499');
      expect(item.calculatedTotalMinor, 5882);
      expect(item.lineTotalMinor, isNull);
      expect(item.warnings, isNotEmpty);
    },
  );

  test('fuel units must agree and missing volume never defaults to one', () {
    for (final text in [
      'UNLEADED\nGallons 10.00\nPrice per litre 1.50\nTOTAL 15.00',
      'UNLEADED\nPrice per gallon 3.50\nTOTAL 35.00',
    ]) {
      expect(parse(text).items, isEmpty);
    }
  });

  test('exact decimal arithmetic rounds half cents without binary floats', () {
    final item = parse('WIRE 0.3 ft x 0.05 0.02').items.single;
    expect(item.calculatedTotalMinor, 2);
    expect(item.warnings, isEmpty);
  });

  test(
    'summary labels need no whitespace; quantity labels are not descriptions',
    () {
      final result = parse(
        'WASHER\nQTY: 2 @ 1.25 2.50\nSUBTOTAL:2.50\n'
        'TAX:0.00\nTOTAL:2.50\nTOTAL ITEMS 2.00',
      );
      expect(result.items, hasLength(1));
      expect(result.items.single.description, 'WASHER');
      expect(result.items.single.quantity!.decimalValue, '2');
      expect(result.items.single.purchaseUnit, isNull);
    },
  );

  test('unpriced description before totals remains available for review', () {
    final result = parse('BOLT 1.00\nWASHER\nSUBTOTAL:2.00');
    expect(result.items, hasLength(1));
    expect(result.unresolvedRows.single.text, 'WASHER');
  });

  test('long text preserves every repeated line identity and amount', () {
    final result = parse(
      '${List.filled(1500, 'WASHER 2 ea x 1.25 2.50').join('\n')}\nTOTAL 3750.00',
    );
    expect(result.items, hasLength(1500));
    expect(result.items.map((i) => i.id).toSet(), hasLength(1500));
    expect(
      result.items.fold<int>(0, (sum, i) => sum + i.lineTotalMinor!),
      375000,
    );
  });

  test('separate OCR columns preserve all source boxes', () {
    final result = proposeReceiptItems(
      ReceiptPhotoText(
        text: '',
        lines: const [
          ReceiptTextLine('2 ea x 1.25', 110, 20, 220, 40),
          ReceiptTextLine('WASHER', 0, 20, 100, 40),
          ReceiptTextLine('2.50', 250, 20, 290, 40),
          ReceiptTextLine('TOTAL 2.50', 0, 70, 290, 90),
        ],
      ),
      sourceId: 'photo-B',
    );
    final item = result.items.single;
    expect(item.description, 'WASHER');
    expect(item.sourceRows.single.sourceLines, hasLength(3));
    expect(item.sourceRows.single.sourceLines.last.left, 250);
  });
}
