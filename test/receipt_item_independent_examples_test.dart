import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_item_parser.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_text.dart';

/// Opt-in read-only characterization against a separate app's existing answers.
/// Printed text is used here. This is NOT an OCR image accuracy benchmark.
void main() {
  final library = Platform.environment['RECEIPT_EXAMPLE_LIBRARY'];
  for (final id in ['example-62a1c6fa', 'example-599fc6be']) {
    test(
      'independent printed-text item characterization: $id',
      () async {
        final folder = Directory('$library${Platform.pathSeparator}$id');
        final expected =
            jsonDecode(
                  await File(
                    '${folder.path}/answers/expected.json',
                  ).readAsString(),
                )
                as Map;
        final text = await File('${folder.path}/printed.txt').readAsString();
        final parsed = proposeReceiptItems(
          ReceiptPhotoText(text: text, lines: []),
          sourceId: id,
        );
        final lines = expected['lines'] as List;
        expect(parsed.items.length, lines.length);
        for (var i = 0; i < lines.length; i++) {
          final answer = lines[i] as Map;
          final actual = parsed.items[i];
          expect(actual.description, answer['description']);
          final quantity = actual.quantity!;
          expect(
            quantity.unscaledValue * 1000,
            (answer['quantityMilli'] as int) * _powerTen(quantity.scale),
          );
          final price = actual.unitPrice!;
          expect(
            price.unscaledValue * 100,
            (answer['unitPriceMinor'] as int) * _powerTen(price.scale),
          );
          expect(actual.calculatedTotalMinor, answer['grossMinor']);
          expect(actual.purchaseUnit, answer['purchaseUnit']);
          if (id == 'example-62a1c6fa') {
            expect(actual.lineTotalMinor, answer['netMinor']);
          } else {
            expect(
              actual.lineTotalMinor,
              isNull,
              reason:
                  'A receipt total is not evidence of a separate fuel line total.',
            );
          }
        }
      },
      skip: library == null
          ? 'Set RECEIPT_EXAMPLE_LIBRARY to the independent native app library.'
          : false,
    );
  }
}

int _powerTen(int scale) {
  var n = 1;
  for (var i = 0; i < scale; i++) {
    n *= 10;
  }
  return n;
}
