import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../shared/documents/document_image_scope.dart';
import '../../layout/app_layout_engine.dart';
import 'documents/customer_document.dart';
import 'documents/document_pdf_assets.dart';
import 'documents/document_template.dart';
import 'document_template_browser.dart';

class DocumentTemplateScreen extends StatefulWidget {
  const DocumentTemplateScreen({
    required this.selectedId,
    required this.document,
    super.key,
  });
  final String selectedId;
  final CustomerDocument document;
  @override
  State<DocumentTemplateScreen> createState() => _DocumentTemplateScreenState();
}

class _DocumentTemplateScreenState extends State<DocumentTemplateScreen> {
  String _category = 'All';
  List<DocumentTemplate> get _templates => DocumentTemplate.catalog
      .where((template) => _category == 'All' || template.category == _category)
      .toList();
  Future<void> _open(int index) async {
    final selected = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentTemplateBrowser(
          document: widget.document,
          templates: _templates,
          initialIndex: index,
        ),
      ),
    );
    if (mounted && selected != null) Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose a template')),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final columns = AppLayoutEngine.templateColumnsFor(
          constraints.maxWidth,
          textScaler: MediaQuery.textScalerOf(context),
        );
        final templates = _templates;
        final width =
            (constraints.maxWidth - 24 - (columns - 1) * 12) / columns;
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            if (widget.document.company.trim().isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'You can preview templates now. Add your business name in Company information before sending a document.',
                ),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final category in {
                  'All',
                  ...DocumentTemplate.catalog.map((t) => t.category),
                })
                  ChoiceChip(
                    label: Text(category),
                    selected: category == _category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            for (var row = 0; row < (templates.length / columns).ceil(); row++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var col = 0; col < columns; col++) ...[
                      if (col > 0) const SizedBox(width: 12),
                      if (row * columns + col < templates.length)
                        SizedBox(
                          width: width,
                          child: _tile(
                            templates[row * columns + col],
                            row * columns + col,
                            width,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    ),
  );
  Widget _tile(DocumentTemplate template, int index, double width) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _open(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            label: 'Enlarge ${template.label}',
            child: IgnorePointer(
              child: SizedBox(
                height: template.landscape ? width * 0.71 : width * 1.414,
                child: PdfPreview(
                  key: ValueKey('template-preview-${template.id}'),
                  build: (_) => generateCustomerPdf(
                    widget.document,
                    templateId: template.id,
                    previewOnly: true,
                    logoLoader: DocumentImageScope.maybeOf(context),
                  ),
                  padding: EdgeInsets.zero,
                  previewPageMargin: EdgeInsets.zero,
                  useActions: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  allowPrinting: false,
                  allowSharing: false,
                  onError: (_, _) => const Center(
                    child: Text(
                      'Preview unavailable. Tap to retry in full screen.',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  template.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (DocumentTemplate.resolve(widget.selectedId).id ==
                    template.id)
                  const Text('Selected'),
                const Text('Tap document to enlarge'),
                FilledButton(
                  key: ValueKey('use-template-${template.id}'),
                  onPressed: () => Navigator.pop(context, template.id),
                  child: const Text('Use template'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
