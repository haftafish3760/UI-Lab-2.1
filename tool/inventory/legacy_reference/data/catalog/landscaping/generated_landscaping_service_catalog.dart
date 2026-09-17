part of '../../work_supply_catalog.dart';

final landscapingGeneratedServiceCatalogCategory = _category(
  'Expanded Landscaping Service Stock',
  [
    _system('Expanded Irrigation and Drip', [
      _type('Irrigation Pipe Tubing and Fittings', _irrigationProducts()),
      _type('Drip Irrigation Parts', _dripIrrigationProducts()),
      _type('Sprinkler Heads Valves and Controls', _sprinklerControlProducts()),
      _type(
        'Irrigation Repair Wire and Accessories',
        _irrigationRepairProducts(),
      ),
      _type('Sprinkler Nozzles Risers and Repairs', _sprinklerRepairProducts()),
    ]),
    _system('Expanded Drainage and Erosion', [
      _type('Drainage Pipe Basins and Fittings', _drainageProducts()),
      _type('Erosion Control Materials', _erosionControlProducts()),
    ]),
    _system('Expanded Hardscape Base and Edging', [
      _type('Pavers Edging and Base', _hardscapeBaseProducts()),
      _type('Retaining Wall and Stone', _stoneAndWallProducts()),
      _type(
        'Hardscape Adhesives Sealers and Accessories',
        _hardscapeAccessoryProducts(),
      ),
    ]),
    _system('Expanded Soil Mulch Lawn and Supplies', [
      _type('Bagged Mulch Soil and Amendments', _groundMaterialProducts()),
      _type('Seed Fertilizer and Lawn Repair', _lawnCareProducts()),
      _type('Landscape Fabric Stakes and Staples', _fabricAndStakeProducts()),
      _type('Sod Straw Weed Control and Sprayers', _sodWeedControlProducts()),
      _type('Tree Shrub and Planting Supplies', _plantingSupportProducts()),
    ]),
    _system('Expanded Landscape Tools Lighting and Consumables', [
      _type(
        'Landscape Hand Tools and Small Equipment',
        _landscapeToolProducts(),
      ),
      _type(
        'Landscape Power Equipment Consumables',
        _landscapeEquipmentConsumableProducts(),
      ),
      _type(
        'Landscape Lighting and Outdoor Wire',
        _landscapeLightingProducts(),
      ),
    ]),
    _system('Pro Landscape Service Detail Stock', [
      _type(
        'Drip Emitters Manifolds and Valve Detail',
        _dripValveDetailProducts(),
      ),
      _type('Drainage Channel and Basin Detail', _drainageDetailProducts()),
      _type('Edging Turf and Hardscape Detail', _hardscapeDetailProducts()),
      _type(
        'Landscape Lighting Timer and Connector Detail',
        _lightingDetailProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _irrigationProducts() {
  final diameters = ['1/2 in', '3/4 in', '1 in', '1-1/4 in', '1-1/2 in'];
  final lengths = ['2 ft', '5 ft', '10 ft', '50 ft', '100 ft'];
  final fittings = [
    'Coupling',
    'Elbow',
    'Tee',
    'Male Adapter',
    'Female Adapter',
    'End Cap',
    'Barbed Coupling',
    'Barbed Elbow',
    'Barbed Tee',
    'Insert Adapter',
    'Hose Adapter',
  ];
  return _landscapeGeneratedVariants(
    baseName: 'Irrigation Material',
    unit: 'each',
    variants: [
      for (final diameter in diameters)
        for (final length in lengths)
          '$diameter x $length Poly Irrigation Pipe',
      for (final diameter in diameters)
        for (final fitting in fittings) '$diameter Irrigation $fitting',
      '3/4 in x 100 ft Blu-Lock Pipe',
      '1 in x 100 ft Blu-Lock Pipe',
      '3/4 in Swing Pipe Roll',
      '1/2 in Swing Pipe Roll',
      'Funny Pipe Roll',
      'Irrigation Manifold Kit',
      '1/2 in Swing Pipe Coupling',
      '1/2 in Swing Pipe Elbow',
      '1/2 in Swing Pipe Tee',
    ],
    aliases: const ['irrigation pipe', 'poly pipe', 'sprinkler pipe'],
  );
}

List<WorkSupplyItem> _sprinklerRepairProducts() {
  final nozzles = ['Quarter', 'Half', 'Full', 'Adjustable', 'Strip', 'Rotary'];
  final risers = ['1/2 in', '3/4 in'];
  return _landscapeGeneratedVariants(
    baseName: 'Sprinkler Repair Part',
    unit: 'each',
    variants: [
      for (final nozzle in nozzles) '$nozzle Spray Nozzle Pack',
      for (final height in ['2 in', '4 in', '6 in', '12 in'])
        '$height Pop-Up Sprinkler Body',
      for (final size in risers)
        for (final length in ['2 in', '4 in', '6 in', '12 in'])
          '$size x $length Cut-Off Riser',
      for (final size in risers) '$size Riser Extension',
      for (final size in risers) '$size Swing Joint Elbow',
      'Sprinkler Head Cap Pack',
      'Sprinkler Head Filter Screen Pack',
      'Rotor Adjustment Tool',
      'Nozzle Cleaning Needle Pack',
      'Sprinkler Head Pull-Up Tool',
      'Sprinkler Valve Bleed Screw Pack',
    ],
    aliases: const [
      'sprinkler nozzle',
      'spray nozzle',
      'cut off riser',
      'riser extension',
      'rotor tool',
    ],
  );
}

List<WorkSupplyItem> _dripIrrigationProducts() {
  final tubing = ['1/4 in', '1/2 in', '5/8 in', '0.700 in'];
  final lengths = ['25 ft', '50 ft', '100 ft', '500 ft'];
  final parts = [
    'Drip Coupling',
    'Drip Tee',
    'Drip Elbow',
    'Drip End Cap',
    'Drip Goof Plug Pack',
    'Drip Emitter Pack',
    'Drip Stake Pack',
    'Drip Flush Valve',
    'Drip Pressure Regulator',
    'Drip Filter',
  ];
  return _landscapeGeneratedVariants(
    baseName: 'Drip Irrigation Material',
    unit: 'each',
    variants: [
      for (final size in tubing)
        for (final length in lengths) '$size x $length Drip Tubing',
      for (final size in tubing)
        for (final part in parts) '$size $part',
      '1 GPH Drip Emitter Pack',
      '2 GPH Drip Emitter Pack',
      '4 GPH Drip Emitter Pack',
      'Micro Sprayer Stake Pack',
      'Micro Bubbler Pack',
      'Drip Irrigation Starter Kit',
    ],
    aliases: const ['drip tubing', 'drip line', 'drip emitter'],
  );
}

List<WorkSupplyItem> _sprinklerControlProducts() {
  final sprayPatterns = ['Quarter', 'Half', 'Full', 'Adjustable', 'Strip'];
  final popHeights = ['2 in', '4 in', '6 in', '12 in'];
  final zones = ['2 Zone', '4 Zone', '6 Zone', '8 Zone', '12 Zone'];
  return _landscapeGeneratedVariants(
    baseName: 'Irrigation Control Part',
    unit: 'each',
    variants: [
      for (final height in popHeights)
        for (final pattern in sprayPatterns)
          '$height $pattern Pop-Up Sprinkler Head',
      'Rotor Sprinkler Head',
      'Gear Drive Rotor Sprinkler Head',
      'Impact Sprinkler Head',
      'Shrub Spray Sprinkler Head',
      '1 in Anti-Siphon Valve',
      '3/4 in Anti-Siphon Valve',
      '1 in Inline Irrigation Valve',
      '3/4 in Inline Irrigation Valve',
      for (final zone in zones) '$zone Irrigation Timer',
      'Indoor Irrigation Timer',
      'Outdoor Irrigation Timer',
      'Rain Sensor',
      'Soil Moisture Sensor',
      '24V Sprinkler Valve Solenoid',
      'Valve Box Round',
      'Valve Box Rectangular',
    ],
    aliases: const ['sprinkler head', 'irrigation valve', 'timer'],
  );
}

List<WorkSupplyItem> _irrigationRepairProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Irrigation Repair Supply',
    unit: 'each',
    variants: [
      for (final gauge in ['14 ga', '16 ga', '18 ga'])
        for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
          '$gauge x $length Sprinkler Wire',
      for (final count in ['10 Pack', '25 Pack', '50 Pack'])
        for (final connector in [
          'Waterproof Wire Connector',
          'Grease Cap Wire Connector',
          'Irrigation Wire Nut',
        ])
          '$count $connector',
      'Valve Locator Flag Pack',
      'Sprinkler Head Donut Guard',
      'Sprinkler Head Riser Assortment',
      'Irrigation Riser Extractor',
      'PVC Irrigation Repair Coupling',
      'Swing Joint Assembly',
      'Valve Diaphragm Repair Kit',
    ],
    aliases: const [
      'sprinkler wire',
      'waterproof wire connector',
      'grease cap',
      'valve repair kit',
    ],
  );
}

List<WorkSupplyItem> _drainageProducts() {
  final diameters = ['3 in', '4 in', '6 in'];
  final lengths = ['10 ft', '20 ft', '50 ft', '100 ft'];
  final fittings = [
    'Drain Pipe Coupling',
    'Drain Pipe Tee',
    'Drain Pipe Wye',
    'Drain Pipe Elbow',
    'Drain Pipe Cap',
    'Pop-Up Drainage Emitter',
    'Downspout Adapter',
    'Drain Grate',
  ];
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Drainage Material',
    unit: 'each',
    variants: [
      for (final diameter in diameters)
        for (final length in lengths)
          '$diameter x $length Corrugated Drain Pipe',
      for (final diameter in diameters)
        for (final fitting in fittings) '$diameter $fitting',
      '9 x 9 in Catch Basin',
      '12 x 12 in Catch Basin',
      '18 x 18 in Catch Basin',
      '24 x 24 in Catch Basin',
      'Catch Basin Universal Outlet',
      'French Drain Fabric Roll',
      '4 in EZ Drain Bundle',
      'Drainage Basin Riser',
      'Drainage Basin Adapter',
      'Channel Drain Kit',
      'Channel Drain Grate',
    ],
    aliases: const ['corrugated drain', 'french drain', 'catch basin'],
  );
}

List<WorkSupplyItem> _erosionControlProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Erosion Control Material',
    unit: 'each',
    variants: [
      for (final size in ['9 in x 10 ft', '12 in x 10 ft', '20 in x 10 ft'])
        '$size Straw Wattle',
      for (final size in ['3 ft x 50 ft', '4 ft x 50 ft', '8 ft x 112 ft'])
        '$size Erosion Control Blanket',
      '3 ft x 50 ft Silt Fence',
      '3 ft x 100 ft Silt Fence',
      'Wood Silt Fence Stake Pack',
      'Biodegradable Landscape Stake Pack',
      'Jute Netting Roll',
      'Seed Starter Mat Roll',
    ],
    aliases: const ['straw wattle', 'silt fence', 'erosion blanket'],
  );
}

