part of '../../work_supply_catalog.dart';

final tileGeneratedFieldCatalogCategory = _category(
  'Pro Tile Field Material Expansion Stock',
  [
    _system('Large Format and Rectified Field Tile', [
      _type(
        'Large Format Porcelain and Ceramic Detail',
        _tileLargeFormatProducts(),
      ),
    ]),
    _system('Mosaic Accent and Sheet Tile', [
      _type('Mosaic Sheet Pattern Detail', _tileMosaicSheetProducts()),
    ]),
    _system('Exterior Quarry Paver and Utility Tile', [
      _type('Exterior Utility Tile Detail', _tileExteriorUtilityProducts()),
    ]),
  ],
);

List<WorkSupplyItem> _tileLargeFormatProducts() {
  return _tileFieldProducts(
    baseName: 'Large Format Field Tile Detail',
    unit: 'box',
    variants: [
      for (final material in ['Porcelain', 'Ceramic'])
        for (final color in [
          'White',
          'Warm White',
          'Carrara',
          'Gray',
          'Charcoal',
          'Black',
          'Beige',
          'Travertine',
          'Slate',
          'Sand',
        ])
          for (final finish in ['Matte', 'Polished', 'Textured', 'Honed'])
            for (final size in [
              '12 x 24 in',
              '16 x 32 in',
              '18 x 36 in',
              '24 x 24 in',
              '24 x 48 in',
              '30 x 30 in',
              '6 x 36 in Plank',
              '8 x 48 in Plank',
            ])
              for (final style in [
                'Rectified Tile',
                'Floor Tile',
                'Wall Tile',
                'Stone Look Tile',
              ])
                '$color $finish $material $size $style',
    ],
    aliases: const [
      'large format tile',
      'rectified tile',
      'lft tile',
      'porcelain tile',
      'ceramic tile',
      'floor tile',
      'wall tile',
    ],
  );
}

List<WorkSupplyItem> _tileMosaicSheetProducts() {
  return _tileFieldProducts(
    baseName: 'Mosaic Sheet Tile Detail',
    unit: 'sheet',
    variants: [
      for (final material in [
        'Ceramic',
        'Porcelain',
        'Glass',
        'Marble',
        'Stone',
      ])
        for (final color in [
          'White',
          'Warm White',
          'Carrara',
          'Gray',
          'Charcoal',
          'Black',
          'Blue',
          'Sage',
          'Green',
          'Travertine',
        ])
          for (final pattern in [
            'Hex Mosaic Sheet',
            'Penny Round Mosaic Sheet',
            'Basketweave Mosaic Sheet',
            'Herringbone Mosaic Sheet',
            'Arabesque Mosaic Sheet',
            'Pickett Mosaic Sheet',
            'Lantern Mosaic Sheet',
            'Chevron Mosaic Sheet',
            'Pebble Mosaic Sheet',
            'Linear Mosaic Sheet',
          ])
            '$color $material $pattern',
    ],
    aliases: const [
      'mosaic sheet',
      'hex mosaic',
      'penny round',
      'basketweave',
      'herringbone mosaic',
      'pebble mosaic',
      'linear mosaic',
    ],
  );
}

List<WorkSupplyItem> _tileExteriorUtilityProducts() {
  return _tileFieldProducts(
    baseName: 'Exterior Utility Tile Detail',
    unit: 'box',
    variants: [
      for (final material in [
        'Quarry',
        'Porcelain Paver',
        'Saltillo',
        'Terracotta',
      ])
        for (final color in [
          'Red',
          'Brown',
          'Gray',
          'Charcoal',
          'Tan',
          'Adobe',
        ])
          for (final finish in ['Matte', 'Textured', 'Anti Slip'])
            for (final size in [
              '6 x 6 in',
              '8 x 8 in',
              '12 x 12 in',
              '12 x 24 in',
              '16 x 16 in',
            ])
              for (final item in [
                'Floor Tile',
                'Paver Tile',
                'Cove Base Tile',
                'Tread Tile',
              ])
                '$color $finish $material $size $item',
    ],
    aliases: const [
      'quarry tile',
      'paver tile',
      'saltillo tile',
      'terracotta tile',
      'anti slip tile',
      'cove base tile',
      'tread tile',
    ],
  );
}

List<WorkSupplyItem> _tileFieldProducts({
  required String baseName,
  required String unit,
  required List<String> variants,
  required List<String> aliases,
}) {
  return [
    for (final variant in variants)
      WorkSupplyItem(
        id: '',
        name: '$variant $baseName',
        trade: '',
        category: '',
        system: '',
        itemType: '',
        variant: variant,
        unit: unit,
        aliases: aliases,
      ),
  ];
}
