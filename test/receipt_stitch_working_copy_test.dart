import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ui_lab_2_1/src/data/receipts/receipt_stitch_working_copy.dart';
import 'package:ui_lab_2_1/src/data/device_capabilities/device_workload_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'large source is reduced to the batch budget without changing original bytes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'stitch_large_source_',
      );
      final source = File(
        '${directory.path}${Platform.pathSeparator}photo.jpg',
      );
      final image = img.Image(width: 2400, height: 3200);
      img.fill(image, color: img.ColorRgb8(245, 245, 245));
      img.drawString(
        image,
        'GENERIC BUILDING SUPPLIES',
        font: img.arial48,
        x: 80,
        y: 100,
        color: img.ColorRgb8(0, 0, 0),
      );
      final bytes = img.encodeJpg(image);
      await source.writeAsBytes(bytes);
      var writeCheckpoints = 0;
      final copy = await ReceiptStitchWorkingCopy.prepare(
        path: source.path,
        maxPixels: 800000,
        profile: const DeviceWorkloadProfile(),
        checkActive: () {},
        beforeWrite: () async {
          writeCheckpoints++;
        },
      );
      expect(copy.path, isNot(source.path));
      expect(copy.pixels, lessThanOrEqualTo(800000));
      expect(copy.pixels, greaterThan(790000));
      expect(writeCheckpoints, 1);
      expect(await source.readAsBytes(), bytes);
      final working = img.decodePng(await File(copy.path).readAsBytes())!;
      expect(working.width / working.height, closeTo(.75, .002));
    },
  );
}