List<WorkSupplyItem> _hardscapeBaseProducts() {
  final sizes = ['0.5 cu ft', '1 cu ft', '40 lb', '50 lb'];
  final materials = [
    'Paver Base',
    'Paver Leveling Sand',
    'Polymeric Sand',
    'Jointing Sand',
    'All Purpose Gravel',
    'Crushed Stone',
    'Drainage Rock',
  ];
  final edgingLengths = ['8 ft', '10 ft', '20 ft', '40 ft', '60 ft'];
  return _landscapeGeneratedVariants(
    baseName: 'Hardscape Material',
    unit: 'each',
    variants: [
      for (final size in sizes)
        for (final material in materials) '$size $material',
      for (final length in edgingLengths) '$length Plastic Landscape Edging',
      for (final length in edgingLengths) '$length Steel Landscape Edging',
      for (final length in edgingLengths) '$length Aluminum Landscape Edging',
      'Landscape Edging Stake Pack',
      'Paver Restraint Edge',
      'Spiral Landscape Spike Pack',
    ],
    aliases: const ['paver base', 'leveling sand', 'polymeric sand'],
  );
}

List<WorkSupplyItem> _stoneAndWallProducts() {
  final sizes = [
    '4 x 8 in',
    '6 x 9 in',
    '12 x 12 in',
    '16 x 16 in',
    '24 x 24 in',
  ];
  final pavers = ['Paver Stone', 'Patio Stone', 'Stepping Stone'];
  final stoneBags = ['0.5 cu ft', '1 cu ft', '40 lb', '50 lb'];
  final stones = ['Pea Gravel', 'River Rock', 'Marble Chips', 'Lava Rock'];
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Stone Material',
    unit: 'each',
    variants: [
      for (final size in sizes)
        for (final paver in pavers) '$size $paver',
      'Retaining Wall Block',
      'Straight Retaining Wall Block',
      'Corner Retaining Wall Block',
      'Wall Cap Block',
      'Garden Wall Block',
      'Tree Ring Block',
      'Concrete Splash Block',
      for (final size in stoneBags)
        for (final stone in stones) '$size $stone',
    ],
    aliases: const ['patio paver', 'wall block', 'pea gravel', 'river rock'],
  );
}

