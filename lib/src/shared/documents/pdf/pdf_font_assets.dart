import 'package:flutter/services.dart';

/// Offline, versioned font resources shared by every document builder.
class PdfFontAssets {
  const PdfFontAssets(this.regular, this.bold);
  final ByteData regular, bold;
  static Future<PdfFontAssets> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    return PdfFontAssets(
      await assets.load('assets/document_templates/NotoSans-Regular.ttf'),
      await assets.load('assets/document_templates/NotoSans-Bold.ttf'),
    );
  }
}
