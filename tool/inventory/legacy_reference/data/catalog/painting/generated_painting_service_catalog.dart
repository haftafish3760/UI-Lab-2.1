part of '../../work_supply_catalog.dart';

final paintingGeneratedServiceCatalogCategory = _category(
  'Expanded Painting Service Stock',
  [
    _system('Expanded Paint and Primer', [
      _type(
        'Interior Paint Bases',
        _paintingProducts(
          baseName: 'Interior Paint',
          unit: 'can',
          variants: [
            for (final sheen in _paintSheens)
              for (final size in _paintCanSizes)
                '$size ${_titlePaintSheen(sheen)}',
          ],
          aliases: const ['wall paint', 'interior coating', 'latex paint'],
        ),
      ),
      _type(
        'Exterior Paint Bases',
        _paintingProducts(
          baseName: 'Exterior Paint',
          unit: 'can',
          variants: [
            for (final sheen in ['flat', 'satin', 'semi-gloss'])
              for (final size in _paintCanSizes)
                '$size ${_titlePaintSheen(sheen)}',
          ],
          aliases: const ['outside paint', 'exterior coating'],
        ),
      ),
      _type(
        'Primers and Sealers',
        _paintingProducts(
          baseName: 'Primer or Sealer',
          unit: 'can',
          variants: [
            for (final kind in [
              'Drywall Primer',
              'Stain Blocking Primer',
              'Bonding Primer',
              'Masonry Primer',
              'Oil Based Primer',
            ])
              for (final size in ['quart', '1 gal', '5 gal']) '$size $kind',
          ],
          aliases: const ['paint primer', 'sealer', 'stain blocker'],
        ),
      ),
      _type('Stains Clear Coats and Specialty Coatings', _specialtyCoatings()),
    ]),
    _system('Expanded Brushes Rollers and Trays', [
      _type(
        'Brushes and Roller Covers',
        _paintingProducts(
          baseName: 'Paint Applicator',
          unit: 'each',
          variants: [
            for (final brush in [
              '1 in Angle Brush',
              '2 in Angle Brush',
              '2-1/2 in Angle Brush',
              '3 in Flat Brush',
            ])
              brush,
            for (final nap in [
              '1/4 in nap',
              '3/8 in nap',
              '1/2 in nap',
              '3/4 in nap',
              '1 in nap',
            ])
              for (final length in ['4 in', '9 in', '18 in'])
                '$length $nap Roller Cover',
          ],
          aliases: const ['paint brush', 'roller cover', 'roller sleeve'],
        ),
      ),
      _type(
        'Frames Trays and Liners',
        _paintingProducts(
          baseName: 'Paint Tray or Frame',
          unit: 'each',
          variants: const [
            '4 in Mini Roller Frame',
            '9 in Roller Frame',
            '18 in Roller Frame',
            'Metal Paint Tray',
            'Plastic Paint Tray',
            'Paint Tray Liner Pack',
            '5 gal Bucket Grid',
            'Paint Pail',
          ],
          aliases: const ['roller frame', 'paint tray', 'tray liner'],
        ),
      ),
      _type(
        'Sprayers Poles and Application Accessories',
        _sprayerAccessoryProducts(),
      ),
    ]),
    _system('Expanded Prep and Masking', [
      _type(
        'Tape Plastic and Paper',
        _paintingProducts(
          baseName: 'Masking Supply',
          unit: 'roll',
          variants: [
            for (final width in ['0.94 in', '1.41 in', '1.88 in', '2.83 in'])
              '$width Painter Tape',
            for (final size in [
              '9 ft x 12 ft',
              '12 ft x 400 ft',
              '24 in x 180 ft',
              '48 in x 180 ft',
            ])
              '$size Plastic Sheeting',
            '6 in x 180 ft Masking Paper',
            '9 in x 180 ft Masking Paper',
            '12 in x 180 ft Masking Paper',
          ],
          aliases: const ['painter tape', 'masking tape', 'drop plastic'],
        ),
      ),
      _type(
        'Abrasives and Surface Prep',
        _paintingProducts(
          baseName: 'Paint Prep Supply',
          unit: 'each',
          variants: [
            for (final grit in [
              '80 grit',
              '120 grit',
              '150 grit',
              '180 grit',
              '220 grit',
            ])
              for (final type in ['Sanding Sponge', 'Sandpaper Pack'])
                '$grit $type',
            'Tack Cloth Pack',
            'Deglosser Quart',
            'TSP Cleaner Box',
            'Paint Scraper',
            'Putty Knife',
          ],
          aliases: const ['sandpaper', 'sanding sponge', 'surface prep'],
        ),
      ),
      _type(
        'Paint Removers Cleaners and Surface Treatments',
        _paintRemovalProducts(),
      ),
    ]),
    _system('Expanded Caulk Patch and Repair', [
      _type(
        'Paintable Caulk and Sealants',
        _paintingProducts(
          baseName: 'Paintable Sealant',
          unit: 'tube',
          variants: [
            for (final color in ['white', 'clear', 'almond'])
              for (final kind in [
                'Acrylic Latex Caulk',
                'Siliconized Acrylic Caulk',
                'Painter Caulk',
              ])
                '10 oz $color $kind',
          ],
          aliases: const ['paintable caulk', 'acrylic caulk', 'painter caulk'],
        ),
      ),
      _type(
        'Patch Compounds',
        _paintingProducts(
          baseName: 'Paint Patch Material',
          unit: 'each',
          variants: const [
            '8 oz Spackling Compound',
            '16 oz Spackling Compound',
            '32 oz Spackling Compound',
            '1 gal Spackling Compound',
            'Wood Filler 6 oz',
            'Wood Filler 16 oz',
            'Painter Putty 16 oz',
            'Orange Peel Texture Spray',
            'Knockdown Texture Spray',
          ],
          aliases: const ['spackle', 'wood filler', 'painter putty'],
        ),
      ),
    ]),
    _system('Expanded Sundries and Cleanup', [
      _type(
        'Mixing and Cleanup Supplies',
        _paintingProducts(
          baseName: 'Painting Sundry',
          unit: 'each',
          variants: const [
            '1 qt Paint Cup',
            '1 gal Paint Bucket',
            '5 gal Paint Bucket',
            'Paint Strainer Bag Pack',
            'Stir Stick Pack',
            'Paint Can Opener',
            'Latex Gloves Pack',
            'Rags Pack',
            'Mineral Spirits Quart',
            'Paint Thinner Quart',
            'Brush Cleaner Quart',
          ],
          aliases: const ['paint sundry', 'cleanup supply', 'paint thinner'],
        ),
      ),
      _type('Painter Safety and Color Supplies', _painterSafetyColorProducts()),
    ]),
    _system('Expanded Pro Prep Specialty and Sprayer Service', [
      _type(
        'Concrete Garage and Specialty Prep',
        _paintingProducts(
          baseName: 'Specialty Coating Prep Supply',
          unit: 'each',
          variants: [
            for (final size in ['quart', '1 gal'])
              for (final prep in [
                'Concrete Etcher',
                'Concrete Cleaner Degreaser',
                'Garage Floor Cleaner',
                'Masonry Cleaner',
                'Rust Converter',
                'Metal Degreaser',
              ])
                '$size $prep',
            'Garage Floor Flake Pack',
            'Epoxy Anti-Skid Additive',
            'Concrete Crack Filler 10 oz',
            'Concrete Patch and Repair 1 qt',
            'Floor Coating Roller Cover 9 in',
            'Acid Brush Pack',
          ],
          aliases: const [
            'concrete etcher',
            'garage floor cleaner',
            'rust converter',
            'anti skid additive',
            'floor coating roller',
          ],
        ),
      ),
      _type(
        'Specialty Painter Sealants and Gap Fillers',
        _paintingProducts(
          baseName: 'Painter Sealant Specialty',
          unit: 'tube',
          variants: [
            for (final color in ['White', 'Clear', 'Gray', 'Almond'])
              for (final sealant in [
                'Elastomeric Sealant',
                'Advanced Acrylic Sealant',
                'Window Door Trim Sealant',
                'Big Stretch Sealant',
                'Paintable Silicone Sealant',
              ])
                '10 oz $color $sealant',
            'Backer Rod 3/8 in x 20 ft',
            'Backer Rod 1/2 in x 20 ft',
            'Backer Rod 5/8 in x 20 ft',
            'Caulk Finishing Tool Kit',
            'Caulk Saver Cap Pack',
          ],
          aliases: const [
            'elastomeric sealant',
            'big stretch',
            'paintable silicone',
            'backer rod',
            'caulk tool',
          ],
        ),
      ),
      _type(
        'Sprayer Tips Filters and Service Parts',
        _paintingProducts(
          baseName: 'Sprayer Service Part',
          unit: 'each',
          variants: [
            for (final tip in [
              '0.011',
              '0.013',
              '0.015',
              '0.017',
              '0.019',
              '0.021',
            ])
              for (final fan in ['211', '313', '315', '415', '517', '619'])
                '$tip $fan Airless Spray Tip',
            for (final mesh in ['30 mesh', '60 mesh', '100 mesh', '150 mesh'])
              '$mesh Spray Gun Filter Pack',
            'Airless Tip Guard',
            'Sprayer Pump Repair Kit',
            'Sprayer Inlet Strainer',
            'Sprayer Manifold Filter',
            'Pressure Roller Attachment',
            'Sprayer Storage Fluid Quart',
          ],
          aliases: const [
            'airless tip',
            'spray gun filter',
            'tip guard',
            'pump repair kit',
            'sprayer strainer',
          ],
        ),
      ),
      _type(
        'Masking Film Drop Cloth and Disposal',
        _paintingProducts(
          baseName: 'Painter Protection Supply',
          unit: 'each',
          variants: [
            for (final size in [
              '24 in x 180 ft',
              '48 in x 180 ft',
              '72 in x 90 ft',
              '99 in x 90 ft',
            ])
              '$size Pre-Taped Masking Film',
            for (final size in [
              '4 ft x 12 ft',
              '9 ft x 12 ft',
              '12 ft x 15 ft',
            ])
              '$size Canvas Drop Cloth',
            for (final size in ['1 qt', '1 gal']) '$size Paint Hardener',
            'Paint Disposal Bag Kit',
            'Hazardous Waste Label Pack',
            'Bucket Lid Pour Spout',
            'Paint Can Clip Pack',
          ],
          aliases: const [
            'pre taped masking film',
            'canvas drop cloth',
            'paint hardener',
            'paint disposal',
            'pour spout',
          ],
        ),
      ),
    ]),
    _system('Bulk Painting Receipt Variants', [
      _type(
        'Bulk Paint Coatings',
        _paintingProducts(
          baseName: 'Paint Coating',
          unit: 'can',
          variants: [
            for (final size in ['quart', '1 gal', '5 gal'])
              for (final sheen in [
                'Flat',
                'Matte',
                'Eggshell',
                'Satin',
                'Semi-Gloss',
                'Gloss',
              ])
                for (final use in [
                  'Interior Wall',
                  'Exterior House',
                  'Ceiling',
                  'Trim and Door',
                  'Cabinet and Furniture',
                  'Porch and Floor',
                ])
                  '$size $sheen $use',
            for (final finish in [
              'Flat Black',
              'Gloss White',
              'Satin Nickel',
              'Primer Gray',
              'Rust Preventive Black',
            ])
              '12 oz $finish Spray Paint',
          ],
          aliases: const [
            'paint',
            'wall paint',
            'ceiling paint',
            'spray paint',
            'cabinet paint',
          ],
        ),
      ),
      _type(
        'Bulk Primers Stains and Sealers',
        _paintingProducts(
          baseName: 'Primer Stain or Sealer',
          unit: 'can',
          variants: [
            for (final size in ['quart', '1 gal', '5 gal'])
              for (final kind in [
                'Drywall Primer',
                'Multi Purpose Primer',
                'Stain Blocking Primer',
                'Bonding Primer',
                'Masonry Primer',
                'Shellac Primer',
                'Oil Based Primer',
                'Waterproofing Sealer',
                'Deck Stain',
                'Fence Stain',
              ])
                '$size $kind',
          ],
          aliases: const [
            'primer',
            'sealer',
            'stain blocker',
            'deck stain',
            'fence stain',
          ],
        ),
      ),
    ]),
    _system('Bulk Painting Tools Prep and Cleanup', [
      _type(
        'Bulk Brushes Rollers and Kits',
        _paintingProducts(
          baseName: 'Paint Tool',
          unit: 'each',
          variants: [
            for (final width in [
              '1 in',
              '1-1/2 in',
              '2 in',
              '2-1/2 in',
              '3 in',
            ])
              for (final style in ['Angle Brush', 'Flat Brush', 'Trim Brush'])
                '$width $style',
            for (final length in ['4 in', '6 in', '9 in', '14 in', '18 in'])
              for (final nap in [
                '1/4 in',
                '3/8 in',
                '1/2 in',
                '3/4 in',
                '1 in',
              ])
                for (final pack in ['Single', '3 Pack', '6 Pack'])
                  '$length $nap nap Roller Cover $pack',
            '9 in Roller Frame',
            '18 in Roller Frame',
            'Paint Edger',
            'Paint Pad',
            '5 gal Bucket Grid',
            'Paint Tray Kit',
          ],
          aliases: const [
            'paint brush',
            'roller cover',
            'roller sleeve',
            'paint kit',
          ],
        ),
      ),
      _type(
        'Bulk Masking Drop Cloth and Prep',
        _paintingProducts(
          baseName: 'Paint Prep Material',
          unit: 'each',
          variants: [
            for (final width in ['0.94 in', '1.41 in', '1.88 in', '2.83 in'])
              for (final grade in [
                'General Purpose',
                'Delicate Surface',
                'Exterior',
              ])
                '$width $grade Painter Tape',
            for (final size in ['6 ft x 9 ft', '9 ft x 12 ft', '12 ft x 15 ft'])
              for (final material in [
                'Canvas Drop Cloth',
                'Plastic Drop Cloth',
              ])
                '$size $material',
            for (final grit in [
              '80 grit',
              '120 grit',
              '150 grit',
              '180 grit',
              '220 grit',
            ])
              for (final item in ['Sandpaper Pack', 'Sanding Sponge'])
                '$grit $item',
            'Tack Cloth Pack',
            'Masking Film 48 in x 180 ft',
            'Masking Paper 12 in x 180 ft',
            'Paint Scraper',
            'Putty Knife',
          ],
          aliases: const [
            'painter tape',
            'masking tape',
            'drop cloth',
            'sandpaper',
          ],
        ),
      ),
      _type(
        'Bulk Caulk Patch and Solvents',
        _paintingProducts(
          baseName: 'Paint Repair or Cleanup Supply',
          unit: 'each',
          variants: [
            for (final color in ['White', 'Clear', 'Almond', 'Brown'])
              for (final caulk in [
                'Acrylic Latex Caulk',
                'Siliconized Acrylic Caulk',
                'Painter Caulk',
                'Window Door and Trim Sealant',
              ])
                '10 oz $color $caulk',
            for (final size in ['8 oz', '16 oz', '32 oz', '1 gal'])
              for (final patch in [
                'Lightweight Spackle',
                'Vinyl Spackle',
                'Wood Filler',
                'Painter Putty',
              ])
                '$size $patch',
            for (final size in ['quart', '1 gal'])
              for (final solvent in [
                'Mineral Spirits',
                'Paint Thinner',
                'Brush Cleaner',
                'Denatured Alcohol',
                'TSP Substitute',
              ])
                '$size $solvent',
          ],
          aliases: const [
            'painter caulk',
            'paintable caulk',
            'spackle',
            'paint thinner',
          ],
        ),
      ),
      _type(
        'Bulk Painter Consumables',
        _paintingProducts(
          baseName: 'Painter Consumable',
          unit: 'pack',
          variants: [
            for (final pack in ['10 Pack', '25 Pack', '50 Pack', '100 Pack'])
              for (final item in [
                'Stir Stick',
                'Paint Strainer Bag',
                'Lint Free Rag',
                'Tack Cloth',
                'Disposable Glove',
                'Paint Can Lid',
                'Paint Pail Liner',
                'Tray Liner',
                'Razor Blade',
                'Respirator Pre Filter',
              ])
                '$item $pack',
          ],
          aliases: const [
            'paint sundry',
            'paint supplies',
            'painter supply',
            'cleanup supply',
          ],
        ),
      ),
      _type(
        'Bulk Specialty Coatings and Concrete Paint',
        _paintingProducts(
          baseName: 'Specialty Paint Coating',
          unit: 'can',
          variants: [
            for (final size in ['quart', '1 gal', '5 gal'])
              for (final coating in [
                'Porch and Patio Floor Paint',
                'Concrete Garage Floor Paint',
                'Garage Floor Epoxy Coating',
                'Concrete Epoxy Coating',
                'Basement Waterproofing Paint',
                'Masonry Waterproofing Paint',
                'Metal Rust Preventive Paint',
                'High Heat Paint',
                'Chalkboard Paint',
                'Dry Erase Paint',
              ])
                '$size $coating',
            for (final size in ['quart', '1 gal'])
              for (final clear in [
                'Satin Polyurethane',
                'Gloss Polyurethane',
                'Spar Urethane',
                'Clear Shellac',
                'Wood Conditioner',
              ])
                '$size $clear',
          ],
          aliases: const [
            'floor paint',
            'garage floor paint',
            'epoxy coating',
            'polyurethane',
            'high heat paint',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _specialtyCoatings() {
  return _paintingProducts(
    baseName: 'Specialty Paint or Finish',
    unit: 'can',
    variants: [
      for (final size in ['8 oz', 'quart', '1 gal'])
        for (final stain in [
          'Interior Wood Stain',
          'Exterior Wood Stain',
          'Deck Stain',
          'Fence Stain',
          'Gel Stain',
        ])
          '$size $stain',
      for (final size in ['quart', '1 gal'])
        for (final clear in [
          'Polyurethane',
          'Spar Urethane',
          'Water Based Polycrylic',
          'Shellac',
          'Lacquer',
        ])
          '$size $clear',
      '12 oz Appliance Epoxy Spray Paint',
      '12 oz High Heat Spray Paint',
      '12 oz Fluorescent Marking Paint',
      '12 oz Metallic Spray Paint',
      '12 oz Primer Spray Paint',
    ],
    aliases: const [
      'wood stain',
      'deck stain',
      'polyurethane',
      'spray paint',
      'high heat paint',
    ],
  );
}

List<WorkSupplyItem> _sprayerAccessoryProducts() {
  return _paintingProducts(
    baseName: 'Paint Application Accessory',
    unit: 'each',
    variants: [
      for (final length in ['2 ft', '4 ft', '6 ft', '8 ft'])
        '$length Extension Pole',
      for (final size in ['0.011 in', '0.013 in', '0.015 in', '0.017 in'])
        '$size Airless Spray Tip',
      'Airless Spray Tip Guard',
      'Paint Sprayer Filter Pack',
      'Sprayer Hose 25 ft',
      'Sprayer Hose 50 ft',
      'Handheld Paint Sprayer Cup',
      'Pump Armor Quart',
      'Masking Machine',
      'Hand Masker Film Blade',
      'Paint Edger Refill Pack',
      'Paint Pad Refill Pack',
    ],
    aliases: const [
      'extension pole',
      'spray tip',
      'paint sprayer',
      'masking machine',
      'hand masker',
    ],
  );
}

List<WorkSupplyItem> _paintRemovalProducts() {
  return _paintingProducts(
    baseName: 'Paint Surface Treatment',
    unit: 'each',
    variants: [
      for (final size in ['quart', '1 gal'])
        for (final remover in [
          'Paint Stripper',
          'Paint Remover',
          'Adhesive Remover',
          'Mildew Stain Remover',
          'Deck Cleaner',
          'Concrete Etcher',
          'Liquid Sandpaper Deglosser',
        ])
          '$size $remover',
      'Lead Paint Test Kit',
      'Mold and Mildew Cleaner Spray',
      'Sanding Block',
      'Pole Sander Head',
      'Hand Sander',
      'Wire Brush Paint Scraper',
    ],
    aliases: const [
      'paint stripper',
      'paint remover',
      'deglosser',
      'lead test kit',
      'deck cleaner',
    ],
  );
}

List<WorkSupplyItem> _painterSafetyColorProducts() {
  return _paintingProducts(
    baseName: 'Painter Safety or Color Supply',
    unit: 'each',
    variants: [
      for (final size in ['Half Pint', 'Quart'])
        for (final item in ['Paint Sample', 'Color Sample']) '$size $item',
      for (final color in ['Black', 'Brown', 'Red', 'Blue', 'Yellow'])
        '$color Universal Colorant',
      'Paint Color Fan Deck',
      'Paint Formula Label Pack',
      'Disposable Paint Suit',
      'Painter Respirator Cartridge Pack',
      'Spray Sock Hood',
      'Shoe Cover Pack',
      'Nitrile Gloves Painter Pack',
      'Paint Waste Hardener',
      'Paint Disposal Bag',
      'Paint Pour Spout',
    ],
    aliases: const [
      'paint sample',
      'color sample',
      'colorant',
      'paint suit',
      'paint hardener',
    ],
  );
}

List<WorkSupplyItem> _paintingProducts({
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

const _paintSheens = ['flat', 'eggshell', 'satin', 'semi-gloss', 'gloss'];
const _paintCanSizes = ['sample', 'quart', '1 gal', '5 gal'];

String _titlePaintSheen(String sheen) {
  return sheen
      .split('-')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join('-');
}
