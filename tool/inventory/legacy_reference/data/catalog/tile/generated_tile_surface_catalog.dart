part of '../../work_supply_catalog.dart';

final tileGeneratedSurfaceCatalogCategory = _category(
  'Pro Tile Surface and Finish Stock',
  [
    _system('Tile Field Materials by Room', [
      _type('Bathroom and Shower Tile Detail', _tileRoomFieldProducts()),
      _type('Kitchen and Backsplash Tile Detail', _tileKitchenFieldProducts()),
      _type('Floor and Entry Tile Detail', _tileFloorEntryProducts()),
      _type(
        'Natural Stone and Specialty Tile Detail',
        _tileStoneDetailProducts(),
      ),
    ]),
    _system('Tile Edge Profiles and Transitions', [
      _type('Metal Tile Profiles Detail', _tileMetalProfileProducts()),
      _type(
        'Thresholds Sills and Transitions Detail',
        _tileTransitionProducts(),
      ),
    ]),
    _system('Grout Caulk Color and Finish Detail', [
      _type('Color Matched Grout Detail', _tileColorGroutProducts()),
      _type('Tile Caulk Sealer and Repair Detail', _tileCaulkRepairProducts()),
    ]),
    _system('Tile Underlayment and Prep Boards', [
      _type('Cement Foam and Fiber Board Detail', _tileBoardPrepProducts()),
      _type(
        'Self Leveling and Surface Prep Detail',
        _tileLevelingPrepProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _tileRoomFieldProducts() {
  return _tileSurfaceProducts(
    baseName: 'Bathroom Shower Tile Detail',
    unit: 'box',
    variants: [
      for (final material in ['Ceramic', 'Porcelain', 'Glass', 'Marble Look'])
        for (final finish in ['Gloss', 'Matte', 'Textured'])
          for (final color in [
            'White',
            'Warm White',
            'Gray',
            'Charcoal',
            'Blue',
            'Sage',
          ])
            for (final size in [
              '3 x 6 in Subway',
              '4 x 12 in Subway',
              '12 x 24 in Wall',
              '2 x 2 in Mosaic Sheet',
              'Hex Mosaic Sheet',
              'Penny Round Mosaic Sheet',
            ])
              '$color $finish $material $size Tile',
    ],
    aliases: const [
      'bath tile',
      'shower tile',
      'wall tile',
      'subway tile',
      'mosaic sheet',
    ],
  );
}

List<WorkSupplyItem> _tileKitchenFieldProducts() {
  return _tileSurfaceProducts(
    baseName: 'Kitchen Backsplash Tile Detail',
    unit: 'box',
    variants: [
      for (final material in ['Ceramic', 'Porcelain', 'Glass', 'Stone Look'])
        for (final color in [
          'White',
          'Gray',
          'Black',
          'Blue',
          'Green',
          'Carrara',
          'Travertine',
        ])
          for (final style in [
            'Subway',
            'Beveled Subway',
            'Pickett',
            'Arabesque',
            'Herringbone Mosaic',
            'Lantern Mosaic',
          ])
            '$color $material $style Backsplash Tile',
    ],
    aliases: const [
      'backsplash tile',
      'kitchen tile',
      'beveled subway',
      'herringbone mosaic',
    ],
  );
}

List<WorkSupplyItem> _tileFloorEntryProducts() {
  return _tileSurfaceProducts(
    baseName: 'Floor Entry Tile Detail',
    unit: 'box',
    variants: [
      for (final material in ['Porcelain', 'Ceramic', 'Quarry', 'Stone Look'])
        for (final finish in ['Matte', 'Textured', 'Polished'])
          for (final color in [
            'White',
            'Gray',
            'Charcoal',
            'Beige',
            'Slate',
            'Travertine',
          ])
            for (final size in [
              '6 x 24 in Plank',
              '8 x 36 in Plank',
              '12 x 12 in',
              '12 x 24 in',
              '18 x 18 in',
              '24 x 24 in',
            ])
              '$color $finish $material $size Floor Tile',
    ],
    aliases: const [
      'floor tile',
      'entry tile',
      'plank tile',
      'porcelain floor',
    ],
  );
}

List<WorkSupplyItem> _tileStoneDetailProducts() {
  return _tileSurfaceProducts(
    baseName: 'Natural Stone Specialty Tile Detail',
    unit: 'piece',
    variants: [
      for (final stone in [
        'Marble',
        'Travertine',
        'Slate',
        'Limestone',
        'Granite',
        'Pebble',
      ])
        for (final finish in ['Honed', 'Polished', 'Tumbled', 'Split Face'])
          for (final size in [
            '12 x 12 in',
            '12 x 24 in',
            '6 x 24 in',
            'Mosaic Sheet',
            'Ledger Panel',
          ])
            '$finish $stone $size Tile',
    ],
    aliases: const [
      'stone tile',
      'marble tile',
      'travertine tile',
      'ledger panel',
      'pebble mosaic',
    ],
  );
}

List<WorkSupplyItem> _tileMetalProfileProducts() {
  return _tileSurfaceProducts(
    baseName: 'Metal Tile Profile Detail',
    unit: 'each',
    variants: [
      for (final finish in [
        'Brushed Nickel',
        'Matte Black',
        'Satin Aluminum',
        'Chrome',
        'Oil Rubbed Bronze',
      ])
        for (final height in [
          '5/16 in',
          '3/8 in',
          '1/2 in',
          '5/8 in',
          '3/4 in',
        ])
          for (final profile in [
            'Jolly Edge Trim',
            'Rondec Edge Trim',
            'Quadec Edge Trim',
            'Schiene Edge Trim',
            'Inside Corner Profile',
            'Outside Corner Profile',
          ])
            '8 ft $finish $height $profile',
    ],
    aliases: const [
      'schluter trim',
      'tile profile',
      'edge trim',
      'jolly trim',
      'rondec trim',
    ],
  );
}

List<WorkSupplyItem> _tileTransitionProducts() {
  return _tileSurfaceProducts(
    baseName: 'Tile Threshold Transition Detail',
    unit: 'each',
    variants: [
      for (final color in ['White', 'Carrara', 'Gray', 'Travertine', 'Black'])
        for (final size in ['2 x 36 in', '4 x 36 in', '4 x 48 in', '6 x 72 in'])
          for (final item in [
            'Marble Threshold',
            'Engineered Stone Threshold',
            'Shower Curb Cap',
            'Window Sill',
          ])
            '$size $color $item',
      for (final finish in [
        'Brushed Nickel',
        'Matte Black',
        'Satin Aluminum',
        'Bronze',
      ])
        for (final item in [
          'Tile Reducer Transition Strip',
          'Tile T Molding Transition Strip',
          'Tile Carpet Transition Strip',
          'Movement Joint Profile',
        ])
          '8 ft $finish $item',
    ],
    aliases: const [
      'marble threshold',
      'shower curb cap',
      'tile transition',
      'movement joint',
      'tile reducer',
    ],
  );
}

List<WorkSupplyItem> _tileColorGroutProducts() {
  return _tileSurfaceProducts(
    baseName: 'Color Matched Grout Detail',
    unit: 'each',
    variants: [
      for (final color in [
        'White',
        'Alabaster',
        'Bone',
        'Biscuit',
        'Haystack',
        'Warm Gray',
        'Silver',
        'Pewter',
        'Charcoal',
        'Black',
        'Mocha',
        'Sage',
      ])
        for (final type in [
          'Sanded Grout',
          'Unsanded Grout',
          'Premixed Grout',
          'Epoxy Grout',
          'Urethane Grout',
        ])
          for (final size in ['1 qt', '1 gal', '10 lb', '25 lb'])
            '$size $color $type',
    ],
    aliases: const [
      'tile grout',
      'colored grout',
      'premixed grout',
      'epoxy grout',
      'urethane grout',
    ],
  );
}

List<WorkSupplyItem> _tileCaulkRepairProducts() {
  return _tileSurfaceProducts(
    baseName: 'Tile Caulk Sealer Repair Detail',
    unit: 'each',
    variants: [
      for (final color in [
        'White',
        'Alabaster',
        'Bone',
        'Warm Gray',
        'Pewter',
        'Charcoal',
        'Black',
        'Mocha',
      ])
        for (final item in [
          'Sanded Ceramic Tile Caulk',
          'Unsanded Ceramic Tile Caulk',
          'Silicone Tile Sealant',
          'Grout Colorant',
        ])
          '$color $item',
      for (final item in [
        '16 oz Grout Sealer',
        '32 oz Grout Sealer',
        '1 gal Grout Sealer',
        'Stone Sealer 1 qt',
        'Natural Stone Enhancer 1 qt',
        'Tile Chip Repair Kit',
        'Grout Repair Tube',
        'Grout Haze Remover Quart',
        'Heavy Duty Grout Cleaner Quart',
      ])
        item,
    ],
    aliases: const [
      'tile caulk',
      'grout caulk',
      'grout sealer',
      'stone sealer',
      'grout repair',
    ],
  );
}

List<WorkSupplyItem> _tileBoardPrepProducts() {
  return _tileSurfaceProducts(
    baseName: 'Tile Board Prep Detail',
    unit: 'each',
    variants: [
      for (final thickness in ['1/4 in', '1/2 in', '5/8 in'])
        for (final size in ['3 x 5 ft', '4 x 8 ft'])
          for (final board in [
            'Cement Backer Board',
            'Fiber Cement Backer Board',
            'Foam Tile Backer Board',
            'Waterproof Tile Board',
          ])
            '$thickness $size $board',
      for (final item in [
        'Backer Board Screw 185 Pack',
        'Backer Board Screw 750 Pack',
        'Foam Board Washer 100 Pack',
        'Alkali Resistant Mesh Tape Roll',
        'Backer Board Seam Tape Roll',
        'Liquid Waterproofing Membrane 1 gal',
        'Liquid Waterproofing Membrane 3.5 gal',
      ])
        item,
    ],
    aliases: const [
      'cement board',
      'backer board',
      'foam board',
      'tile board',
      'mesh tape',
    ],
  );
}

List<WorkSupplyItem> _tileLevelingPrepProducts() {
  return _tileSurfaceProducts(
    baseName: 'Tile Surface Prep Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 qt', '1 gal', '2 gal', '5 gal'])
        for (final item in [
          'Self Leveling Primer',
          'Tile Membrane Primer',
          'Concrete Bonding Primer',
          'Waterproofing Primer',
        ])
          '$size $item',
      for (final size in ['25 lb', '50 lb'])
        for (final item in [
          'Self Leveling Underlayment',
          'Floor Patch and Leveler',
          'Feather Finish Patch',
          'Rapid Set Floor Patch',
        ])
          '$size $item',
      for (final item in [
        'Crack Isolation Membrane Roll',
        'Anti Fracture Membrane Roll',
        'Uncoupling Membrane Roll',
        'Peel and Stick Tile Membrane Roll',
      ])
        item,
    ],
    aliases: const [
      'self leveling',
      'floor leveler',
      'floor patch',
      'crack isolation',
      'uncoupling membrane',
    ],
  );
}

List<WorkSupplyItem> _tileSurfaceProducts({
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