List<WorkSupplyItem> _hardscapeAccessoryProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Hardscape Accessory',
    unit: 'each',
    variants: [
      for (final size in ['10 oz', '28 oz']) '$size Landscape Block Adhesive',
      for (final size in ['1 gal', '2 gal', '5 gal']) '$size Paver Sealer',
      for (final size in ['1 gal', '2 gal']) '$size Concrete Paver Cleaner',
      for (final size in ['50 lb', '70 lb']) '$size Polymeric Sand',
      'Paver Joint Stabilizer',
      'Paver Edge Restraint Spike Pack',
      'Paver Spacer Pack',
      'Paver Leveling Screed Rail Set',
      'Rubber Paver Mallet',
      'Landscape Stone Adhesive',
      'Retaining Wall Drain Pipe Sleeve',
      'Geogrid Retaining Wall Reinforcement',
    ],
    aliases: const [
      'block adhesive',
      'paver sealer',
      'paver cleaner',
      'geogrid',
      'edge restraint',
    ],
  );
}

List<WorkSupplyItem> _groundMaterialProducts() {
  final mulchColors = ['Black', 'Brown', 'Red', 'Natural', 'Cypress', 'Cedar'];
  final soils = [
    'Topsoil',
    'Garden Soil',
    'Raised Bed Soil',
    'Potting Mix',
    'Compost',
    'Manure Compost',
    'Peat Moss',
    'Soil Conditioner',
    'Lawn Soil',
  ];
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Ground Material',
    unit: 'bag',
    variants: [
      for (final color in mulchColors) '2 cu ft $color Bagged Mulch',
      for (final color in mulchColors) '3 cu ft $color Bagged Mulch',
      for (final soil in soils) '40 lb $soil',
      for (final soil in soils) '1 cu ft $soil',
      for (final soil in soils) '2 cu ft $soil',
      '40 lb Garden Lime',
      '40 lb Pelletized Lime',
      '40 lb Gypsum Soil Conditioner',
    ],
    aliases: const ['bagged mulch', 'topsoil', 'garden soil', 'compost'],
  );
}

