part of '../../work_supply_catalog.dart';

final windowsDoorsGeneratedDetailCatalogCategory = _category(
  'Windows Doors Detail Stock',
  [
    _system('Residential Windows and Opening Units', [
      _type(
        'Vinyl and Aluminum Windows',
        _windowsDoorsProducts(
          baseName: 'Window Unit',
          unit: 'each',
          variants: [
            for (final width in [
              '24 in',
              '28 in',
              '30 in',
              '32 in',
              '36 in',
              '40 in',
              '48 in',
            ])
              for (final height in [
                '36 in',
                '48 in',
                '54 in',
                '60 in',
                '72 in',
              ])
                for (final glass in ['Low E', 'Low E Grid', 'Tempered Low E'])
                  for (final style in [
                    'White Vinyl Single Hung Window',
                    'White Vinyl Double Hung Window',
                    'White Vinyl Sliding Window',
                    'Black Vinyl Single Hung Window',
                    'Black Vinyl Double Hung Window',
                    'Bronze Aluminum Sliding Window',
                    'New Construction Vinyl Window',
                    'Replacement Vinyl Window',
                  ])
                    '$width x $height $glass $style',
            for (final size in ['14 x 22 in', '22 x 22 in', '22 x 46 in'])
              for (final style in [
                'Glass Block Window',
                'Basement Hopper Window',
              ])
                '$size $style',
          ],
          aliases: const [
            'vinyl window',
            'single hung window',
            'double hung window',
            'sliding window',
            'replacement window',
            'basement window',
            'glass block window',
          ],
        ),
      ),
      _type(
        'Window Screens Sash and Repair Parts',
        _windowsDoorsProducts(
          baseName: 'Window Repair Part',
          unit: 'each',
          variants: [
            for (final color in ['White', 'Black', 'Bronze'])
              for (final size in ['24 x 36 in', '30 x 48 in', '36 x 60 in'])
                '$color $size Replacement Window Screen',
            for (final item in [
              'Window Sash Balance Pair',
              'Window Tilt Latch Pair',
              'Window Lock and Keeper Set',
              'Window Crank Operator',
              'Casement Window Handle',
              'Screen Frame Kit',
              'Fiberglass Screen Roll',
              'Aluminum Screen Roll',
              'Screen Spline Roll',
              'Screen Repair Patch Kit',
            ])
              item,
          ],
          aliases: const [
            'window screen',
            'sash balance',
            'tilt latch',
            'window lock',
            'window crank',
            'screen spline',
            'screen repair',
          ],
        ),
      ),
    ]),
    _system('Entry Interior Storm and Patio Doors', [
      _type(
        'Exterior Entry and Patio Doors',
        _windowsDoorsProducts(
          baseName: 'Exterior Door Unit',
          unit: 'each',
          variants: [
            for (final width in ['30 in', '32 in', '34 in', '36 in'])
              for (final hand in ['Left Hand Inswing', 'Right Hand Inswing'])
                for (final finish in ['Primed', 'White'])
                  for (final style in [
                    '6 Panel Steel Prehung Entry Door',
                    'Half Lite Steel Prehung Entry Door',
                    'Full Lite Steel Prehung Entry Door',
                    'Full Lite Fiberglass Prehung Entry Door',
                    'Craftsman Fiberglass Prehung Entry Door',
                    'Flush Steel Fire Rated Prehung Entry Door',
                  ])
                    '$width $finish $hand $style',
            for (final width in ['60 in', '72 in', '96 in'])
              for (final finish in [
                'White Vinyl',
                'Black Vinyl',
                'Bronze Aluminum',
              ])
                for (final glass in [
                  'Clear Glass',
                  'Low E Glass',
                  'Blinds Between Glass',
                ])
                  '$width $finish $glass Sliding Patio Door',
            for (final width in ['32 in', '36 in'])
              for (final color in ['White', 'Black', 'Bronze'])
                for (final style in [
                  'Full View Storm Door',
                  'Mid View Storm Door',
                  'Self Storing Storm Door',
                ])
                  '$color $width $style',
          ],
          aliases: const [
            'entry door',
            'prehung entry door',
            'steel door',
            'fiberglass door',
            'patio door',
            'sliding patio door',
            'storm door',
          ],
        ),
      ),
      _type(
        'Interior Doors Closet Doors and Slabs',
        _windowsDoorsProducts(
          baseName: 'Interior Door Unit',
          unit: 'each',
          variants: [
            for (final width in ['24 in', '28 in', '30 in', '32 in', '36 in'])
              for (final hand in ['Left Hand', 'Right Hand'])
                for (final style in [
                  '6 Panel Hollow Core Prehung Door',
                  '2 Panel Hollow Core Prehung Door',
                  '3 Panel Craftsman Hollow Core Prehung Door',
                  'Shaker Solid Core Prehung Door',
                  '2 Panel Solid Core Prehung Door',
                  'Primed Fire Rated Prehung Door',
                  'Flush Hollow Core Door Slab',
                  'Louvered Interior Door Slab',
                ])
                  '$width $hand $style',
            for (final width in ['24 in', '30 in', '36 in'])
              for (final style in [
                'Bifold Closet Door',
                'Mirror Bifold Closet Door',
                'Sliding Closet Door Kit',
                'Barn Door Slab',
              ])
                '$width $style',
          ],
          aliases: const [
            'interior door',
            'prehung door',
            'door slab',
            'hollow core door',
            'solid core door',
            'bifold door',
            'closet door',
            'barn door',
          ],
        ),
      ),
    ]),
    _system('Door Hardware Hinges and Locksets', [
      _type(
        'Locksets Deadbolts and Handlesets',
        _windowsDoorsProducts(
          baseName: 'Door Lock Hardware',
          unit: 'each',
          variants: [
            for (final finish in _doorHardwareFinishes)
              for (final style in [
                'Entry Door Knob',
                'Privacy Door Knob',
                'Passage Door Knob',
                'Dummy Door Knob',
                'Entry Door Lever',
                'Privacy Door Lever',
                'Passage Door Lever',
                'Dummy Door Lever',
                'Single Cylinder Deadbolt',
                'Double Cylinder Deadbolt',
                'Keypad Deadbolt',
                'Smart Wi-Fi Deadbolt',
                'Electronic Door Lever',
                'Front Door Handleset',
                'Interior Door Hardware Kit',
              ])
                '$finish $style',
          ],
          aliases: const [
            'door knob',
            'door lever',
            'lockset',
            'deadbolt',
            'handleset',
            'keypad deadbolt',
          ],
        ),
      ),
      _type(
        'Hinges Latches Rollers and Door Repair',
        _windowsDoorsProducts(
          baseName: 'Door Hardware Repair',
          unit: 'each',
          variants: [
            for (final finish in _doorHardwareFinishes)
              for (final size in ['3 in', '3-1/2 in', '4 in'])
                '$finish $size Door Hinge 3 Pack',
            for (final item in [
              'Door Latch Replacement Kit',
              'Strike Plate Reinforcer',
              'Security Strike Plate',
              'Hinge Shim Pack',
              'Pocket Door Roller Assembly',
              'Sliding Door Roller Assembly',
              'Sliding Door Handle Set',
              'Patio Door Lock Set',
              'Barn Door Track Hardware Kit',
              'Bifold Door Repair Kit',
              'Door Closer',
              'Commercial Door Closer',
              'Panic Exit Bar',
              'Kick Plate',
              'Push Plate',
              'Pull Plate',
              'Door Stop',
              'Wall Door Stop',
              'Floor Door Stop',
            ])
              item,
          ],
          aliases: const [
            'door hinge',
            'door latch',
            'strike plate',
            'hinge shim',
            'pocket door roller',
            'sliding door roller',
            'barn door hardware',
            'bifold repair',
          ],
        ),
      ),
    ]),
    _system('Jamb Threshold Weatherstrip and Install Supplies', [
      _type(
        'Jambs Thresholds Sweeps and Weatherstrip',
        _windowsDoorsProducts(
          baseName: 'Door Opening Weather Seal',
          unit: 'each',
          variants: [
            for (final width in ['30 in', '32 in', '36 in'])
              for (final finish in ['Mill', 'Bronze', 'White'])
                '$finish $width Adjustable Door Threshold',
            for (final width in ['30 in', '32 in', '36 in'])
              for (final finish in ['Mill', 'Bronze', 'White'])
                '$finish $width Low Profile Door Threshold',
            for (final width in ['30 in', '32 in', '36 in'])
              for (final style in [
                'Door Sweep',
                'U Shaped Door Bottom',
                'Automatic Door Bottom',
                'Kerf Door Weatherstrip Kit',
                'Magnetic Door Weatherstrip Kit',
                'Compression Weatherstrip Kit',
              ])
                '$width $style',
            for (final size in ['4-9/16 in', '5-1/4 in', '6-9/16 in'])
              for (final item in [
                'Exterior Door Jamb Kit',
                'Interior Door Jamb Kit',
                'Extension Jamb Kit',
              ])
                '$size $item',
          ],
          aliases: const [
            'door threshold',
            'adjustable threshold',
            'door sweep',
            'door bottom',
            'kerf weatherstrip',
            'door jamb',
            'jamb kit',
            'extension jamb',
          ],
        ),
      ),
      _type(
        'Opening Flashing Foam Shims and Sealants',
        _windowsDoorsProducts(
          baseName: 'Window Door Install Supply',
          unit: 'each',
          variants: [
            for (final size in ['12 oz', '16 oz', '20 oz'])
              for (final foam in [
                'Low Expansion Window Door Foam',
                'Pest Block Window Door Foam',
                'Fire Block Window Door Foam',
              ])
                '$size $foam',
            for (final width in ['4 in', '6 in', '9 in'])
              for (final tape in [
                'Window Door Flashing Tape',
                'Butyl Flashing Tape',
                'Stretch Flashing Tape',
              ])
                '$width $tape',
            for (final item in [
              'Composite Shims 12 Pack',
              'Cedar Shims 42 Pack',
              'Door Install Bracket Kit',
              'Window Installation Screw Pack',
              'Door Frame Anchor Pack',
              'Sill Pan Flashing Kit',
              'Backer Rod Roll',
              'Window Door Sealant Tube',
            ])
              item,
          ],
          aliases: const [
            'window door foam',
            'low expansion foam',
            'flashing tape',
            'window flashing',
            'door flashing',
            'shims',
            'install bracket',
            'sill pan',
            'window sealant',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _windowsDoorsProducts({
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

const _doorHardwareFinishes = [
  'Satin Nickel',
  'Matte Black',
  'Oil Rubbed Bronze',
  'Polished Brass',
  'Antique Brass',
  'Chrome',
];
