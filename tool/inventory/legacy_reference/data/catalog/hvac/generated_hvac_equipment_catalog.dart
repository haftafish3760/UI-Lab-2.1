part of '../../work_supply_catalog.dart';

final hvacGeneratedEquipmentCatalogCategory = _category(
  'Pro HVAC Equipment and Major Install Stock',
  [
    _system('Split System Outdoor Equipment', [
      _type('Condenser and Heat Pump Detail', _hvacEquipmentOutdoorProducts()),
    ]),
    _system('Indoor Coils Furnaces and Air Handlers', [
      _type('Evaporator Coil Detail', _hvacEquipmentCoilProducts()),
      _type('Gas Furnace Detail', _hvacEquipmentFurnaceProducts()),
      _type(
        'Air Handler and Heat Kit Detail',
        _hvacEquipmentAirHandlerProducts(),
      ),
    ]),
    _system('Mini Split and Package Unit Equipment', [
      _type('Mini Split Equipment Detail', _hvacEquipmentMiniSplitProducts()),
      _type('Package Unit and Curb Detail', _hvacEquipmentPackageProducts()),
    ]),
    _system('Equipment Service Panels and Install Accessories', [
      _type(
        'Cabinet Panel and Drain Kit Detail',
        _hvacEquipmentPanelProducts(),
      ),
      _type(
        'Equipment Install Accessory Detail',
        _hvacEquipmentAccessoryProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacEquipmentOutdoorProducts() {
  return _hvacEquipmentProducts(
    baseName: 'HVAC Outdoor Equipment Detail',
    unit: 'each',
    variants: [
      for (final tons in _hvacEquipmentTonnages)
        for (final efficiency in [
          '14.3 SEER2',
          '15.2 SEER2',
          '16 SEER2',
          '17 SEER2',
          '18 SEER2',
        ])
          for (final refrigerant in ['R410A', 'R454B'])
            for (final item in [
              'AC Condenser',
              'Heat Pump Condenser',
              'Side Discharge Heat Pump',
              'Inverter Condenser',
            ])
              '$tons $efficiency $refrigerant $item',
    ],
    aliases: const [
      'ac condenser',
      'condensing unit',
      'heat pump condenser',
      'side discharge heat pump',
      'outdoor unit',
      'inverter condenser',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentCoilProducts() {
  return _hvacEquipmentProducts(
    baseName: 'HVAC Evaporator Coil Detail',
    unit: 'each',
    variants: [
      for (final tons in _hvacEquipmentTonnages)
        for (final width in ['14 in', '17.5 in', '21 in', '24.5 in'])
          for (final orientation in [
            'Upflow Downflow',
            'Horizontal',
            'Multi Position',
          ])
            for (final refrigerant in ['R410A', 'R454B'])
              for (final item in [
                'Cased Evaporator Coil',
                'Uncased Evaporator Coil',
              ])
                '$tons $width $orientation $refrigerant $item',
    ],
    aliases: const [
      'evap coil',
      'evaporator coil',
      'cased coil',
      'uncased coil',
      'a coil',
      'indoor coil',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentFurnaceProducts() {
  return _hvacEquipmentProducts(
    baseName: 'Gas Furnace Equipment Detail',
    unit: 'each',
    variants: [
      for (final btu in [
        '40K BTU',
        '60K BTU',
        '80K BTU',
        '100K BTU',
        '120K BTU',
      ])
        for (final efficiency in ['80 AFUE', '92 AFUE', '96 AFUE', '97 AFUE'])
          for (final orientation in [
            'Upflow',
            'Downflow',
            'Horizontal',
            'Multi Position',
          ])
            for (final fuel in ['Natural Gas', 'LP Convertible'])
              '$btu $efficiency $orientation $fuel Gas Furnace',
    ],
    aliases: const [
      'gas furnace',
      'forced air furnace',
      'upflow furnace',
      'downflow furnace',
      'lp furnace',
      'natural gas furnace',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentAirHandlerProducts() {
  return _hvacEquipmentProducts(
    baseName: 'Air Handler Equipment Detail',
    unit: 'each',
    variants: [
      for (final tons in _hvacEquipmentTonnages)
        for (final voltage in ['120V', '208-230V'])
          for (final heat in [
            'No Heat Kit',
            '5 kW Heat Kit',
            '10 kW Heat Kit',
            '15 kW Heat Kit',
          ])
            for (final item in [
              'Multi Position Air Handler',
              'Wall Mount Air Handler',
              'Modular Blower',
              'Electric Furnace Air Handler',
            ])
              '$tons $voltage $heat $item',
      for (final kw in ['5 kW', '8 kW', '10 kW', '15 kW', '20 kW', '25 kW'])
        for (final voltage in ['208-230V', '240V'])
          for (final breaker in ['Single Breaker', 'Dual Breaker'])
            '$kw $voltage $breaker Electric Heat Kit',
    ],
    aliases: const [
      'air handler',
      'electric furnace',
      'modular blower',
      'heat kit',
      'electric heat kit',
      'fan coil',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentMiniSplitProducts() {
  return _hvacEquipmentProducts(
    baseName: 'Mini Split Equipment Detail',
    unit: 'each',
    variants: [
      for (final capacity in [
        '9K BTU',
        '12K BTU',
        '18K BTU',
        '24K BTU',
        '30K BTU',
        '36K BTU',
      ])
        for (final efficiency in ['18 SEER2', '20 SEER2', '22 SEER2'])
          for (final refrigerant in ['R410A', 'R454B'])
            for (final item in [
              'Mini Split Outdoor Condenser',
              'Mini Split Wall Mount Indoor Head',
              'Mini Split Ceiling Cassette',
              'Mini Split Floor Console',
              'Mini Split Multi Zone Branch Box',
            ])
              '$capacity $efficiency $refrigerant $item',
    ],
    aliases: const [
      'mini split',
      'ductless mini split',
      'wall mount head',
      'indoor head',
      'ceiling cassette',
      'branch box',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentPackageProducts() {
  return _hvacEquipmentProducts(
    baseName: 'Package Unit Equipment Detail',
    unit: 'each',
    variants: [
      for (final tons in _hvacEquipmentTonnages)
        for (final phase in ['Single Phase', 'Three Phase'])
          for (final item in [
            'Gas Electric Package Unit',
            'Heat Pump Package Unit',
            'AC Package Unit with Electric Heat',
          ])
            '$tons $phase $item',
      for (final size in ['2 Ton', '2.5 Ton', '3 Ton', '4 Ton', '5 Ton'])
        for (final item in [
          'Package Unit Roof Curb',
          'Horizontal Adapter Curb',
          'Economizer Kit',
          'Fresh Air Damper Kit',
          'Hail Guard Kit',
        ])
          '$size $item',
    ],
    aliases: const [
      'package unit',
      'rtu',
      'rooftop unit',
      'roof curb',
      'economizer',
      'fresh air damper',
      'hail guard',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentPanelProducts() {
  return _hvacEquipmentProducts(
    baseName: 'HVAC Cabinet Service Detail',
    unit: 'each',
    variants: [
      for (final tons in _hvacEquipmentTonnages)
        for (final item in [
          'Condenser Fan Guard',
          'Condenser Top Panel',
          'Condenser Louvered Panel',
          'Air Handler Door Panel',
          'Furnace Blower Door Panel',
          'Evaporator Coil Drain Pan',
          'Coil Access Panel',
          'Filter Door Assembly',
        ])
          '$tons $item',
      for (final width in ['14 in', '17.5 in', '21 in', '24.5 in'])
        for (final item in [
          'Furnace Coil Adapter Plate',
          'Return Air Drop Adapter',
          'Filter Cabinet Door',
        ])
          '$width $item',
    ],
    aliases: const [
      'condenser fan guard',
      'cabinet panel',
      'access panel',
      'blower door',
      'coil drain pan',
      'filter door',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentAccessoryProducts() {
  return _hvacEquipmentProducts(
    baseName: 'HVAC Equipment Install Accessory Detail',
    unit: 'each',
    variants: [
      for (final tons in _hvacEquipmentTonnages)
        for (final item in [
          'Condenser Riser Kit',
          'Unit Tie Down Kit',
          'Vibration Isolation Kit',
          'Compressor Sound Blanket',
          'Coil Guard Kit',
          'Low Ambient Control Kit',
          'Crankcase Heater Kit',
        ])
          '$tons $item',
      for (final size in [
        '18 x 38',
        '24 x 24',
        '24 x 36',
        '30 x 30',
        '32 x 32',
        '36 x 36',
      ])
        for (final item in [
          'Equipment Pad',
          'Condenser Pad',
          'Snow Stand Base',
        ])
          '$size $item',
    ],
    aliases: const [
      'riser kit',
      'tie down kit',
      'vibration kit',
      'sound blanket',
      'low ambient kit',
      'crankcase heater',
      'condenser pad',
    ],
  );
}

List<WorkSupplyItem> _hvacEquipmentProducts({
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

const _hvacEquipmentTonnages = [
  '1.5 Ton',
  '2 Ton',
  '2.5 Ton',
  '3 Ton',
  '3.5 Ton',
  '4 Ton',
  '5 Ton',
];
