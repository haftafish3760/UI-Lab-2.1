part of '../../work_supply_catalog.dart';

final fencingGeneratedFieldCatalogCategory = _category('Fencing Field Stock', [
  _system('Composite Wood Repair and Decorative Fence Field Stock', [
    _type('Composite Wood and Decorative Boards', _fencingFieldBoards()),
    _type('Fence Repair Caps Brackets and Coatings', _fencingRepairParts()),
  ]),
  _system('Chain Link Gate and Framework Field Stock', [
    _type('Chain Link Fabric Framework and Gates', _fencingChainLinkField()),
    _type('Chain Link Hardware and Tie Detail', _fencingChainLinkHardware()),
  ]),
  _system('Farm Electric Privacy and Temporary Fence Field Stock', [
    _type('Farm Wire Netting and Electric Detail', _fencingFarmElectricField()),
    _type(
      'Privacy Temporary Pool and Gate Control Detail',
      _fencingPrivacyGateField(),
    ),
  ]),
]);

List<WorkSupplyItem> _fencingFieldBoards() {
  return _fencingProducts(
    baseName: 'Fence Field Board',
    unit: 'each',
    variants: [
      for (final color in ['Cedar Tone', 'Gray', 'Brown', 'Black'])
        for (final size in ['5/8 x 5-1/2 x 6 ft', '1 x 6 x 8 ft'])
          for (final style in [
            'Composite Dog Ear Picket',
            'Composite Privacy Board',
            'Horizontal Fence Board',
          ])
            '$color $size $style',
      for (final size in ['2 x 4 x 8 ft', '2 x 4 x 10 ft', '2 x 6 x 8 ft'])
        for (final material in [
          'Cedar Fence Rail',
          'Pressure Treated Fence Rail',
        ])
          '$size $material',
      for (final color in ['Black', 'Bronze', 'White'])
        for (final size in ['4 ft x 6 ft', '4 ft x 8 ft', '5 ft x 6 ft'])
          for (final panel in ['Aluminum Fence Panel', 'Steel Fence Panel'])
            '$color $size $panel',
    ],
    aliases: const [
      'composite picket',
      'horizontal fence board',
      'fence rail',
      'aluminum fence panel',
      'steel fence panel',
    ],
  );
}

List<WorkSupplyItem> _fencingRepairParts() {
  return _fencingProducts(
    baseName: 'Fence Repair Detail',
    unit: 'each',
    variants: [
      for (final size in ['4 x 4', '5 x 5', '6 x 6'])
        for (final part in [
          'Flat Fence Post Cap',
          'Pyramid Fence Post Cap',
          'Solar Fence Post Cap',
          'Post Repair Sleeve',
          'Post Base Anchor',
          'Adjustable Post Base',
          'Post Anchor Spike',
          'Fence Flange',
        ])
          '$size $part',
      for (final item in [
        '2 x 4 Fence Rail Bracket',
        'Mending Plate Fence Repair Bracket',
        'Fence Panel Repair Bracket',
        'Galvanized Fence Tie 100 Pack',
        'Hog Ring 100 Pack',
        'Wire Stretcher',
        'Fence Stain Cedar Tone 1 gal',
        'Fence Stain Clear 1 gal',
      ])
        item,
    ],
    aliases: const [
      'post cap',
      'post repair sleeve',
      'post anchor',
      'rail bracket',
      'fence tie',
      'hog ring',
      'fence stain',
    ],
  );
}

List<WorkSupplyItem> _fencingChainLinkField() {
  return _fencingProducts(
    baseName: 'Chain Link Field Detail',
    unit: 'each',
    variants: [
      for (final gauge in ['9 gauge', '11 gauge', '11.5 gauge'])
        for (final height in ['4 ft', '5 ft', '6 ft', '8 ft'])
          for (final finish in ['Galvanized', 'Black Vinyl Coated'])
            '$height x 50 ft $gauge $finish Chain Link Fabric',
      for (final diameter in ['1-3/8 in', '1-5/8 in', '1-7/8 in', '2-3/8 in'])
        for (final length in ['6 ft', '8 ft', '10 ft', '21 ft'])
          for (final part in [
            'Top Rail',
            'Line Post',
            'Terminal Post',
            'Gate Post',
          ])
            '$diameter x $length Chain Link $part',
      for (final height in ['4 ft', '5 ft', '6 ft'])
        for (final width in ['3 ft', '4 ft', '5 ft', '6 ft'])
          '$height x $width Chain Link Walk Gate',
    ],
    aliases: const [
      'chain link fabric',
      'chainlink fabric',
      'top rail',
      'line post',
      'terminal post',
      'walk gate',
    ],
  );
}

