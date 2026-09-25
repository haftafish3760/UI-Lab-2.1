import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:ui_lab_2_1/src/data/receipts/image_pipeline/receipt_image_processor.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_service.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resource refusal happens before touching receipt inputs', () async {
    final workloads = DeviceWorkloadService(
      probe: () async =>
          const DeviceWorkloadProfile(freeStorageBytes: 100 * 1024 * 1024),
    );
    await expectLater(
      ReceiptStitchService(
        workloads: workloads,
      ).stitch(paths: const ['missing_a.png', 'missing_b.png']),
      throwsA(isA<DeviceWorkloadUnavailable>()),
    );
    expect(workloads.busy, isFalse);
    await workloads.dispose();
  });

  test('cancelled stitch never starts image decoding', () async {
    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: const ['missing_a.png', 'missing_b.png'],
      nativeRegistrationProposals: const [],
      shouldCancel: () => true,
    );
    expect(result.fallbackReasonCode, 'stitch_cancelled');
  });

  test(
    'periodic identical rows cannot authorize an arbitrary automatic seam',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt_repeat_test_',
      );
      final paths = <String>[];
      for (var section = 0; section < 2; section++) {
        final image = img.Image(width: 400, height: 800);
        img.fill(image, color: img.ColorRgb8(245, 245, 245));
        for (var row = 0; row < 16; row++) {
          img.drawString(
            image,
            'COPPER ELBOW 2.49',
            font: img.arial24,
            x: 20,
            y: 10 + row * 50,
            color: img.ColorRgb8(20, 20, 20),
          );
        }
        // Different bytes, with no unique identifying mark in the overlap.
        image.setPixelRgb(399, section == 0 ? 0 : 799, 230, 230, 230);
        final file = File(p.join(directory.path, 'section_$section.png'));
        await file.writeAsBytes(img.encodePng(image));
        paths.add(file.path);
      }
      final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
        paths: paths,
        maxTargetWidth: 400,
        nativeRegistrationProposals: const [],
        processingTimeout: const Duration(seconds: 40),
      );
      expect(
        result.didStitch,
        isFalse,
        reason: 'Repeated rows have several equally plausible placements.',
      );
      expect(result.ocrSourcePaths, paths);
    },
  );

  test('automatic stitch finds known overlap in two receipt images', () async {
    final directory = await Directory.systemTemp.createTemp(
      'receipt_auto_test_',
    );
    final receipt = img.Image(width: 400, height: 1200);
    img.fill(receipt, color: img.ColorRgb8(245, 245, 245));
    const products = [
      'COPPER ELBOW',
      'PVC TEE',
      'PAINT BRUSH',
      'STEEL BOLT',
      'PINE BOARD',
      'WIRE SPOOL',
      'DRAIN PIPE',
    ];
    for (var row = 0; row < 23; row++) {
      img.drawString(
        receipt,
        '${products[row % products.length]} ${row + 1}.49',
        font: img.arial24,
        x: 20,
        y: 25 + row * 50,
        color: img.ColorRgb8(20, 20, 20),
      );
    }
    final paths = <String>[];
    for (final y in [0, 400]) {
      final file = File(p.join(directory.path, 'section_$y.png'));
      await file.writeAsBytes(
        img.encodePng(
          img.copyCrop(receipt, x: 0, y: y, width: 400, height: 800),
        ),
      );
      paths.add(file.path);
    }
    final result = await ReceiptImageProcessor.stitchReceiptPhotosForOcr(
      paths: paths,
      maxTargetWidth: 400,
      nativeRegistrationProposals: const [],
      processingTimeout: const Duration(seconds: 40),
    );
    expect(result.didStitch, isTrue, reason: result.fallbackReasonCode);
    expect(result.stitchedHeight, closeTo(1200, 12));
    expect(result.pairs.single.overlapPixels, closeTo(400, 12));
  });

  test(
    'real image composition writes a decodable receipt and keeps originals',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'receipt_port_test_',
      );
      final paths = <String>[];
      final originals = <List<int>>[];
      for (var section = 0; section < 2; section++) {
        final image = img.Image(width: 320, height: 600);
        img.fill(image, color: img.ColorRgb8(245, 245, 245));
        for (var row = 0; row < 10; row++) {
          img.drawString(
            image,
            'ITEM ${section * 10 + row}  12.50',
            font: img.arial24,
            x: 20,
            y: 30 + row * 50,
            color: img.ColorRgb8(20, 20, 20),
          );
        }
        final bytes = img.encodePng(image);
        final file = File(p.join(directory.path, 'section_$section.png'));
        await file.writeAsBytes(bytes);
        paths.add(file.path);
        originals.add(bytes);
      }
      final workloads = DeviceWorkloadService(
        probe: () async => const DeviceWorkloadProfile(
          physicalRamMb: 4096,
          availableRamMb: 2048,
          freeStorageBytes: 1024 * 1024 * 1024,
          thermal: 'nominal',
        ),
      );
      final result = await ReceiptStitchService(
        workloads: workloads,
      ).stitch(paths: paths, manualZeroOverlapPairs: const [true]);
      expect(workloads.busy, isFalse);
      await workloads.dispose();
      expect(result.didStitch, isTrue, reason: result.fallbackReasonCode);
      final output = img.decodeImage(
        await File(result.stitchedPath!).readAsBytes(),
      );
      expect(output, isNotNull);
      expect(output!.width, result.stitchedWidth);
      expect(output.height, result.stitchedHeight);
      expect(output.height, greaterThan(600));
      for (var index = 0; index < paths.length; index++) {
        expect(await File(paths[index]).readAsBytes(), originals[index]);
      }
    },
  );
}
