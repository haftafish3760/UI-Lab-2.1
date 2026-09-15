import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_ocr_image.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_read_cancellation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired preparation performs no source-file access', () async {
    await expectLater(
      ReceiptOcrImage.prepare(
        'unavailable-photo-must-not-be-opened',
        const DeviceWorkloadProfile(),
        checkActive: () => requireReceiptReadActive(() => true),
      ),
      throwsA(isA<DeviceWorkloadUnavailable>()),
    );
  });
  test(
    'OCR copy obeys pixel budget, maps coordinates and preserves original',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'receipt-image-test-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final sourceImage = await picture.toImage(2000, 1000);
      final bytes = (await sourceImage.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();
      sourceImage.dispose();
      picture.dispose();
      final original = File(
        '${folder.path}${Platform.pathSeparator}original.png',
      );
      await original.writeAsBytes(bytes);
      final copy = await ReceiptOcrImage.prepare(
        original.path,
        const DeviceWorkloadProfile(),
      );
      final buffer = await ui.ImmutableBuffer.fromFilePath(copy.path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      expect(descriptor.width * descriptor.height, lessThanOrEqualTo(1000000));
      expect(descriptor.width * copy.scaleX, closeTo(2000, 0.01));
      expect(descriptor.height * copy.scaleY, closeTo(1000, 0.01));
      descriptor.dispose();
      buffer.dispose();
      await copy.dispose();
      expect(await File(copy.path).exists(), isFalse);
      expect(await original.readAsBytes(), bytes);
    },
  );
}
