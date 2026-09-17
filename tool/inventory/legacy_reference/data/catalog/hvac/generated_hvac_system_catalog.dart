part of '../../work_supply_catalog.dart';

final hvacGeneratedSystemCatalogCategory = _category(
  'Pro HVAC System Material Stock',
  [
    _system('Rectangular Duct Plenum and Trunk Stock', [
      _type('Rectangular Duct System Detail', _hvacSystemRectDuctProducts()),
      _type('Transition Plenum and Box Detail', _hvacSystemPlenumProducts()),
    ]),
    _system('Vent Exhaust and Combustion Air Stock', [
      _type('B Vent Gas Vent Detail', _hvacSystemGasVentProducts()),
      _type('Dryer Bath and Exhaust Detail', _hvacSystemExhaustProducts()),
    ]),
    _system('Refrigerant Fittings Brazing and Protection', [
      _type(
        'Refrigerant Copper Fitting Detail',
        _hvacSystemRefrigerantFittings(),
      ),
      _type(
        'Brazing Drier and Line Protection Detail',
        _hvacSystemBrazingProducts(),
      ),
    ]),
    _system('Registers Diffusers Dampers and Zoning', [
      _type(
        'Diffuser Register and Grille Detail',
        _hvacSystemDiffuserProducts(),
      ),
      _type('Zone Control Damper Detail', _hvacSystemZoneProducts()),
    ]),
    _system('Outdoor Unit Mounting and Install Stock', [
      _type('Pad Bracket Stand and Riser Detail', _hvacSystemMountProducts()),
      _type(
        'Mini Split Cover and Sleeve Detail',
        _hvacSystemMiniSplitCoverProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacSystemRectDuctProducts() {
  return _hvacSystemProducts(
    baseName: 'Rectangular Duct System Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '8 x 8',
        '8 x 10',
        '10 x 10',
        '10 x 12',
        '12 x 12',
        '12 x 14',
        '14 x 14',
        '14 x 16',
        '16 x 16',
        '16 x 20',
        '18 x 18',
        '20 x 20',
        '20 x 25',
        '24 x 24',
      ])
        for (final length in ['24 in', '36 in', '48 in', '60 in'])
          for (final item in [
            'Rectangular Duct Section',
            'Duct Trunk Section',
            'Return Duct Section',
            'Supply Duct Section',
            'Duct End Cap',
            'Duct Access Door',
          ])
            '$size x $length $item',
    ],
    aliases: const [
      'rectangular duct',
      'duct trunk',
      'return duct',
      'supply duct',
      'duct section',
      'duct access door',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemPlenumProducts() {
  return _hvacSystemProducts(
    baseName: 'HVAC Plenum Box Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '16 x 16',
        '16 x 20',
        '18 x 18',
        '20 x 20',
        '20 x 25',
        '24 x 24',
      ])
        for (final height in ['24 in', '30 in', '36 in', '48 in'])
          for (final item in [
            'Supply Plenum',
            'Return Plenum',
            'Return Air Box',
            'Filter Box',
          ])
            '$size x $height $item',
      for (final size in ['16 x 16', '20 x 20', '20 x 25', '24 x 24'])
        for (final round in ['10 in', '12 in', '14 in', '16 in', '18 in'])
          for (final item in ['Duct Transition', 'Square to Round Transition'])
            '$size to $round $item',
    ],
    aliases: const [
      'supply plenum',
      'return plenum',
      'return air box',
      'filter box',
      'duct transition',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemGasVentProducts() {
  return _hvacSystemProducts(
    baseName: 'Gas Vent Detail',
    unit: 'each',
    variants: [
      for (final size in ['3 in', '4 in', '5 in', '6 in', '7 in', '8 in'])
        for (final item in [
          'B Vent Pipe',
          'B Vent Adjustable Elbow',
          'B Vent 90 Elbow',
          'B Vent Tee',
          'B Vent Cap',
          'B Vent Storm Collar',
          'B Vent Wall Thimble',
          'Draft Hood Connector',
          'Single Wall Flue Pipe',
          'Gas Vent Support Strap',
        ])
          '$size $item',
    ],
    aliases: const [
      'b vent',
      'gas vent',
      'flue pipe',
      'draft hood',
      'storm collar',
      'wall thimble',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemExhaustProducts() {
  return _hvacSystemProducts(
    baseName: 'HVAC Exhaust Vent Detail',
    unit: 'each',
    variants: [
      for (final size in ['3 in', '4 in', '5 in', '6 in'])
        for (final item in [
          'Dryer Vent Hood',
          'Dryer Vent Elbow',
          'Semi Rigid Dryer Duct',
          'Dryer Vent Clamp',
          'Bath Fan Wall Cap',
          'Bath Fan Roof Cap',
          'Exhaust Duct',
          'Exhaust Backdraft Damper',
          'Soffit Exhaust Vent',
          'Exhaust Wall Sleeve',
        ])
          '$size $item',
    ],
    aliases: const [
      'dryer vent',
      'bath fan cap',
      'exhaust duct',
      'vent hood',
      'backdraft damper',
      'wall sleeve',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemRefrigerantFittings() {
  return _hvacSystemProducts(
    baseName: 'Refrigerant Copper Fitting Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '1/4 in',
        '3/8 in',
        '1/2 in',
        '5/8 in',
        '3/4 in',
        '7/8 in',
        '1-1/8 in',
      ])
        for (final item in [
          'Refrigeration Copper Coupling',
          'Refrigeration Copper 90 Elbow',
          'Refrigeration Copper 45 Elbow',
          'Copper Line Set Sleeve',
          'Suction Line Insulation',
          'Liquid Line Filter Drier',
          'Suction Line Filter Drier',
          'Refrigerant Service Tee',
          'Flare Nut',
          'Access Fitting',
        ])
          '$size $item',
    ],
    aliases: const [
      'refrigeration fitting',
      'copper coupling',
      'filter drier',
      'line insulation',
      'flare nut',
      'access fitting',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemBrazingProducts() {
  return _hvacSystemProducts(
    baseName: 'HVAC Brazing Service Detail',
    unit: 'each',
    variants: [
      for (final percent in ['0%', '5%', '15%', '45%'])
        for (final item in ['Silver Brazing Rod', 'Phos Copper Brazing Rod'])
          '$percent $item',
      for (final size in ['1/4 in', '3/8 in', '1/2 in', '5/8 in', '7/8 in'])
        for (final item in [
          'Liquid Line Filter Drier',
          'Suction Line Filter Drier',
        ])
          '$size $item',
      'Nitrogen Purge Regulator',
      'Nitrogen Flow Meter',
      'Brazing Heat Shield Pad',
      'Wet Rag Heat Block',
      '1 Quart Refrigerant Leak Detector',
      'Acid Test Kit',
      'Service Valve Cap Pack',
      'Schrader Core Pack',
      'Refrigerant Hose Gasket Pack',
    ],
    aliases: const [
      'brazing rod',
      'silver solder',
      'filter drier',
      'nitrogen purge',
      'heat shield',
      'leak bubbles',
      'schrader core',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemDiffuserProducts() {
  return _hvacSystemProducts(
    baseName: 'HVAC Diffuser Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '4 in',
        '5 in',
        '6 in',
        '7 in',
        '8 in',
        '10 in',
        '12 in',
        '14 in',
      ])
        for (final item in [
          'Round Ceiling Diffuser',
          'Round Supply Grille',
          'Round Return Grille',
          'Round Butterfly Damper',
        ])
          '$size $item',
      for (final size in [
        '12 x 12',
        '14 x 14',
        '16 x 16',
        '20 x 20',
        '24 x 24',
      ])
        for (final finish in ['White', 'Black', 'Brown'])
          for (final item in [
            'Ceiling Diffuser',
            'Lay In Diffuser',
            'Eggcrate Return Grille',
            'Louvered Return Grille',
          ])
            '$size $finish $item',
    ],
    aliases: const [
      'ceiling diffuser',
      'round diffuser',
      'supply grille',
      'return grille',
      'eggcrate grille',
      'butterfly damper',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemZoneProducts() {
  return _hvacSystemProducts(
    baseName: 'HVAC Zoning Detail',
    unit: 'each',
    variants: [
      for (final size in ['6 in', '8 in', '10 in', '12 in', '14 in', '16 in'])
        for (final power in ['24V', '120V'])
          for (final item in [
            'Round Zone Damper',
            'Bypass Damper',
            'Motorized Round Damper',
          ])
            '$size $power $item',
      for (final zones in ['2 Zone', '3 Zone', '4 Zone', '6 Zone'])
        '$zones Zone Control Panel',
      'Duct Temperature Sensor',
      'Discharge Air Sensor',
      'Zone Damper Motor',
      'Bypass Damper Barometric Weight',
    ],
    aliases: const [
      'zone damper',
      'bypass damper',
      'zone panel',
      'damper motor',
      'duct sensor',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemMountProducts() {
  return _hvacSystemProducts(
    baseName: 'Outdoor Unit Mount Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '18 x 38',
        '24 x 24',
        '24 x 36',
        '30 x 30',
        '32 x 32',
        '36 x 36',
        '40 x 40',
      ])
        for (final item in [
          'Equipment Pad',
          'Condenser Pad',
          'Hurricane Pad',
          'Plastic Equipment Pad',
        ])
          '$size $item',
      for (final capacity in [
        '9000 BTU',
        '12000 BTU',
        '18000 BTU',
        '24000 BTU',
        '36000 BTU',
      ])
        for (final item in ['Wall Bracket', 'Ground Stand', 'Snow Stand'])
          '$capacity $item',
      'Condenser Tie Down Strap Kit',
      'Hurricane Pad Strap Kit',
      'Rubber Equipment Riser 4 Pack',
      'Anti Vibration Pad 4 Pack',
    ],
    aliases: const [
      'equipment pad',
      'condenser pad',
      'wall bracket',
      'ground stand',
      'tie down kit',
      'vibration pad',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemMiniSplitCoverProducts() {
  return _hvacSystemProducts(
    baseName: 'Mini Split Cover Detail',
    unit: 'each',
    variants: [
      for (final size in ['3 in', '4 in', '5 in'])
        for (final color in ['White', 'Ivory', 'Brown', 'Black'])
          for (final part in [
            'Line Set Cover Straight',
            'Line Set Cover Coupling',
            'Line Set Cover Elbow',
            'Line Set Cover Wall Cap',
            'Line Set Cover End Cap',
            'Line Set Cover Flexible Joint',
          ])
            '$size $color $part',
      for (final length in ['15 ft', '25 ft', '35 ft', '50 ft'])
        for (final cable in ['14/4', '16/4'])
          '$cable x $length Mini Split Communication Cable',
      'Mini Split Wall Sleeve',
      'Mini Split Drain Hose 20 ft',
      'Mini Split Condensate Hose Adapter',
    ],
    aliases: const [
      'line set cover',
      'line hide',
      'mini split cover',
      'communication cable',
      'wall sleeve',
      'drain hose',
    ],
  );
}

List<WorkSupplyItem> _hvacSystemProducts({
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
