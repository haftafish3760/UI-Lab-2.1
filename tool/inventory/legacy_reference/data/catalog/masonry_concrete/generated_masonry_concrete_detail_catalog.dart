part of '../../work_supply_catalog.dart';

final masonryConcreteGeneratedDetailCatalogCategory = _category(
  'Masonry and Concrete Detail Stock',
  [
    _system('Concrete Mix Strength Color and Additive Detail', [
      _type('Concrete Mix Detail', _masonryConcreteMixDetail()),
      _type('Concrete Additive Detail', _masonryConcreteAdditiveDetail()),
    ]),
    _system('Block Brick Paver and Stone Detail', [
      _type('Block and Brick Detail', _masonryConcreteUnitDetail()),
      _type('Paver Wall Block and Cap Detail', _masonryHardscapeUnitDetail()),
    ]),
    _system('Rebar Mesh Forms and Joint Detail', [
      _type('Rebar Mesh and Spacer Detail', _masonryReinforcementDetail()),
      _type('Form Tube Joint and Stake Detail', _masonryFormJointDetail()),
    ]),
    _system('Anchor Fastener Repair and Coating Detail', [
      _type('Concrete Anchor Detail', _masonryAnchorDetail()),
      _type('Concrete Repair Coating Detail', _masonryRepairCoatingDetail()),
    ]),
    _system('Stucco Chimney and Masonry Tool Detail', [
      _type('Stucco Chimney Detail', _masonryStuccoChimneyDetail()),
      _type('Masonry Tool Consumable Detail', _masonryToolDetail()),
    ]),
  ],
);

List<WorkSupplyItem> _masonryConcreteMixDetail() {
  return _masonryDetailProducts(
    baseName: 'Concrete Mix Detail',
    unit: 'bag',
    variants: [
      for (final weight in ['40 lb', '50 lb', '60 lb', '80 lb'])
        for (final mix in [
          '5000 PSI Concrete Mix',
          'Fast Setting Concrete Mix',
          'High Early Strength Concrete Mix',
          'Fiber Reinforced Concrete Mix',
          'Crack Resistant Concrete Mix',
          'Countertop Concrete Mix',
          'Sand Topping Mix',
          'Vinyl Patch Mix',
        ])
          '$weight $mix',
      for (final weight in ['10 lb', '20 lb', '40 lb', '60 lb'])
        for (final mix in [
          'Anchoring Cement',
          'Hydraulic Water Stop Cement',
          'Surface Bonding Cement',
          'Non Shrink Grout',
        ])
          '$weight $mix',
    ],
    aliases: const [
      '5000 psi concrete',
      'fast set concrete',
      'fiber concrete',
      'anchoring cement',
      'non shrink grout',
    ],
  );
}

List<WorkSupplyItem> _masonryConcreteAdditiveDetail() {
  return _masonryDetailProducts(
    baseName: 'Concrete Additive Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 qt', '1 gal', '5 gal'])
        for (final item in [
          'Concrete Bonding Adhesive',
          'Acrylic Fortifier',
          'Latex Additive',
          'Concrete Cure and Seal',
          'Concrete Retarder',
          'Concrete Accelerator',
          'Water Reducer',
          'Form Release Oil',
        ])
          '$size $item',
      for (final color in ['Charcoal', 'Buff', 'Red', 'Brown', 'Terra Cotta'])
        for (final size in ['10 oz', '1 lb', '5 lb'])
          '$size $color Integral Concrete Color',
    ],
    aliases: const [
      'bonding adhesive',
      'acrylic fortifier',
      'latex additive',
      'cure and seal',
      'integral color',
    ],
  );
}

