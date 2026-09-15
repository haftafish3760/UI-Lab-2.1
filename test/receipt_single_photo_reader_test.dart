import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_ocr_image.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_photo_text.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_single_photo_reader.dart';

void main() {
  late Directory folder;
  late File original;
  final copies = <String>[];
  setUp(() async {
    folder = await Directory.systemTemp.createTemp('single-receipt-read-');
    original = await File.fromUri(
      folder.uri.resolve('original'),
    ).writeAsString('original evidence');
    copies.clear();
  });
  tearDown(() async {
    expect(await original.readAsString(), 'original evidence');
    for (final path in copies) {
      expect(await File(path).exists(), isFalse);
    }
    await folder.delete(recursive: true);
  });

  Future<ReceiptOcrImage> prepare() async {
    final temporary = await folder.createTemp('derived-');
    final file = await File.fromUri(
      temporary.uri.resolve('photo'),
    ).writeAsString('temporary copy');
    copies.add(file.path);
    return ReceiptOcrImage(file.path, 2, 3, temporary);
  }

  ReceiptPhotoText observed() => ReceiptPhotoText(
    text: 'ELBOW 3.49',
    lines: [const ReceiptTextLine('ELBOW 3.49', 10, 20, 100, 40)],
    warnings: ['Review this observation'],
  );

  test(
    'ordinary photo maps evidence coordinates and cleans its copy',
    () async {
      final result = await readReceiptSinglePhoto(
        prepare: prepare,
        recognize: (path) async {
          expect(await File(path).exists(), isTrue);
          return observed();
        },
        expired: () => false,
      );
      expect(result.text, 'ELBOW 3.49');
      expect(result.warnings, ['Review this observation']);
      final line = result.lines.single;
      expect(
        [line.left, line.top, line.right, line.bottom],
        [20, 60, 200, 120],
      );
    },
  );

  test(
    'expired request schedules neither preparation nor recognition',
    () async {
      await expectLater(
        readReceiptSinglePhoto(
          prepare: () async => fail('Expired request prepared an image'),
          recognize: (_) async => fail('Expired request started recognition'),
          expired: () => true,
        ),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(copies, isEmpty);
    },
  );

  test(
    'expiry during preparation cleans the copy without recognition',
    () async {
      var expired = false;
      await expectLater(
        readReceiptSinglePhoto(
          prepare: () async {
            final image = await prepare();
            expired = true;
            return image;
          },
          recognize: (_) async => fail('Late preparation started recognition'),
          expired: () => expired,
        ),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(copies, hasLength(1));
    },
  );

  test('preparation failure never starts recognition', () async {
    await expectLater(
      readReceiptSinglePhoto(
        prepare: () async => throw const FileSystemException('disk full'),
        recognize: (_) async => fail('Failed preparation started recognition'),
        expired: () => false,
      ),
      throwsA(isA<FileSystemException>()),
    );
    expect(copies, isEmpty);
  });

  test('recognition failure cleans the copy and returns no result', () async {
    await expectLater(
      readReceiptSinglePhoto(
        prepare: prepare,
        recognize: (_) async => throw StateError('native failure'),
        expired: () => false,
      ),
      throwsStateError,
    );
    expect(copies, hasLength(1));
  });

  test(
    'UI timeout holds the workload gate through late native completion and cleanup',
    () async {
      final service = DeviceWorkloadService(
        probe: () async => const DeviceWorkloadProfile(),
      );
      final started = Completer<void>();
      final native = Completer<ReceiptPhotoText>();
      final cleanupStarted = Completer<void>();
      final allowCleanup = Completer<void>();
      var expired = false;
      final operation = service.run(
        (_) => readReceiptSinglePhoto(
          prepare: () async {
            final image = await prepare();
            return _DelayedCleanup(image, cleanupStarted, allowCleanup);
          },
          recognize: (_) {
            started.complete();
            return native.future;
          },
          expired: () => expired,
        ),
      );
      final rejected = expectLater(
        operation,
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      await started.future;
      await expectLater(
        operation.timeout(
          Duration.zero,
          onTimeout: () {
            expired = true;
            throw const DeviceWorkloadUnavailable('expired');
          },
        ),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      expect(service.busy, isTrue);
      expect(await File(copies.single).exists(), isTrue);
      await expectLater(
        service.run((_) async => fail('Second native read admitted')),
        throwsA(isA<DeviceWorkloadUnavailable>()),
      );
      native.complete(observed());
      await cleanupStarted.future;
      expect(service.busy, isTrue);
      allowCleanup.complete();
      await rejected;
      expect(service.busy, isFalse);
    },
  );
}

class _DelayedCleanup extends ReceiptOcrImage {
  _DelayedCleanup(this.image, this.started, this.proceed)
    : super(image.path, image.scaleX, image.scaleY, File(image.path).parent);
  final ReceiptOcrImage image;
  final Completer<void> started, proceed;
  @override
  Future<void> dispose() async {
    started.complete();
    await proceed.future;
    await image.dispose();
  }
}
