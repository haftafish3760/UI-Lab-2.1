import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_text_editing_session.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_text_entry_screen.dart';
import 'receipt_evidence_draft_workflow_test.dart' show openEvidenceSession;
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final failWrite in [false, true]) {
    testWidgets('receipt text Back retains input; write failure=$failWrite', (
      tester,
    ) async {
      late Directory root;
      late LocalPersistence persistence;
      late ReceiptTextEditingSession editor;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('receipt-text-screen-');
        persistence = await LocalPersistence.open(directory: root);
        final session = await openEvidenceSession(persistence);
        await session.receipts.create(
          draftId: 'text',
          title: 'Receipt',
          expenseDate: DateTime(2030, 1, 2),
          evidence: const [],
          occurredAtUtc: DateTime.utc(2030, 1, 2),
        );
        editor = session.openTextEditing('text');
        if (failWrite) {
          await persistence.database.customStatement(
            "CREATE TRIGGER reject_text BEFORE UPDATE ON local_records WHEN NEW.domain = 'receipt-drafts/records' BEGIN SELECT RAISE(ABORT, 'failure'); END",
          );
        }
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ReceiptTextEntryScreen(editor: editor),
                  ),
                ),
                child: const Text('Open receipt text'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open receipt text'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('receipt-pasted-text')),
        '  Partial\n12. ',
      );
      await waitForNativeSave(
        tester,
        () =>
            editor.state ==
            (failWrite ? DraftSaveState.notSaved : DraftSaveState.savedLocally),
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      if (failWrite) {
        expect(find.byType(ReceiptTextEntryScreen), findsOneWidget);
        expect(
          find.text('Latest changes have not been saved.'),
          findsOneWidget,
        );
        await tester.runAsync(
          () =>
              persistence.database.customStatement('DROP TRIGGER reject_text'),
        );
        await tester.ensureVisible(find.text('Retry save'));
        await tester.tap(find.text('Retry save'));
        await waitForNativeSave(
          tester,
          () => editor.state == DraftSaveState.savedLocally,
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      expect(find.byType(ReceiptTextEntryScreen), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await editor.close();
        await persistence.close();
        persistence = await LocalPersistence.open(directory: root);
        final reopened = await openEvidenceSession(persistence);
        final recovered = reopened.openTextEditing('text');
        expect(recovered.text, '  Partial\n12. ');
        await recovered.close();
        await persistence.close();
        await root.delete(recursive: true);
      });
    });
  }
}