List<WorkSupplyItem> _masonryConcreteUnitDetail() {
  return _masonryDetailProducts(
    baseName: 'Masonry Unit Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '4 x 8 x 16 in',
        '6 x 8 x 16 in',
        '8 x 8 x 16 in',
        '10 x 8 x 16 in',
        '12 x 8 x 16 in',
      ])
        for (final unit in [
          'Concrete Block',
          'Concrete Half Block',
          'Concrete Solid Block',
          'Concrete Cap Block',
          'Concrete Lintel Block',
          'Concrete Bond Beam Block',
          'Split Face Concrete Block',
        ])
          '$size $unit',
      for (final brick in [
        'Modular Red Clay Brick',
        'Queen Red Clay Brick',
        'King Red Clay Brick',
        'Common Clay Brick',
        'Concrete Brick',
        'Fire Brick',
        'Thin Brick Flat',
        'Thin Brick Corner',
      ])
        brick,
    ],
    aliases: const [
      'cmu',
      'cinder block',
      'concrete block',
      'split face block',
      'red brick',
      'fire brick',
    ],
  );
}

List<WorkSupplyItem> _masonryHardscapeUnitDetail() {
  return _masonryDetailProducts(
    baseName: 'Hardscape Masonry Detail',
    unit: 'each',
    variants: [
      for (final color in ['Gray', 'Charcoal', 'Tan', 'Red', 'Brown'])
        for (final unit in [
          '12 x 12 in Patio Stone',
          '12 x 24 in Patio Stone',
          '16 x 16 in Stepping Stone',
          '6 x 9 in Rectangle Paver',
          '4 x 8 in Holland Paver',
          'Retaining Wall Block',
          'Wall Cap Block',
          'Fire Pit Block',
        ])
          '$color $unit',
      'Paver Spike 10 Pack',
      'Paver Edge Restraint 6 ft',
      'Aluminum Paver Edge 8 ft',
      'Plastic Paver Edging 10 ft',
    ],
    aliases: const [
      'paver',
      'patio stone',
      'stepping stone',
      'wall block',
      'paver edge',
    ],
  );
}

List<WorkSupplyItem> _masonryReinforcementDetail() {
  return _masonryDetailProducts(
    baseName: 'Concrete Reinforcement Detail',
    unit: 'each',
    variants: [
      for (final size in ['#3', '#4', '#5', '#6'])
        for (final length in ['2 ft', '4 ft', '10 ft', '20 ft'])
          '$size x $length Grade 60 Rebar',
      for (final sheet in [
        '42 x 84 in Remesh Sheet',
        '5 x 10 ft Remesh Sheet',
        '7 x 50 ft Remesh Roll',
        '5 ft x 150 ft Wire Mesh Roll',
      ])
        sheet,
      for (final item in [
        '16 Gauge Rebar Tie Wire',
        'Rebar Chair 50 Pack',
        'Rebar Safety Cap 25 Pack',
        'Concrete Dobie Block 20 Pack',
        'Plastic Slab Bolster 5 ft',
      ])
        item,
    ],
    aliases: const ['rebar', 'remesh', 'wire mesh', 'tie wire', 'rebar chair'],
  );
}

List<WorkSupplyItem> _masonryFormJointDetail() {
  return _masonryDetailProducts(
    baseName: 'Concrete Form Joint Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 x 4 x 8 ft', '2 x 4 x 8 ft', '2 x 6 x 8 ft'])
        '$size Concrete Form Board',
      for (final diameter in ['8 in', '10 in', '12 in', '16 in', '18 in'])
        for (final height in ['48 in', '60 in'])
          '$diameter x $height Concrete Form Tube',
      for (final width in ['1/2 in', '3/4 in', '1 in'])
        for (final item in [
          'Fiber Expansion Joint',
          'Closed Cell Expansion Joint',
          'Backer Rod',
          'Zip Strip Control Joint',
        ])
          '$width $item',
      for (final stake in ['18 in Wood', '24 in Wood', '18 in Steel'])
        '$stake Concrete Form Stake',
    ],
    aliases: const [
      'form board',
      'sonotube',
      'form tube',
      'expansion joint',
      'control joint',
      'backer rod',
    ],
  );
}

