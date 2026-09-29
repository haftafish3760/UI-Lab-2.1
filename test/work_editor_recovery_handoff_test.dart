import 'support/document_form_navigation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/prototype_operations_store.dart';
import 'package:ui_lab_2_1/src/data/work/invoice_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/job_draft_workflow.dart';
import 'package:ui_lab_2_1/src/data/work/work_ui_lab_bootstrap.dart';
import 'package:ui_lab_2_1/src/data/work/work_primary_draft_recovery.dart';
import 'package:ui_lab_2_1/src/screens/work/work_primary_recovery_routes.dart';
import 'package:ui_lab_2_1/src/shared/operational_scope.dart';
import 'package:ui_lab_2_1/src/theme/app_theme.dart';
import 'invoice_draft_workflow_test.dart' as invoice_fixture;
import 'job_draft_workflow_test.dart' as job_fixture;
import 'support/storage/database_harness.dart';
import 'support/storage/native_widget_pump.dart';

void main() {
  for (final job in [false, true]) {
    testWidgets(
      'selected work editor job=$job retains edits without confirmation',
      (tester) async {
        final harness = (await tester.runAsync(DatabaseHarness.create))!;
        final db = (await tester.runAsync(harness.open))!;
        final work = (await tester.runAsync(() => openUiLabWorkSession(db)))!;
        final actor = work.permissions.actorEmployeeId;
        final invoice = job
            ? null
            : (await tester.runAsync(work.openInvoiceDraft))!;
        final jobWorkflow = job
            ? (await tester.runAsync(work.openJobDraft))!
            : null;
        final session = invoice?.session ?? jobWorkflow!.session;
        await tester.runAsync(() async {
          invoice?.updateInput(invoice_fixture.inputFor(actor));
          jobWorkflow?.updateInput(
            job_fixture.inputFor(null, 0, pending: true),
          );
          await session.flush();
        });
        final store = PrototypeOperationsStore(workSession: work);
        final scope = OperationalScopeController();
        Future<void>? route;
        try {
          await tester.pumpWidget(
            PrototypeOperationsScope(
              store: store,
              child: OperationalScope(
                controller: scope,
                child: MaterialApp(
                  theme: AppTheme.light,
                  home: Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => route = openPrimaryWorkRecovery(
                          context,
                          job
                              ? ResumedJobDraft(jobWorkflow!)
                              : ResumedInvoiceDraft(invoice!),
                        ),
                        child: const Text('Resume selected work'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Resume selected work'));
          await tester.pumpAndSettle();
          expect(find.textContaining('Continue an unfinished'), findsNothing);
          if (!job) await openDocumentSection(tester, 'invoice-information');
          final title = find.byKey(
            ValueKey(job ? 'job-title-field' : 'invoice-title'),
          );
          expect(title, findsOneWidget);
          if (!job) expect(session.input['discount'], '12.');
          await tester.enterText(title, 'Selected work updated');
          await finishNativeOperation(tester, session.flush);
          if (!job) await closeDocumentSection(tester);
          await tester.ensureVisible(find.byTooltip('Back to Work'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('Back to Work'));
          await tester.pumpAndSettle();
          expect(find.text('Keep your changes?'), findsOneWidget);
          await tester.tap(
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text('Save draft'),
            ),
          );
          await finishNativeOperation(tester, () => route!);
          expect(find.text('Resume selected work'), findsOneWidget);
          final saved = await tester.runAsync(
            () => work.drafts.find(
              organizationId: session.organizationId,
              domain: session.domain,
              draftId: session.draftId,
              ownerId: actor,
            ),
          );
          expect(jsonDecode(saved!.payload)['title'], 'Selected work updated');
          expect(
            work.records.where(
              (record) =>
                  record.id == (job ? 'workflow-job' : 'workflow-invoice'),
            ),
            isEmpty,
          );
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await finishNativeOperation(tester, session.close);
          store.dispose();
          work.dispose();
          scope.dispose();
          await tester.runAsync(harness.dispose);
        }
      },
    );
  }
}
