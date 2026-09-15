import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_reader.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_item_parser.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_item_proposal.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_parsed_items.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_photo_text_panel.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'receipt_item_read_recovery_test.dart' show exampleItemRead;

class _Reader implements ReceiptPhotoReader {
  @override
  bool get supported => true;
  final requests = <Completer<ReceiptPhotoText>>[];
  @override
  Future<ReceiptPhotoText> read(String path) {
    final request = Completer<ReceiptPhotoText>();
    requests.add(request);
    return request.future;
  }
}

Widget _host(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets(
    'restored photo observations display without starting OCR again',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final read = exampleItemRead('photo', 'a' * 64);
      final reader = _Reader();
      await tester.pumpWidget(
        _host(
          ReceiptPhotoTextPanel(
            path: 'retained-photo',
            sourceId: 'photo',
            initialRead: read,
            reader: reader,
            autoRead: true,
          ),
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      expect(reader.requests, isEmpty);
      expect(find.text('Items found: 1'), findsOneWidget);
      expect(find.text('Copper fitting'), findsOneWidget);
      expect(find.text('Price for one: 3.499'), findsOneWidget);
      expect(find.text('Printed line amount: 7.00'), findsOneWidget);
      expect(find.text('Calculated line amount: 7.00'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reading publishes proposals with unknown fields and clears busy state',
    (tester) async {
      final reader = _Reader();
      final busy = <bool>[];
      ReceiptItemParseResult? received;
      await tester.pumpWidget(
        _host(
          ReceiptPhotoTextPanel(
            path: 'photo',
            reader: reader,
            sourceId: 'photo-id',
            onReadingChanged: busy.add,
            onItemsRead: (_, result) => received = result,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('read-receipt-photo')));
      await tester.pump();
      expect(busy, [true]);
      reader.requests.single.complete(
        ReceiptPhotoText(text: 'MYSTERY PART 7.00\nTOTAL 7.00', lines: []),
      );
      await tester.pumpAndSettle();
      expect(busy, [true, false]);
      expect(received!.items.single.quantity, isNull);
      expect(received!.items.single.unitPrice, isNull);
      expect(find.text('Quantity: Not read'), findsOneWidget);
      expect(find.text('Price for one: Not read'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('item suggestions show a bounded first group and allow more', (
    tester,
  ) async {
    final text = List.generate(
      80,
      (i) => 'PART $i 1 each x 1.23 1.23',
    ).join('\n');
    final result = proposeReceiptItems(
      ReceiptPhotoText(text: text, lines: []),
      sourceId: 'long',
    );
    expect(result.items.length, 80);
    await tester.pumpWidget(_host(ReceiptParsedItems(result: result)));
    await tester.pumpAndSettle();
    expect(find.text('Items found: 80'), findsOneWidget);
    expect(find.text('PART 9'), findsOneWidget);
    expect(find.text('PART 10'), findsNothing);
    await tester.ensureVisible(find.text('Show more items'));
    await tester.tap(find.text('Show more items'));
    await tester.pumpAndSettle();
    expect(find.text('PART 34'), findsOneWidget);
    expect(find.text('PART 35'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a disposed photo clears its busy state and cannot publish late items',
    (tester) async {
      final reader = _Reader();
      final busy = <bool>[];
      var delivered = 0;
      await tester.pumpWidget(
        _host(
          ReceiptPhotoTextPanel(
            path: 'photo',
            reader: reader,
            onReadingChanged: busy.add,
            onItemsRead: (_, _) => delivered++,
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('read-receipt-photo')));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      reader.requests.single.complete(
        ReceiptPhotoText(text: 'PART 1 each x 1.00 1.00', lines: []),
      );
      await tester.pumpAndSettle();
      expect(busy, [true, false]);
      expect(delivered, 0);
    },
  );
}
