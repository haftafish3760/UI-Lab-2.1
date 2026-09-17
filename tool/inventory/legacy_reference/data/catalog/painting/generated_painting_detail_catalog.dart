part of '../../work_supply_catalog.dart';

final paintingGeneratedDetailCatalogCategory = _category(
  'Painting Detail Stock',
  [
    _system('Architectural Paint and Primer Detail', [
      _type(
        'Interior and Exterior Paint Detail',
        _paintingProducts(
          baseName: 'Architectural Paint Detail',
          unit: 'can',
          variants: [
            for (final size in ['Quart', '1 gal', '5 gal'])
              for (final sheen in _paintingSheens)
                for (final use in [
                  'Interior Wall Paint',
                  'Interior Trim Paint',
                  'Exterior Siding Paint',
                  'Exterior Trim Paint',
                  'Porch and Floor Paint',
                  'Cabinet and Furniture Paint',
                ])
                  '$size $sheen $use',
            for (final size in ['8 oz', 'Half Pint', 'Quart'])
              for (final sheen in ['Flat', 'Satin', 'Semi Gloss'])
                '$size $sheen Paint Sample',
          ],
          aliases: const [
            'interior paint',
            'exterior paint',
            'trim paint',
            'cabinet paint',
            'porch paint',
            'floor paint',
            'paint sample',
          ],
        ),
      ),
      _type(
        'Primer and Sealer Detail',
        _paintingProducts(
          baseName: 'Primer Sealer Detail',
          unit: 'can',
          variants: [
            for (final size in ['Quart', '1 gal', '5 gal'])
              for (final type in [
                'Drywall Primer',
                'Stain Blocking Primer',
                'Bonding Primer',
                'Masonry Primer',
                'Metal Primer',
                'Shellac Primer',
                'Oil Based Primer',
              ])
                '$size $type',
          ],
          aliases: const [
            'primer',
            'drywall primer',
            'stain blocker',
            'bonding primer',
            'shellac primer',
            'oil primer',
          ],
        ),
      ),
    ]),
    _system('Stains Clear Coats and Specialty Coatings', [
      _type(
        'Stain and Clear Coat Detail',
        _paintingProducts(
          baseName: 'Stain Clear Coat Detail',
          unit: 'can',
          variants: [
            for (final size in ['Quart', '1 gal'])
              for (final tone in ['Natural', 'Cedar', 'Walnut', 'Espresso'])
                for (final stain in ['Deck Stain', 'Fence Stain', 'Gel Stain'])
                  '$size $tone $stain',
            for (final size in ['Quart', '1 gal'])
              for (final sheen in ['Satin', 'Semi Gloss', 'Gloss'])
                for (final clear in [
                  'Polyurethane',
                  'Polycrylic',
                  'Spar Urethane',
                  'Lacquer',
                ])
                  '$size $sheen $clear',
          ],
          aliases: const [
            'deck stain',
            'fence stain',
            'gel stain',
            'polyurethane',
            'polycrylic',
            'spar urethane',
            'lacquer',
          ],
        ),
      ),
      _type(
        'Specialty Coating Detail',
        _paintingProducts(
          baseName: 'Specialty Paint Coating Detail',
          unit: 'can',
          variants: [
            for (final size in ['Quart', '1 gal'])
              for (final coating in [
                'Garage Floor Epoxy',
                'Rust Preventive Enamel',
                'High Heat Paint',
                'Appliance Epoxy',
                'Chalkboard Paint',
                'Dry Erase Paint',
                'Masonry Waterproofing Paint',
              ])
                '$size $coating',
          ],
          aliases: const [
            'garage floor epoxy',
            'rust paint',
            'high heat paint',
            'appliance epoxy',
            'chalkboard paint',
            'dry erase paint',
            'waterproofing paint',
          ],
        ),
      ),
    ]),
    _system('Application Tools Masking and Surface Prep', [
      _type(
        'Brush Roller and Tray Detail',
        _paintingProducts(
          baseName: 'Paint Tool Detail',
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
            for (final width in ['4 in', '6 in', '9 in', '18 in'])
              for (final nap in ['1/4 in nap', '3/8 in nap', '1/2 in nap'])
                for (final pack in ['Single', '3 Pack', '6 Pack'])
                  '$width $nap Roller Cover $pack',
            for (final item in ['Metal Paint Tray', 'Tray Liner 10 Pack']) item,
          ],
          aliases: const [
            'paint brush',
            'angle brush',
            'roller cover',
            'paint tray',
            'tray liner',
          ],
        ),
      ),
      _type(
        'Masking Protection and Prep Detail',
        _paintingProducts(
          baseName: 'Painting Prep Detail',
          unit: 'each',
          variants: [
            for (final width in ['0.94 in', '1.41 in', '1.88 in', '2.83 in'])
              for (final tape in [
                'General Purpose Painter Tape',
                'Delicate Surface Painter Tape',
                'Exterior Painter Tape',
              ])
                '$width $tape',
            for (final size in ['48 in', '72 in', '99 in'])
              for (final film in ['Masking Film', 'Pre-Taped Masking Film'])
                '$size $film',
            for (final size in ['9 x 12 ft', '12 x 15 ft'])
              for (final cloth in ['Canvas Drop Cloth', 'Plastic Drop Cloth'])
                '$size $cloth',
            for (final item in ['Tack Cloth Pack', 'Sanding Sponge Pack']) item,
          ],
          aliases: const [
            'painter tape',
            'masking tape',
            'masking film',
            'pre taped film',
            'drop cloth',
            'tack cloth',
          ],
        ),
      ),
    ]),
    _system('Sprayers Removers Sealants and Disposal', [
      _type(
        'Sprayer and Remover Detail',
        _paintingProducts(
          baseName: 'Sprayer Prep Detail',
          unit: 'each',
          variants: [
            for (final size in ['0.011', '0.013', '0.015', '0.017', '0.019'])
              '$size Airless Spray Tip',
            for (final mesh in ['60 Mesh', '100 Mesh', '200 Mesh'])
              '$mesh Spray Gun Filter Pack',
            for (final item in [
              'Tip Guard',
              'Sprayer Pump Repair Kit',
              'Manifold Filter',
              'Pump Armor Storage Fluid',
              'Quart Paint Stripper',
              'Quart Liquid Sandpaper Deglosser',
              'Lead Paint Test Kit',
              'Rust Converter',
            ])
              item,
          ],
          aliases: const [
            'airless spray tip',
            'spray gun filter',
            'sprayer repair',
            'pump armor',
            'paint stripper',
            'deglosser',
            'lead test',
            'rust converter',
          ],
        ),
      ),
      _type(
        'Painter Sealant and Disposal Detail',
        _paintingProducts(
          baseName: 'Painter Sealant Disposal Detail',
          unit: 'each',
          variants: [
            for (final color in ['White', 'Clear', 'Almond'])
              for (final sealant in [
                '10 oz Painter Caulk',
                '10 oz Big Stretch Sealant',
                '10 oz Paintable Silicone',
              ])
                '$color $sealant',
            for (final size in ['3/8 in', '1/2 in', '5/8 in'])
              '$size Backer Rod 20 ft',
            for (final item in [
              'Paint Waste Hardener',
              'Paint Disposal Bag',
              'Paint Can Pour Spout',
              'Paint Can Clip',
            ])
              item,
          ],
          aliases: const [
            'painter caulk',
            'big stretch',
            'paintable silicone',
            'backer rod',
            'paint hardener',
            'paint disposal',
          ],
        ),
      ),
    ]),
  ],
);

const _paintingSheens = [
  'Flat',
  'Matte',
  'Eggshell',
  'Satin',
  'Semi Gloss',
  'Gloss',
];
