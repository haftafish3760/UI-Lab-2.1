import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/work/work_financial_codec.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/documents/document_image_scope.dart';
import '../../shared/documents/document_source.dart';
import '../../shared/documents/pdf/pdf_document_view.dart';
import '../../shared/documents/pdf/pdf_export_feedback.dart';
import '../../shared/documents/pdf/pdf_export_service.dart';
import 'documents/payment_receipt_pdf.dart';
import 'work_models.dart';

class PaymentReceiptScreen extends StatelessWidget {
  const PaymentReceiptScreen({
    required this.payment,
    this.linkedWork,
    super.key,
  });

  final PrototypeFinancialEntry payment;
  final WorkRecord? linkedWork;

  @override
  Widget build(BuildContext context) {
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    final directory = store.directorySession;
    if (work == null ||
        directory?.permissions.canViewCompany != true ||
        directory!.company.companyName.trim().isEmpty ||
        !work.permissions.canManageOtherCreators ||
        !work.permissions.canShareDocuments ||
        !_isCurrent(work.financialEntries)) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: Text('This payment receipt is unavailable.')),
        ),
      );
    }

    final currentWork = linkedWork == null
        ? null
        : work.records
              .where((record) => record.id == linkedWork!.id)
              .firstOrNull;
    final document = paymentReceiptData(
      organizationId: work.permissions.organizationId,
      payment: payment,
      company: directory.company,
      linkedWork: currentWork,
    );
    final logoLoader = DocumentImageScope.maybeOf(context);
    return Scaffold(
      key: const ValueKey('payment-receipt-screen'),
      appBar: AppBar(title: const Text('Payment receipt')),
      body: LayoutBuilder(
        builder: (context, constraints) => ListView(
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: PdfDocumentView(
                open: () async => PdfDocument.openData(
                  await generatePaymentReceiptPdf(
                    document,
                    logoLoader: logoLoader,
                  ),
                ),
              ),
            ),
            _actions(context, document),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, PaymentReceiptData document) =>
      SafeArea(
        minimum: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final buttons = [
              OutlinedButton.icon(
                key: const ValueKey('save-payment-receipt'),
                onPressed: () =>
                    _export(context, document, PdfExportAction.save),
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Save PDF'),
              ),
              FilledButton.icon(
                key: const ValueKey('share-payment-receipt'),
                onPressed: () =>
                    _export(context, document, PdfExportAction.share),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share PDF'),
              ),
            ];
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final stack =
                constraints.maxWidth - insets.horizontal < 320 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            return Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: stack
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons.first,
                          const SizedBox(height: 8),
                          buttons.last,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: buttons.first),
                          const SizedBox(width: 8),
                          Expanded(child: buttons.last),
                        ],
                      ),
              ),
            );
          },
        ),
      );

  bool _isCurrent(Iterable<PrototypeFinancialEntry> entries) {
    final current = entries
        .where((entry) => entry.id == payment.id)
        .firstOrNull;
    return current != null &&
        current.kind == PrototypeFinancialKind.paymentReceived &&
        jsonEncode(encodeFinancialEntry(current)) ==
            jsonEncode(encodeFinancialEntry(payment));
  }

  Future<void> _export(
    BuildContext context,
    PaymentReceiptData document,
    PdfExportAction action,
  ) async {
    final store = PrototypeOperationsScope.of(context);
    final work = store.workSession;
    final directory = store.directorySession;
    if (work == null || directory == null) return;
    final logoLoader = DocumentImageScope.maybeOf(context);
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox && renderObject.hasSize
        ? renderObject
        : null;
    Future<void> authorize() async {
      if (!context.mounted) {
        throw StateError('The receipt screen is no longer open.');
      }
      work.requireActiveDraftOwner();
      if (!work.permissions.canManageOtherCreators ||
          !work.permissions.canShareDocuments ||
          !directory.permissions.canViewCompany ||
          directory.company.companyName.trim().isEmpty ||
          !_isCurrent(work.financialEntries)) {
        throw StateError('This payment receipt is no longer available.');
      }
    }

    final source = DocumentSource(
      origin: DocumentOrigin.generated,
      fileName: 'Payment receipt ${document.reference}',
      authorize: authorize,
      readBytes: () =>
          generatePaymentReceiptPdf(document, logoLoader: logoLoader),
    );
    try {
      final result = await const PdfExportService().export(
        source,
        action,
        shareOrigin: box == null
            ? const Rect.fromLTWH(0, 0, 1, 1)
            : box.localToGlobal(Offset.zero) & box.size,
        subject: 'Payment receipt ${document.reference}',
        text: 'Payment receipt from ${document.branding.companyName}.',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pdfExportOutcomeMessage(action, result))),
      );
    } on Object catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(pdfExportErrorMessage(error))));
    }
  }
}
