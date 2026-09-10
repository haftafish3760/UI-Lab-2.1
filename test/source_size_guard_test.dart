import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authored Dart files stay at or below 500 lines', () {
    const maximumLines = 500;
    const generatedFiles = {
      'lib/l10n/app_localizations.dart',
      'lib/l10n/app_localizations_en.dart',
      'lib/l10n/app_localizations_es.dart',
      'lib/l10n/app_localizations_fr.dart',
      // Drift owns this generated schema mapping; authored SQL/Dart remains checked.
      'lib/src/data/storage/local_database.g.dart',
    };
    final oversized = <String>[];

    for (final root in const ['lib', 'test']) {
      for (final entity in Directory(root).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (generatedFiles.contains(entity.path)) continue;
        final lineCount = entity.readAsLinesSync().length;
        if (lineCount > maximumLines) {
          oversized.add('${entity.path}: $lineCount lines');
        }
      }
    }

    expect(
      oversized,
      isEmpty,
      reason:
          'Split files at cohesive responsibility boundaries before they exceed '
          '$maximumLines lines:\n'
          '${oversized.join('\n')}',
    );
  });
}
