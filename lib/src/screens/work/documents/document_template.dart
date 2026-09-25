enum DocumentLayout {
  standard,
  splitHeader,
  project,
  service,
  masonry,
  plumbing,
  carpentry,
  garden,
}

class DocumentTemplate {
  const DocumentTemplate(
    this.id,
    this.label,
    this.description,
    this.accent, {
    this.artAsset,
    this.layout = DocumentLayout.standard,
    this.landscape = false,
    this.printerFriendly = false,
  });
  String get category => printerFriendly
      ? 'Printer friendly'
      : artAsset == null && layout.index < DocumentLayout.masonry.index
      ? 'Classic'
      : 'Trade themes';
  final DocumentLayout layout;
  final bool landscape, printerFriendly;
  final String id;
  final String label;
  final String description;
  final int accent;
  final String? artAsset;
  static List<DocumentTemplate> get legacyCatalog => [
    for (final t in _base) ...[
      t,
      DocumentTemplate(
        '${t.id}|landscape',
        '${t.label} - Landscape',
        t.description,
        t.accent,
        artAsset: t.artAsset,
        landscape: true,
        printerFriendly: t.printerFriendly,
      ),
    ],
  ];
  static List<DocumentTemplate> get catalog => [
    ...legacyCatalog.take(2),
    const DocumentTemplate(
      'business-split-v2',
      'Business ledger',
      'Split company and document header with a structured pricing ledger.',
      0x183C55,
      layout: DocumentLayout.splitHeader,
    ),
    const DocumentTemplate(
      'project-proposal-v2',
      'Project proposal',
      'Project title and total lead, followed by scope and an itemized breakdown.',
      0x315A43,
      layout: DocumentLayout.project,
    ),
    const DocumentTemplate(
      'service-detail-v2',
      'Service detail',
      'Numbered work entries with individual amounts and a closing summary.',
      0x713F24,
      layout: DocumentLayout.service,
    ),
    const DocumentTemplate(
      'business-wide-v2',
      'Wide business ledger',
      'Landscape header with company, customer and dates across the page.',
      0x183C55,
      landscape: true,
      layout: DocumentLayout.splitHeader,
    ),
    const DocumentTemplate(
      'masonry-v2',
      'Masonry stonework',
      'Brickwork borders, stone panels and a structured project breakdown.',
      0x693D2E,
      layout: DocumentLayout.masonry,
    ),
    const DocumentTemplate(
      'plumbing-v2',
      'Copper and tile',
      'Copper pipework frames a tiled service document.',
      0x205665,
      layout: DocumentLayout.plumbing,
    ),
    const DocumentTemplate(
      'carpentry-v2',
      'Carpentry workbench',
      'Timber framing and workshop tools around a clear project ledger.',
      0x663C23,
      landscape: true,
      layout: DocumentLayout.carpentry,
    ),
    const DocumentTemplate(
      'garden-v2',
      'Garden and grounds',
      'Leafy borders and flower beds surround a project proposal.',
      0x315A43,
      layout: DocumentLayout.garden,
    ),
  ];
  static const _base = [
    DocumentTemplate(
      'print-v1',
      'Printer friendly',
      'Black text, light rules and no decorative artwork.',
      0,
      printerFriendly: true,
    ),
    DocumentTemplate(
      'Service standard',
      'Classic service',
      'Clean navy heading with generous room for your work details.',
      0x183C55,
    ),
    DocumentTemplate(
      'plumbing-v1',
      'Plumbing',
      'Navy and copper pipework with a restrained water illustration.',
      0x176174,
      artAsset: 'assets/document_templates/plumbing-header-v1.png',
    ),
    DocumentTemplate(
      'electrical-v1',
      'Electrical',
      'Precision electrical artwork with warm gold accents.',
      0x745713,
      artAsset: 'assets/document_templates/electrical-header-v1.png',
    ),
    DocumentTemplate(
      'hvac-v1',
      'Heating and cooling',
      'Fine equipment linework and flowing teal accents.',
      0x176278,
      artAsset: 'assets/document_templates/hvac-header-v1.png',
    ),
  ];
  static DocumentTemplate resolve(String id) =>
      catalog.where((t) => t.id == id).firstOrNull ??
      legacyCatalog.where((t) => t.id == id).firstOrNull ??
      _base.firstWhere((t) => t.id == 'Service standard');
}
