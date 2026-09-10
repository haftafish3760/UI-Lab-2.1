import 'dart:io';

import 'package:flutter/services.dart';

/// Geometry checks use the shipped Material font, not Flutter test's Ahem
/// square glyphs, which wrap ordinary vehicle names and currency differently.
Future<void> loadMaterialTestFont() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) throw StateError('Run these tests using flutter test.');
  final font = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  final loader = FontLoader('Roboto');
  loader.addFont(
    font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
  );
  await loader.load();
}
