part of '../../work_supply_catalog.dart';

final landscapingGeneratedDetailCatalogCategory = _category(
  'Landscaping Detail Stock',
  [
    _system('Irrigation Drip and Drainage Detail Stock', [
      _type(
        'Irrigation Fitting Valve and Control Detail',
        _landscapeIrrigationDetail(),
      ),
      _type(
        'Drainage Basin Pipe and Erosion Detail',
        _landscapeDrainageDetail(),
      ),
    ]),
    _system('Ground Material Lawn and Planting Detail Stock', [
      _type('Mulch Soil Seed and Fertilizer Detail', _landscapeGroundDetail()),
      _type(
        'Planting Support Fabric and Treatment Detail',
        _landscapePlantingDetail(),
      ),
    ]),
    _system('Hardscape Turf Lighting and Equipment Detail Stock', [
      _type(
        'Hardscape Edging Turf and Seal Detail',
        _landscapeHardscapeDetail(),
      ),
      _type(
        'Lighting Wire and Equipment Consumable Detail',
        _landscapeLightingEquipmentDetail(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _landscapeIrrigationDetail() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Irrigation Detail',
    unit: 'each',
    variants: [
      for (final size in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
        for (final part in [
          'Blu-Lock Coupling',
          'Blu-Lock Elbow',
          'Blu-Lock Tee',
          'Funny Pipe Elbow',
          'Funny Pipe Coupling',
          'Barbed Coupling',
          'Barbed Tee',
          'Insert Adapter',
          'Irrigation Male Adapter',
          'Irrigation Female Adapter',
        ])
          '$size $part',
      for (final gph in ['0.5 GPH', '1 GPH', '2 GPH', '4 GPH'])
        for (final count in ['10 Pack', '25 Pack', '50 Pack'])
          '$gph Pressure Compensating Drip Emitter $count',
      for (final outlets in ['4 Outlet', '6 Outlet', '8 Outlet', '12 Outlet'])
        '$outlets Drip Manifold',
      for (final zone in ['4 Zone', '6 Zone', '8 Zone', '12 Zone'])
        for (final timer in [
          'Indoor Irrigation Timer',
          'Outdoor Irrigation Timer',
        ])
          '$zone $timer',
      '1 in Inline Irrigation Valve',
      '3/4 in Anti-Siphon Valve',
      '24V Irrigation Valve Solenoid',
      'Valve Box Extension',
      'Valve Box Lid',
      'Drip Pressure Regulator',
      'Drip Filter',
      'Drip Flush Valve',
    ],
    aliases: const [
      'blu-lock',
      'funny pipe',
      'barbed fitting',
      'drip emitter',
      'drip manifold',
      'irrigation timer',
      'valve solenoid',
    ],
  );
}

List<WorkSupplyItem> _landscapeDrainageDetail() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Drainage Detail',
    unit: 'each',
    variants: [
      for (final size in ['3 in', '4 in', '6 in'])
        for (final part in [
          'Corrugated Drain Pipe Coupling',
          'Corrugated Drain Pipe Wye',
          'Corrugated Drain Pipe Tee',
          'Pop-Up Drainage Emitter',
          'Downspout Adapter',
          'French Drain Sock',
        ])
          '$size $part',
      for (final basin in [
        '9 x 9 in',
        '12 x 12 in',
        '18 x 18 in',
        '24 x 24 in',
      ])
        for (final part in [
          'Catch Basin',
          'Catch Basin Grate',
          'Catch Basin Riser',
          'Catch Basin Outlet Adapter',
          'Atrium Grate',
        ])
          '$basin $part',
      for (final size in ['3 ft x 50 ft', '4 ft x 50 ft', '8 ft x 112 ft'])
        for (final item in ['Erosion Control Blanket', 'Jute Netting'])
          '$size $item',
      '4 in Channel Drain Grate',
      '4 in Channel Drain End Cap',
      '4 in Channel Drain Outlet',
      'Straw Wattle 9 in x 10 ft',
      'Silt Fence Stake Pack',
    ],
    aliases: const [
      'corrugated drain',
      'catch basin',
      'atrium grate',
      'channel drain',
      'downspout adapter',
      'erosion blanket',
    ],
  );
}

List<WorkSupplyItem> _landscapeGroundDetail() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Ground Detail',
    unit: 'bag',
    variants: [
      for (final color in ['Black', 'Brown', 'Red', 'Natural'])
        for (final size in ['1.5 cu ft', '2 cu ft', '3 cu ft'])
          '$size $color Bagged Mulch',
      for (final size in ['0.75 cu ft', '1 cu ft', '1.5 cu ft', '2 cu ft'])
        for (final material in [
          'Topsoil',
          'Garden Soil',
          'Potting Mix',
          'Compost',
          'Peat Moss',
          'Cow Manure Compost',
          'Paver Leveling Sand',
          'All Purpose Gravel',
          'Pea Gravel',
          'River Rock',
        ])
          '$size $material',
      for (final weight in ['10 lb', '20 lb', '40 lb', '50 lb'])
        for (final item in [
          'Tall Fescue Grass Seed',
          'Bermuda Grass Seed',
          'Ryegrass Seed',
          'Starter Fertilizer',
          'Lawn Fertilizer',
          'Weed and Feed',
          'Pelletized Lime',
        ])
          '$weight $item',
    ],
    aliases: const [
      'bagged mulch',
      'topsoil',
      'garden soil',
      'compost',
      'grass seed',
      'weed and feed',
      'fertilizer',
    ],
  );
}

List<WorkSupplyItem> _landscapePlantingDetail() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Planting Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '3 ft x 50 ft',
        '4 ft x 50 ft',
        '4 ft x 100 ft',
        '6 ft x 100 ft',
      ])
        for (final fabric in ['Landscape Fabric', 'Weed Barrier Fabric'])
          '$size $fabric',
      for (final count in ['25 Pack', '50 Pack', '100 Pack'])
        for (final item in [
          'Landscape Fabric Staple',
          'Tree Stake',
          'Plant Support Stake',
          'Plant Tie',
        ])
          '$count $item',
      for (final size in ['1 qt', '1 gal', '2 gal'])
        for (final item in [
          'Root Stimulator',
          'Concentrate Weed Killer',
          'Brush Killer',
          'Pre-Emergent Weed Control',
          'Insect Control',
        ])
          '$size $item',
      '3 in Tree Tie Strap Roll',
      'Tree Watering Bag',
      'Burlap Root Ball Wrap',
      'Deer Netting 7 ft x 100 ft',
      'Bird Netting 14 ft x 14 ft',
      'Pump Sprayer 1 gal',
      'Backpack Sprayer 4 gal',
    ],
    aliases: const [
      'landscape fabric',
      'weed barrier',
      'fabric staple',
      'tree stake',
      'root stimulator',
      'weed killer',
      'pump sprayer',
    ],
  );
}

