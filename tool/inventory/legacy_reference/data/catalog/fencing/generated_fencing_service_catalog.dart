part of '../../work_supply_catalog.dart';

final fencingGeneratedServiceCatalogCategory = _category(
  'Expanded Fencing Service Stock',
  [
    _system('Expanded Wood and Vinyl Fence', [
      _type(
        'Wood Fence Boards and Rails',
        _fencingProducts(
          baseName: 'Wood Fence Material',
          unit: 'each',
          variants: [
            for (final board in ['5/8 in', '3/4 in', '1 in'])
              for (final length in ['6 ft', '8 ft'])
                '$board x 5-1/2 in x $length Dog Ear Picket',
            '2 in x 3 in x 8 ft Pressure Treated Fence Rail',
            '2 in x 4 in x 8 ft Pressure Treated Fence Rail',
            '1 in x 6 in x 8 ft Cedar Fence Board',
          ],
          aliases: const ['wood picket', 'privacy fence board', 'fence rail'],
        ),
      ),
      _type(
        'Vinyl Fence Panels and Parts',
        _fencingProducts(
          baseName: 'Vinyl Fence Material',
          unit: 'each',
          variants: const [
            '6 ft x 6 ft White Privacy Panel',
            '6 ft x 8 ft White Privacy Panel',
            '6 ft White Vinyl Rail',
            '8 ft White Vinyl Rail',
            'Vinyl Post Cap',
            'Vinyl Bracket Kit',
          ],
          aliases: const ['vinyl fence panel', 'privacy panel', 'vinyl rail'],
        ),
      ),
    ]),
    _system('Expanded Chain Link and Farm Fence', [
      _type(
        'Chain Link Fabric and Framework',
        _fencingProducts(
          baseName: 'Chain Link Fence Material',
          unit: 'roll',
          variants: [
            for (final height in ['4 ft', '5 ft', '6 ft'])
              '$height x 50 ft Galvanized Chain Link Fabric',
            '1-3/8 in x 10 ft Top Rail',
            '1-3/8 in x 21 ft Top Rail',
            '1-5/8 in x 6 ft Line Post',
            '1-7/8 in x 8 ft Line Post',
            '2-3/8 in x 8 ft Terminal Post',
          ],
          aliases: const ['chainlink fabric', 'wire fence fabric', 'top rail'],
        ),
      ),
      _type(
        'Wire Farm Fence',
        _fencingProducts(
          baseName: 'Wire Fence Roll',
          unit: 'roll',
          variants: const [
            '2 ft x 50 ft Welded Wire',
            '4 ft x 50 ft Welded Wire',
            '4 ft x 100 ft Welded Wire',
            '2 Point 1320 ft Barbed Wire',
            '4 Point 1320 ft Barbed Wire',
            '48 in x 100 ft Field Fence',
            '60 in x 100 ft Field Fence',
          ],
          aliases: const ['welded wire', 'barb wire', 'field fence'],
        ),
      ),
    ]),
    _system('Expanded Posts Gates and Hardware', [
      _type(
        'Fence Posts',
        _fencingProducts(
          baseName: 'Fence Post',
          unit: 'each',
          variants: const [
            '4 in x 4 in x 8 ft Pressure Treated',
            '4 in x 4 in x 10 ft Pressure Treated',
            '6 in x 6 in x 8 ft Pressure Treated',
            '6 ft Green T-Post',
            '7 ft Green T-Post',
            '8 ft Green T-Post',
          ],
          aliases: const ['treated post', 'wood fence post', 't post'],
        ),
      ),
      _type(
        'Gate Hardware',
        _fencingProducts(
          baseName: 'Fence Gate Hardware',
          unit: 'each',
          variants: const [
            'Heavy Duty Gate Hinge Set',
            'Residential Gate Hinge Set',
            'Standard Gate Latch',
            'Lockable Gate Latch',
            'Anti-Sag Gate Kit',
            'Chain Link Gate Frame Kit',
            'Wood Gate Frame Kit',
          ],
          aliases: const ['gate hinge', 'gate latch', 'gate kit'],
        ),
      ),
    ]),
    _system('Expanded Fence Fasteners and Setting', [
      _type(
        'Fence Fasteners',
        _fencingProducts(
          baseName: 'Fence Fastener',
          unit: 'box',
          variants: const [
            '#8 x 1-1/2 in Exterior Fence Screw',
            '#9 x 2 in Exterior Fence Screw',
            '#9 x 2-1/2 in Exterior Fence Screw',
            '1-1/4 in Fence Staple',
            '1-3/4 in Fence Staple',
            'Chain Link Tension Band Pack',
            'Chain Link Brace Band Pack',
          ],
          aliases: const ['wood fence screw', 'wire staple', 'tension band'],
        ),
      ),
      _type(
        'Concrete and Post Setting',
        _fencingProducts(
          baseName: 'Fence Setting Material',
          unit: 'bag',
          variants: const [
            '50 lb Fast Setting Concrete Mix',
            '60 lb Fast Setting Concrete Mix',
            '80 lb Fast Setting Concrete Mix',
            '50 lb Gravel Base',
            'Post Foam Setting Mix',
          ],
          aliases: const ['post concrete', 'fence post concrete', 'post foam'],
        ),
      ),
    ]),
    _system('Bulk Fencing Receipt Variants', [
      _type(
        'Bulk Wood Fence Pickets Rails and Posts',
        _fencingProducts(
          baseName: 'Wood Fence Material',
          unit: 'each',
          variants: [
            for (final thickness in ['5/8 in', '3/4 in', '1 in'])
              for (final width in ['5-1/2 in', '6 in'])
                for (final length in ['6 ft', '8 ft'])
                  for (final style in [
                    'Dog Ear Cedar Picket',
                    'Dog Ear Pressure Treated Picket',
                    'Flat Top Cedar Picket',
                    'French Gothic Picket',
                  ])
                    '$thickness x $width x $length $style',
            for (final size in ['2 in x 3 in', '2 in x 4 in', '2 in x 6 in'])
              for (final length in ['8 ft', '10 ft', '12 ft', '16 ft'])
                for (final material in ['Pressure Treated Rail', 'Cedar Rail'])
                  '$size x $length $material',
            for (final size in ['4 in x 4 in', '5 in x 5 in', '6 in x 6 in'])
              for (final length in ['8 ft', '10 ft', '12 ft'])
                for (final material in ['Pressure Treated Post', 'Cedar Post'])
                  '$size x $length $material',
          ],
          aliases: const [
            'fence picket',
            'dog ear picket',
            'wood fence board',
            'fence rail',
            'treated fence post',
          ],
        ),
      ),
      _type(
        'Bulk Vinyl Composite and Decorative Fence',
        _fencingProducts(
          baseName: 'Vinyl Fence Material',
          unit: 'each',
          variants: [
            for (final color in ['White', 'Tan', 'Gray'])
              for (final size in ['6 ft x 6 ft', '6 ft x 8 ft', '4 ft x 8 ft'])
                for (final style in [
                  'Privacy Panel',
                  'Lattice Top Panel',
                  'Picket Panel',
                  'Ranch Rail Panel',
                ])
                  '$color $size $style',
            for (final color in ['White', 'Tan', 'Gray'])
              for (final length in ['6 ft', '8 ft'])
                for (final part in [
                  'Vinyl Fence Rail',
                  'Vinyl Post Sleeve',
                  'Vinyl Top Rail',
                  'Vinyl Bottom Rail',
                ])
                  '$color $length $part',
            for (final color in ['White', 'Tan', 'Gray', 'Black'])
              for (final cap in [
                'Flat Post Cap',
                'Gothic Post Cap',
                'Solar Post Cap',
                'Bracket Kit',
              ])
                '$color Vinyl $cap',
          ],
          aliases: const [
            'vinyl fence panel',
            'privacy panel',
            'vinyl rail',
            'post sleeve',
            'vinyl bracket',
          ],
        ),
      ),
    ]),
    _system('Bulk Chain Link Farm Fence and Gates', [
      _type(
        'Bulk Chain Link Framework and Fabric',
        _fencingProducts(
          baseName: 'Chain Link Fence Material',
          unit: 'each',
          variants: [
            for (final height in ['3 ft', '4 ft', '5 ft', '6 ft', '8 ft'])
              for (final length in ['50 ft', '100 ft'])
                for (final finish in ['Galvanized', 'Black Vinyl Coated'])
                  '$height x $length $finish Chain Link Fabric',
            for (final diameter in [
              '1-3/8 in',
              '1-5/8 in',
              '1-7/8 in',
              '2-3/8 in',
              '2-7/8 in',
            ])
              for (final length in ['6 ft', '8 ft', '10 ft', '21 ft'])
                for (final part in [
                  'Line Post',
                  'Terminal Post',
                  'Top Rail',
                  'Gate Post',
                ])
                  '$diameter x $length $part',
            for (final size in ['3 ft', '4 ft', '5 ft', '6 ft'])
              for (final width in ['4 ft', '5 ft', '6 ft'])
                '$size x $width Chain Link Walk Gate',
          ],
          aliases: const [
            'chain link fabric',
            'chainlink fabric',
            'top rail',
            'line post',
            'terminal post',
            'chain link gate',
          ],
        ),
      ),
      _type(
        'Bulk Farm Fence Wire and Posts',
        _fencingProducts(
          baseName: 'Farm Fence Material',
          unit: 'roll',
          variants: [
            for (final height in ['24 in', '36 in', '48 in', '60 in', '72 in'])
              for (final length in ['50 ft', '100 ft', '330 ft'])
                for (final wire in [
                  'Welded Wire',
                  'Field Fence',
                  'Hardware Cloth',
                  'Poultry Netting',
                  'Garden Fence',
                ])
                  '$height x $length $wire',
            for (final point in ['2 Point', '4 Point'])
              for (final length in ['1320 ft', '80 Rod'])
                '$point $length Barbed Wire',
            for (final height in ['5 ft', '6 ft', '7 ft', '8 ft'])
              for (final color in ['Green', 'Black']) '$height $color T-Post',
            for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
              for (final clip in ['T-Post Clip', 'Fence Clip', 'U-Post Clip'])
                '$clip $pack',
          ],
          aliases: const [
            'welded wire',
            'field fence',
            'barbed wire',
            'barb wire',
            't-post',
            't post clip',
          ],
        ),
      ),
    ]),
    _system('Bulk Fence Hardware Fasteners and Setting', [
      _type(
        'Bulk Gate Hardware and Chain Link Fittings',
        _fencingProducts(
          baseName: 'Fence Hardware',
          unit: 'each',
          variants: [
            for (final finish in ['Black', 'Galvanized', 'Zinc', 'Stainless'])
              for (final hardware in [
                'Gate Hinge Set',
                'Gate Latch',
                'Lockable Gate Latch',
                'Drop Rod',
                'Cane Bolt',
                'Anti-Sag Gate Kit',
                'Wood Gate Frame Kit',
                'Chain Link Gate Frame Kit',
              ])
                '$finish $hardware',
            for (final size in ['1-3/8 in', '1-5/8 in', '1-7/8 in', '2-3/8 in'])
              for (final fitting in [
                'Tension Band',
                'Brace Band',
                'Rail End',
                'Loop Cap',
                'Post Cap',
                'Tension Bar',
                'Truss Rod',
              ])
                '$size Chain Link $fitting',
          ],
          aliases: const [
            'gate hinge',
            'gate latch',
            'anti sag gate kit',
            'tension band',
            'brace band',
            'rail end',
          ],
        ),
      ),
      _type(
        'Bulk Fence Fasteners Setting and Finish',
        _fencingProducts(
          baseName: 'Fence Supply',
          unit: 'each',
          variants: [
            for (final size in [
              '#8 x 1-1/2 in',
              '#9 x 2 in',
              '#9 x 2-1/2 in',
              '#10 x 3 in',
            ])
              for (final pack in ['1 lb', '5 lb', '25 lb'])
                '$size Exterior Fence Screw $pack',
            for (final length in ['1-1/4 in', '1-1/2 in', '1-3/4 in', '2 in'])
              for (final pack in ['1 lb', '5 lb'])
                '$length Galvanized Fence Staple $pack',
            for (final weight in ['50 lb', '60 lb', '80 lb'])
              for (final mix in [
                'Fast Setting Concrete Mix',
                'Fence Post Concrete',
                'Gravel Base',
              ])
                '$weight $mix',
            'Post Foam Setting Mix',
            for (final size in ['1 gal', '5 gal'])
              for (final finish in [
                'Fence Stain',
                'Fence Sealer',
                'Wood Preservative',
              ])
                '$size $finish',
          ],
          aliases: const [
            'fence screw',
            'fence staple',
            'post concrete',
            'post foam',
            'fence stain',
            'fence sealer',
          ],
        ),
      ),
    ]),
    _system('Bulk Gates Ornamental and Repair', [
      _type(
        'Driveway Walk Gates and Gate Operators',
        _fencingProducts(
          baseName: 'Fence Gate System Part',
          unit: 'each',
          variants: [
            for (final width in ['36 in', '42 in', '48 in'])
              for (final material in ['Wood', 'Vinyl', 'Chain Link'])
                '$width $material Walk Gate',
            for (final width in ['10 ft', '12 ft', '14 ft', '16 ft'])
              '$width Galvanized Tube Farm Gate',
            'Single Swing Gate Opener Kit',
            'Dual Swing Gate Opener Kit',
            'Gate Opener Remote',
            'Gate Opener Battery',
            'Gate Wheel Kit',
            'Adjustable Gate Drop Rod',
          ],
          aliases: const [
            'walk gate',
            'farm gate',
            'driveway gate',
            'gate opener',
            'gate wheel',
          ],
        ),
      ),
      _type(
        'Ornamental Aluminum and Steel Fence',
        _fencingProducts(
          baseName: 'Ornamental Fence Material',
          unit: 'each',
          variants: [
            for (final height in ['4 ft', '5 ft', '6 ft'])
              for (final width in ['6 ft', '8 ft'])
                for (final material in ['Black Aluminum', 'Black Steel'])
                  '$height x $width $material Fence Panel',
            for (final height in ['5 ft', '6 ft', '7 ft'])
              for (final material in ['Black Aluminum', 'Black Steel'])
                '$height $material Fence Post',
            'Ornamental Fence Bracket Kit',
            'Ornamental Fence Gate Latch',
            'Ornamental Fence Spear Top Finial',
          ],
          aliases: const [
            'ornamental fence',
            'aluminum fence panel',
            'steel fence panel',
            'fence finial',
          ],
        ),
      ),
      _type(
        'Fence Repair Sleeves Caps and Ties',
        _fencingProducts(
          baseName: 'Fence Repair Part',
          unit: 'each',
          variants: [
            for (final size in ['4 x 4', '5 x 5', '6 x 6'])
              for (final finish in ['Black', 'White', 'Copper', 'Stainless'])
                '$size $finish Post Cap',
            for (final size in ['4 x 4', '6 x 6']) '$size Post Repair Sleeve',
            for (final length in ['6 in', '8 in', '12 in'])
              '$length Fence Mending Plate',
            'Fence Rail Repair Bracket',
            'Picket Repair Clip Pack',
            'Chain Link Fence Tie 100 Pack',
            'Chain Link Hog Ring 100 Pack',
            'Fence Wire Stretcher',
          ],
          aliases: const [
            'post cap',
            'post repair sleeve',
            'mending plate',
            'rail repair bracket',
            'fence tie',
            'hog ring',
          ],
        ),
      ),
      _type(
        'Electric Fence and Livestock Hardware',
        _fencingProducts(
          baseName: 'Electric Fence Supply',
          unit: 'each',
          variants: [
            for (final rating in ['2 mile', '5 mile', '10 mile', '30 mile'])
              '$rating Electric Fence Charger',
            'Electric Fence Poly Wire 1320 ft',
            'Electric Fence Poly Tape 656 ft',
            'T-Post Electric Fence Insulator 25 Pack',
            'Wood Post Electric Fence Insulator 25 Pack',
            'Electric Fence Gate Handle',
            'Electric Fence Ground Rod',
            'Electric Fence Warning Sign',
            'Fence Voltage Tester',
          ],
          aliases: const [
            'electric fence',
            'fence charger',
            'poly wire',
            'fence insulator',
            'gate handle',
            'voltage tester',
          ],
        ),
      ),
    ]),
    _system('Bulk Fence Privacy Screens and Site Barrier', [
      _type(
        'Fence Privacy Slats and Screens',
        _fencingProducts(
          baseName: 'Fence Privacy Supply',
          unit: 'each',
          variants: [
            for (final color in ['Black', 'Green', 'Brown', 'Gray'])
              for (final height in ['4 ft', '5 ft', '6 ft'])
                '$height $color Chain Link Privacy Slat Kit',
            for (final color in ['Black', 'Green', 'Tan'])
              for (final size in [
                '4 ft x 50 ft',
                '6 ft x 50 ft',
                '8 ft x 50 ft',
              ])
                '$size $color Fence Privacy Screen',
            for (final material in ['Reed', 'Bamboo', 'Willow'])
              for (final height in ['4 ft', '6 ft'])
                '$height $material Privacy Fence Roll',
            'Fence Screen Clip 100 Pack',
            'Fence Screen Zip Tie 100 Pack',
            'Fence Screen Grommet Repair Kit',
          ],
          aliases: const [
            'privacy slat',
            'chain link privacy slat',
            'fence screen',
            'privacy fence roll',
            'screen clip',
          ],
        ),
      ),
      _type(
        'Temporary Safety and Silt Fence',
        _fencingProducts(
          baseName: 'Temporary Fence Supply',
          unit: 'roll',
          variants: [
            for (final height in ['3 ft', '4 ft'])
              for (final length in ['50 ft', '100 ft'])
                '$height x $length Orange Safety Fence',
            for (final height in ['24 in', '36 in'])
              for (final length in ['50 ft', '100 ft'])
                '$height x $length Silt Fence Fabric',
            'Silt Fence Stake 10 Pack',
            'Safety Fence Stake 10 Pack',
            'Temporary Fence Panel Clamp',
            'Temporary Fence Panel Stand',
          ],
          aliases: const [
            'orange safety fence',
            'temporary fence',
            'silt fence',
            'fence stake',
            'panel clamp',
          ],
        ),
      ),
    ]),
    _system('Bulk Fence Anchors Brackets and Specialty Gates', [
      _type(
        'Fence Post Anchors and Brackets',
        _fencingProducts(
          baseName: 'Fence Anchor Hardware',
          unit: 'each',
          variants: [
            for (final size in ['4 x 4', '5 x 5', '6 x 6'])
              for (final style in [
                'Post Base Anchor',
                'Post Anchor Spike',
                'Adjustable Post Base',
                'Post Repair Bracket',
              ])
                '$size $style',
            for (final size in ['2 x 4', '2 x 6'])
              for (final bracket in [
                'Fence Rail Bracket',
                'Angle Rail Bracket',
                'End Rail Bracket',
              ])
                '$size $bracket',
            'Chain Link Floor Flange',
            'Fence Panel Mounting Bracket',
            'Masonry Fence Post Bracket',
          ],
          aliases: const [
            'post base anchor',
            'post anchor spike',
            'post repair bracket',
            'rail bracket',
            'fence flange',
          ],
        ),
      ),
      _type(
        'Pool Child and Pet Fence Hardware',
        _fencingProducts(
          baseName: 'Safety Fence Hardware',
          unit: 'each',
          variants: [
            for (final height in ['4 ft', '5 ft'])
              for (final length in ['12 ft', '24 ft', '48 ft'])
                '$height x $length Removable Pool Fence Panel',
            'Self Closing Pool Gate Hinge',
            'Magnetic Pool Gate Latch',
            'Pool Fence Deck Sleeve',
            'Pool Fence Deck Cap',
            'Pet Fence Gate Kit',
            'Pet Fence Ground Stake 25 Pack',
            'Child Safety Fence Mesh Roll',
          ],
          aliases: const [
            'pool fence',
            'pool gate latch',
            'pool gate hinge',
            'pet fence',
            'child safety fence',
          ],
        ),
      ),
      _type(
        'Gate Opener Controls and Power',
        _fencingProducts(
          baseName: 'Gate Opener Accessory',
          unit: 'each',
          variants: const [
            'Gate Opener Keypad',
            'Gate Opener Photo Eye Sensor',
            'Gate Opener Solar Panel Kit',
            'Gate Opener Transformer',
            'Gate Opener Control Board',
            'Gate Opener Exit Wand',
            'Gate Opener Push Button',
            'Gate Opener Battery Box',
          ],
          aliases: const [
            'gate keypad',
            'gate opener sensor',
            'gate solar panel',
            'gate control board',
            'exit wand',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _fencingProducts({
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
