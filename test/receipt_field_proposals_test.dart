import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_field_proposals.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_reader.dart';

void main() {
  ReceiptFieldProposals parse(String text) =>
      proposeReceiptFields(ReceiptPhotoText(text: text, lines: []));
  test('unknown merchant, change and card payment do not override total', () {
    final result = parse(
      'Cedar Service Counter\nRECEIPT\nSubtotal 18.90\nTax 1.10\nTOTAL 20.00\nCASH 50.00\nCHANGE 30.00',
    );
    expect(result.merchant, 'Cedar Service Counter');
    expect(result.totalMinor, 2000);
    expect(result.subtotalMinor, 1890);
    expect(result.taxMinor, 110);
    expect(result.warnings, isEmpty);
  });
  test('conflicting totals and ambiguous decimal formats are not guessed', () {
    expect(parse('TOTAL 20.00\nTOTAL 30.00').totalMinor, isNull);
    expect(parse('TOTAL 20,00').totalMinor, isNull);
    expect(parse('SUBTOTAL 20.00').totalMinor, isNull);
    expect(parse('TOTAL ITEMS 20.00').totalMinor, isNull);
    expect(parse('TOTAL 1,234.56').totalMinor, 123456);
    expect(parse('TOTAL -12.50').totalMinor, -1250);
  });
  test(
    'inconsistent math stays visible rather than replacing printed total',
    () {
      final result = parse('Subtotal 10.00\nTax 2.00\nTotal 11.00');
      expect(result.totalMinor, 1100);
      expect(result.warnings.single, contains('do not match'));
    },
  );
  test('separate price blocks align and repeated purchases survive', () {
    final source = ReceiptPhotoText(
      text: 'unordered',
      lines: const [
        ReceiptTextLine('5.00', 200, 40, 250, 60),
        ReceiptTextLine('5.00', 200, 70, 250, 90),
        ReceiptTextLine('10.00', 200, 110, 260, 130),
        ReceiptTextLine('Washer', 10, 40, 100, 60),
        ReceiptTextLine('Washer', 10, 70, 100, 90),
        ReceiptTextLine('TOTAL', 10, 110, 100, 130),
      ],
    );
    final result = proposeReceiptFields(source);
    expect(result.rows, ['Washer 5.00', 'Washer 5.00', 'TOTAL 10.00']);
    expect(result.totalMinor, 1000);
  });
}
