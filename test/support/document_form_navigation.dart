import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/document_form_section.dart';

import 'storage/native_widget_pump.dart';

Future<void> openDocumentSection(WidgetTester tester, String key) async {
  if (find.byType(DocumentSectionEditor).evaluate().isNotEmpty) {
    await closeDocumentSection(tester);
  }
  final tile = find.byKey(ValueKey(key));
  await waitForNativeSave(tester, () => tile.evaluate().isNotEmpty);
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> closeDocumentSection(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final done = find.byKey(const ValueKey('document-section-done'));
  await tester.ensureVisible(done);
  await tester.pumpAndSettle();
  await tester.tap(done);
  await waitForNativeSave(
    tester,
    () => find.byType(DocumentSectionEditor).evaluate().isEmpty,
  );
  await tester.pumpAndSettle();
}
