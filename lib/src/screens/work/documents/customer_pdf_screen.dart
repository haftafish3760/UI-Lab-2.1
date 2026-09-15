import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../../shared/documents/pdf/pdf_document_view.dart';
import '../../../shared/documents/document_image_scope.dart';
import 'customer_document.dart';
import 'document_pdf_assets.dart';

/// Work's full-screen wrapper around the same reader used for uploaded PDFs.
class CustomerPdfScreen extends StatelessWidget {
  const CustomerPdfScreen({
    required this.document,
    this.templateId,
    this.allowExport = false,
    this.actions = const [],
    super.key,
  });
  final CustomerDocument document;
  final String? templateId;
  final bool allowExport;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    final loader = DocumentImageScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text('${document.kind} PDF'), actions: actions),
      body: PdfDocumentView(
        key: ObjectKey(document),
        open: () async => PdfDocument.openData(
          await generateCustomerPdf(
            document,
            templateId: templateId,
            logoLoader: loader,
          ),
        ),
      ),
    );
  }
}
