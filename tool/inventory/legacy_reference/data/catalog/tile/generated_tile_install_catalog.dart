part of '../../work_supply_catalog.dart';

final tileGeneratedInstallCatalogCategory = _category(
  'Pro Tile Installation System Stock',
  [
    _system('Shower Systems and Waterproof Parts', [
      _type('Shower Pan Tray Kit Detail', _tileShowerPanKitProducts()),
      _type('Drain Grate and Channel Detail', _tileDrainGrateProducts()),
      _type('Niche Bench Shelf and Curb Detail', _tileFoamShowerPartProducts()),
      _type(
        'Waterproofing Seal and Band Detail',
        _tileWaterproofSealProducts(),
      ),
    ]),
    _system('Heated Floor and Underlayment Systems', [
      _type(
        'Floor Heat Mat Cable and Control Detail',
        _tileHeatSystemProducts(),
      ),
      _type('Uncoupling and Heat Membrane Detail', _tileHeatMembraneProducts()),
    ]),
    _system('Tile Layout Cutting and Install Consumables', [
      _type('Leveling Spacer and Wedge Detail', _tileLevelingSystemProducts()),
      _type('Diamond Blade Bit and Hole Saw Detail', _tileCuttingProducts()),
      _type(
        'Trowel Float Sponge and Cleanup Detail',
        _tileInstallToolProducts(),
      ),
    ]),
    _system('Mortar Additives and Jobsite Prep', [
      _type('Mortar Additive and Primer Detail', _tileAdditivePrimerProducts()),
      _type(
        'Tile Protection and Cleanup Detail',
        _tileProtectionCleanupProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _tileShowerPanKitProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Shower Pan Kit Detail',
    unit: 'kit',
    variants: [
      for (final size in [
        '32 x 60 in',
        '36 x 36 in',
        '36 x 48 in',
        '36 x 60 in',
        '48 x 48 in',
        '48 x 60 in',
        '60 x 60 in',
      ])
        for (final drain in ['Center Drain', 'Left Drain', 'Right Drain'])
          for (final item in [
            'Foam Shower Tray Kit',
            'Tile Ready Shower Pan Kit',
            'Waterproof Shower Pan Kit',
            'Shower Pan Extension Kit',
          ])
            '$size $drain $item',
    ],
    aliases: const [
      'shower pan kit',
      'shower tray',
      'tile ready pan',
      'pan extension',
    ],
  );
}

List<WorkSupplyItem> _tileDrainGrateProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Drain Grate Detail',
    unit: 'each',
    variants: [
      for (final length in [
        '24 in',
        '30 in',
        '36 in',
        '42 in',
        '48 in',
        '60 in',
      ])
        for (final finish in [
          'Brushed Nickel',
          'Matte Black',
          'Chrome',
          'Oil Rubbed Bronze',
          'Satin Stainless',
        ])
          for (final style in [
            'Linear Shower Drain',
            'Tileable Linear Drain',
            'Linear Drain Grate',
            'Linear Drain Channel',
            'Shower Drain Grate Cover',
          ])
            '$length $finish $style',
      for (final finish in [
        'Brushed Nickel',
        'Matte Black',
        'Chrome',
        'Oil Rubbed Bronze',
        'Satin Stainless',
      ])
        for (final shape in ['Square', 'Round'])
          for (final size in ['4 in', '5 in', '6 in'])
            '$size $finish $shape Shower Drain Grate',
    ],
    aliases: const [
      'linear drain',
      'tileable drain',
      'drain grate',
      'shower drain',
    ],
  );
}

List<WorkSupplyItem> _tileFoamShowerPartProducts() {
  return _tileInstallProducts(
    baseName: 'Foam Shower Part Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '12 x 12 in',
        '12 x 20 in',
        '12 x 28 in',
        '16 x 20 in',
        '16 x 28 in',
        '16 x 32 in',
      ])
        for (final item in [
          'Waterproof Shower Niche',
          'Foam Shower Niche',
          'Tile Ready Shower Niche',
          'Recessed Shower Niche',
        ])
          '$size $item',
      for (final length in ['36 in', '48 in', '60 in', '72 in'])
        for (final item in [
          'Foam Shower Curb',
          'Waterproof Shower Curb',
          'Shower Curb Overlay',
          'Foam Shower Bench',
          'Triangular Corner Bench',
          'Floating Shower Bench Bracket',
        ])
          '$length $item',
      for (final side in ['Left', 'Right', 'Corner'])
        for (final item in [
          'Waterproof Corner Shelf',
          'Tile Ready Corner Shelf',
          'Foam Foot Rest',
          'Corner Foot Rest',
        ])
          '$side $item',
    ],
    aliases: const [
      'shower niche',
      'foam curb',
      'shower bench',
      'corner shelf',
      'foot rest',
    ],
  );
}

