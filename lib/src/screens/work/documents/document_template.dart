class DocumentTemplate {
  const DocumentTemplate(
    this.id,
    this.label,
    this.description,
    this.accent, {
    this.artAsset,
    this.landscape = false,
    this.printerFriendly = false,
  });
  final bool landscape, printerFriendly;
  final String id;
  final String label;
  final String description;
  final int accent;
  final String? artAsset;
  static List<DocumentTemplate> get catalog => [
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
      _base.firstWhere((t) => t.id == 'Service standard');
}
