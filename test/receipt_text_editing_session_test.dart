import 'dart:io';
import 'package:ui_lab_2_1/src/data/receipts/receipt_submission_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/storage/draft_autosave_session.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_text_editing_session.dart';
import 'receipt_evidence_draft_workflow_test.dart' show openEvidenceSession;

void main() {
  late Directory root;
  late LocalPersistence persistence;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('receipt-text-');
    persistence = await LocalPersistence.open(directory: root);
  });
  tearDown(() async {
    await persistence.close();
    await root.delete(recursive: true);
  });

  Future<ReceiptSubmissionSession> seed() async {
    final session = await openEvidenceSession(persistence);
    await session.receipts.create(
      draftId: 'receipt-text',
      title: 'Receipt',
      expenseDate: DateTime(2030, 1, 2),
      evidence: const [],
      occurredAtUtc: DateTime.utc(2030, 1, 2),
    );
    return session;
  }

  test(
    'rapid raw edits drain on pause and survive reopening without confirmation',
    () async {
      final session = await seed();
      final ReceiptTextEditingSession editor = session.openTextEditing(
        'receipt-text',
      );
      editor.updateText('1');
      editor.updateText('12.');
      editor.updateText('  Unfinished receipt\n12.  ');
      final pause = await persistence.database.draftSessions.pauseAndFlush();
      expect(editor.state, DraftSaveState.savedLocally);
      expect(() => editor.updateText('rejected'), throwsStateError);
      pause.release();
      await editor.close();
      await persistence.close();
      persistence = await LocalPersistence.open(directory: root);
      final reopened = await openEvidenceSession(persistence);
      final recovered = reopened.openTextEditing('receipt-text');
      expect(recovered.text, '  Unfinished receipt\n12.  ');
      expect(recovered.savedReceipt.lifecycle.revision, 4);
      expect(
        await persistence.database
            .customSelect(
              "SELECT * FROM local_records WHERE domain LIKE 'expenses/%'",
            )
            .get(),
        isEmpty,
      );
      await recovered.close();
    },
  );

  test(
    'write failure blocks switch, retains latest input and permits explicit retry',
    () async {
      final session = await seed();
      final ReceiptTextEditingSession editor = session.openTextEditing(
        'receipt-text',
      );
      await persistence.database.customStatement(
        "CREATE TRIGGER fail_text BEFORE UPDATE ON local_records WHEN NEW.domain = 'receipt-drafts/records' BEGIN SELECT RAISE(ABORT, 'failure'); END",
      );
      editor.updateText('first');
      await expectLater(editor.flush(), throwsStateError);
      editor.updateText('latest unfinished');
      expect(editor.text, 'latest unfinished');
      expect(editor.state, DraftSaveState.notSaved);
      await expectLater(
        persistence.database.draftSessions.pauseAndFlush(),
        throwsStateError,
      );
      await persistence.database.customStatement('DROP TRIGGER fail_text');
      editor.retry();
      await editor.flush();
      expect(editor.savedReceipt.entrySetup!.pastedText, 'latest unfinished');
      expect(editor.savedReceipt.lifecycle.revision, 2);
      editor.retry();
      editor.updateText('latest unfinished');
      await editor.flush();
      expect(editor.savedReceipt.lifecycle.revision, 2);
      await editor.close();
      expect(() => editor.updateText('after close'), throwsStateError);
    },
  );

  test('stale editor cannot overwrite another edit, even on retry', () async {
    final session = await seed();
    final ReceiptTextEditingSession first = session.openTextEditing(
      'receipt-text',
    );
    final ReceiptTextEditingSession stale = session.openTextEditing(
      'receipt-text',
    );
    first.updateText('saved by first');
    await first.flush();
    stale.updateText('unfinished stale text');
    await expectLater(stale.flush(), throwsStateError);
    stale.retry();
    await expectLater(stale.flush(), throwsStateError);
    expect(stale.text, 'unfinished stale text');
    expect(
      session.receipts.recordById('receipt-text')!.entrySetup!.pastedText,
      'saved by first',
    );
    await first.close();
    // Failed input intentionally stays registered: installation switching must
    // refuse it until the owner explicitly resolves or discards the conflict.
    await expectLater(
      persistence.database.draftSessions.pauseAndFlush(),
      throwsStateError,
    );
    await stale.discardUnsavedAndClose();
    final pause = await persistence.database.draftSessions.pauseAndFlush();
    pause.release();
    expect(
      session.receipts.recordById('receipt-text')!.entrySetup!.pastedText,
      'saved by first',
    );
  });
}
