part of '../../work_supply_catalog.dart';

final tileGeneratedServiceCatalogCategory = _category(
  'Expanded Tile Service Stock',
  [
    _system('Expanded Tile Materials', [
      _type(
        'Ceramic and Porcelain Tile',
        _tileProducts(
          baseName: 'Tile',
          unit: 'box',
          variants: [
            for (final material in ['Ceramic', 'Porcelain'])
              for (final use in ['Wall', 'Floor'])
                for (final size in [
                  '3 x 6 in',
                  '4 x 12 in',
                  '12 x 12 in',
                  '12 x 24 in',
                  '24 x 24 in',
                ])
                  '$size $material $use',
            '2 x 2 in Porcelain Mosaic Sheet',
            'Hexagon Porcelain Mosaic Sheet',
            'Penny Round Porcelain Mosaic Sheet',
          ],
          aliases: const ['ceramic tile', 'porcelain tile', 'mosaic tile'],
        ),
      ),
      _type(
        'Natural Stone Tile',
        _tileProducts(
          baseName: 'Stone Tile',
          unit: 'box',
          variants: [
            for (final stone in ['Marble', 'Travertine', 'Slate', 'Granite'])
              for (final size in ['12 x 12 in', '12 x 24 in', '18 x 18 in'])
                '$size $stone',
          ],
          aliases: const ['natural stone tile', 'stone floor tile'],
        ),
      ),
    ]),
    _system('Expanded Setting Materials', [
      _type(
        'Thinset and Tile Adhesive',
        _tileProducts(
          baseName: 'Tile Setting Material',
          unit: 'bag',
          variants: [
            for (final color in ['Gray', 'White'])
              for (final type in [
                'Modified Thinset Mortar',
                'Large Format Tile Mortar',
                'Uncoupling Membrane Mortar',
              ])
                '50 lb $color $type',
            '1 gal Tile Mastic',
            '3.5 gal Tile Mastic',
          ],
          aliases: const [
            'thinset',
            'thin set',
            'tile mortar',
            'tile adhesive',
          ],
        ),
      ),
      _type(
        'Grout and Sealer',
        _tileProducts(
          baseName: 'Tile Grout Material',
          unit: 'bag',
          variants: [
            for (final color in ['White', 'Gray', 'Bone', 'Charcoal'])
              for (final type in ['Sanded Grout', 'Unsanded Grout'])
                '10 lb $color $type',
            '25 lb Gray Sanded Grout',
            '16 oz Grout Sealer',
            '32 oz Grout Sealer',
          ],
          aliases: const [
            'tile grout',
            'sanded grout',
            'unsanded grout',
            'grout sealer',
          ],
        ),
      ),
    ]),
    _system('Expanded Waterproofing and Shower Systems', [
      _type(
        'Membranes and Backer Board',
        _tileProducts(
          baseName: 'Tile Waterproofing Material',
          unit: 'each',
          variants: const [
            '3 ft x 16 ft Waterproofing Membrane Roll',
            '3 ft x 33 ft Waterproofing Membrane Roll',
            '3 ft x 98 ft Uncoupling Membrane Roll',
            '1/4 in 3 x 5 ft Cement Backer Board',
            '1/2 in 3 x 5 ft Cement Backer Board',
            '1/2 in 4 x 8 ft Foam Backer Board',
            'Waterproofing Liquid Membrane 1 gal',
            'Waterproofing Liquid Membrane 3.5 gal',
          ],
          aliases: const [
            'shower membrane',
            'uncoupling membrane',
            'cement board',
            'backer board',
          ],
        ),
      ),
      _type(
        'Shower Pans Drains and Niches',
        _tileProducts(
          baseName: 'Tile Shower System Part',
          unit: 'each',
          variants: const [
            '48 x 48 in Shower Pan Kit',
            '60 x 32 in Shower Pan Kit',
            '60 x 36 in Shower Pan Kit',
            '24 in Linear Shower Drain',
            '36 in Linear Shower Drain',
            '48 in Linear Shower Drain',
            '12 x 12 in Shower Niche',
            '12 x 24 in Shower Niche',
          ],
          aliases: const ['shower pan', 'linear drain', 'shower niche'],
        ),
      ),
      _type(
        'Shower Curbs Benches Shelves and Waterproofing Accessories',
        _tileProducts(
          baseName: 'Tile Shower Waterproofing Accessory',
          unit: 'each',
          variants: [
            for (final length in ['48 in', '60 in']) '$length Foam Shower Curb',
            'Foam Shower Bench',
            'Triangular Corner Shower Shelf',
            'Rectangle Corner Shower Shelf',
            'Waterproofing Seam Tape Roll',
            'Waterproofing Inside Corner 2 Pack',
            'Waterproofing Outside Corner 2 Pack',
            'Backer Board Screw 185 Pack',
            'Backer Board Washer 100 Pack',
            'Pipe Seal Waterproofing Collar',
            'Mixing Valve Waterproofing Seal',
          ],
          aliases: const [
            'shower curb',
            'shower bench',
            'corner shelf',
            'seam tape',
            'backer board screw',
            'waterproofing collar',
          ],
        ),
      ),
    ]),
    _system('Expanded Tile Tools and Accessories', [
      _type(
        'Spacers Leveling and Profiles',
        _tileProducts(
          baseName: 'Tile Layout Accessory',
          unit: 'pack',
          variants: [
            for (final size in ['1/16 in', '1/8 in', '3/16 in', '1/4 in'])
              '$size Tile Spacer',
            for (final size in ['1/16 in', '1/8 in', '3/16 in'])
              '$size Tile Leveling Clip',
            'Tile Leveling Wedge Pack',
            '8 ft Brushed Nickel Tile Edge Trim',
            '8 ft Black Tile Edge Trim',
          ],
          aliases: const [
            'tile spacer',
            'leveling clips',
            'tile profile',
            'edge trim',
          ],
        ),
      ),
      _type(
        'Trowels Blades and Cleanup',
        _tileProducts(
          baseName: 'Tile Tool',
          unit: 'each',
          variants: const [
            '1/4 x 1/4 in Notched Trowel',
            '1/4 x 3/8 in Notched Trowel',
            '1/2 x 1/2 in Notched Trowel',
            '7 in Wet Saw Diamond Blade',
            '10 in Wet Saw Diamond Blade',
            'Grout Float',
            'Tile Sponge Pack',
            'Tile Nipper',
            'Margin Trowel',
          ],
          aliases: const [
            'tile trowel',
            'diamond blade',
            'grout float',
            'tile sponge',
          ],
        ),
      ),
      _type(
        'Thresholds Profiles and Movement Joints',
        _tileProducts(
          baseName: 'Tile Trim or Threshold',
          unit: 'each',
          variants: [
            for (final width in ['2 in', '4 in', '6 in'])
              for (final length in ['36 in', '48 in', '72 in'])
                '$width x $length White Marble Threshold',
            for (final finish in ['Brushed Nickel', 'Matte Black', 'Aluminum'])
              for (final side in ['Inside Corner', 'Outside Corner'])
                '$finish Tile Profile $side Piece',
            for (final length in ['8 ft', '10 ft'])
              '$length Movement Joint Profile',
            'Stair Nose Tile Profile',
            'Tile Reducer Transition Strip',
            'Tile T Molding Transition Strip',
          ],
          aliases: const [
            'marble threshold',
            'tile sill',
            'profile corner',
            'movement joint',
            'tile transition',
          ],
        ),
      ),
      _type(
        'Grout Caulk Repair and Cleanup',
        _tileProducts(
          baseName: 'Tile Repair or Cleanup Supply',
          unit: 'each',
          variants: [
            for (final color in [
              'White',
              'Alabaster',
              'Bone',
              'Warm Gray',
              'Charcoal',
              'Black',
            ])
              '$color Sanded Ceramic Tile Caulk',
            for (final color in ['White', 'Gray', 'Charcoal'])
              '$color Grout Colorant',
            'Grout Haze Remover Quart',
            'Grout Saw',
            'Manual Grout Removal Tool',
            'Tile Repair Mortar Tube',
            'Tile Chip Repair Kit',
            'Stone Sealer 1 qt',
            'Natural Stone Enhancer 1 qt',
          ],
          aliases: const [
            'grout caulk',
            'tile caulk',
            'grout colorant',
            'grout haze remover',
            'grout saw',
            'stone sealer',
          ],
        ),
      ),
    ]),
    _system('Bulk Tile Receipt Variants', [
      _type(
        'Bulk Ceramic Porcelain and Stone Tile',
        _tileProducts(
          baseName: 'Tile Box',
          unit: 'box',
          variants: [
            for (final material in [
              'Ceramic',
              'Porcelain',
              'Glazed Porcelain',
              'Matte Porcelain',
              'Polished Porcelain',
            ])
              for (final use in ['Wall', 'Floor', 'Floor and Wall'])
                for (final size in [
                  '3 x 6 in',
                  '4 x 12 in',
                  '6 x 24 in',
                  '8 x 8 in',
                  '12 x 12 in',
                  '12 x 24 in',
                  '24 x 24 in',
                  '24 x 48 in',
                ])
                  '$size $material $use',
            for (final stone in [
              'Marble',
              'Travertine',
              'Slate',
              'Granite',
              'Pebble',
            ])
              for (final size in [
                '2 x 2 in Mosaic',
                '12 x 12 in',
                '12 x 24 in',
              ])
                '$size $stone Natural Stone',
            for (final mosaic in [
              'Penny Round',
              'Hexagon',
              'Herringbone',
              'Basketweave',
              'Subway',
              'Pebble',
            ])
              '$mosaic Mosaic Sheet',
          ],
          aliases: const [
            'ceramic tile',
            'porcelain tile',
            'floor tile',
            'wall tile',
            'mosaic tile',
          ],
        ),
      ),
      _type(
        'Glass Decorative and Trim Tile',
        _tileProducts(
          baseName: 'Decorative Tile',
          unit: 'box',
          variants: [
            for (final finish in [
              'Clear Glass',
              'Frosted Glass',
              'Blue Glass',
              'White Ceramic',
              'Matte Black Ceramic',
            ])
              for (final shape in [
                '3 x 6 in Subway Tile',
                '4 x 12 in Subway Tile',
                'Pencil Liner',
                'Chair Rail',
                'Mosaic Accent Strip',
              ])
                '$finish $shape',
            for (final color in ['White', 'Almond', 'Gray', 'Black'])
              for (final trim in [
                '3 x 12 in Bullnose Tile',
                '4 x 16 in Bullnose Tile',
                '6 x 6 in Cove Base Tile',
                'Inside Corner Cove Base',
                'Outside Corner Cove Base',
              ])
                '$color $trim',
          ],
          aliases: const [
            'glass tile',
            'bullnose tile',
            'cove base tile',
            'pencil liner',
            'accent tile',
          ],
        ),
      ),
      _type(
        'Bulk Mortar Adhesive Grout and Sealer',
        _tileProducts(
          baseName: 'Tile Setting Supply',
          unit: 'each',
          variants: [
            for (final color in ['Gray', 'White'])
              for (final mortar in [
                'Modified Thinset Mortar',
                'Large Format Tile Mortar',
                'LFT Mortar',
                'Uncoupling Membrane Mortar',
                'Rapid Setting Mortar',
                'Natural Stone Mortar',
              ])
                '50 lb $color $mortar',
            for (final size in ['1 gal', '3.5 gal'])
              for (final adhesive in ['Tile Mastic', 'Premixed Thinset'])
                '$size $adhesive',
            for (final color in [
              'White',
              'Alabaster',
              'Bone',
              'Warm Gray',
              'Silver',
              'Pewter',
              'Charcoal',
              'Black',
              'Haystack',
              'Mocha',
            ])
              for (final grout in [
                'Sanded Grout',
                'Unsanded Grout',
                'Premixed Grout',
                'Epoxy Grout',
              ])
                for (final size in ['1 qt', '10 lb', '25 lb'])
                  '$size $color $grout',
            '16 oz Grout Sealer',
            '32 oz Grout Sealer',
            '1 gal Grout Sealer',
            'Grout Haze Remover Quart',
          ],
          aliases: const [
            'thinset',
            'thin set',
            'lft mortar',
            'tile mortar',
            'grout',
            'grout sealer',
          ],
        ),
      ),
    ]),
    _system('Bulk Tile Shower Waterproofing and Accessories', [
      _type(
        'Bulk Shower Waterproofing Systems',
        _tileProducts(
          baseName: 'Tile Waterproofing System Part',
          unit: 'each',
          variants: [
            for (final size in [
              '3 ft x 16 ft',
              '3 ft x 33 ft',
              '3 ft x 98 ft',
              '39 in x 98 ft',
            ])
              for (final membrane in [
                'Waterproofing Membrane Roll',
                'Uncoupling Membrane Roll',
                'Crack Isolation Membrane Roll',
              ])
                '$size $membrane',
            for (final thickness in ['1/4 in', '1/2 in', '5/8 in'])
              for (final board in [
                '3 x 5 ft Cement Backer Board',
                '3 x 5 ft Foam Backer Board',
                '4 x 8 ft Foam Backer Board',
                '4 x 8 ft Glass Mat Backer Board',
              ])
                '$thickness $board',
            'Waterproofing Band Roll',
            'Inside Corner Waterproofing Piece',
            'Outside Corner Waterproofing Piece',
            'Pipe Seal Waterproofing Piece',
            'Mixing Valve Seal Waterproofing Piece',
          ],
          aliases: const [
            'shower membrane',
            'uncoupling membrane',
            'backer board',
            'cement board',
            'waterproofing band',
          ],
        ),
      ),
      _type(
        'Crack Isolation Primer and Heated Floor Supplies',
        _tileProducts(
          baseName: 'Tile Underlayment System Supply',
          unit: 'each',
          variants: [
            for (final size in [
              '3 ft x 33 ft',
              '3 ft x 50 ft',
              '39 in x 50 ft',
              '39 in x 98 ft',
            ])
              for (final membrane in [
                'Crack Isolation Membrane Roll',
                'Anti Fracture Membrane Roll',
                'Uncoupling Membrane Roll',
                'Peel and Stick Tile Membrane Roll',
              ])
                '$size $membrane',
            for (final size in ['1 qt', '1 gal', '2 gal'])
              for (final primer in [
                'Tile Membrane Primer',
                'Self Leveling Primer',
                'Waterproofing Primer',
              ])
                '$size $primer',
            for (final coverage in [
              '10 sq ft',
              '15 sq ft',
              '25 sq ft',
              '50 sq ft',
            ])
              for (final item in [
                'Electric Floor Heat Mat',
                'Radiant Floor Heat Cable Kit',
                'Uncoupling Heat Membrane Sheet',
              ])
                '$coverage $item',
            'Floor Heat Thermostat',
            'Floor Heat Sensor Wire',
            'Floor Heat Repair Kit',
            'Self Leveling Underlayment 50 lb',
            'LevelQuik Underlayment 50 lb',
          ],
          aliases: const [
            'crack isolation membrane',
            'anti fracture membrane',
            'membrane primer',
            'floor heat mat',
            'heated floor',
          ],
        ),
      ),
      _type(
        'Bulk Shower Drains Pans Niches and Profiles',
        _tileProducts(
          baseName: 'Tile Shower and Trim Part',
          unit: 'each',
          variants: [
            for (final size in [
              '32 x 60 in',
              '36 x 60 in',
              '48 x 48 in',
              '60 x 60 in',
            ])
              for (final pan in ['Shower Pan Kit', 'Shower Tray Kit'])
                '$size $pan',
            for (final length in ['24 in', '32 in', '36 in', '48 in', '60 in'])
              for (final finish in [
                'Stainless',
                'Matte Black',
                'Brushed Nickel',
                'Oil Rubbed Bronze',
                'Polished Chrome',
              ])
                '$length $finish Linear Shower Drain',
            for (final finish in [
              'Stainless',
              'Matte Black',
              'Brushed Nickel',
              'Oil Rubbed Bronze',
            ])
              for (final style in [
                'Square Shower Drain Grate',
                'Tileable Drain Grate',
                'Point Drain Grate',
                'Linear Drain Grate Cover',
              ])
                '$finish $style',
            for (final size in ['12 x 12 in', '12 x 20 in', '12 x 24 in'])
              for (final niche in ['Shower Niche', 'Double Shower Niche'])
                '$size $niche',
            for (final size in ['6 x 12 in', '12 x 28 in', '16 x 20 in'])
              for (final niche in [
                'Foam Shower Niche',
                'Waterproof Shower Niche',
              ])
                '$size $niche',
            for (final accessory in [
              'Waterproof Corner Shelf',
              'Stainless Corner Shelf',
              'Recessed Foot Rest',
              'Foam Shower Bench Seat',
              'Floating Shower Bench Bracket',
              'Shower Curb Overlay',
            ])
              accessory,
            for (final length in ['8 ft', '10 ft'])
              for (final finish in [
                'Aluminum',
                'Brushed Nickel',
                'Matte Black',
                'White PVC',
              ])
                for (final profile in [
                  'Tile Edge Trim',
                  'Jolly Profile',
                  'Rondec Profile',
                  'Schiene Profile',
                ])
                  '$length $finish $profile',
          ],
          aliases: const [
            'shower pan',
            'linear drain',
            'shower niche',
            'schluter trim',
            'tile profile',
          ],
        ),
      ),
    ]),
    _system('Bulk Tile Layout Tools and Consumables', [
      _type(
        'Bulk Tile Spacers Leveling and Trowels',
        _tileProducts(
          baseName: 'Tile Layout Supply',
          unit: 'pack',
          variants: [
            for (final size in [
              '1/16 in',
              '1/8 in',
              '3/16 in',
              '1/4 in',
              '3/8 in',
            ])
              for (final item in [
                'Tile Spacer 500 Pack',
                'Tile Spacer 1000 Pack',
                'Tile Leveling Clip 100 Pack',
                'Tile Leveling Clip 300 Pack',
                'Tile Leveling Wedge 100 Pack',
              ])
                '$size $item',
            for (final notch in [
              '1/4 x 1/4 in',
              '1/4 x 3/8 in',
              '1/2 x 1/2 in',
              '3/16 x 5/32 in V Notch',
            ])
              '$notch Notched Trowel',
            for (final size in ['4 in', '4-1/2 in', '7 in', '10 in'])
              for (final blade in [
                'Wet Saw Diamond Blade',
                'Continuous Rim Blade',
              ])
                '$size $blade',
            'Grout Float',
            'Epoxy Grout Float',
            'Margin Trowel',
            'Tile Sponge 3 Pack',
            'Grout Bag',
            'Tile Nipper',
            'Tile Wedge Pack',
          ],
          aliases: const [
            'tile spacer',
            'leveling clip',
            'leveling wedge',
            'notched trowel',
            'diamond blade',
          ],
        ),
      ),
    ]),
    _system('Pro Tile Service Detail Stock', [
      _type(
        'Decorative Mosaics Trim and Accent Detail',
        _decorativeTileDetailProducts(),
      ),
      _type(
        'Advanced Mortar Grout and Prep Detail',
        _advancedSettingDetailProducts(),
      ),
      _type(
        'Waterproof Shower and Heated Floor Detail',
        _waterproofShowerDetailProducts(),
      ),
      _type(
        'Tile Tools Cleanup and Repair Detail',
        _tileToolCleanupDetailProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _decorativeTileDetailProducts() {
  return _tileProducts(
    baseName: 'Tile Decorative Detail',
    unit: 'box',
    variants: [
      for (final color in [
        'White',
        'Matte White',
        'Gloss White',
        'Gray',
        'Black',
        'Blue',
        'Carrara',
      ])
        for (final shape in [
          '3 x 6 in Subway Tile',
          '4 x 12 in Subway Tile',
          '2 x 2 in Mosaic Sheet',
          'Hexagon Mosaic Sheet',
          'Penny Round Mosaic Sheet',
          'Herringbone Mosaic Sheet',
          'Basketweave Mosaic Sheet',
          'Arabesque Mosaic Sheet',
        ])
          '$color $shape',
      for (final finish in [
        'White Ceramic',
        'Gray Ceramic',
        'Black Ceramic',
        'Carrara Marble',
        'Travertine',
      ])
        for (final trim in [
          '3 x 12 in Bullnose Tile',
          '4 x 16 in Bullnose Tile',
          '6 x 6 in Cove Base Tile',
          'Inside Corner Cove Base',
          'Outside Corner Cove Base',
          'Pencil Liner',
          'Chair Rail',
          'Quarter Round Trim',
        ])
          '$finish $trim',
    ],
    aliases: const [
      'mosaic sheet',
      'subway tile',
      'bullnose tile',
      'cove base tile',
      'pencil liner',
      'quarter round tile',
    ],
  );
}

List<WorkSupplyItem> _advancedSettingDetailProducts() {
  return _tileProducts(
    baseName: 'Tile Setting Detail Supply',
    unit: 'each',
    variants: [
      for (final color in ['Gray', 'White'])
        for (final mortar in [
          'Modified Thinset Mortar',
          'Large Format Tile Mortar',
          'LFT Mortar',
          'Rapid Setting Mortar',
          'Natural Stone Mortar',
          'Glass Tile Mortar',
          'Medium Bed Mortar',
          'Uncoupling Membrane Mortar',
        ])
          '50 lb $color $mortar',
      for (final size in ['1 qt', '1 gal', '3.5 gal'])
        for (final adhesive in [
          'Tile Mastic',
          'Premixed Thinset',
          'Tile Membrane Primer',
          'Self Leveling Primer',
          'Latex Mortar Additive',
        ])
          '$size $adhesive',
      for (final color in [
        'White',
        'Alabaster',
        'Bone',
        'Warm Gray',
        'Silver',
        'Pewter',
        'Charcoal',
        'Black',
        'Haystack',
        'Mocha',
      ])
        for (final grout in [
          'Sanded Grout',
          'Unsanded Grout',
          'Premixed Grout',
          'Epoxy Grout',
          'Urethane Grout',
          'High Performance Grout',
        ])
          for (final size in ['1 qt', '1 gal', '10 lb', '25 lb'])
            '$size $color $grout',
    ],
    aliases: const [
      'large format mortar',
      'rapid set mortar',
      'glass tile mortar',
      'premixed grout',
      'epoxy grout',
      'urethane grout',
    ],
  );
}

List<WorkSupplyItem> _waterproofShowerDetailProducts() {
  return _tileProducts(
    baseName: 'Tile Waterproofing Detail Supply',
    unit: 'each',
    variants: [
      for (final size in [
        '3 ft x 16 ft',
        '3 ft x 33 ft',
        '3 ft x 98 ft',
        '39 in x 98 ft',
      ])
        for (final membrane in [
          'Waterproofing Membrane Roll',
          'Uncoupling Membrane Roll',
          'Crack Isolation Membrane Roll',
          'Anti Fracture Membrane Roll',
          'Peel and Stick Tile Membrane Roll',
        ])
          '$size $membrane',
      for (final thickness in ['1/4 in', '1/2 in', '5/8 in'])
        for (final board in [
          '3 x 5 ft Cement Backer Board',
          '3 x 5 ft Foam Backer Board',
          '4 x 8 ft Foam Backer Board',
          '4 x 8 ft Glass Mat Backer Board',
        ])
          '$thickness $board',
      for (final item in [
        'Waterproofing Band Roll',
        'Inside Corner Waterproofing Piece',
        'Outside Corner Waterproofing Piece',
        'Pipe Seal Waterproofing Collar',
        'Mixing Valve Waterproofing Seal',
        'Backer Board Screw 185 Pack',
        'Foam Board Washer 100 Pack',
        'Kerdi Fix Sealant Tube',
        'Waterproof Sealant Tube',
      ])
        item,
      for (final size in [
        '32 x 60 in',
        '36 x 60 in',
        '48 x 48 in',
        '60 x 60 in',
      ])
        for (final part in [
          'Shower Tray Kit',
          'Shower Pan Kit',
          'Shower Pan Extension',
        ])
          '$size $part',
      for (final coverage in ['10 sq ft', '15 sq ft', '25 sq ft', '50 sq ft'])
        for (final heat in [
          'Electric Floor Heat Mat',
          'Radiant Floor Heat Cable Kit',
          'Uncoupling Heat Membrane Sheet',
        ])
          '$coverage $heat',
      'Floor Heat Thermostat',
      'Floor Heat Sensor Wire',
      'Floor Heat Repair Kit',
      'Floor Heat Alarm Monitor',
    ],
    aliases: const [
      'waterproofing band',
      'waterproofing corner',
      'foam board washer',
      'kerdi fix',
      'shower pan extension',
      'floor heat sensor',
    ],
  );
}

List<WorkSupplyItem> _tileToolCleanupDetailProducts() {
  return _tileProducts(
    baseName: 'Tile Tool Cleanup Detail',
    unit: 'each',
    variants: [
      for (final size in ['1/16 in', '1/8 in', '3/16 in', '1/4 in', '3/8 in'])
        for (final item in [
          'Tile Spacer 500 Pack',
          'Tile Leveling Clip 100 Pack',
          'Tile Leveling Clip 300 Pack',
          'Tile Leveling Wedge 100 Pack',
          'Reusable Tile Leveling Cap 50 Pack',
        ])
          '$size $item',
      for (final notch in [
        '1/4 x 1/4 in',
        '1/4 x 3/8 in',
        '1/2 x 1/2 in',
        '3/16 x 5/32 in V Notch',
      ])
        '$notch Notched Trowel',
      for (final size in ['4 in', '4-1/2 in', '7 in', '10 in'])
        for (final blade in [
          'Wet Saw Diamond Blade',
          'Continuous Rim Tile Blade',
          'Porcelain Diamond Blade',
          'Glass Tile Blade',
        ])
          '$size $blade',
      for (final item in [
        'Epoxy Grout Float',
        'Rubber Grout Float',
        'Margin Trowel',
        'Tile Sponge 3 Pack',
        'Microfiber Grout Sponge',
        'Grout Haze Remover Quart',
        'Grout Release Quart',
        'Grout Sealer Applicator Bottle',
        'Grout Saw',
        'Carbide Grout Removal Blade',
        'Tile Nipper',
        'Tile Hole Saw Kit',
        'Tile Chip Repair Kit',
        'Stone Sealer 1 qt',
        'Natural Stone Enhancer 1 qt',
      ])
        item,
    ],
    aliases: const [
      'tile leveling cap',
      'porcelain blade',
      'glass tile blade',
      'epoxy grout float',
      'grout release',
      'grout removal blade',
    ],
  );
}

List<WorkSupplyItem> _tileProducts({
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