List<WorkSupplyItem> _lawnCareProducts() {
  final weights = ['3 lb', '5 lb', '10 lb', '20 lb', '40 lb', '50 lb'];
  final products = [
    'Tall Fescue Grass Seed',
    'Bermuda Grass Seed',
    'Ryegrass Seed',
    'Sun and Shade Grass Seed',
    'Starter Fertilizer',
    'All Purpose Fertilizer',
    'Weed and Feed',
    'Crabgrass Preventer',
    'Lawn Repair Mix',
    'Grub Control',
  ];
  return _landscapeGeneratedVariants(
    baseName: 'Lawn Care Material',
    unit: 'bag',
    variants: [
      for (final weight in weights)
        for (final product in products) '$weight $product',
    ],
    aliases: const ['grass seed', 'fertilizer', 'weed and feed'],
  );
}

List<WorkSupplyItem> _fabricAndStakeProducts() {
  final widths = ['3 ft', '4 ft', '6 ft'];
  final lengths = ['25 ft', '50 ft', '100 ft', '225 ft', '300 ft'];
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Accessory',
    unit: 'each',
    variants: [
      for (final width in widths)
        for (final length in lengths) '$width x $length Landscape Fabric',
      for (final width in widths)
        for (final length in lengths) '$width x $length Weed Barrier',
      '6 in Landscape Fabric Staple Pack',
      '8 in Landscape Fabric Staple Pack',
      '10 in Sod Staple Pack',
      'Tree Stake Kit',
      'Plant Tie Roll',
      'Burlap Tree Wrap Roll',
      'Tree Watering Bag',
      'Root Barrier Roll',
    ],
    aliases: const ['weed barrier', 'landscape fabric', 'fabric staple'],
  );
}

