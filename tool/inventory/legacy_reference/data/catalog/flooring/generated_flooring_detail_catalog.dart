part of '../../work_supply_catalog.dart';

final flooringGeneratedDetailCatalogCategory = _category(
  'Flooring Detail Stock',
  [
    _system('Resilient Plank Tile and Sheet Flooring', [
      _type(
        'Luxury Vinyl Plank and Tile',
        _flooringProducts(
          baseName: 'Luxury Vinyl Flooring',
          unit: 'carton',
          variants: [
            for (final color in _flooringWoodLooks)
              for (final thickness in ['4 mm', '5 mm', '6 mm', '8 mm'])
                for (final style in [
                  'Click Lock LVP Plank',
                  'Waterproof Rigid Core LVP Plank',
                  'Glue Down LVP Plank',
                  'Loose Lay LVP Plank',
                  'SPC Vinyl Plank',
                  'WPC Vinyl Plank',
                ])
                  '$color $thickness $style',
            for (final color in _flooringStoneLooks)
              for (final size in ['12 x 24 in', '18 x 18 in', '24 x 24 in'])
                for (final style in [
                  'Click Lock LVT Tile',
                  'Glue Down LVT Tile',
                ])
                  '$color $size $style',
          ],
          aliases: const [
            'lvp',
            'vinyl plank',
            'luxury vinyl plank',
            'rigid core',
            'waterproof plank',
            'spc plank',
            'wpc plank',
            'lvt',
            'vinyl tile',
          ],
        ),
      ),
      _type(
        'Sheet Vinyl and Peel Stick',
        _flooringProducts(
          baseName: 'Vinyl Floor Covering',
          unit: 'roll',
          variants: [
            for (final pattern in _flooringStoneLooks)
              for (final width in ['6 ft', '12 ft'])
                '$pattern $width Sheet Vinyl Roll',
            for (final pattern in _flooringStoneLooks)
              for (final size in ['12 x 12 in', '12 x 24 in'])
                '$pattern $size Peel and Stick Vinyl Tile 20 Pack',
            for (final color in _flooringWoodLooks)
              for (final size in ['6 x 36 in', '7 x 48 in'])
                '$color $size Peel and Stick Vinyl Plank 20 Pack',
          ],
          aliases: const [
            'sheet vinyl',
            'vinyl roll',
            'peel stick tile',
            'peel and stick tile',
            'self stick plank',
          ],
        ),
      ),
    ]),
    _system('Laminate Hardwood and Engineered Wood', [
      _type(
        'Laminate Flooring',
        _flooringProducts(
          baseName: 'Laminate Flooring',
          unit: 'carton',
          variants: [
            for (final color in _flooringWoodLooks)
              for (final thickness in ['7 mm', '8 mm', '10 mm', '12 mm'])
                for (final rating in ['AC3', 'AC4', 'Water Resistant'])
                  '$color $thickness $rating Laminate Plank',
          ],
          aliases: const [
            'laminate',
            'laminate plank',
            'floating floor',
            'water resistant laminate',
          ],
        ),
      ),
      _type(
        'Hardwood and Engineered Flooring',
        _flooringProducts(
          baseName: 'Wood Flooring',
          unit: 'carton',
          variants: [
            for (final species in _flooringWoodSpecies)
              for (final width in ['2-1/4 in', '3-1/4 in', '5 in', '7 in'])
                for (final finish in ['Natural', 'Gunstock', 'Coffee', 'Gray'])
                  '$finish $width $species Solid Hardwood Plank',
            for (final species in _flooringWoodSpecies)
              for (final width in ['5 in', '6-1/2 in', '7-1/2 in'])
                for (final finish in [
                  'Natural',
                  'Wire Brushed',
                  'Hand Scraped',
                ])
                  '$finish $width $species Engineered Hardwood Plank',
          ],
          aliases: const [
            'hardwood',
            'solid hardwood',
            'engineered hardwood',
            'wood floor',
            'oak flooring',
            'maple flooring',
          ],
        ),
      ),
    ]),
    _system('Carpet Pad and Soft Flooring', [
      _type(
        'Carpet and Carpet Tile',
        _flooringProducts(
          baseName: 'Carpet Flooring',
          unit: 'roll',
          variants: [
            for (final color in _flooringCarpetColors)
              for (final style in ['Berber', 'Plush', 'Texture', 'Frieze'])
                for (final width in ['12 ft', '15 ft'])
                  '$color $width $style Carpet Roll',
            for (final color in _flooringCarpetColors)
              for (final size in ['18 x 18 in', '24 x 24 in'])
                '$color $size Carpet Tile 20 Pack',
          ],
          aliases: const [
            'carpet',
            'carpet roll',
            'carpet tile',
            'berber',
            'plush carpet',
          ],
        ),
      ),
      _type(
        'Carpet Pad Tack Strip and Seam Supplies',
        _flooringProducts(
          baseName: 'Carpet Install Supply',
          unit: 'each',
          variants: [
            for (final thickness in ['1/4 in', '3/8 in', '7/16 in', '1/2 in'])
              for (final density in ['6 lb', '8 lb', 'Memory Foam'])
                '$thickness $density Carpet Pad Roll',
            for (final item in [
              '4 ft Tack Strip Bundle',
              'Concrete Tack Strip Bundle',
              'Carpet Seam Tape Roll',
              'Hot Melt Carpet Seam Tape Roll',
              'Carpet Transition Binder Bar',
              'Knee Kicker Replacement Pad',
            ])
              item,
          ],
          aliases: const [
            'carpet pad',
            'tack strip',
            'seam tape',
            'binder bar',
            'knee kicker',
          ],
        ),
      ),
    ]),
    _system('Underlayment Moisture Control and Floor Prep', [
      _type(
        'Floor Underlayment and Moisture Barrier',
        _flooringProducts(
          baseName: 'Floor Underlayment',
          unit: 'roll',
          variants: [
            for (final coverage in ['100 sq ft', '200 sq ft', '400 sq ft'])
              for (final type in [
                'Foam Underlayment',
                'Cork Underlayment',
                'Rubber Underlayment',
                'Sound Control Underlayment',
                'Vapor Barrier Underlayment',
                'Moisture Barrier Film',
              ])
                '$coverage $type',
            for (final thickness in ['1/4 in', '1/2 in'])
              for (final size in ['4 x 4 ft', '4 x 8 ft'])
                '$thickness $size Plywood Floor Underlayment Panel',
          ],
          aliases: const [
            'floor underlayment',
            'foam underlayment',
            'cork underlayment',
            'moisture barrier',
            'vapor barrier',
            'sound underlayment',
          ],
        ),
      ),
      _type(
        'Leveler Patch and Subfloor Prep',
        _flooringProducts(
          baseName: 'Floor Prep Material',
          unit: 'bag',
          variants: [
            for (final size in ['10 lb', '25 lb', '40 lb', '50 lb'])
              for (final material in [
                'Self Leveling Underlayment',
                'Floor Patch',
                'Feather Finish Patch',
                'Floor Leveler Primer',
                'Concrete Floor Primer',
              ])
                '$size $material',
            for (final size in ['Quart', '1 gal', '5 gal'])
              for (final material in [
                'Floor Adhesive Remover',
                'Moisture Vapor Barrier Coating',
              ])
                '$size $material',
          ],
          aliases: const [
            'self leveler',
            'floor leveler',
            'floor patch',
            'feather finish',
            'leveler primer',
            'adhesive remover',
          ],
        ),
      ),
    ]),
    _system('Transitions Trim Stair Parts Adhesives and Fasteners', [
      _type(
        'Transitions and Floor Trim',
        _flooringProducts(
          baseName: 'Floor Transition Trim',
          unit: 'piece',
          variants: [
            for (final color in _flooringWoodLooks)
              for (final length in ['72 in', '78 in', '94 in'])
                for (final profile in [
                  'T Molding',
                  'Reducer',
                  'End Cap',
                  'Threshold',
                  'Quarter Round',
                  'Shoe Molding',
                  'Stair Nose',
                  'Overlap Stair Nose',
                ])
                  '$color $length $profile',
            for (final finish in ['Satin Nickel', 'Bronze', 'Silver', 'Gold'])
              for (final length in ['36 in', '72 in'])
                for (final profile in [
                  'Metal Transition Strip',
                  'Carpet Gripper Transition',
                  'Vinyl Floor Divider',
                ])
                  '$finish $length $profile',
          ],
          aliases: const [
            't molding',
            'transition strip',
            'reducer',
            'end cap',
            'threshold',
            'quarter round',
            'shoe molding',
            'stair nose',
          ],
        ),
      ),
      _type(
        'Floor Adhesives Fasteners and Repair',
        _flooringProducts(
          baseName: 'Floor Install Supply',
          unit: 'each',
          variants: [
            for (final size in ['Quart', '1 gal', '4 gal'])
              for (final adhesive in [
                'Vinyl Flooring Adhesive',
                'Wood Flooring Adhesive',
                'Carpet Adhesive',
                'Pressure Sensitive Adhesive',
              ])
                '$size $adhesive',
            for (final item in [
              'Flooring Installation Kit',
              'Laminate Pull Bar Kit',
              'Floor Spacers 30 Pack',
              'Floor Tapping Block',
              'Hardwood Floor Cleat 1000 Pack',
              'Hardwood Flooring Staple 5000 Pack',
              'Floor Repair Marker Kit',
              'Laminate Floor Repair Putty',
              'Vinyl Plank Seam Roller',
              'Flooring Cutter Replacement Blade',
            ])
              item,
          ],
          aliases: const [
            'floor adhesive',
            'vinyl adhesive',
            'wood adhesive',
            'floor install kit',
            'pull bar',
            'spacers',
            'floor cleat',
            'floor staple',
            'floor repair',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _flooringProducts({
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

const _flooringWoodLooks = [
  'Oak',
  'Natural Oak',
  'Gray Oak',
  'Walnut',
  'Hickory',
  'Maple',
  'Pine',
  'Barnwood',
  'Weathered Gray',
  'Espresso',
  'Chestnut',
  'Acacia',
];

const _flooringWoodSpecies = [
  'Red Oak',
  'White Oak',
  'Maple',
  'Hickory',
  'Birch',
  'Bamboo',
];

const _flooringStoneLooks = [
  'Carrara',
  'Slate',
  'Travertine',
  'Concrete Gray',
  'Sandstone',
  'Black Marble',
  'Limestone',
  'Terrazzo',
];

const _flooringCarpetColors = [
  'Beige',
  'Taupe',
  'Gray',
  'Charcoal',
  'Brown',
  'Navy',
  'Sand',
  'Oatmeal',
];
