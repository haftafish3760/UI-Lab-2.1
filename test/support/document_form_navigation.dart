import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';

import 'storage/native_widget_pump.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_form_section.dart';
import 'package:ui_lab_2_1/src/screens/work/estimate_price_summary.dart';

Future<void> openDocumentSection(WidgetTester tester, String key) async {
  if (find.byType(DocumentSectionEditor).evaluate().isNotEmpty) {
    await closeDocumentSection(tester);
  }
  final tile = find.byKey(ValueKey(key));
  await waitForNativeSave(tester, () => tile.evaluate().isNotEmpty);
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  if (tester.widget(tile) is EstimateFormSection ||
      tester.widget(tile) is EstimatePriceSummary) {
    final action = find
        .descendant(of: tile, matching: find.byType(TextButton))
        .first;
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    await tester.tap(action);
  } else {
    await tester.tap(tile);
  }
  await tester.pumpAndSettle();
}

Future<void> closeDocumentSection(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final done = find.byKey(const ValueKey('document-section-done'));
  if (done.evaluate().isEmpty) return;
  await tester.ensureVisible(done);
  await tester.pumpAndSettle();
  await tester.tap(done);
  await waitForNativeSave(
    tester,
    () => find.byType(DocumentSectionEditor).evaluate().isEmpty,
  );
  await tester.pumpAndSettle();
}