List<WorkSupplyItem> _sodWeedControlProducts() {
  final controls = [
    'Ready To Use Weed Killer',
    'Concentrate Weed Killer',
    'Grass and Weed Killer',
    'Brush Killer',
    'Pre-Emergent Weed Preventer',
    'Selective Lawn Weed Control',
  ];
  return _landscapeGeneratedVariants(
    baseName: 'Lawn and Landscape Treatment',
    unit: 'each',
    variants: [
      for (final size in ['1 gal', '1.33 gal', '2 gal'])
        for (final control in controls) '$size $control',
      for (final size in ['1 qt', '1 gal', '2.5 gal'])
        for (final control in ['Herbicide Concentrate', 'Insect Control'])
          '$size $control',
      for (final size in ['500 sq ft', '1000 sq ft', '2000 sq ft'])
        '$size Sod Roll',
      for (final pack in ['10 sq ft', '25 sq ft', '50 sq ft'])
        '$pack Sod Patch',
      for (final size in ['1 cu ft', '2 cu ft', '3 cu ft'])
        for (final straw in ['Wheat Straw Bale', 'Pine Straw Bale'])
          '$size $straw',
      '2 gal Pump Sprayer',
      '1 gal Pump Sprayer',
      'Backpack Sprayer',
      'Marking Flag Pack',
    ],
    aliases: const [
      'weed killer',
      'herbicide',
      'sod roll',
      'pine straw',
      'pump sprayer',
    ],
  );
}

List<WorkSupplyItem> _plantingSupportProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Planting and Tree Support Supply',
    unit: 'each',
    variants: [
      for (final size in ['2 in', '3 in', '4 in']) '$size Tree Tie Strap Roll',
      for (final count in ['10 Pack', '25 Pack', '50 Pack'])
        '$count Bamboo Plant Stake',
      for (final size in ['18 in', '24 in', '30 in', '36 in'])
        '$size Plant Support Ring',
      for (final size in ['2 ft', '3 ft', '4 ft']) '$size Tree Trunk Protector',
      'Root Stimulator 1 gal',
      'Tree Fertilizer Spike Pack',
      'Shrub Fertilizer Spike Pack',
      'Tree Watering Bag 20 gal',
      'Burlap Ball Wrap Roll',
      'Tree Guying Kit',
      'Landscape Plant Tag Pack',
      'Deer Protection Netting Roll',
      'Bird Netting Roll',
    ],
    aliases: const [
      'tree tie',
      'plant stake',
      'plant support',
      'root stimulator',
      'tree watering bag',
    ],
  );
}

List<WorkSupplyItem> _landscapeToolProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Tool or Consumable',
    unit: 'each',
    variants: [
      for (final tool in [
        'Round Point Shovel',
        'Transfer Shovel',
        'Drain Spade',
        'Trenching Shovel',
        'Bow Rake',
        'Leaf Rake',
        'Landscape Rake',
        'Garden Hoe',
        'Tamper',
        'Post Hole Digger',
        'Hand Pruner',
        'Lopper',
        'Hedge Shear',
        'Wheelbarrow',
      ])
        tool,
      for (final length in ['50 ft', '100 ft', '150 ft'])
        '$length Commercial Garden Hose',
      for (final item in [
        'Hose Nozzle',
        'Hose Repair Coupling',
        'Trimmer Line Spool',
        'Edger Blade',
        'Mower Blade',
        'Leaf Bag Pack',
        'Yard Waste Bag Pack',
        'Contractor Trash Bag Pack',
      ])
        item,
    ],
    aliases: const [
      'shovel',
      'rake',
      'tamper',
      'trimmer line',
      'mower blade',
      'yard waste bag',
    ],
  );
}