List<WorkSupplyItem> _masonryAnchorDetail() {
  return _masonryDetailProducts(
    baseName: 'Concrete Anchor Detail',
    unit: 'pack',
    variants: [
      for (final size in ['3/16 in', '1/4 in', '3/8 in', '1/2 in'])
        for (final length in ['1-1/4 in', '1-3/4 in', '2-3/4 in', '3-3/4 in'])
          for (final anchor in [
            'Blue Concrete Screw',
            'Flat Head Concrete Screw',
            'Hex Head Concrete Screw',
            'Wedge Anchor',
            'Sleeve Anchor',
            'Drop In Anchor',
          ])
            '$size x $length $anchor',
      '1/4 in Tapcon Drill Bit and Anchor Kit',
      '3/16 in Tapcon Drill Bit and Anchor Kit',
      'Powder Actuated Concrete Pin 100 Pack',
      'Powder Actuated Load Strip 100 Pack',
    ],
    aliases: const [
      'tapcon',
      'concrete screw',
      'wedge anchor',
      'sleeve anchor',
      'drop in anchor',
      'powder actuated',
    ],
  );
}

List<WorkSupplyItem> _masonryRepairCoatingDetail() {
  return _masonryDetailProducts(
    baseName: 'Concrete Repair Coating Detail',
    unit: 'each',
    variants: [
      for (final size in ['10 oz', '1 qt', '1 gal', '5 gal', '20 lb', '40 lb'])
        for (final item in [
          'Concrete Crack Sealant',
          'Self Leveling Concrete Sealant',
          'Vinyl Concrete Patch',
          'Concrete Resurfacer',
          'Foundation Coating',
          'Masonry Waterproofing Paint',
          'Concrete Etcher',
          'Concrete Cleaner',
          'Concrete Sealer',
          'Paver Sealer',
        ])
          '$size $item',
    ],
    aliases: const [
      'concrete patch',
      'crack sealant',
      'self leveling sealant',
      'foundation coating',
      'paver sealer',
    ],
  );
}

List<WorkSupplyItem> _masonryStuccoChimneyDetail() {
  return _masonryDetailProducts(
    baseName: 'Stucco Chimney Detail',
    unit: 'each',
    variants: [
      for (final length in ['8 ft', '10 ft'])
        for (final item in [
          'Galvanized Weep Screed',
          'Stucco Corner Bead',
          'Stucco Casing Bead',
          'Stucco Control Joint',
        ])
          '$length $item',
      for (final size in ['27 in x 8 ft', '36 in x 150 ft'])
        for (final lath in [
          'Expanded Metal Lath',
          'Self Furring Metal Lath',
          'Paper Backed Wire Lath',
        ])
          '$size $lath',
      for (final size in ['8 x 8 in', '8 x 12 in', '12 x 12 in'])
        for (final item in ['Clay Flue Liner', 'Flue Tile']) '$size $item',
      'Fire Brick',
      'Refractory Mortar',
      'Fireplace Mortar',
      'Smoke Chamber Parging Mix',
      'Chimney Crown Repair',
    ],
    aliases: const [
      'weep screed',
      'stucco bead',
      'metal lath',
      'flue liner',
      'refractory mortar',
    ],
  );
}

List<WorkSupplyItem> _masonryToolDetail() {
  return _masonryDetailProducts(
    baseName: 'Masonry Tool Consumable Detail',
    unit: 'each',
    variants: [
      for (final size in ['3/16 in', '1/4 in', '3/8 in', '1/2 in', '5/8 in'])
        for (final bit in ['Masonry Drill Bit', 'SDS Plus Masonry Bit'])
          '$size $bit',
      for (final size in ['4 in', '4-1/2 in', '7 in', '10 in', '12 in'])
        for (final blade in [
          'Concrete Diamond Blade',
          'Masonry Grinding Wheel',
        ])
          '$size $blade',
      'Brick Chisel',
      'Cold Chisel',
      'Masonry Line Block Set',
      '500 ft Mason Line',
      'Concrete Finishing Broom',
    ],
    aliases: const [
      'masonry bit',
      'sds masonry bit',
      'diamond blade',
      'masonry blade',
      'mason line',
    ],
  );
}

List<WorkSupplyItem> _masonryDetailProducts({
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
