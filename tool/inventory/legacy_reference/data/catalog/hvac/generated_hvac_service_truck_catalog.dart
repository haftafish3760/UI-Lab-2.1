part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckCatalogCategory = _category(
  'HVAC Service Truck Stock',
  [
    _system('High Turnover Electrical Controls', [
      _type(
        'Service Truck Capacitors',
        _hvacTruckProducts(
          baseName: 'HVAC Service Capacitor',
          unit: 'each',
          variants: [
            for (final brand in _hvacTruckGrades)
              for (final value in _hvacTruckDualCapacitors)
                '$brand $value 440V Dual Run Capacitor',
            for (final brand in _hvacTruckGrades)
              for (final value in _hvacTruckSingleCapacitors)
                '$brand $value 440V Single Run Capacitor',
            for (final value in ['88-108 MFD', '108-130 MFD', '124-149 MFD'])
              '$value Start Capacitor',
            for (final rating in ['1/12-1/2 HP', '1/2-10 HP'])
              '$rating Potential Relay Start Kit',
          ],
          aliases: const [
            'dual run capacitor',
            'run cap',
            'single run capacitor',
            'start capacitor',
            'hard start kit',
            'potential relay',
            'mfd capacitor',
          ],
        ),
      ),
      _type(
        'Contactors Relays Transformers and Fuses',
        _hvacTruckProducts(
          baseName: 'HVAC Electrical Control',
          unit: 'each',
          variants: [
            for (final pole in ['1 Pole', '2 Pole'])
              for (final amp in [
                '25 Amp',
                '30 Amp',
                '40 Amp',
                '50 Amp',
                '60 Amp',
              ])
                '$pole $amp 24V Coil Contactor',
            for (final coil in ['24V', '120V', '208/230V'])
              for (final item in [
                'Fan Relay',
                'Isolation Relay',
                'Time Delay Relay',
                'Sequencer Relay',
              ])
                '$coil $item',
            for (final va in ['20VA', '40VA', '50VA', '75VA'])
              '$va 120/208/240V Primary 24V Transformer',
            for (final amp in ['3 Amp', '5 Amp'])
              for (final count in ['5 Pack', '10 Pack'])
                '$amp Low Voltage Blade Fuse $count',
            for (final amp in [
              '30 Amp',
              '35 Amp',
              '40 Amp',
              '45 Amp',
              '50 Amp',
              '60 Amp',
            ])
              '$amp Time Delay Cartridge Fuse Pair',
          ],
          aliases: const [
            'contactor',
            'compressor contactor',
            'fan relay',
            'time delay relay',
            'sequencer',
            '24v transformer',
            'blade fuse',
            'cartridge fuse',
          ],
        ),
      ),
    ]),
    _system('Furnace Heat and Combustion Service Parts', [
      _type(
        'Ignition Sensors Switches and Tubing',
        _hvacTruckProducts(
          baseName: 'Furnace Service Part',
          unit: 'each',
          variants: [
            for (final item in [
              'Universal Hot Surface Ignitor',
              'Silicon Nitride Hot Surface Ignitor',
              'Round Silicon Carbide Ignitor',
              'Flame Sensor Rod',
              'Universal Flame Sensor',
              'Spark Ignition Cable',
              'Integrated Furnace Control Fuse Pack',
            ])
              item,
            for (final wc in [
              '.20 WC',
              '.30 WC',
              '.40 WC',
              '.50 WC',
              '.60 WC',
              '.70 WC',
            ])
              for (final port in ['Single Port', 'Dual Port'])
                '$port $wc Pressure Switch',
            for (final item in [
              'Pressure Switch Tubing Kit',
              'Inducer Drain Hose',
              'Condensate Trap Furnace Kit',
              'Rollout Switch Manual Reset',
              'High Limit Switch',
              'Fan Limit Switch',
              'Furnace Door Switch',
              'Draft Inducer Gasket',
            ])
              item,
          ],
          aliases: const [
            'hot surface ignitor',
            'hsi',
            'flame sensor',
            'pressure switch',
            'pressure switch tubing',
            'rollout switch',
            'limit switch',
            'furnace door switch',
            'inducer gasket',
          ],
        ),
      ),
      _type(
        'Gas Valve Burner and Pilot Service',
        _hvacTruckProducts(
          baseName: 'Gas Heat Service Part',
          unit: 'each',
          variants: [
            for (final pipe in ['1/2 in', '3/4 in'])
              '$pipe Furnace Gas Shutoff Valve',
            for (final item in [
              'Universal Furnace Gas Valve',
              'Pilot Assembly',
              'Thermocouple 24 in',
              'Thermopile Generator',
              'Burner Orifice Kit',
              'Manifold Pressure Tap Plug',
              'Combustion Analyzer Filter Pack',
              'Gas Leak Detector Solution',
            ])
              item,
          ],
          aliases: const [
            'furnace gas valve',
            'gas valve',
            'pilot assembly',
            'thermocouple',
            'thermopile',
            'burner orifice',
            'gas leak detector',
          ],
        ),
      ),
    ]),
    _system('Motors Blower Wheels Belts and Fan Parts', [
      _type(
        'Universal Motors and Fan Parts',
        _hvacTruckProducts(
          baseName: 'HVAC Motor Service Part',
          unit: 'each',
          variants: [
            for (final hp in [
              '1/6 HP',
              '1/5 HP',
              '1/4 HP',
              '1/3 HP',
              '1/2 HP',
              '3/4 HP',
            ])
              for (final rpm in ['825 RPM', '1075 RPM', '1625 RPM'])
                '$hp $rpm 208/230V Condenser Fan Motor',
            for (final hp in ['1/4 HP', '1/3 HP', '1/2 HP', '3/4 HP', '1 HP'])
              '$hp 1075 RPM Direct Drive Blower Motor',
            for (final size in ['9 in', '10 in', '11 in', '12 in'])
              for (final pitch in ['22 Degree', '28 Degree'])
                '$size $pitch Condenser Fan Blade',
            for (final item in [
              'Blower Wheel Puller',
              'Motor Mount Belly Band',
              'Condenser Motor Rain Shield',
              'Fan Blade Hub Adapter',
              'Motor Rotation Plug',
            ])
              item,
          ],
          aliases: const [
            'condenser fan motor',
            'blower motor',
            'fan blade',
            'blower wheel',
            'belly band',
            'motor mount',
            'hub adapter',
          ],
        ),
      ),
      _type(
        'Belts Bearings and Blower Hardware',
        _hvacTruckProducts(
          baseName: 'Blower Drive Service Part',
          unit: 'each',
          variants: [
            for (final belt in [
              'A24',
              'A25',
              'A26',
              'A27',
              'A28',
              'A29',
              'A30',
              'A31',
              'A32',
              'A33',
              'A34',
              'A35',
            ])
              '$belt V Belt',
            for (final bore in ['1/2 in', '5/8 in', '3/4 in', '1 in'])
              '$bore Pillow Block Bearing',
            for (final item in [
              'Blower Wheel Set Screw Pack',
              'Motor Pulley Adjustable Sheave',
              'Blower Door Screw Pack',
              'Rubber Isolation Grommet Pack',
            ])
              item,
          ],
          aliases: const [
            'v belt',
            'blower belt',
            'pillow block bearing',
            'motor pulley',
            'adjustable sheave',
            'isolation grommet',
          ],
        ),
      ),
    ]),
    _system('Refrigerant Service Truck Consumables', [
      _type(
        'Cores Caps Fittings and Filter Driers',
        _hvacTruckProducts(
          baseName: 'Refrigerant Service Part',
          unit: 'each',
          variants: [
            for (final count in ['5 Pack', '10 Pack', '25 Pack'])
              for (final item in [
                'Schrader Valve Core',
                'Brass Service Port Cap',
                'Locking Refrigerant Cap',
                '1/4 in Access Tee',
              ])
                '$count $item',
            for (final size in [
              '1/4 in',
              '3/8 in',
              '1/2 in',
              '5/8 in',
              '3/4 in',
              '7/8 in',
            ])
              for (final item in [
                'Copper Refrigerant Coupling',
                'Copper Refrigerant Elbow',
                'Copper Refrigerant Tee',
                'Liquid Line Filter Drier',
                'Suction Line Filter Drier',
              ])
                '$size $item',
            for (final item in [
              'Core Removal Tool',
              'Valve Core Depressor',
              'Low Loss Hose Gasket Pack',
              'Charging Hose Seal Pack',
              'Refrigerant Leak Detector Dye',
            ])
              item,
          ],
          aliases: const [
            'schrader core',
            'valve core',
            'service port cap',
            'locking cap',
            'filter drier',
            'core remover',
            'low loss gasket',
            'leak dye',
          ],
        ),
      ),
      _type(
        'Brazing Nitrogen and Leak Repair Stock',
        _hvacTruckProducts(
          baseName: 'Brazing Service Supply',
          unit: 'each',
          variants: [
            for (final count in ['1 lb', '5 lb'])
              for (final item in [
                '15 Percent Silver Brazing Rod',
                '0 Percent Silver Brazing Rod',
                'Phos Copper Brazing Rod',
              ])
                '$count $item',
            for (final item in [
              'Brazing Heat Shield Pad',
              'Wet Rag Heat Block Compound',
              'Nitrogen Purge Regulator',
              'Nitrogen Flow Meter',
              '1 Quart Bubble Leak Detector',
              'Nylog Blue Gasket Sealant',
              '1 Quart Vacuum Pump Oil',
            ])
              item,
          ],
          aliases: const [
            'brazing rod',
            'silver solder',
            'heat shield',
            'nitrogen regulator',
            'bubble leak detector',
            'nylog',
            'vacuum pump oil',
          ],
        ),
      ),
    ]),
    _system('Condensate Drain and IAQ Service Stock', [
      _type(
        'Condensate Pumps Switches Tubing and Treatment',
        _hvacTruckProducts(
          baseName: 'Condensate Service Stock',
          unit: 'each',
          variants: [
            for (final voltage in ['115V', '230V'])
              for (final item in [
                'Condensate Pump',
                'Condensate Pump With Safety Switch',
                'Mini Split Condensate Pump',
              ])
                '$voltage $item',
            for (final length in ['20 ft', '50 ft', '100 ft'])
              for (final size in ['3/8 in', '1/2 in'])
                '$size x $length Clear Vinyl Condensate Tubing',
            for (final item in [
              'Wet Switch Flood Detector',
              'Float Switch Tee',
              'Inline Condensate Float Switch',
              'Secondary Drain Pan Float Switch',
              'Primary Drain Line Safety Switch',
              'Condensate Overflow Switch',
              'Condensate Drain Pan Tablets',
              'Condensate Drain Pan Strip Pack',
              'Condensate Drain Line Cleaner',
              'Condensate Drain Gun',
              'Condensate Drain Gun Cartridge Pack',
              'Condensate Drain Brush Kit',
              'Condensate Trap Brush',
              'PVC Condensate Trap',
              'PVC Condensate Cleanout Tee',
              'Condensate Pump Check Valve',
              'Condensate Pump Replacement Tubing Kit',
              'Condensate Neutralizer Cartridge',
            ])
              item,
          ],
          aliases: const [
            'condensate pump',
            'mini split pump',
            'vinyl tubing',
            'wet switch',
            'float switch',
            'pan tablets',
            'pan strip',
            'drain line cleaner',
            'drain gun',
            'drain cartridge',
            'drain brush',
            'trap brush',
            'neutralizer cartridge',
            'overflow switch',
            'safety switch',
          ],
        ),
      ),
      _type(
        'IAQ UV Humidifier and Filter Service',
        _hvacTruckProducts(
          baseName: 'IAQ Service Stock',
          unit: 'each',
          variants: [
            for (final watt in ['16W', '24W', '36W'])
              '$watt UV Lamp Replacement',
            for (final size in [
              '10 x 20 x 1',
              '14 x 20 x 1',
              '16 x 20 x 1',
              '16 x 25 x 1',
              '20 x 20 x 1',
              '20 x 25 x 1',
            ])
              for (final merv in ['MERV 8', 'MERV 11', 'MERV 13'])
                '$size $merv Pleated Filter 12 Pack',
            for (final item in [
              for (final size in ['10', '12', '35'])
                'Humidifier Pad Model $size',
              for (final size in ['10', '12', '35'])
                'Humidifier Water Panel Model $size',
              'Humidifier Solenoid Valve',
              'Humidifier Saddle Valve Kit',
              'Humidifier Feed Tube Kit',
              'Humidifier Drain Tube Kit',
              'Humidifier Bypass Damper',
              'Humidifier Pad Frame',
              'Humidifier Orifice Strainer',
              'Air Scrubber Bulb',
              'Air Scrubber Cell',
              'Air Scrubber Ballast',
              'Electronic Air Cleaner Cell',
              'Electronic Air Cleaner Prefilter',
              'Electronic Air Cleaner Ionizing Wire',
              'Media Cabinet Door Latch',
              'Media Filter Cabinet Gasket',
              'Filter Rack Door Latch',
            ])
              item,
          ],
          aliases: const [
            'uv lamp',
            'uv bulb',
            'humidifier pad',
            'water panel',
            'humidifier solenoid',
            'humidifier feed tube',
            'humidifier drain tube',
            'humidifier saddle valve',
            'humidifier bypass damper',
            'pleated filter',
            'merv filter',
            'media cabinet',
            'air cleaner',
            'air scrubber',
            'ionizing wire',
          ],
        ),
      ),
    ]),
  ],
);

const _hvacTruckGrades = ['Standard', 'Heavy Duty', 'Turbo'];

const _hvacTruckDualCapacitors = [
  '25/5 MFD',
  '30/5 MFD',
  '35/5 MFD',
  '40/5 MFD',
  '45/5 MFD',
  '50/5 MFD',
  '55/5 MFD',
  '60/5 MFD',
  '70/5 MFD',
  '80/5 MFD',
];

const _hvacTruckSingleCapacitors = [
  '5 MFD',
  '7.5 MFD',
  '10 MFD',
  '12.5 MFD',
  '15 MFD',
  '20 MFD',
  '25 MFD',
  '30 MFD',
  '35 MFD',
  '40 MFD',
  '45 MFD',
  '50 MFD',
];

List<WorkSupplyItem> _hvacTruckProducts({
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
        aliases: [
          ...aliases,
          variant,
          variant.toLowerCase(),
          '$variant $baseName',
        ],
      ),
  ];
}