List<WorkSupplyItem> _landscapeEquipmentConsumableProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Equipment Consumable',
    unit: 'each',
    variants: [
      for (final shape in ['Round', 'Twisted', 'Square'])
        for (final diameter in ['0.065 in', '0.080 in', '0.095 in', '0.105 in'])
          '$diameter $shape Trimmer Line',
      for (final length in ['18 in', '20 in', '21 in', '22 in'])
        '$length Mulching Mower Blade',
      for (final length in ['18 in', '20 in', '21 in', '22 in'])
        '$length High Lift Mower Blade',
      for (final size in ['8 in', '9 in', '10 in']) '$size Edger Blade',
      'Chainsaw Bar and Chain Oil 1 gal',
      'Two Cycle Oil 2.6 oz',
      'Two Cycle Oil 6.4 oz',
      'Small Engine Fuel Treatment',
      'Mower Air Filter',
      'Mower Spark Plug',
      'Fuel Line Repair Kit',
      'Primer Bulb Pack',
      'Trimmer Head Replacement',
      'Brush Cutter Blade',
    ],
    aliases: const [
      'trimmer line',
      'mower blade',
      'edger blade',
      'two cycle oil',
      'mower spark plug',
    ],
  );
}

List<WorkSupplyItem> _landscapeLightingProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Lighting Supply',
    unit: 'each',
    variants: [
      for (final watt in ['60W', '100W', '120W', '200W'])
        '$watt Low Voltage Transformer',
      for (final gauge in ['12/2', '14/2', '16/2'])
        for (final length in ['50 ft', '100 ft', '250 ft'])
          '$gauge x $length Low Voltage Landscape Wire',
      for (final finish in ['Black', 'Bronze', 'Stainless'])
        for (final fixture in ['Path Light', 'Spot Light', 'Well Light'])
          '$finish LED Landscape $fixture',
      'Landscape Lighting Wire Connector Pack',
      'Photocell Timer',
      'Landscape Light Stake Pack',
    ],
    aliases: const [
      'landscape light',
      'low voltage landscape wire',
      'path light',
      'transformer',
    ],
  );
}

List<WorkSupplyItem> _dripValveDetailProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Irrigation Detail Supply',
    unit: 'each',
    variants: [
      for (final size in ['1/4 in', '1/2 in', '5/8 in', '0.700 in'])
        for (final part in [
          'Barbed Coupling',
          'Barbed Tee',
          'Barbed Elbow',
          'Compression Coupling',
          'Compression Tee',
          'Compression Elbow',
          'Drip End Cap',
          'Drip Goof Plug 25 Pack',
          'Drip Emitter 25 Pack',
          'Drip Emitter 100 Pack',
          'Drip Stake 25 Pack',
          'Drip Tubing Hold Down Stake 50 Pack',
        ])
          '$size $part',
      for (final gph in ['0.5 GPH', '1 GPH', '2 GPH', '4 GPH'])
        for (final count in ['10 Pack', '25 Pack', '100 Pack'])
          '$gph Pressure Compensating Drip Emitter $count',
      for (final item in [
        'Drip Pressure Regulator 25 PSI',
        'Drip Pressure Regulator 30 PSI',
        'Drip Filter 150 Mesh',
        'Drip Flush Valve',
        'Drip Manifold 4 Outlet',
        'Drip Manifold 6 Outlet',
        'Drip Manifold 12 Outlet',
        'Irrigation Valve Diaphragm Kit',
        'Irrigation Valve Solenoid',
        'Valve Box Lid Round',
        'Valve Box Lid Rectangular',
        'Valve Box Extension',
        'Sprinkler Manifold Tee',
        'Sprinkler Manifold Elbow',
      ])
        item,
    ],
    aliases: const [
      'drip emitter',
      'pressure compensating emitter',
      'drip manifold',
      'drip regulator',
      'valve box lid',
      'valve diaphragm',
    ],
  );
}