List<WorkSupplyItem> _landscapeHardscapeDetail() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Hardscape Detail',
    unit: 'each',
    variants: [
      for (final length in ['20 ft', '40 ft', '60 ft'])
        for (final edging in [
          'No-Dig Landscape Edging',
          'Steel Landscape Edging',
          'Aluminum Landscape Edging',
          'Plastic Landscape Edging',
        ])
          '$length $edging',
      for (final size in ['4 ft x 8 ft', '6 ft x 8 ft', '6 ft x 10 ft'])
        for (final turf in ['Artificial Turf Roll', 'Putting Green Turf Roll'])
          '$size $turf',
      for (final size in ['1 gal', '5 gal'])
        for (final item in [
          'Paver Sealer',
          'Paver Cleaner',
          'Wet Look Paver Sealer',
        ])
          '$size $item',
      'Paver Sand Base Panel 20 Pack',
      'Paver Edge Restraint 6 ft',
      'Paver Spike 10 in 25 Pack',
      'Geogrid Retaining Wall Grid',
      'Retaining Wall Pin 25 Pack',
      'Retaining Wall Cap',
      'Turf Seam Tape',
      'Artificial Turf Adhesive',
    ],
    aliases: const [
      'landscape edging',
      'no-dig edging',
      'artificial turf',
      'paver sealer',
      'geogrid',
      'retaining wall cap',
    ],
  );
}

List<WorkSupplyItem> _landscapeLightingEquipmentDetail() {
  return _landscapeGeneratedVariants(
    baseName: 'Landscape Lighting Equipment Detail',
    unit: 'each',
    variants: [
      for (final watt in ['60W', '120W', '200W', '300W'])
        '$watt Low Voltage Landscape Transformer',
      for (final gauge in ['12/2', '14/2', '16/2'])
        for (final length in ['50 ft', '100 ft', '250 ft'])
          '$gauge $length Low Voltage Landscape Wire',
      for (final finish in ['Black', 'Bronze'])
        for (final light in [
          'LED Landscape Path Light',
          'LED Landscape Spot Light',
          'Hardscape Wall Light',
          'Deck Step Light',
          'Well Light',
        ])
          '$finish $light',
      for (final count in ['10 Pack', '25 Pack', '50 Pack'])
        for (final item in [
          'Waterproof Landscape Wire Nut',
          'Pierce Point Wire Connector',
          'Landscape Lighting Wire Connector',
        ])
          '$count $item',
      for (final item in [
        'Astronomical Landscape Timer',
        'Photocell Landscape Timer',
        'Smart Outdoor Plug',
        'Trimmer Line Spool',
        'Mower Blade',
        'Edger Blade',
        '2 Cycle Oil 2.6 oz',
        'Mower Spark Plug',
        'Primer Bulb Kit',
      ])
        item,
    ],
    aliases: const [
      'landscape transformer',
      'landscape wire',
      'path light',
      'hardscape light',
      'wire connector',
      'trimmer line',
      'mower blade',
    ],
  );
}
