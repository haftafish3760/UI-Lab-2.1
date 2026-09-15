import '../../shared/documents/document_image_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:printing/printing.dart';
import 'documents/customer_document.dart';
import 'documents/document_pdf_assets.dart';
import 'documents/document_template.dart';
import 'documents/customer_pdf_screen.dart';
import '../../layout/app_layout_engine.dart';

class DocumentTemplateScreen extends StatelessWidget {
  const DocumentTemplateScreen({
    required this.selectedId,
    required this.document,
    super.key,
  });
  final String selectedId;
  final CustomerDocument document;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a template')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final layout = AppLayoutEngine.workFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        // Rasterize only visible template rows. Ten simultaneous PDF readers can
        // exhaust a phone's memory before the user has chosen a design.
        final columns = layout.columns;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          scrollCacheExtent: const ScrollCacheExtent.pixels(0),
          itemCount: (DocumentTemplate.catalog.length / columns).ceil(),
          itemBuilder: (context, row) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (final template
                      in DocumentTemplate.catalog
                          .skip(row * columns)
                          .take(columns))
                    SizedBox(
                      width: (constraints.maxWidth - 16).clamp(
                        0,
                        layout.laneWidth,
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 340,
                              child: PdfPreview(
                                key: ValueKey(
                                  'template-preview-${template.id}',
                                ),
                                build: (_) => generateCustomerPdf(
                                  document,
                                  templateId: template.id,
                                  logoLoader: DocumentImageScope.maybeOf(
                                    context,
                                  ),
                                ),
                                useActions: false,
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                                canDebug: false,
                                allowPrinting: false,
                                allowSharing: false,
                                onError: (_, _) => const Center(
                                  child: Text(
                                    'Preview unavailable. Tap Preview to retry.',
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    template.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(template.description),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).push<void>(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    CustomerPdfScreen(
                                                      document: document,
                                                      templateId: template.id,
                                                    ),
                                              ),
                                            ),
                                        child: const Text('Preview'),
                                      ),
                                      FilledButton.icon(
                                        key: ValueKey(
                                          'use-template-${template.id}',
                                        ),
                                        onPressed: () => Navigator.of(
                                          context,
                                        ).pop(template.id),
                                        icon: Icon(
                                          DocumentTemplate.resolve(
                                                    selectedId,
                                                  ).id ==
                                                  template.id
                                              ? Icons.check
                                              : Icons.description_outlined,
                                        ),
                                        label: const Text('Use template'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
