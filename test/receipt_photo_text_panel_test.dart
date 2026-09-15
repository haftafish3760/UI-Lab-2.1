import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_reader.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_field_proposals.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_photo_text_panel.dart';
import 'package:ui_lab_2_1/src/shared/local_document_path_scope.dart';

class _Reader implements ReceiptPhotoReader {
  @override
  bool supported = true;
  final requests = <Completer<ReceiptPhotoText>>[];
  final paths = <String>[];
  @override
  Future<ReceiptPhotoText> read(String path) {
    paths.add(path);
    final pending = Completer<ReceiptPhotoText>();
    requests.add(pending);
    return pending.future;
  }
}

void main() {
  testWidgets('saved opt-in starts one read, rebuilds never repeat it', (
    tester,
  ) async {
    final reader = _Reader();
    Widget host(String path) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReceiptPhotoTextPanel(
            path: path,
            reader: reader,
            autoRead: true,
          ),
        ),
      ),
    );
    await tester.pumpWidget(host('first'));
    await tester.pump();
    expect(reader.paths, ['first']);
    await tester.pumpWidget(host('first'));
    await tester.pump();
    expect(reader.paths, ['first']);
    reader.requests.first.complete(
      ReceiptPhotoText(text: 'TOTAL 12.00', lines: []),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(host('second'));
    await tester.pump();
    expect(reader.paths, ['first', 'second']);
    reader.requests.last.complete(
      ReceiptPhotoText(text: 'TOTAL 24.00', lines: []),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'suggested details require selection and expire when photo changes',
    (tester) async {
      final reader = _Reader();
      ReceiptFieldProposals? selected;
      Widget panel(String path) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReceiptPhotoTextPanel(
              path: path,
              reader: reader,
              onUseDetails: (value) => selected = value,
            ),
          ),
        ),
      );
      await tester.pumpWidget(panel('first'));
      await tester.tap(find.text('Read photo'));
      reader.requests.single.complete(
        ReceiptPhotoText(text: 'Juniper Tool Counter\nTOTAL 12.30', lines: []),
      );
      await tester.pumpAndSettle();
      expect(selected, isNull);
      final use = find.byKey(const ValueKey('use-receipt-suggested-details'));
      await tester.ensureVisible(use);
      await tester.tap(use);
      expect(selected?.totalMinor, 1230);
      expect(selected?.merchant, 'Juniper Tool Counter');
      await tester.pumpWidget(panel('second'));
      expect(use, findsNothing);
      expect(find.text('Store: Juniper Tool Counter'), findsNothing);
    },
  );
  testWidgets(
    'retained references use the authoritative restored-file resolver',
    (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(
          home: LocalDocumentPathScope(
            resolve: (reference) => 'restored/$reference',
            child: Scaffold(
              body: ReceiptPhotoTextPanel(
                path: 'evidence/photo',
                reader: reader,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Read photo'));
      expect(reader.paths, ['restored/evidence/photo']);
      reader.requests.single.complete(
        ReceiptPhotoText(text: 'Receipt', lines: []),
      );
      await tester.pumpAndSettle();
    },
  );
  Widget host(_Reader reader, {String path = 'photo-a'}) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ReceiptPhotoTextPanel(path: path, reader: reader),
      ),
    ),
  );

  testWidgets(
    'reading is opt-in and duplicate taps do not start another read',
    (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(host(reader));
      expect(reader.requests, isEmpty);
      await tester.tap(find.text('Read photo'));
      await tester.pump();
      expect(reader.requests, hasLength(1));
      await tester.tap(find.text('Reading photo…'));
      expect(reader.requests, hasLength(1));
      reader.requests.single.complete(
        ReceiptPhotoText(text: 'BIG BOX A\nTOTAL 12.30', lines: []),
      );
      await tester.pumpAndSettle();
      expect(find.text('BIG BOX A\nTOTAL 12.30'), findsOneWidget);
      expect(find.textContaining('has not been added'), findsOneWidget);
    },
  );

  testWidgets(
    'a result from a replaced image never appears under the new image',
    (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(host(reader));
      await tester.tap(find.text('Read photo'));
      await tester.pumpWidget(host(reader, path: 'photo-b'));
      reader.requests.single.complete(
        ReceiptPhotoText(text: 'WRONG PHOTO', lines: []),
      );
      await tester.pumpAndSettle();
      expect(find.text('WRONG PHOTO'), findsNothing);
      expect(find.text('Read photo'), findsOneWidget);
    },
  );

  testWidgets(
    'failure can be retried and empty text is not reported as success',
    (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(host(reader));
      await tester.tap(find.text('Read photo'));
      reader.requests.single.completeError(StateError('native failure'));
      await tester.pumpAndSettle();
      expect(find.textContaining('could not be read'), findsOneWidget);
      await tester.tap(find.text('Read photo'));
      reader.requests.last.complete(ReceiptPhotoText(text: '', lines: []));
      await tester.pumpAndSettle();
      expect(find.text('No readable text found'), findsOneWidget);
    },
  );

  testWidgets('unsupported platforms preserve manual entry guidance', (
    tester,
  ) async {
    final reader = _Reader()..supported = false;
    await tester.pumpWidget(host(reader));
    expect(find.text('Read photo'), findsNothing);
    expect(find.textContaining('enter the expense manually'), findsOneWidget);
    expect(reader.requests, isEmpty);
  });

  testWidgets('320 logical pixels with large text reflows without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ReceiptPhotoTextPanel(path: 'photo', reader: _Reader()),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
