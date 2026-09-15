import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/storage/local_persistence.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_submission_session.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_evidence_draft_workflow.dart';
import 'package:ui_lab_2_1/src/screens/expenses/receipt_evidence_review_screen.dart';
import 'package:ui_lab_2_1/src/screens/expenses/expense_permissions.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'receipt_evidence_draft_workflow_test.dart'
    show openEvidenceSession, seedEvidence;
import 'support/storage/native_widget_pump.dart';

void main() {
  testWidgets(
    'evidence handoff restores undo state without changing retained evidence',
    (tester) async {
      final f = (await tester.runAsync(() async {
        final dir = await Directory.systemTemp.createTemp('evidence-handoff-');
        final p = await LocalPersistence.open(directory: dir);
        final app = await openEvidenceSession(p);
        final source = await seedEvidence(
          app,
          dir,
          bytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAIAAAD91JpzAAAAEElEQVR4nGOIqpgGRAwQCgAmfgWhCo6K7AAAAABJRU5ErkJggg==',
          ),
        );
        final workflow = await app.openEvidenceDraft(
          receiptId: source.draftId,
          expectedRevision: source.lifecycle.revision,
        );
        workflow.updateInput(workflow.input.remove(0));
        await workflow.session.flush();
        return (dir: dir, p: p, app: app, source: source, workflow: workflow);
      }))!;
      final scope = OperationalScopeController();
      try {
        await tester.pumpWidget(
          ReceiptSubmissionScope(
            session: f.app,
            child: OperationalScope(
              controller: scope,
              child: MaterialApp(
                theme: AppTheme.light,
                home: ReceiptEvidenceReviewScreen(
                  evidence: const [],
                  permissions: const ExpensePermissions.development(),
                  receiptDraftId: f.source.draftId,
                  receiptRevision: f.source.lifecycle.revision,
                  recoveredWorkflow: f.workflow,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await waitForNativeSave(
          tester,
          () => find.textContaining('Undo').evaluate().isNotEmpty,
        );
        expect(f.workflow.input.orderedEvidenceIds, hasLength(1));
        // FileImage decoding uses native I/O. Finish the preview before tearing
        // down its temporary directory, especially on Windows with file locks.
        await waitForNativeSave(
          tester,
          () => tester
              .widgetList<RawImage>(find.byType(RawImage))
              .any((image) => image.image != null),
        );
        expect(
          f.workflow.input.undoId,
          f.source.activeEvidence.first.evidenceId,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await finishNativeOperation(tester, f.workflow.session.close);
        await tester.runAsync(() async {
          final stored = (await f.app.receipts.findById(
            draftId: f.source.draftId,
          )).record!;
          expect(stored.activeEvidence, hasLength(2));
          final draft = (await f.p.drafts.find(
            organizationId: f.workflow.session.organizationId,
            ownerId: f.workflow.session.ownerId,
            domain: f.workflow.session.domain,
            draftId: f.workflow.session.draftId,
          ))!;
          expect(f.p.drafts.decode(draft), f.workflow.session.input);
        });
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        scope.dispose();
        await finishNativeOperation(tester, f.workflow.session.close);
        await tester.runAsync(() async {
          await f.p.close();
          await f.dir.delete(recursive: true);
        });
      }
    },
  );
}
