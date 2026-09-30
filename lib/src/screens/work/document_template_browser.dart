import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../shared/documents/document_image_scope.dart';
import '../../shared/documents/pdf/pdf_document_view.dart';
import 'documents/customer_document.dart';
import 'documents/document_pdf_assets.dart';
import 'documents/document_template.dart';

/// Full-screen template browsing renders the exact PDF, with independent page
/// navigation supplied by the shared reader and design navigation below it.
class DocumentTemplateBrowser extends StatefulWidget {
  const DocumentTemplateBrowser({
    required this.document,
    required this.templates,
    required this.initialIndex,
    super.key,
  });
  final CustomerDocument document;
  final List<DocumentTemplate> templates;
  final int initialIndex;
  @override
  State<DocumentTemplateBrowser> createState() =>
      _DocumentTemplateBrowserState();
}

class _DocumentTemplateBrowserState extends State<DocumentTemplateBrowser> {
  late int _index = widget.initialIndex;
  @override
  Widget build(BuildContext context) {
    final template = widget.templates[_index];
    final loader = DocumentImageScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(template.label)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            children: [
              Expanded(
                child: PdfDocumentView(
                  generated: true,
                  key: ValueKey(template.id),
                  open: () async => PdfDocument.openData(
                    await generateCustomerPdf(
                      widget.document,
                      templateId: template.id,
                      previewOnly: true,
                      logoLoader: loader,
                    ),
                  ),
                ),
              ),
              SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Previous template',
                          onPressed: _index > 0
                              ? () => setState(() => _index--)
                              : null,
                          icon: const Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: Text(
                            'Template ${_index + 1} of ${widget.templates.length}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Next template',
                          onPressed: _index + 1 < widget.templates.length
                              ? () => setState(() => _index++)
                              : null,
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context, template.id),
                      icon: const Icon(Icons.check),
                      label: const Text('Use template'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
