part of '../../work_supply_catalog.dart';

final sidingExteriorGeneratedDetailCatalogCategory = _category(
  'Siding Exterior Detail Stock',
  [
    _system('Siding Panels Planks and Shakes', [
      _type(
        'Vinyl Siding Panels',
        _sidingProducts(
          baseName: 'Vinyl Siding Panel',
          unit: 'carton',
          variants: [
            for (final color in _sidingColors)
              for (final profile in [
                'Double 4 in Dutch Lap',
                'Double 4 in Traditional Lap',
                'Double 5 in Traditional Lap',
                'Triple 3 in Lap',
                'Board and Batten',
              ])
                '$color $profile',
          ],
          aliases: const [
            'vinyl siding',
            'd4 dutch lap',
            'd4 siding',
            'd5 siding',
            'board batten siding',
          ],
        ),
      ),
      _type(
        'Fiber Cement and Engineered Siding',
        _sidingProducts(
          baseName: 'Exterior Siding Board',
          unit: 'piece',
          variants: [
            for (final color in _sidingColors)
              for (final width in ['6-1/4 in', '7-1/4 in', '8-1/4 in'])
                for (final material in [
                  'Fiber Cement Lap Siding',
                  'Engineered Wood Lap Siding',
                  'Cedar Texture Lap Siding',
                ])
                  '$color $width $material',
            for (final color in _sidingColors)
              for (final panel in [
                '4 x 8 Fiber Cement Panel',
                '4 x 8 Engineered Wood Panel',
                '4 x 8 T1-11 Siding Panel',
              ])
                '$color $panel',
          ],
          aliases: const [
            'fiber cement siding',
            'cement siding',
            'engineered siding',
            'lap siding',
            't1-11',
            'siding panel',
          ],
        ),
      ),
      _type(
        'Shake Shingle and Specialty Siding',
        _sidingProducts(
          baseName: 'Specialty Siding',
          unit: 'carton',
          variants: [
            for (final color in _sidingColors)
              for (final style in [
                'Vinyl Cedar Shake Siding',
                'Perfection Shingle Siding',
                'Staggered Shake Siding',
                'Scallop Siding',
              ])
                '$color $style',
          ],
          aliases: const [
            'cedar shake siding',
            'shake siding',
            'shingle siding',
            'scallop siding',
          ],
        ),
      ),
    ]),
    _system('Siding Trim Corners and Channels', [
      _type(
        'Starter Corners and Receiver Trim',
        _sidingProducts(
          baseName: 'Siding Trim',
          unit: 'piece',
          variants: [
            for (final color in _sidingColors)
              for (final length in ['10 ft', '12 ft'])
                for (final trim in [
                  'Starter Strip',
                  'J Channel',
                  'F Channel',
                  'Undersill Trim',
                  'Finish Trim',
                  'Utility Trim',
                  'Outside Corner Post',
                  'Inside Corner Post',
                ])
                  '$color $length $trim',
          ],
          aliases: const [
            'starter strip',
            'j channel',
            'f channel',
            'undersill trim',
            'finish trim',
            'utility trim',
            'corner post',
          ],
        ),
      ),
      _type(
        'Trim Boards Coil and Mounting Blocks',
        _sidingProducts(
          baseName: 'Exterior Trim Accessory',
          unit: 'piece',
          variants: [
            for (final color in _sidingColors)
              for (final width in ['4 in', '6 in', '8 in', '12 in'])
                '$color $width PVC Trim Board',
            for (final color in _sidingColors)
              for (final width in ['12 in', '24 in'])
                '$color $width Aluminum Trim Coil',
            for (final color in _sidingColors)
              for (final block in [
                'Light Mounting Block',
                'Outlet Mounting Block',
                'Hose Bib Mounting Block',
                'Universal Mounting Block',
              ])
                '$color $block',
          ],
          aliases: const [
            'pvc trim board',
            'trim coil',
            'aluminum coil',
            'mounting block',
            'siding block',
          ],
        ),
      ),
    ]),
    _system('Weather Barrier Flashing and Exterior Sealants', [
      _type(
        'Housewrap Flashing and Drainage',
        _sidingProducts(
          baseName: 'Exterior Weather Barrier',
          unit: 'roll',
          variants: [
            for (final size in ['3 x 100 ft', '5 x 100 ft', '9 x 100 ft'])
              for (final wrap in [
                'Housewrap Roll',
                'Drainage Housewrap Roll',
                'Commercial Grade Housewrap Roll',
              ])
                '$size $wrap',
            for (final width in ['4 in', '6 in', '9 in', '12 in'])
              for (final tape in [
                'Flashing Tape',
                'Butyl Flashing Tape',
                'Housewrap Seam Tape',
              ])
                '$width $tape',
            for (final item in [
              'Rain Screen Mat Roll',
              'Siding Drainage Mat Roll',
              'Window Flashing Pan',
              'Door Sill Pan',
            ])
              item,
          ],
          aliases: const [
            'housewrap',
            'house wrap',
            'flashing tape',
            'seam tape',
            'rain screen',
            'drainage mat',
            'sill pan',
          ],
        ),
      ),
      _type(
        'Siding Sealant and Repair',
        _sidingProducts(
          baseName: 'Siding Sealant Repair',
          unit: 'each',
          variants: [
            for (final color in _sidingColors)
              for (final sealant in [
                'Color Match Siding Caulk',
                'Exterior Polyurethane Sealant',
                'Window Door Siding Sealant',
              ])
                '$color $sealant',
            for (final item in [
              'Vinyl Siding Repair Kit',
              'Fiber Cement Patch Compound',
              'Siding Removal Tool',
              'Siding Zip Tool',
              'Siding Touch Up Paint',
            ])
              item,
          ],
          aliases: const [
            'siding caulk',
            'siding sealant',
            'vinyl siding repair',
            'fiber cement patch',
            'zip tool',
          ],
        ),
      ),
    ]),
    _system('Vents Shutters Fasteners and Exterior Accessories', [
      _type(
        'Siding Vents Shutters and Blocks',
        _sidingProducts(
          baseName: 'Exterior Siding Accessory',
          unit: 'each',
          variants: [
            for (final color in _sidingColors)
              for (final vent in [
                'Gable Vent',
                'Foundation Vent',
                'Dryer Vent Hood',
                'Mini Louver Vent',
                'Round Siding Vent',
              ])
                '$color $vent',
            for (final color in _sidingColors)
              for (final height in ['31 in', '39 in', '43 in', '55 in'])
                for (final style in [
                  'Raised Panel Vinyl Shutter Pair',
                  'Louvered Vinyl Shutter Pair',
                  'Board and Batten Shutter Pair',
                ])
                  '$color $height $style',
          ],
          aliases: const [
            'gable vent',
            'foundation vent',
            'dryer vent hood',
            'louver vent',
            'vinyl shutter',
            'shutter pair',
          ],
        ),
      ),
      _type(
        'Exterior Siding Fasteners',
        _sidingProducts(
          baseName: 'Siding Fastener',
          unit: 'box',
          variants: [
            for (final length in ['1-1/4 in', '1-1/2 in', '2 in', '2-1/2 in'])
              for (final finish in ['Hot Dipped Galvanized', 'Stainless Steel'])
                for (final fastener in [
                  'Siding Nail',
                  'Ring Shank Siding Nail',
                  'Trim Nail',
                ])
                  '$finish $length $fastener',
            for (final length in ['1-1/4 in', '1-5/8 in', '2 in'])
              for (final screw in [
                'Fiber Cement Screw',
                'Exterior Trim Screw',
                'Siding Panel Screw',
              ])
                '$length $screw',
          ],
          aliases: const [
            'siding nail',
            'ring shank siding nail',
            'trim nail',
            'fiber cement screw',
            'siding screw',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _sidingProducts({
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

const _sidingColors = [
  'White',
  'Almond',
  'Clay',
  'Sandstone',
  'Gray',
  'Charcoal',
  'Brown',
  'Black',
  'Blue',
  'Sage',
  'Cedar',
  'Tan',
];
