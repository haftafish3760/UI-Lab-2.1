import 'package:flutter/material.dart';
import '../../shared/documents/document_source.dart';
import '../../shared/documents/pdf/pdf_export_service.dart';
import '../../shared/documents/pdf/pdf_export_feedback.dart';
import '../../data/work/company_document_branding.dart';
import '../../data/prototype_operations_store.dart';
import 'documents/document_pdf_assets.dart';
import 'work_customer_document.dart';
import 'work_models.dart';
import '../../data/work/work_export_audit.dart';

enum WorkPdfAction { share, save, print }

/// Opening the system share sheet is not proof of delivery or customer approval.
Future<void> deliverWorkPdf(
  BuildContext context,
  WorkRecord record,
  WorkPdfAction action, {
  String? recipient,
  String? composeMethod,
}) async {
  final store = PrototypeOperationsScope.of(context);
  final work = store.workSession;
  if (work == null) {
    throw StateError('Open a saved document before sharing.');
  }
  final expected = work.storageRevisionFor(record.id);
  final audit = WorkExportAudit(work);
  final saved = await audit.assertCurrent(
    record.id,
    expected,
    expectedDocument: record,
  );
  if (!context.mounted) return;
  final label = switch (record.kind) {
    WorkRecordKind.estimate => 'Estimate',
    WorkRecordKind.quote => 'Quote',
    WorkRecordKind.invoice => 'Invoice',
    WorkRecordKind.job => 'Job',
  };
  final document = workCustomerDocument(
    saved,
    store.companyProfile,
    resolveWorkDocumentCustomer(saved, store.customers),
    financialEntries: store.financialEntries,
  );
  final directory = store.directorySession;
  final renderObject = context.findRenderObject();
  final box = renderObject is RenderBox && renderObject.hasSize
      ? renderObject
      : null;
  final source = DocumentSource(
    origin: DocumentOrigin.generated,
    fileName: record.number,
    authorize: () async {
      if (!context.mounted) {
        throw StateError('The document screen is no longer open.');
      }
      work.requireActiveDraftOwner();
      if (work.storageRevisionFor(record.id) != expected ||
          !work.permissions.canShareDocuments) {
        throw StateError(
          'The document changed. Review the latest copy before sharing.',
        );
      }
      await audit.assertCurrent(record.id, expected, expectedDocument: saved);
    },
    readBytes: () => generateCustomerPdf(
      document,
      logoLoader: directory == null
          ? null
          : CompanyDocumentBrandingService(directory).readLogo,
    ),
  );
  final attempt = await audit.begin(
    record.id,
    expected,
    action.name,
    expectedDocument: saved,
  );
  final PdfExportOutcome outcome;
  try {
    outcome = await const PdfExportService().export(
      source,
      switch (action) {
        WorkPdfAction.save => PdfExportAction.save,
        WorkPdfAction.print => PdfExportAction.print,
        WorkPdfAction.share => PdfExportAction.share,
      },
      subject: '$label ${record.number}',
      recipient: recipient,
      composeMethod: composeMethod,
      text:
          'Please review the attached ${label.toLowerCase()} for ${record.title}.',
      shareOrigin: box == null
          ? const Rect.fromLTWH(0, 0, 1, 1)
          : box.localToGlobal(Offset.zero) & box.size,
    );
  } catch (_) {
    await audit.finish(attempt, 'failed');
    rethrow;
  }
  try {
    await audit.finish(attempt, outcome.name);
  } catch (_) {
    throw StateError(
      'The external action returned, but its result could not be saved. Check the sharing app before retrying; activity retains the original attempt.',
    );
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pdfExportOutcomeMessage(switch (action) {
            WorkPdfAction.save => PdfExportAction.save,
            WorkPdfAction.print => PdfExportAction.print,
            WorkPdfAction.share => PdfExportAction.share,
          }, outcome),
        ),
      ),
    );
  }
}