List<WorkSupplyItem> _fencingChainLinkHardware() {
  return _fencingProducts(
    baseName: 'Chain Link Hardware Detail',
    unit: 'pack',
    variants: [
      for (final size in ['1-3/8 in', '1-5/8 in', '1-7/8 in', '2-3/8 in'])
        for (final item in [
          'Tension Band',
          'Brace Band',
          'Rail End',
          'Loop Cap',
          'Dome Post Cap',
          'Tension Bar',
          'Boulevard Clamp',
        ])
          '$size Chain Link $item',
      for (final item in [
        'Chain Link Fence Tie 100 Pack',
        'Chain Link Hog Ring 100 Pack',
        'Chain Link Tension Wire 170 ft',
        'Chain Link Bottom Wire 170 ft',
        'Chain Link Gate Latch',
        'Chain Link Gate Hinge Set',
        'Fork Latch',
      ])
        item,
    ],
    aliases: const [
      'tension band',
      'brace band',
      'rail end',
      'fence tie',
      'hog ring',
      'fork latch',
    ],
  );
}

List<WorkSupplyItem> _fencingFarmElectricField() {
  return _fencingProducts(
    baseName: 'Farm Electric Fence Detail',
    unit: 'each',
    variants: [
      for (final height in ['24 in', '36 in', '48 in', '60 in'])
        for (final length in ['50 ft', '100 ft', '150 ft'])
          for (final wire in [
            'Welded Wire Fence',
            'Poultry Netting',
            'Hardware Cloth',
            'Field Fence',
          ])
            '$height x $length $wire',
      for (final length in ['660 ft', '1320 ft'])
        for (final wire in ['2 Point Barbed Wire', '4 Point Barbed Wire'])
          '$length $wire',
      for (final length in ['656 ft', '1320 ft'])
        for (final item in [
          'Electric Fence Poly Wire',
          'Electric Fence Poly Tape',
        ])
          '$length $item',
      for (final item in [
        'Electric Fence Gate Handle 2 Pack',
        'T-Post Electric Fence Insulator 25 Pack',
        'Wood Post Electric Fence Insulator 25 Pack',
        'Electric Fence Voltage Tester',
        'Fence Ground Rod Clamp',
      ])
        item,
    ],
    aliases: const [
      'welded wire',
      'poultry netting',
      'hardware cloth',
      'field fence',
      'barbed wire',
      'poly wire',
      'electric fence insulator',
    ],
  );
}

List<WorkSupplyItem> _fencingPrivacyGateField() {
  return _fencingProducts(
    baseName: 'Fence Privacy Gate Detail',
    unit: 'each',
    variants: [
      for (final color in ['Black', 'Green', 'Brown', 'Tan'])
        for (final height in ['4 ft', '5 ft', '6 ft', '8 ft'])
          '$height $color Chain Link Privacy Slat Kit',
      for (final color in ['Black', 'Green', 'Brown'])
        for (final size in ['4 ft x 50 ft', '6 ft x 50 ft', '8 ft x 50 ft'])
          '$color $size Fence Privacy Screen',
      for (final width in ['4 ft', '8 ft', '10 ft', '12 ft', '16 ft'])
        for (final gate in ['Galvanized Tube Farm Gate', 'Driveway Gate'])
          '$width $gate',
      for (final item in [
        'Magnetic Pool Gate Latch',
        'Pool Gate Hinge Set',
        'No Dig Pet Fence Panel',
        'Gate Opener Control Board',
        'Gate Opener Photo Eye Sensor',
        'Gate Opener Exit Wand',
        'Gate Opener Solar Panel Kit',
        'Gate Wheel Kit',
      ])
        item,
    ],
    aliases: const [
      'privacy slat',
      'fence screen',
      'farm gate',
      'driveway gate',
      'pool gate latch',
      'gate opener',
      'exit wand',
    ],
  );
}
