import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_contact_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_export_audit.dart';
import 'package:ui_lab_2_1/src/screens/work/documents/document_pdf_assets.dart';
import 'package:ui_lab_2_1/src/screens/work/work_customer_document.dart';
import 'package:ui_lab_2_1/src/shared/documents/document_source.dart';
import 'package:ui_lab_2_1/src/shared/documents/pdf/pdf_export_service.dart';

import '../test/support/storage/database_harness.dart';
import '../test/support/storage/seeded_work_fixture.dart';

/// Opt-in device QA: opens a composer with a synthetic estimate but never sends.
/// An optional inspection interval lets the operator inspect/dismiss the native
/// chooser and copy the generated PDF before this isolated runner is removed.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  test(
    'native email handoff retains PDF and never marks estimate sent',
    () async {
      if (!Platform.isAndroid ||
          !const bool.fromEnvironment('STORAGE_QA') ||
          !const bool.fromEnvironment('VERIFY_NATIVE_COMPOSER')) {
        throw StateError(
          'Requires isolated Android QA and explicit composer opt-in.',
        );
      }
      final harness = await DatabaseHarness.create();
      final db = await harness.open();
      final work = await openSeededTestWorkSession(db);
      try {
        final record = work.records.firstWhere((r) => r.id == 'est-1041');
        final revision = work.storageRevisionFor(record.id);
        final audit = WorkExportAudit(work);
        final document = workCustomerDocument(
          record,
          demoWorkCompany,
          demoWorkCustomers.where((c) => c.name == record.client).firstOrNull,
        );
        final bytes = await generateCustomerPdf(document);
        final attempt = await audit.begin(record.id, revision, 'share');
        final outcome = await const PdfExportService().export(
          DocumentSource(
            origin: DocumentOrigin.generated,
            fileName: 'QA-estimate-do-not-send',
            authorize: () => audit.assertCurrent(record.id, revision),
            readBytes: () async => bytes,
          ),
          PdfExportAction.share,
          composeMethod: 'email',
          recipient: 'estimate-qa@example.invalid',
          subject: 'QA estimate - do not send',
          text: 'Synthetic device verification only. Do not send.',
        );
        expect(outcome, PdfExportOutcome.unconfirmed);
        await audit.finish(attempt, outcome.name);
        expect(work.storageRevisionFor(record.id), revision);
        expect(work.records.firstWhere((r) => r.id == record.id), record);
        expect(
          (await audit.read(record.id)).single.changes.single,
          contains('without a confirmed result'),
        );
        // This delay is only for an explicitly requested native inspection run.
        const seconds = int.fromEnvironment('QA_HANDOFF_INSPECTION_SECONDS');
        if (seconds > 0) {
          debugPrint('QA_HANDOFF_OPEN: inspect attachment; do not send.');
          await Future<void>.delayed(Duration(seconds: seconds));
        }
      } finally {
        work.dispose();
        await harness.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
