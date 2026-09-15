import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/android_receipt_regions.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_ocr_sections.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_text.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_section_reader.dart';

void main() {
  late Directory folder;
  late File original;
  final created = <File>[];
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('section-reader-test-');
    original = await File(
      '${folder.path}/original',
    ).writeAsString('original evidence');
    created.clear();
  });
  tearDown(() async {
    expect(await original.readAsString(), 'original evidence');
    for (final file in created) {
      expect(await file.exists(), isFalse);
    }
    await folder.delete(recursive: true);
  });
  final sections = [
    const ReceiptOcrSection(0, 1000, 640, 1),
    const ReceiptOcrSection(800, 1800, 640, 1),
  ];
  Future<AndroidReceiptRegion> prepare(ReceiptOcrSection section) async {
    for (final file in created) {
      expect(await file.exists(), isFalse);
    }
    final file = await File(
      '${folder.path}/section-${section.top}',
    ).writeAsString('derived');
    created.add(file);
    return AndroidReceiptRegion(file.path, 2, 2, section.top.toDouble());
  }

  ReceiptPhotoText observed() => ReceiptPhotoText(
    text: 'ELBOW',
    lines: [const ReceiptTextLine('ELBOW', 10, 20, 100, 40)],
  );

  test(
    'sections read sequentially and coordinates map to original image',
    () async {
      final result = await readReceiptSectionSequence(
        sections: sections,
        prepare: prepare,
        recognize: (_) async => observed(),
        expired: () => false,
      );
      expect(created, hasLength(2));
      expect(result.lines.map((line) => line.top), [40, 840]);
      expect(result.lines.map((line) => line.left), [20, 20]);
    },
  );

  test(
    'failure on second recognition rejects first result and deletes both copies',
    () async {
      var calls = 0;
      await expectLater(
        readReceiptSectionSequence(
          sections: sections,
          prepare: prepare,
          recognize: (_) async {
            if (++calls == 2) throw StateError('native failure');
            return observed();
          },
          expired: () => false,
        ),
        throwsStateError,
      );
      expect(created, hasLength(2));
    },
  );

  test(
    'timeout waits for in-flight native work then deletes copy without another section',
    () async {
      final started = Completer<void>();
      final native = Completer<ReceiptPhotoText>();
      var expired = false;
      final task = readReceiptSectionSequence(
        sections: sections,
        prepare: prepare,
        recognize: (_) {
          started.complete();
          return native.future;
        },
        expired: () => expired,
      );
      final rejected = expectLater(
        task,
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      await started.future;
      expired = true;
      expect(await created.single.exists(), isTrue);
      native.complete(observed());
      await rejected;
      expect(created, hasLength(1));
    },
  );

  test(
    'timeout during preparation cleans the copy without starting recognition',
    () async {
      var expired = false;
      var reads = 0;
      await expectLater(
        readReceiptSectionSequence(
          sections: sections,
          prepare: (section) async {
            final copy = await prepare(section);
            expired = true;
            return copy;
          },
          recognize: (_) async {
            reads++;
            return observed();
          },
          expired: () => expired,
        ),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(reads, 0);
      expect(created, hasLength(1));
    },
  );

  test('preparation failure never returns earlier sections', () async {
    var preparations = 0;
    await expectLater(
      readReceiptSectionSequence(
        sections: sections,
        prepare: (section) {
          if (++preparations == 2) throw const FileSystemException('disk full');
          return prepare(section);
        },
        recognize: (_) async => observed(),
        expired: () => false,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(created, hasLength(1));
  });
}