List<WorkSupplyItem> _tileWaterproofSealProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Waterproof Seal Detail',
    unit: 'each',
    variants: [
      for (final length in ['16 ft', '33 ft', '50 ft', '98 ft'])
        for (final item in [
          'Waterproofing Band Roll',
          'Waterproofing Seam Tape Roll',
          'Uncoupling Seam Tape Roll',
        ])
          '$length $item',
      for (final count in ['2 Pack', '4 Pack', '10 Pack'])
        for (final item in [
          'Inside Corner Waterproofing Piece',
          'Outside Corner Waterproofing Piece',
          'Pipe Seal Waterproofing Collar',
          'Mixing Valve Waterproofing Seal',
        ])
          '$count $item',
      for (final size in ['10 oz', '20 oz', '28 oz'])
        for (final item in [
          'Waterproof Sealant Tube',
          'Kerdi Fix Sealant Tube',
          'Waterproofing Adhesive Sealant',
        ])
          '$size $item',
    ],
    aliases: const [
      'waterproofing band',
      'seam tape',
      'inside corner',
      'outside corner',
      'pipe seal',
      'mixing valve seal',
      'kerdi fix',
    ],
  );
}

List<WorkSupplyItem> _tileHeatSystemProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Floor Heat System Detail',
    unit: 'each',
    variants: [
      for (final area in [
        '10 sq ft',
        '15 sq ft',
        '20 sq ft',
        '25 sq ft',
        '30 sq ft',
        '40 sq ft',
        '50 sq ft',
        '60 sq ft',
        '80 sq ft',
        '100 sq ft',
      ])
        for (final item in [
          'Electric Floor Heat Mat',
          'Radiant Floor Heat Cable Kit',
          'Floor Heat Cable Spool',
          'Loose Lay Floor Heat Cable',
        ])
          '$area $item',
      for (final item in [
        'Programmable Floor Heat Thermostat',
        'Wi-Fi Floor Heat Thermostat',
        'Floor Heat Sensor Wire',
        'Floor Heat Alarm Monitor',
        'Floor Heat Repair Kit',
        'Floor Heat Continuity Alarm',
      ])
        item,
    ],
    aliases: const [
      'floor heat',
      'heated floor',
      'heat mat',
      'heat cable',
      'floor heat thermostat',
      'heat sensor',
    ],
  );
}

List<WorkSupplyItem> _tileHeatMembraneProducts() {
  return _tileInstallProducts(
    baseName: 'Heat Membrane Underlayment Detail',
    unit: 'each',
    variants: [
      for (final area in ['27 sq ft', '54 sq ft', '108 sq ft', '161 sq ft'])
        for (final item in [
          'Uncoupling Heat Membrane Sheet',
          'Heat Cable Uncoupling Membrane Roll',
          'Waterproof Heat Membrane Roll',
        ])
          '$area $item',
      for (final item in [
        'Heat Membrane Repair Patch',
        'Heat Membrane Seam Band',
        'Heat Membrane Sensor Sleeve',
        'Heat Membrane Cable Guide',
      ])
        item,
    ],
    aliases: const [
      'heat membrane',
      'uncoupling heat membrane',
      'heat cable membrane',
    ],
  );
}

List<WorkSupplyItem> _tileLevelingSystemProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Leveling System Detail',
    unit: 'pack',
    variants: [
      for (final size in [
        '1/32 in',
        '1/16 in',
        '1/8 in',
        '3/16 in',
        '1/4 in',
        '3/8 in',
      ])
        for (final count in ['100 Pack', '250 Pack', '500 Pack', '1000 Pack'])
          for (final item in [
            'Tile Spacer',
            'Tile Leveling Clip',
            'Tile Leveling Wedge',
            'Reusable Tile Leveling Cap',
            'T Spin Leveling Spacer',
          ])
            '$size $count $item',
      for (final item in [
        'Tile Leveling Pliers',
        'Tile Wedge Removal Tool',
        'Tile Spacer Bucket',
        'Reusable Leveling Cap Tool',
      ])
        item,
    ],
    aliases: const [
      'tile spacer',
      'leveling clip',
      'leveling wedge',
      'leveling cap',
      't spin spacer',
    ],
  );
}

