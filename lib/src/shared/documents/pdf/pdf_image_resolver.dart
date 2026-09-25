import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

enum PdfImageIssue { missing, unsupported, corrupt, tooLarge }

class PdfResolvedImage {
  PdfResolvedImage(Uint8List bytes, this.width, this.height)
    : _bytes = Uint8List.fromList(bytes);
  final Uint8List _bytes;
  Uint8List get bytes => Uint8List.fromList(_bytes);
  final int width, height;
  ({double width, double height}) fit(double maxWidth, double maxHeight) {
    final scale = math.min(maxWidth / width, maxHeight / height);
    return (width: width * scale, height: height * scale);
  }
}

class PdfImageResult {
  const PdfImageResult({this.image, this.issue});
  final PdfResolvedImage? image;
  final PdfImageIssue? issue;
}

/// Decoding creates a derived render image; it never modifies original evidence.
class PdfImageResolver {
  const PdfImageResolver({
    this.maxBytes = 12 * 1024 * 1024,
    this.maxPixels = 24000000,
    this.maxDimension = 1600,
    this.allowCommonFormats = false,
  });
  final int maxBytes, maxPixels, maxDimension;
  final bool allowCommonFormats;
  Future<PdfImageResult> resolve(Future<Uint8List?> Function() read) async {
    try {
      return decode(await read());
    } on Object {
      return const PdfImageResult(issue: PdfImageIssue.missing);
    }
  }

  PdfImageResult decode(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      return const PdfImageResult(issue: PdfImageIssue.missing);
    }
    if (bytes.length > maxBytes) {
      return const PdfImageResult(issue: PdfImageIssue.tooLarge);
    }
    try {
      final png =
          bytes.length > 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final jpeg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if (!png && !jpeg && !allowCommonFormats) {
        return const PdfImageResult(issue: PdfImageIssue.unsupported);
      }
      final decoder = allowCommonFormats
          ? img.findDecoderForData(bytes)
          : png
          ? img.PngDecoder()
          : img.JpegDecoder();
      if (decoder == null) {
        return const PdfImageResult(issue: PdfImageIssue.unsupported);
      }
      final info = decoder.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) {
        return const PdfImageResult(issue: PdfImageIssue.corrupt);
      }
      if (info.width * info.height > maxPixels) {
        return const PdfImageResult(issue: PdfImageIssue.tooLarge);
      }
      final decoded = decoder.decodeFrame(0);
      if (decoded == null) {
        return const PdfImageResult(issue: PdfImageIssue.corrupt);
      }
      final oriented = img.bakeOrientation(decoded);
      final scale = math.min(
        1.0,
        maxDimension / math.max(oriented.width, oriented.height),
      );
      final resized = scale == 1
          ? oriented
          : img.copyResize(
              oriented,
              width: math.max(1, (oriented.width * scale).round()),
              height: math.max(1, (oriented.height * scale).round()),
              interpolation: img.Interpolation.average,
            );
      return PdfImageResult(
        image: PdfResolvedImage(
          img.encodePng(resized),
          resized.width,
          resized.height,
        ),
      );
    } on Object {
      return const PdfImageResult(issue: PdfImageIssue.corrupt);
    }
  }
}