List<WorkSupplyItem> _drainageDetailProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Drainage Detail Supply',
    unit: 'each',
    variants: [
      for (final width in ['3 in', '4 in', '5 in', '6 in'])
        for (final length in ['3 ft', '4 ft', '6 ft', '10 ft'])
          '$width x $length Channel Drain Kit',
      for (final width in ['3 in', '4 in', '5 in', '6 in'])
        for (final part in [
          'Channel Drain Grate',
          'Channel Drain End Cap',
          'Channel Drain End Outlet',
          'Channel Drain Inline Basin',
          'Channel Drain Coupler',
          'Channel Drain Corner',
        ])
          '$width $part',
      for (final size in ['9 x 9 in', '12 x 12 in', '18 x 18 in', '24 x 24 in'])
        for (final item in [
          'Catch Basin',
          'Catch Basin Grate',
          'Catch Basin Riser',
          'Catch Basin Outlet Adapter',
          'Atrium Grate',
        ])
          '$size $item',
      for (final diameter in ['3 in', '4 in', '6 in'])
        for (final item in [
          'Pop-Up Drainage Emitter',
          'Downspout Adapter',
          'Flexible Drain Coupling',
          'Drain Pipe Wye',
          'Drain Pipe Tee',
          'Drain Pipe End Cap',
        ])
          '$diameter $item',
      'French Drain Fabric Sock Roll',
      'Drainage Gravel 0.5 cu ft',
      'Drainage Basin Universal Outlet',
    ],
    aliases: const [
      'channel drain',
      'catch basin grate',
      'atrium grate',
      'pop up emitter',
      'downspout adapter',
      'french drain sock',
    ],
  );
}

List<WorkSupplyItem> _hardscapeDetailProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Hardscape Detail Supply',
    unit: 'each',
    variants: [
      for (final length in ['6 ft', '8 ft', '10 ft', '16 ft', '20 ft'])
        for (final edging in [
          'No-Dig Landscape Edging',
          'Steel Landscape Edging',
          'Aluminum Landscape Edging',
          'Composite Landscape Edging',
          'Paver Edge Restraint',
        ])
          '$length $edging',
      for (final count in ['25 Pack', '50 Pack', '100 Pack'])
        for (final item in [
          'Landscape Edging Spike',
          'Paver Edge Spike',
          'Spiral Landscape Spike',
          'Artificial Turf Nail',
          'Landscape Fabric Pin',
          'Sod Staple',
        ])
          '$item $count',
      for (final size in ['3 ft x 5 ft', '6 ft x 8 ft', '7.5 ft x 10 ft'])
        for (final item in [
          'Artificial Turf Roll',
          'Putting Green Turf Roll',
          'Turf Weed Barrier',
        ])
          '$size $item',
      for (final item in [
        'Artificial Turf Seam Tape',
        'Artificial Turf Adhesive',
        'Turf Infill Sand',
        'Turf Deodorizer',
        'Retaining Wall Cap',
        'Retaining Wall Pin Pack',
        'Retaining Wall Drainage Stone',
        'Paver Joint Sand',
        'Paver Polymeric Sand',
        'Paver Sand Base Panel',
      ])
        item,
    ],
    aliases: const [
      'no dig edging',
      'edging spike',
      'artificial turf',
      'turf seam tape',
      'retaining wall cap',
      'paver sand base',
    ],
  );
}

List<WorkSupplyItem> _lightingDetailProducts() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Lighting Detail Supply',
    unit: 'each',
    variants: [
      for (final watt in ['45W', '60W', '100W', '120W', '200W', '300W'])
        for (final type in [
          'Low Voltage Transformer',
          'Low Voltage Transformer With Timer',
          'Smart Landscape Transformer',
        ])
          '$watt $type',
      for (final gauge in ['12/2', '14/2', '16/2'])
        for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
          '$gauge x $length Direct Burial Landscape Wire',
      for (final finish in ['Black', 'Bronze', 'Stainless'])
        for (final fixture in [
          'LED Path Light',
          'LED Spot Light',
          'LED Well Light',
          'LED Flood Light',
          'Deck Step Light',
          'Hardscape Wall Light',
        ])
          '$finish $fixture',
      for (final count in ['4 Pack', '10 Pack', '25 Pack'])
        for (final item in [
          'Landscape Lighting Wire Connector',
          'Waterproof Landscape Wire Nut',
          'Pierce Point Wire Connector',
          'Landscape Light Stake',
          'Landscape Light Extension Cable',
        ])
          '$item $count',
      'Photocell Timer',
      'Astronomical Landscape Timer',
      'Smart Outdoor Plug',
      'Landscape Lighting Splitter',
      'Landscape Lighting Hub',
    ],
    aliases: const [
      'landscape transformer',
      'direct burial landscape wire',
      'hardscape wall light',
      'waterproof landscape connector',
      'photocell timer',
      'smart outdoor plug',
    ],
  );
}

List<WorkSupplyItem> _landscapeGeneratedVariants({
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
