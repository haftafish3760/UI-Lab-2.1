part of '../../work_supply_catalog.dart';

final fencingGeneratedDetailCatalogCategory = _category(
  'Fencing Detail Stock',
  [
    _system('Wood Vinyl and Composite Fence Detail', [
      _type(
        'Wood Fence Boards Rails and Posts',
        _fencingProducts(
          baseName: 'Wood Fence Detail',
          unit: 'each',
          variants: [
            for (final species in ['Cedar', 'Pressure Treated Pine', 'Redwood'])
              for (final style in [
                'Dog Ear Picket',
                'Flat Top Picket',
                'Privacy Board',
              ])
                for (final size in [
                  '5/8 in x 5-1/2 in x 6 ft',
                  '3/4 in x 5-1/2 in x 6 ft',
                  '1 x 6 x 8 ft',
                ])
                  '$size $species $style',
            for (final size in [
              '2 x 3 x 8 ft',
              '2 x 4 x 8 ft',
              '2 x 4 x 10 ft',
            ])
              for (final species in ['Cedar', 'Pressure Treated Pine'])
                '$size $species Fence Rail',
            for (final size in ['4 x 4 x 6 ft', '4 x 4 x 8 ft', '6 x 6 x 8 ft'])
              '$size Pressure Treated Fence Post',
          ],
          aliases: const [
            'wood fence picket',
            'dog ear picket',
            'privacy board',
            'fence rail',
            'fence post',
          ],
        ),
      ),
      _type(
        'Vinyl Composite and Decorative Panels',
        _fencingProducts(
          baseName: 'Vinyl Composite Fence Detail',
          unit: 'each',
          variants: [
            for (final color in ['White', 'Tan', 'Gray'])
              for (final style in [
                'Privacy Panel',
                'Picket Panel',
                'Lattice Top Panel',
              ])
                for (final size in [
                  '4 ft x 8 ft',
                  '6 ft x 6 ft',
                  '6 ft x 8 ft',
                ])
                  '$color Vinyl $size $style',
            for (final color in ['White', 'Tan', 'Gray'])
              for (final length in ['6 ft', '8 ft'])
                '$color Vinyl Fence Rail $length',
            for (final color in ['Black', 'Bronze'])
              for (final size in ['4 ft x 6 ft', '5 ft x 6 ft'])
                '$color $size Aluminum Fence Panel',
          ],
          aliases: const [
            'vinyl privacy panel',
            'vinyl picket panel',
            'vinyl rail',
            'aluminum fence panel',
            'ornamental fence',
          ],
        ),
      ),
    ]),
    _system('Chain Link Wire and Farm Fence Detail', [
      _type(
        'Chain Link Fabric Rails and Posts',
        _fencingProducts(
          baseName: 'Chain Link Fence Detail',
          unit: 'each',
          variants: [
            for (final height in ['4 ft', '5 ft', '6 ft', '8 ft'])
              for (final finish in [
                'Galvanized',
                'Black Vinyl Coated',
                'Green Vinyl Coated',
              ])
                '$height x 50 ft $finish Chain Link Fabric',
            for (final diameter in ['1-3/8 in', '1-5/8 in', '2 in'])
              for (final length in ['6 ft', '8 ft', '10 ft'])
                '$diameter x $length Chain Link Line Post',
            for (final diameter in ['1-3/8 in', '1-5/8 in'])
              for (final length in ['10 ft', '21 ft'])
                '$diameter x $length Chain Link Top Rail',
            for (final size in ['1-3/8 in', '1-5/8 in', '2 in'])
              for (final part in [
                'Tension Band',
                'Brace Band',
                'Rail End',
                'Post Cap',
              ])
                '$size Chain Link $part',
          ],
          aliases: const [
            'chain link fabric',
            'chainlink fabric',
            'line post',
            'top rail',
            'tension band',
            'brace band',
          ],
        ),
      ),
      _type(
        'Wire Farm and Electric Fence Detail',
        _fencingProducts(
          baseName: 'Wire Farm Electric Fence Detail',
          unit: 'each',
          variants: [
            for (final length in ['50 ft', '100 ft', '330 ft'])
              for (final wire in [
                'Welded Wire Fence',
                'Field Fence',
                'Barbed Wire',
              ])
                '$length $wire',
            for (final height in ['5 ft', '6 ft', '7 ft', '8 ft'])
              for (final color in ['Green', 'Black']) '$height $color T-Post',
            for (final miles in ['2 Mile', '5 Mile', '10 Mile', '30 Mile'])
              '$miles Electric Fence Charger',
            for (final count in ['25 Pack', '50 Pack'])
              for (final item in [
                'T-Post Electric Fence Insulator',
                'Electric Fence Gate Handle',
              ])
                '$count $item',
          ],
          aliases: const [
            'welded wire',
            'field fence',
            'barbed wire',
            't post',
            'electric fence charger',
            'electric fence insulator',
          ],
        ),
      ),
    ]),
    _system('Gates Hardware Anchors and Privacy Detail', [
      _type(
        'Gate Hardware and Post Anchors',
        _fencingProducts(
          baseName: 'Gate Hardware Anchor Detail',
          unit: 'each',
          variants: [
            for (final width in [
              '4 ft',
              '5 ft',
              '6 ft',
              '8 ft',
              '10 ft',
              '12 ft',
            ])
              for (final type in [
                'Galvanized Tube Farm Gate',
                'Chain Link Walk Gate',
                'Wood Fence Gate Kit',
              ])
                '$width $type',
            for (final finish in ['Black', 'Galvanized', 'Zinc'])
              for (final hardware in [
                'Gate Hinge',
                'Lockable Gate Latch',
                'Drop Rod',
                'Anti-Sag Gate Kit',
              ])
                '$finish $hardware',
            for (final size in ['4 x 4', '6 x 6'])
              for (final anchor in [
                'Post Base Anchor',
                'Post Anchor Spike',
                'Adjustable Post Base',
              ])
                '$size $anchor',
            for (final item in [
              '2 x 4 Fence Rail Bracket',
              'Magnetic Pool Gate Latch',
              'Gate Opener Keypad',
            ])
              item,
          ],
          aliases: const [
            'farm gate',
            'walk gate',
            'gate latch',
            'gate hinge',
            'drop rod',
            'post anchor',
            'rail bracket',
            'gate keypad',
          ],
        ),
      ),
      _type(
        'Privacy Temporary and Barrier Detail',
        _fencingProducts(
          baseName: 'Fence Privacy Barrier Detail',
          unit: 'each',
          variants: [
            for (final color in ['Black', 'Green', 'Brown'])
              for (final height in ['4 ft', '5 ft', '6 ft'])
                '$height $color Chain Link Privacy Slat Kit',
            for (final color in ['Black', 'Green'])
              for (final size in [
                '4 ft x 50 ft',
                '6 ft x 50 ft',
                '8 ft x 50 ft',
              ])
                '$color $size Fence Privacy Screen',
            for (final size in ['4 ft x 100 ft', '4 ft x 50 ft'])
              for (final type in [
                'Orange Safety Fence',
                'Silt Fence Fabric',
                'Temporary Fence Mesh',
              ])
                '$size $type',
            for (final item in [
              'Temporary Fence Panel Stand',
              'Fence Screen Clip 50 Pack',
            ])
              item,
          ],
          aliases: const [
            'privacy slat',
            'fence screen',
            'privacy screen',
            'orange safety fence',
            'silt fence',
            'temporary fence',
          ],
        ),
      ),
    ]),
  ],
);
