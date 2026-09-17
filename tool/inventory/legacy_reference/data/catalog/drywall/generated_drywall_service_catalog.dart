part of '../../work_supply_catalog.dart';

final drywallGeneratedServiceCatalogCategory = _category(
  'Expanded Drywall Service Stock',
  [
    _system('Expanded Panels and Board', [
      _type(
        'Drywall Sheets',
        _drywallProducts(
          baseName: 'Drywall Sheet',
          unit: 'sheet',
          variants: [
            for (final type in [
              'Regular',
              'Lightweight',
              'Moisture Resistant',
              'Fire Rated Type X',
            ])
              for (final thickness in ['1/4 in', '3/8 in', '1/2 in', '5/8 in'])
                for (final size in ['4 x 8', '4 x 10', '4 x 12'])
                  '$thickness $size $type',
          ],
          aliases: const ['sheetrock', 'gypsum board', 'drywall board'],
        ),
      ),
      _type(
        'Specialty Drywall Panels',
        _drywallProducts(
          baseName: 'Specialty Drywall Panel',
          unit: 'sheet',
          variants: const [
            '1/2 in 4 x 8 Mold Resistant',
            '1/2 in 4 x 12 Mold Resistant',
            '5/8 in 4 x 8 Sound Dampening',
            '5/8 in 4 x 12 Sound Dampening',
            '1/2 in 4 x 8 Cement Backer Board',
            '1/4 in 3 x 5 Cement Backer Board',
            '1/2 in 3 x 5 Cement Backer Board',
          ],
          aliases: const ['green board', 'purple board', 'backer board'],
        ),
      ),
    ]),
    _system('Expanded Compound and Mud', [
      _type(
        'Premixed Joint Compound',
        _drywallProducts(
          baseName: 'Joint Compound',
          unit: 'bucket',
          variants: [
            for (final kind in [
              'All Purpose',
              'Lightweight',
              'Topping',
              'Dust Control',
            ])
              for (final size in ['1 gal', '3.5 gal', '4.5 gal', '5 gal'])
                '$size $kind',
          ],
          aliases: const ['drywall mud', 'mud bucket', 'premixed mud'],
        ),
      ),
      _type(
        'Setting Type Compound',
        _drywallProducts(
          baseName: 'Setting Type Joint Compound',
          unit: 'bag',
          variants: [
            for (final time in [
              '5 min',
              '20 min',
              '45 min',
              '90 min',
              '210 min',
            ])
              for (final weight in ['4 lb', '18 lb', '25 lb']) '$time $weight',
          ],
          aliases: const ['hot mud', 'easy sand', 'quick set mud'],
        ),
      ),
    ]),
    _system('Expanded Tape Bead and Trim', [
      _type(
        'Drywall Tape',
        _drywallProducts(
          baseName: 'Drywall Tape',
          unit: 'roll',
          variants: [
            for (final tape in [
              'Paper',
              'Fiberglass Mesh',
              'Mold Resistant Mesh',
              'Strait-Flex',
            ])
              for (final length in ['75 ft', '150 ft', '250 ft', '500 ft'])
                '$length $tape',
          ],
          aliases: const ['joint tape', 'mesh tape', 'paper tape'],
        ),
      ),
      _type(
        'Corner Bead and Trim',
        _drywallProducts(
          baseName: 'Drywall Bead',
          unit: 'piece',
          variants: [
            for (final style in [
              'Metal Corner',
              'Vinyl Corner',
              'Paper Faced Corner',
              'Bullnose Corner',
              'J Bead',
              'L Bead',
            ])
              for (final length in ['8 ft', '9 ft', '10 ft', '12 ft'])
                '$length $style',
          ],
          aliases: const ['corner bead', 'j bead', 'edge bead', 'drywall trim'],
        ),
      ),
      _type(
        'Access Panels Control Joints and Detail Trim',
        _drywallProducts(
          baseName: 'Drywall Detail Trim',
          unit: 'each',
          variants: [
            for (final size in [
              '8 x 8 in',
              '12 x 12 in',
              '14 x 14 in',
              '24 x 24 in',
            ])
              '$size Plastic Access Panel',
            for (final size in [
              '8 x 8 in',
              '12 x 12 in',
              '14 x 14 in',
              '24 x 24 in',
            ])
              '$size Metal Access Panel',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              '$length Vinyl Tear Away Bead',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              '$length Drywall Control Joint',
            'No Coat Inside Corner Roll',
            'Flexible Corner Tape Roll',
            'Shadow Reveal Bead 10 ft',
            'Z Shadow Bead 10 ft',
          ],
          aliases: const [
            'access panel',
            'tear away bead',
            'control joint',
            'no coat',
            'shadow bead',
          ],
        ),
      ),
    ]),
    _system('Expanded Texture Patch and Repair', [
      _type(
        'Patch and Spackle',
        _drywallProducts(
          baseName: 'Wall Repair Material',
          unit: 'each',
          variants: const [
            '8 oz Lightweight Spackle',
            '16 oz Lightweight Spackle',
            '32 oz Lightweight Spackle',
            '1 gal Lightweight Spackle',
            '4 x 4 in Aluminum Drywall Patch',
            '6 x 6 in Aluminum Drywall Patch',
            '8 x 8 in Aluminum Drywall Patch',
            '2 ft x 2 ft Drywall Repair Panel',
            'Drywall Repair Clip Pack',
          ],
          aliases: const ['spackle', 'wall patch', 'repair patch'],
        ),
      ),
      _type(
        'Texture Materials',
        _drywallProducts(
          baseName: 'Drywall Texture Material',
          unit: 'each',
          variants: [
            for (final texture in ['Orange Peel', 'Knockdown', 'Popcorn'])
              for (final package in [
                'Aerosol Can',
                '15 lb Bag',
                '25 lb Bag',
                '40 lb Bag',
              ])
                '$package $texture',
          ],
          aliases: const ['texture spray', 'texture mix', 'wall texture'],
        ),
      ),
      _type(
        'Dust Control Protection and Cleanup',
        _drywallProducts(
          baseName: 'Drywall Protection Supply',
          unit: 'each',
          variants: [
            for (final size in [
              '9 ft x 12 ft',
              '10 ft x 25 ft',
              '20 ft x 100 ft',
            ])
              '$size Plastic Dust Barrier',
            'Zip Door Dust Barrier Kit',
            'Adhesive Zipper Door 2 Pack',
            'Dust Control Floor Protection Roll',
            'Tack Cloth Pack',
            'Drywall Dust Collection Bag',
            'Sanding Pole Vacuum Adapter',
            'Drywall Cleanup Sponge',
          ],
          aliases: const [
            'dust barrier',
            'zip door',
            'floor protection',
            'dust collection',
            'cleanup sponge',
          ],
        ),
      ),
    ]),
    _system('Expanded Drywall Fasteners and Adhesives', [
      _type(
        'Drywall Screws and Nails',
        _drywallProducts(
          baseName: 'Drywall Fastener',
          unit: 'box',
          variants: [
            for (final thread in ['Coarse Thread', 'Fine Thread'])
              for (final size in [
                '#6 x 1 in',
                '#6 x 1-1/4 in',
                '#6 x 1-5/8 in',
                '#8 x 2 in',
                '#8 x 2-1/2 in',
              ])
                '$size $thread Screw',
            for (final size in ['1-1/4 in', '1-3/8 in', '1-5/8 in'])
              '$size Drywall Nail',
          ],
          aliases: const ['sheetrock screw', 'drywall screw', 'gypsum screw'],
        ),
      ),
      _type(
        'Drywall Adhesives and Sanding',
        _drywallProducts(
          baseName: 'Drywall Supply',
          unit: 'each',
          variants: const [
            '10 oz Drywall Adhesive',
            '28 oz Drywall Adhesive',
            '80 grit Sanding Screen',
            '120 grit Sanding Screen',
            '220 grit Sanding Screen',
            'Medium Sanding Sponge',
            'Fine Sanding Sponge',
            'Dust Barrier Plastic Roll',
            'Drywall Shim Bundle',
          ],
          aliases: const ['panel adhesive', 'sanding screen', 'sanding sponge'],
        ),
      ),
      _type(
        'Drywall Hanging and Finishing Tools',
        _drywallProducts(
          baseName: 'Drywall Tool',
          unit: 'each',
          variants: const [
            'Drywall T-Square',
            'Drywall Rasp',
            'Drywall Jab Saw',
            'Drywall Screw Setter Bit Pack',
            'Drywall Lift Panel Hoist',
            'Panel Carry Handle',
            'Drywall Bench',
            'Mud Pan 12 in',
            'Mud Pan 14 in',
            '6 in Taping Knife',
            '10 in Taping Knife',
            '12 in Taping Knife',
            'Corner Trowel',
            'Texture Hopper Gun',
          ],
          aliases: const [
            'drywall t square',
            'drywall rasp',
            'jab saw',
            'screw setter',
            'drywall lift',
            'mud pan',
            'taping knife',
            'texture hopper',
          ],
        ),
      ),
    ]),
    _system('Expanded Metal Framing Ceiling and Sound Control', [
      _type(
        'Metal Studs Track and Furring',
        _drywallProducts(
          baseName: 'Drywall Metal Framing',
          unit: 'piece',
          variants: [
            for (final gauge in ['25 ga', '20 ga'])
              for (final width in ['1-5/8 in', '2-1/2 in', '3-5/8 in', '6 in'])
                for (final length in ['8 ft', '10 ft', '12 ft'])
                  '$gauge $width x $length Metal Stud',
            for (final gauge in ['25 ga', '20 ga'])
              for (final width in ['1-5/8 in', '2-1/2 in', '3-5/8 in', '6 in'])
                for (final length in ['8 ft', '10 ft', '12 ft'])
                  '$gauge $width x $length Metal Track',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              '$length Hat Channel',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              '$length Resilient Channel',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              '$length Z Furring Channel',
          ],
          aliases: const [
            'metal stud',
            'metal track',
            'hat channel',
            'resilient channel',
            'furring channel',
          ],
        ),
      ),
      _type(
        'Ceiling Grid Wire and Acoustic Support',
        _drywallProducts(
          baseName: 'Drywall Ceiling Support',
          unit: 'each',
          variants: const [
            '12 ga Ceiling Hanger Wire Roll',
            '9 ga Ceiling Hanger Wire Roll',
            'Eye Lag Screw Pack',
            'Ceiling Wire Tie Tool',
            'RC Sound Isolation Clip',
            'Furring Channel Clip',
            'Acoustic Putty Pad Pack',
            'Sound Isolation Clip Pack',
            'Sound Sealant 28 oz',
            'Acoustical Backer Rod',
          ],
          aliases: const [
            'ceiling wire',
            'hanger wire',
            'sound isolation clip',
            'rc clip',
            'sound sealant',
          ],
        ),
      ),
      _type(
        'Metal Framing Fasteners and Accessories',
        _drywallProducts(
          baseName: 'Metal Framing Accessory',
          unit: 'pack',
          variants: [
            for (final length in ['7/16 in', '1/2 in', '5/8 in'])
              '$length Pan Head Framing Screw',
            for (final length in ['7/16 in', '1/2 in', '5/8 in'])
              '$length Wafer Head Framing Screw',
            'Metal Stud Crimper',
            'Aviation Snip Set',
            'Metal Stud Punch Tool',
            'Track Fastener Pin Pack',
            'Deflection Track Clip Pack',
            'Metal Track End Cap Pack',
            'Metal Stud Bushing Pack',
            'Drywall Corner Backing Clip Pack',
          ],
          aliases: const [
            'pan head screw',
            'wafer head screw',
            'metal stud screw',
            'stud crimper',
            'track fastener',
          ],
        ),
      ),
    ]),
    _system('Bulk Drywall Board Receipt Variants', [
      _type(
        'Bulk Drywall Board Packs',
        _drywallProducts(
          baseName: 'Drywall Board',
          unit: 'sheet',
          variants: [
            for (final thickness in ['1/4 in', '3/8 in', '1/2 in', '5/8 in'])
              for (final size in ['4 x 8', '4 x 10', '4 x 12', '4 x 14'])
                for (final board in [
                  'Regular',
                  'Lightweight',
                  'Ultra Lightweight',
                  'Mold Resistant',
                  'Moisture Resistant',
                  'Fire Rated Type X',
                  'Abuse Resistant',
                  'Sound Dampening',
                ])
                  '$thickness $size $board',
          ],
          aliases: const [
            'sheetrock',
            'gypsum board',
            'wall board',
            'drywall panel',
          ],
        ),
      ),
      _type(
        'Bulk Backer and Specialty Board',
        _drywallProducts(
          baseName: 'Specialty Board',
          unit: 'sheet',
          variants: [
            for (final thickness in ['1/4 in', '1/2 in', '5/8 in'])
              for (final size in ['3 x 5', '4 x 8'])
                for (final board in [
                  'Cement Backer',
                  'Foam Tile Backer',
                  'Glass Mat',
                  'Shaftliner',
                  'Exterior Sheathing',
                ])
                  '$thickness $size $board',
          ],
          aliases: const [
            'backer board',
            'cement board',
            'tile backer',
            'densglass',
          ],
        ),
      ),
    ]),
    _system('Bulk Drywall Mud Tape and Finish', [
      _type(
        'Bulk Premixed Compound Buckets',
        _drywallProducts(
          baseName: 'Premixed Joint Compound',
          unit: 'bucket',
          variants: [
            for (final size in ['1 qt', '1 gal', '3.5 gal', '4.5 gal', '5 gal'])
              for (final kind in [
                'All Purpose',
                'Plus 3 Lightweight',
                'Lightweight',
                'Topping',
                'Dust Control',
                'Mold Resistant',
                'Blue Lid',
                'Green Lid',
              ])
                '$size $kind',
          ],
          aliases: const [
            'drywall mud',
            'joint compound',
            'mud bucket',
            'plus 3',
          ],
        ),
      ),
      _type(
        'Bulk Setting Compound Bags',
        _drywallProducts(
          baseName: 'Setting Type Compound',
          unit: 'bag',
          variants: [
            for (final time in [
              '5 min',
              '20 min',
              '45 min',
              '90 min',
              '210 min',
            ])
              for (final weight in ['4.5 lb', '18 lb', '25 lb'])
                for (final sand in ['Easy Sand', 'Durabond'])
                  '$time $weight $sand',
          ],
          aliases: const ['hot mud', 'quick set', 'easy sand', 'durabond'],
        ),
      ),
      _type(
        'Bulk Tape Bead and Trim Packs',
        _drywallProducts(
          baseName: 'Drywall Trim Supply',
          unit: 'each',
          variants: [
            for (final length in ['75 ft', '150 ft', '250 ft', '500 ft'])
              for (final tape in [
                'Paper Tape',
                'Fiberglass Mesh Tape',
                'Mold Resistant Mesh Tape',
                'Inside Corner Tape',
              ])
                '$length $tape',
            for (final length in ['8 ft', '9 ft', '10 ft', '12 ft'])
              for (final bead in [
                'Metal Corner Bead',
                'Vinyl Corner Bead',
                'Bullnose Corner Bead',
                'Paper Faced Corner Bead',
                'J Bead',
                'L Bead',
                'Tear Away Bead',
                'Control Joint',
              ])
                '$length $bead',
          ],
          aliases: const [
            'paper tape',
            'mesh tape',
            'corner bead',
            'drywall bead',
          ],
        ),
      ),
    ]),
    _system('Bulk Drywall Fasteners Repair and Sanding', [
      _type(
        'Bulk Drywall Screw Boxes',
        _drywallProducts(
          baseName: 'Drywall Screw',
          unit: 'box',
          variants: [
            for (final thread in ['Coarse Thread', 'Fine Thread'])
              for (final size in [
                '#6 x 1 in',
                '#6 x 1-1/4 in',
                '#6 x 1-5/8 in',
                '#8 x 2 in',
                '#8 x 2-1/2 in',
                '#8 x 3 in',
              ])
                for (final box in ['1 lb', '5 lb', '25 lb'])
                  '$size $thread $box',
          ],
          aliases: const ['drywall screw', 'sheetrock screw', 'gypsum screw'],
        ),
      ),
      _type(
        'Bulk Patch Texture and Sanding Supplies',
        _drywallProducts(
          baseName: 'Drywall Repair Supply',
          unit: 'each',
          variants: [
            for (final patch in [
              '4 x 4 in Aluminum Patch',
              '6 x 6 in Aluminum Patch',
              '8 x 8 in Aluminum Patch',
              '2 ft x 2 ft Repair Panel',
              'Drywall Repair Clip Pack',
              'Drywall Shim Bundle',
            ])
              patch,
            for (final texture in ['Orange Peel', 'Knockdown', 'Popcorn'])
              for (final package in ['Aerosol Can', '15 lb Bag', '25 lb Bag'])
                '$package $texture Texture',
            for (final grit in [
              '80 grit',
              '100 grit',
              '120 grit',
              '150 grit',
              '220 grit',
            ])
              for (final item in ['Sanding Screen', 'Sanding Sponge'])
                '$grit $item',
          ],
          aliases: const [
            'spackle',
            'wall patch',
            'texture spray',
            'sanding screen',
          ],
        ),
      ),
    ]),
    _system('Bulk Drywall Detail Trim and Access', [
      _type(
        'Drywall Reveal Bead and Expansion Trim',
        _drywallProducts(
          baseName: 'Drywall Reveal Trim',
          unit: 'piece',
          variants: [
            for (final length in ['8 ft', '10 ft', '12 ft'])
              for (final trim in [
                'Tear Away L Bead',
                'Reveal Bead',
                'Shadow Bead',
                'Expansion Bead',
                'Archway Corner Bead',
                'Bullnose Adapter',
                'Splayed Corner Bead',
              ])
                '$length $trim',
            'Bullnose Three-Way Corner Cap',
            'Bullnose Outside Corner Cap',
            'Vinyl Control Joint Tee',
          ],
          aliases: const [
            'reveal bead',
            'expansion bead',
            'bullnose adapter',
            'shadow bead',
          ],
        ),
      ),
      _type(
        'Access Doors and Fire Rated Panels',
        _drywallProducts(
          baseName: 'Drywall Access Door',
          unit: 'each',
          variants: [
            for (final size in [
              '6 x 6 in',
              '8 x 8 in',
              '12 x 12 in',
              '14 x 14 in',
              '16 x 16 in',
              '24 x 24 in',
            ])
              for (final type in [
                'Plastic Access Panel',
                'Metal Access Door',
                'Fire Rated Access Door',
                'Flush Access Panel',
              ])
                '$size $type',
          ],
          aliases: const [
            'access door',
            'fire rated access panel',
            'flush access panel',
          ],
        ),
      ),
    ]),
    _system('Bulk Drywall Sanding Texture and Ceiling Detail', [
      _type(
        'Drywall Sanding and Dust Extraction Detail',
        _drywallProducts(
          baseName: 'Drywall Sanding Accessory',
          unit: 'each',
          variants: [
            for (final grit in [
              '80 grit',
              '100 grit',
              '120 grit',
              '150 grit',
              '220 grit',
            ])
              for (final item in [
                'Sanding Screen 10 Pack',
                'Hook and Loop Sanding Disc 25 Pack',
                'Sanding Sponge',
              ])
                '$grit $item',
            'Drywall Pole Sander Head',
            'Drywall Hand Sander',
            'Dustless Sanding Hose Adapter',
            'Sanding Vacuum Bag 2 Pack',
            'Dust Extractor Fleece Bag 5 Pack',
            'Drywall Sanding Pad Saver',
          ],
          aliases: const [
            'pole sander',
            'hand sander',
            'dustless sanding',
            'sanding disc',
          ],
        ),
      ),
      _type(
        'Texture Sprayer and Ceiling Repair Detail',
        _drywallProducts(
          baseName: 'Drywall Texture Accessory',
          unit: 'each',
          variants: [
            for (final texture in ['Orange Peel', 'Knockdown', 'Popcorn'])
              for (final package in [
                '2 lb Patch Tub',
                '20 oz Aerosol',
                '1 gal Repair',
              ])
                '$package $texture Texture',
            'Texture Hopper Nozzle Kit',
            'Texture Gun Air Hose',
            'Texture Pattern Sponge',
            'Popcorn Ceiling Scraper',
            'Ceiling Patch Panel',
            'Ceiling Texture Repair Kit',
          ],
          aliases: const [
            'texture nozzle',
            'texture repair',
            'popcorn scraper',
            'ceiling patch',
          ],
        ),
      ),
      _type(
        'Drop Ceiling Grid and Tile Repair',
        _drywallProducts(
          baseName: 'Ceiling Grid Repair Part',
          unit: 'each',
          variants: [
            for (final length in ['2 ft', '4 ft', '8 ft', '12 ft'])
              for (final part in [
                'Ceiling Main Runner',
                'Ceiling Cross Tee',
                'Wall Angle',
                'Ceiling Grid Cover',
              ])
                '$length $part',
            '2 x 2 ft Acoustic Ceiling Tile',
            '2 x 4 ft Acoustic Ceiling Tile',
            'Ceiling Tile Hold Down Clip Pack',
            'Ceiling Grid Pop Rivet Pack',
            'Ceiling Grid Repair Clip Pack',
          ],
          aliases: const [
            'ceiling grid',
            'cross tee',
            'main runner',
            'ceiling tile',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _drywallProducts({
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