List<WorkSupplyItem> _tileCuttingProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Cutting Accessory Detail',
    unit: 'each',
    variants: [
      for (final size in ['3 in', '4 in', '4-1/2 in', '5 in', '7 in', '10 in'])
        for (final blade in [
          'Continuous Rim Diamond Blade',
          'Porcelain Diamond Blade',
          'Glass Tile Diamond Blade',
          'Turbo Rim Tile Blade',
          'Wet Saw Tile Blade',
          'Dry Cut Tile Blade',
        ])
          '$size $blade',
      for (final size in [
        '1/4 in',
        '5/16 in',
        '3/8 in',
        '1/2 in',
        '5/8 in',
        '3/4 in',
        '1 in',
        '1-1/4 in',
        '1-3/8 in',
        '2 in',
      ])
        for (final item in [
          'Diamond Tile Hole Saw',
          'Porcelain Hole Saw',
          'Glass Tile Drill Bit',
          'Diamond Core Bit',
        ])
          '$size $item',
      for (final item in [
        'Tile Nipper',
        'Glass Tile Nipper',
        'Tile Scoring Wheel',
        'Manual Tile Cutter Wheel',
        'Wet Saw Water Pump',
      ])
        item,
    ],
    aliases: const [
      'diamond blade',
      'tile blade',
      'hole saw',
      'core bit',
      'tile nipper',
    ],
  );
}

List<WorkSupplyItem> _tileInstallToolProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Install Tool Detail',
    unit: 'each',
    variants: [
      for (final notch in [
        '1/8 x 1/8 in',
        '3/16 x 5/32 in V Notch',
        '1/4 x 1/4 in',
        '1/4 x 3/8 in',
        '1/2 x 1/2 in',
        '3/4 x 9/16 in',
      ])
        for (final item in [
          'Square Notch Trowel',
          'V Notch Trowel',
          'U Notch Trowel',
          'Stainless Notched Trowel',
        ])
          '$notch $item',
      for (final item in [
        'Epoxy Grout Float',
        'Rubber Grout Float',
        'Margin Trowel',
        'Pointing Trowel',
        'Tile Sponge 3 Pack',
        'Microfiber Grout Sponge',
        'Grout Bag',
        'Grout Saw',
        'Carbide Grout Removal Blade',
        'Grout Brush',
      ])
        item,
    ],
    aliases: const [
      'notched trowel',
      'grout float',
      'margin trowel',
      'tile sponge',
      'grout saw',
    ],
  );
}

List<WorkSupplyItem> _tileAdditivePrimerProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Mortar Additive Primer Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 qt', '1 gal', '2 gal', '3.5 gal', '5 gal'])
        for (final item in [
          'Latex Mortar Additive',
          'Flexible Mortar Additive',
          'Tile Bonding Primer',
          'Self Leveling Primer',
          'Porous Surface Primer',
          'Non Porous Surface Primer',
          'Waterproofing Primer',
        ])
          '$size $item',
      for (final size in ['10 lb', '25 lb', '50 lb'])
        for (final item in [
          'Feather Finish Patch',
          'Rapid Set Floor Patch',
          'Deep Fill Floor Patch',
          'Skim Coat Patch',
        ])
          '$size $item',
    ],
    aliases: const [
      'mortar additive',
      'tile primer',
      'self leveling primer',
      'floor patch',
      'feather finish',
    ],
  );
}

List<WorkSupplyItem> _tileProtectionCleanupProducts() {
  return _tileInstallProducts(
    baseName: 'Tile Protection Cleanup Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 qt', '1 gal'])
        for (final item in [
          'Grout Release',
          'Grout Haze Remover',
          'Heavy Duty Grout Cleaner',
          'Stone Cleaner',
          'Tile Sealer',
          'Stone Enhancer',
          'Natural Stone Sealer',
        ])
          '$size $item',
      for (final item in [
        'Tile Edge Protection Tape',
        'Temporary Tile Floor Protection Roll',
        'Tile Lippage Tuning Kit',
        'Tile Cleanup Sponge Bucket',
        'Tile Installation Knee Pad',
        'Tile Layout Chalk Line',
      ])
        item,
    ],
    aliases: const [
      'grout release',
      'haze remover',
      'stone cleaner',
      'tile sealer',
      'floor protection',
    ],
  );
}

List<WorkSupplyItem> _tileInstallProducts({
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
