part of '../../work_supply_catalog.dart';

final masonryConcreteGeneratedServiceCatalogCategory = _category(
  'Expanded Masonry and Concrete Service Stock',
  [
    _system('Expanded Bagged Mixes and Additives', [
      _type('Concrete Mortar and Cement Mixes', _baggedMixProducts()),
      _type(
        'Concrete Additives and Bonding',
        _sizedProducts(
          baseName: 'Concrete Additive',
          unit: 'each',
          sizes: const ['1 qt', '1 gal', '5 gal'],
          products: const [
            'Concrete Bonding Adhesive',
            'Acrylic Fortifier',
            'Concrete Cure and Seal',
            'Form Release Oil',
            'Concrete Retarder',
            'Concrete Accelerator',
            'Water Reducer',
            'Latex Additive',
          ],
          aliases: const ['bonding adhesive', 'fortifier', 'cure seal'],
        ),
      ),
    ]),
    _system('Expanded Block Brick and Stone', [
      _type('Concrete Block and Brick', _masonryUnitProducts()),
      _type('Pavers Wall Block and Stone', _hardscapeUnitProducts()),
    ]),
    _system('Expanded Reinforcement Forms and Tools', [
      _type('Rebar Mesh and Tie Wire', _reinforcementProducts()),
      _type('Forming Materials', _formingProducts()),
    ]),
    _system('Expanded Anchors Repair and Surface Prep', [
      _type('Concrete Anchors and Fasteners', _anchorProducts()),
      _type('Concrete Repair Materials', _repairAndSealerProducts()),
    ]),
    _system('Expanded Hardscape Base and Drainage Supplies', [
      _type(
        'Paver Base Sand and Jointing',
        _sizedProducts(
          baseName: 'Hardscape Base Material',
          unit: 'bag',
          sizes: const ['40 lb', '50 lb', '60 lb', '0.5 cu ft', '1 cu ft'],
          products: const [
            'Paver Base',
            'Paver Leveling Sand',
            'Polymeric Sand',
            'All Purpose Gravel',
            'Crushed Stone',
            'Pea Gravel',
            'Drainage Rock',
          ],
          aliases: const ['paver base', 'polymeric sand', 'leveling sand'],
        ),
      ),
      _type(
        'Landscape Wall and Masonry Adhesives',
        _sizedProducts(
          baseName: 'Masonry Adhesive',
          unit: 'each',
          sizes: const ['10 oz', '28 oz', '1 qt', '1 gal'],
          products: const [
            'Landscape Block Adhesive',
            'Concrete and Masonry Adhesive',
            'Construction Adhesive for Pavers',
            'Epoxy Anchoring Adhesive',
            'Masonry Joint Sealant',
          ],
          aliases: const ['block adhesive', 'masonry adhesive', 'epoxy anchor'],
        ),
      ),
    ]),
    _system('Expanded Slab Joint Stain and Surface Detail', [
      _type(
        'Concrete Joint and Slab Accessories',
        _sizedProducts(
          baseName: 'Concrete Slab Accessory',
          unit: 'each',
          sizes: const ['1/2 in', '3/4 in', '1 in', '4 in', '6 in'],
          products: const [
            'Expansion Joint Strip',
            'Fiber Expansion Joint',
            'Backer Rod',
            'Control Joint Insert',
            'Zip Strip Control Joint',
            'Slab Isolation Joint',
            'Concrete Edging Form',
          ],
          aliases: const [
            'expansion joint',
            'control joint',
            'backer rod',
            'zip strip',
          ],
        ),
      ),
      _type(
        'Concrete Stain Color and Finish',
        _sizedProducts(
          baseName: 'Concrete Finish Supply',
          unit: 'each',
          sizes: const ['1 qt', '1 gal', '2 gal', '5 gal'],
          products: const [
            'Concrete Stain',
            'Acid Stain',
            'Concrete Dye',
            'Concrete Colorant',
            'Integral Concrete Color',
            'Stamped Concrete Release',
            'Concrete Densifier',
            'Wet Look Concrete Sealer',
          ],
          aliases: const [
            'concrete stain',
            'acid stain',
            'concrete dye',
            'color release',
          ],
        ),
      ),
    ]),
    _system('Expanded Masonry Wall Stucco and Chimney Repair', [
      _type(
        'Stucco Lath and Wall Accessories',
        _sizedProducts(
          baseName: 'Stucco Masonry Accessory',
          unit: 'each',
          sizes: const ['8 ft', '10 ft', '27 in x 8 ft', '36 in x 150 ft'],
          products: const [
            'Galvanized Weep Screed',
            'Stucco Casing Bead',
            'Stucco Corner Bead',
            'Stucco Control Joint',
            'Expanded Metal Lath',
            'Self Furring Metal Lath',
            'Paper Backed Wire Lath',
            'Stucco Netting',
          ],
          aliases: const [
            'weep screed',
            'stucco bead',
            'metal lath',
            'wire lath',
          ],
        ),
      ),
      _type(
        'Fire Brick Flue and Chimney Masonry',
        _sizedProducts(
          baseName: 'Chimney Masonry Part',
          unit: 'each',
          sizes: const ['4 x 8 x 16 in', '8 x 8 in', '8 x 12 in', '12 x 12 in'],
          products: const [
            'Fire Brick',
            'Clay Flue Liner',
            'Flue Tile',
            'Chimney Crown Form',
            'Chimney Crown Repair',
            'Refractory Mortar',
            'Fireplace Mortar',
            'Smoke Chamber Parging Mix',
          ],
          aliases: const [
            'fire brick',
            'flue liner',
            'flue tile',
            'refractory mortar',
          ],
        ),
      ),
    ]),
    _system('Expanded Hardscape Restraint Drainage and Tools', [
      _type(
        'Paver Edge Joint and Drainage Accessories',
        _sizedProducts(
          baseName: 'Hardscape Accessory',
          unit: 'each',
          sizes: const ['6 ft', '8 ft', '10 ft', '25 ft', '50 ft'],
          products: const [
            'Paver Edge Restraint',
            'Aluminum Paver Edge',
            'Plastic Paver Edging',
            'Paver Spike Pack',
            'Permeable Paver Grid',
            'Drainage Mat',
            'Geotextile Fabric',
            'Paver Joint Sand Stabilizer',
          ],
          aliases: const [
            'paver restraint',
            'paver edge',
            'paver spike',
            'joint stabilizer',
          ],
        ),
      ),
      _type(
        'Masonry Blades Bits and Layout Supplies',
        _sizedProducts(
          baseName: 'Masonry Tool Consumable',
          unit: 'each',
          sizes: const ['1/4 in', '3/8 in', '1/2 in', '4 in', '7 in', '10 in'],
          products: const [
            'Masonry Drill Bit',
            'SDS Masonry Bit',
            'Concrete Diamond Blade',
            'Masonry Grinding Wheel',
            'Brick Chisel',
            'Cold Chisel',
            'Masonry Line Block',
            'Mason Line',
          ],
          aliases: const [
            'masonry bit',
            'sds bit',
            'diamond blade',
            'mason line',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _baggedMixProducts() {
  final weights = [
    '10 lb',
    '20 lb',
    '40 lb',
    '50 lb',
    '55 lb',
    '60 lb',
    '80 lb',
  ];
  final mixes = [
    'Concrete Mix',
    'High Strength Concrete Mix',
    'Fast Setting Concrete Mix',
    'Crack Resistant Concrete Mix',
    'Countertop Concrete Mix',
    'Sand Topping Mix',
    'Mortar Mix',
    'Type N Mortar Mix',
    'Type S Mortar Mix',
    'Type M Mortar Mix',
    'Stucco Base Coat',
    'Stucco Finish Coat',
    'Portland Cement',
    'Masonry Cement',
    'Hydraulic Water Stop Cement',
    'Mason Sand',
    'All Purpose Sand',
    'Play Sand',
    'Tube Sand',
    'Gravel Mix',
    'Blacktop Patch',
    'Asphalt Patch',
  ];
  return _generatedMasonryVariants(
    baseName: 'Masonry Mix',
    unit: 'bag',
    variants: [
      for (final weight in weights)
        for (final mix in mixes) '$weight $mix',
      '94 lb Portland Cement',
      '94 lb Masonry Cement Type S',
      '80 lb Surface Bonding Cement',
    ],
    aliases: const ['concrete mix', 'quikrete', 'sakrete', 'mortar mix'],
  );
}

List<WorkSupplyItem> _masonryUnitProducts() {
  final sizes = [
    '4 x 8 x 16 in',
    '6 x 8 x 16 in',
    '8 x 8 x 8 in',
    '8 x 8 x 16 in',
    '8 x 2 x 16 in',
    '10 x 8 x 16 in',
    '12 x 8 x 16 in',
  ];
  final units = [
    'Concrete Block',
    'Concrete Half Block',
    'Concrete Solid Block',
    'Concrete Cap Block',
    'Concrete Lintel Block',
    'Concrete Bond Beam Block',
    'Decorative Screen Block',
  ];
  return [
    ..._generatedMasonryVariants(
      baseName: 'Masonry Unit',
      unit: 'each',
      variants: [
        for (final size in sizes)
          for (final unit in units) '$size $unit',
        'Modular Red Clay Brick',
        'Queen Red Clay Brick',
        'King Red Clay Brick',
        'Common Clay Brick',
        'Concrete Brick',
        'Fire Brick',
        'Thin Brick Corner',
        'Thin Brick Flat',
        'Glass Block',
        'Glass Block Spacer Pack',
      ],
      aliases: const ['cmu', 'cinder block', 'red brick', 'clay brick'],
    ),
  ];
}

List<WorkSupplyItem> _hardscapeUnitProducts() {
  final sizes = [
    '4 x 8 in',
    '6 x 6 in',
    '6 x 9 in',
    '8 x 8 in',
    '12 x 12 in',
    '12 x 24 in',
    '16 x 16 in',
    '18 x 18 in',
    '24 x 24 in',
  ];
  final units = [
    'Concrete Paver',
    'Patio Stone',
    'Stepping Stone',
    'Textured Patio Stone',
    'Square Paver',
    'Rectangle Paver',
  ];
  return _generatedMasonryVariants(
    baseName: 'Hardscape Masonry Unit',
    unit: 'each',
    variants: [
      for (final size in sizes)
        for (final unit in units) '$size $unit',
      'Retaining Wall Block',
      'Straight Retaining Wall Block',
      'Corner Retaining Wall Block',
      'Wall Cap Block',
      'Garden Wall Block',
      'Fire Pit Block',
      'Edging Stone',
      'Concrete Parking Stop',
      'Splash Block',
    ],
    aliases: const ['paver', 'patio stone', 'wall block', 'stepping stone'],
  );
}

List<WorkSupplyItem> _reinforcementProducts() {
  final rebarSizes = ['#3', '#4', '#5', '#6'];
  final lengths = ['2 ft', '4 ft', '10 ft', '20 ft'];
  return _generatedMasonryVariants(
    baseName: 'Concrete Reinforcement',
    unit: 'each',
    variants: [
      for (final size in rebarSizes)
        for (final length in lengths) '$size x $length Rebar',
      '3/8 in x 10 ft Rebar',
      '1/2 in x 10 ft Rebar',
      '42 x 84 in Concrete Wire Mesh',
      '5 x 10 ft Concrete Wire Mesh',
      '7 x 50 ft Remesh Roll',
      '5 ft x 150 ft Wire Mesh Roll',
      '16 gauge Rebar Tie Wire',
      '100 ft Rebar Tie Wire',
      'Rebar Chair Pack',
      'Concrete Dobie Block Pack',
      'Plastic Slab Bolster',
      'Rebar Safety Cap Pack',
    ],
    aliases: const ['rebar', 'reinforcing bar', 'remesh', 'wire mesh'],
  );
}

List<WorkSupplyItem> _formingProducts() {
  final boardSizes = [
    '1 x 4 x 8 ft',
    '1 x 6 x 8 ft',
    '2 x 4 x 8 ft',
    '2 x 6 x 8 ft',
    '2 x 8 x 8 ft',
    '2 x 10 x 8 ft',
    '2 x 12 x 8 ft',
  ];
  return _generatedMasonryVariants(
    baseName: 'Concrete Forming Material',
    unit: 'piece',
    variants: [
      for (final size in boardSizes) '$size Form Board',
      '18 in Wood Form Stake',
      '24 in Wood Form Stake',
      '36 in Wood Form Stake',
      '18 in Steel Form Stake',
      '24 in Steel Form Stake',
      '36 in Steel Form Stake',
      '1/2 in x 4 x 8 ft Form Plywood',
      '3/4 in x 4 x 8 ft Form Plywood',
      '4 in x 50 ft Expansion Joint Roll',
      '6 in x 50 ft Expansion Joint Roll',
      '1/2 in x 4 x 5 ft Fiber Expansion Joint',
      '10 in x 48 in Concrete Form Tube',
      '12 in x 48 in Concrete Form Tube',
      '16 in x 48 in Concrete Form Tube',
    ],
    aliases: const ['form board', 'form lumber', 'form stake', 'sonotube'],
  );
}

List<WorkSupplyItem> _anchorProducts() {
  final sizes = ['3/16 in', '1/4 in', '3/8 in', '1/2 in', '5/8 in'];
  final lengths = [
    '1-1/4 in',
    '1-3/4 in',
    '2-1/4 in',
    '2-3/4 in',
    '3 in',
    '4-1/4 in',
  ];
  final anchors = [
    'Wedge Anchor',
    'Sleeve Anchor',
    'Drop-In Anchor',
    'Concrete Screw Anchor',
    'Hex Head Concrete Screw Anchor',
    'Flat Head Concrete Screw Anchor',
    'Masonry Screw Anchor',
  ];
  return _generatedMasonryVariants(
    baseName: 'Concrete Anchor',
    unit: 'pack',
    variants: [
      for (final size in sizes)
        for (final length in lengths)
          for (final anchor in anchors) '$size x $length $anchor',
      '1/4 in Tapcon Drill Bit and Anchor Kit',
      '3/16 in Tapcon Drill Bit and Anchor Kit',
      'Powder Actuated Concrete Pin Pack',
      'Concrete Anchor Setting Tool',
    ],
    aliases: const [
      'wedge anchor',
      'tapcon',
      'concrete screw',
      'sleeve anchor',
    ],
  );
}

List<WorkSupplyItem> _repairAndSealerProducts() {
  return _generatedMasonryVariants(
    baseName: 'Concrete Repair Material',
    unit: 'each',
    variants: [
      for (final size in ['10 oz', '1 qt', '1 gal', '5 gal', '20 lb', '40 lb'])
        for (final product in [
          'Concrete Patch',
          'Vinyl Concrete Patch',
          'Concrete Crack Sealant',
          'Self Leveling Concrete Sealant',
          'Concrete Resurfacer',
          'Masonry Waterproofing Paint',
          'Concrete Etcher',
          'Concrete Cleaner',
          'Paver Sealer',
          'Concrete Sealer',
          'Masonry Sealer',
          'Foundation Coating',
        ])
          '$size $product',
    ],
    aliases: const ['concrete patch', 'crack repair', 'masonry sealer'],
  );
}

List<WorkSupplyItem> _sizedProducts({
  required String baseName,
  required String unit,
  required List<String> sizes,
  required List<String> products,
  required List<String> aliases,
}) {
  return _generatedMasonryVariants(
    baseName: baseName,
    unit: unit,
    variants: [
      for (final size in sizes)
        for (final product in products) '$size $product',
    ],
    aliases: aliases,
  );
}

List<WorkSupplyItem> _generatedMasonryVariants({
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
