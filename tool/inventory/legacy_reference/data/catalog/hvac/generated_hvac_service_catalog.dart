part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceCatalogCategory = _category(
  'Expanded HVAC Service Stock',
  [
    _system('Expanded Air Filters', [
      _type(
        'MERV Pleated Filters',
        _hvacProducts(
          baseName: 'Pleated Furnace Filter',
          unit: 'each',
          variants: [
            for (final rating in ['MERV 8', 'MERV 11', 'MERV 13'])
              for (final size in _hvacFilterDeepSizes) '$size $rating',
          ],
          aliases: const ['furnace filter', 'return filter', 'ac filter'],
        ),
      ),
      _type(
        'Media Cabinet Filters',
        _hvacProducts(
          baseName: 'Media Cabinet Furnace Filter',
          unit: 'each',
          variants: [
            for (final size in _hvacMediaFilterSizes)
              for (final depth in ['4 in', '5 in']) '$size x $depth',
          ],
          aliases: const [
            'media filter',
            'air cleaner filter',
            'furnace filter',
            'return filter',
          ],
        ),
      ),
      _type(
        'Filter Racks and Return Filter Grilles',
        _hvacProducts(
          baseName: 'Filter Rack or Return Grille',
          unit: 'each',
          variants: [
            for (final size in [
              '14 x 20',
              '14 x 25',
              '16 x 20',
              '16 x 25',
              '20 x 20',
              '20 x 25',
              '24 x 24',
            ])
              for (final part in [
                'Filter Rack',
                'Return Filter Grille',
                'Return Air Grille',
              ])
                '$size $part',
          ],
          aliases: const [
            'filter rack',
            'return filter grille',
            'return grille',
            'air filter grille',
          ],
        ),
      ),
    ]),
    _system('Expanded Controls and Electrical', [
      _type(
        'Dual Run Capacitors',
        _hvacProducts(
          baseName: 'Dual Run Capacitor',
          unit: 'each',
          variants: [
            for (final mfd in _hvacDualCapacitorValues)
              for (final volts in ['370V', '440V']) '$mfd $volts',
          ],
          aliases: const ['run cap', 'dual capacitor', 'mfd capacitor'],
        ),
      ),
      _type(
        'Single Run Capacitors',
        _hvacProducts(
          baseName: 'Single Run Capacitor',
          unit: 'each',
          variants: [
            for (final mfd in _hvacSingleCapacitorValues)
              for (final volts in ['370V', '440V']) '$mfd $volts',
          ],
          aliases: const ['run cap', 'motor capacitor'],
        ),
      ),
      _type(
        'Contactors and Relays',
        _hvacProducts(
          baseName: 'HVAC Contactor',
          unit: 'each',
          variants: [
            for (final pole in ['1 pole', '2 pole', '3 pole'])
              for (final amp in ['25 Amp', '30 Amp', '40 Amp', '50 Amp'])
                '$pole $amp 24V coil',
          ],
          aliases: const ['compressor contactor', 'definite purpose contactor'],
        ),
      ),
      _type(
        'Transformers and Fuses',
        _hvacProducts(
          baseName: 'HVAC Control Part',
          unit: 'each',
          variants: const [
            '40VA 24V Transformer',
            '50VA 24V Transformer',
            '75VA 24V Transformer',
            '3 Amp Blade Fuse',
            '5 Amp Blade Fuse',
            'Low Voltage Fuse Holder',
            '24V Time Delay Relay',
            'Fan Relay',
            'Defrost Control Board',
            'Universal Furnace Control Board',
            'Compressor Hard Start Kit',
            'Compressor Saver Kit',
            'Single Phase Surge Protector',
            'HVAC Disconnect Pullout',
            'Equipment Whip 1/2 in',
            'Equipment Whip 3/4 in',
          ],
          aliases: const ['low voltage control', 'control transformer'],
        ),
      ),
      _type(
        'Thermostat Wire Rolls',
        _hvacProducts(
          baseName: 'Thermostat Wire',
          unit: 'roll',
          variants: [
            for (final conductor in ['18/2', '18/3', '18/5', '18/7', '18/8'])
              for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
                '$conductor x $length',
          ],
          aliases: const ['stat wire', 'low voltage wire'],
        ),
      ),
      _type(
        'Duct Boots and Takeoffs',
        _hvacProducts(
          baseName: 'Duct Boot or Takeoff',
          unit: 'each',
          variants: [
            for (final size in [
              '4 x 10',
              '4 x 12',
              '6 x 10',
              '6 x 12',
              '8 x 8',
              '10 x 10',
              '12 x 12',
            ])
              for (final throat in ['6 in', '7 in', '8 in'])
                '$size x $throat Register Boot',
            for (final size in _hvacRoundDuctSizes)
              for (final part in [
                'Spin-In Takeoff',
                'Start Collar with Damper',
                'End Cap',
                'Round Reducer',
                'Round Wye',
              ])
                '$size $part',
          ],
          aliases: const [
            'register boot',
            'duct boot',
            'spin in',
            'start collar',
            'takeoff',
          ],
        ),
      ),
      _type(
        'Duct Pipe and Venting',
        _hvacProducts(
          baseName: 'Duct Pipe or Vent Part',
          unit: 'each',
          variants: [
            for (final size in ['3 in', '4 in', '5 in', '6 in', '7 in', '8 in'])
              for (final part in [
                'Galvanized Pipe',
                'Adjustable Elbow',
                'Wall Cap',
                'Roof Cap',
                'Backdraft Damper',
              ])
                '$size $part',
            for (final size in ['3 in', '4 in', '5 in', '6 in'])
              for (final part in [
                'B Vent Pipe',
                'B Vent Elbow',
                'B Vent Cap',
                'Draft Hood Connector',
              ])
                '$size $part',
          ],
          aliases: const [
            'galvanized duct',
            'b vent',
            'flue pipe',
            'wall cap',
            'roof cap',
          ],
        ),
      ),
    ]),
    _system('Expanded Duct and Air Distribution', [
      _type(
        'Insulated Flex Duct',
        _hvacProducts(
          baseName: 'Insulated Flex Duct',
          unit: 'box',
          variants: [
            for (final size in _hvacRoundDuctSizes)
              for (final rating in ['R-6', 'R-8']) '$size $rating',
          ],
          aliases: const ['flex duct', 'flexible duct'],
        ),
      ),
      _type(
        'Sheet Metal Fittings',
        _hvacProducts(
          baseName: 'Sheet Metal Duct Fitting',
          unit: 'each',
          variants: [
            for (final size in _hvacRoundDuctSizes)
              for (final fitting in [
                '90 Elbow',
                'Adjustable Elbow',
                'Start Collar',
                'Takeoff Collar',
                'Backdraft Damper',
                'Manual Damper',
              ])
                '$size $fitting',
          ],
          aliases: const ['duct fitting', 'sheet metal fitting'],
        ),
      ),
      _type(
        'Boots Registers and Grilles',
        _hvacProducts(
          baseName: 'Air Distribution Part',
          unit: 'each',
          variants: [
            for (final size in _hvacRegisterSizes)
              for (final item in [
                'Floor Register',
                'Ceiling Register',
                'Return Grille',
                'Wall Stack Boot',
              ])
                '$size $item',
          ],
          aliases: const ['register', 'grille', 'vent cover', 'boot'],
        ),
      ),
      _type(
        'Condensate Pans Tubing and Treatment',
        _hvacProducts(
          baseName: 'Condensate Service Material',
          unit: 'each',
          variants: [
            for (final size in [
              '24 x 24',
              '24 x 30',
              '30 x 30',
              '30 x 36',
              '36 x 48',
            ])
              '$size Secondary Drain Pan',
            for (final size in ['3/8 in', '1/2 in', '5/8 in'])
              '$size Clear Vinyl Tubing 20 ft',
            'Drain Pan Treatment Tablets',
            'Drain Line Cleaner 1 qt',
            'Condensate Pan Safety Switch',
            'Condensate Trap Brush',
            'Condensate Line Brush',
            'Mini Condensate Pump Tubing Kit',
          ],
          aliases: const [
            'drain pan',
            'secondary pan',
            'vinyl tubing',
            'pan tablets',
            'condensate treatment',
          ],
        ),
      ),
    ]),
    _system('Expanded Condensate', [
      _type(
        'Condensate Pipe and Fittings',
        _hvacProducts(
          baseName: 'Condensate PVC Part',
          unit: 'each',
          variants: [
            for (final size in ['3/4 in', '1 in'])
              for (final part in [
                '10 ft Pipe',
                '90 Elbow',
                '45 Elbow',
                'Tee',
                'Coupling',
                'Union',
                'Trap',
                'Cleanout Tee',
              ])
                '$size $part',
          ],
          aliases: const ['condensate line', 'drain line'],
        ),
      ),
      _type(
        'Condensate Pumps and Safety Switches',
        _hvacProducts(
          baseName: 'Condensate Control',
          unit: 'each',
          variants: const [
            '115V Condensate Pump',
            '230V Condensate Pump',
            'Mini Split Condensate Pump',
            'Inline Float Switch',
            'Secondary Pan Float Switch',
            'Wet Switch',
            'Condensate Drain Trap Kit',
            'Condensate Drain Tablets',
            'Condensate Neutralizer Kit',
            'Condensate Overflow Alarm',
            'Clear Vinyl Drain Tubing 3/8 in',
            'Clear Vinyl Drain Tubing 1/2 in',
            'PVC Condensate Vent Tee',
            'EZ Trap Condensate Trap',
          ],
          aliases: const ['cond pump', 'float switch', 'pan switch'],
        ),
      ),
      _type(
        'Line Set Covers Pads and Brackets',
        _hvacProducts(
          baseName: 'Outdoor Unit Install Material',
          unit: 'each',
          variants: [
            for (final length in ['4 ft', '7 ft', '12 ft'])
              for (final color in ['White', 'Ivory', 'Brown'])
                '$length $color Line Set Cover',
            for (final size in ['18 x 38', '24 x 24', '30 x 30', '36 x 36'])
              '$size Equipment Pad',
            'Wall Bracket 9000 BTU',
            'Wall Bracket 12000 BTU',
            'Wall Bracket 24000 BTU',
            'Ground Stand Mini Split',
            'Condenser Tie Down Strap Kit',
            'Hurricane Pad Strap Kit',
          ],
          aliases: const [
            'line set cover',
            'line hide',
            'equipment pad',
            'wall bracket',
            'tie down kit',
          ],
        ),
      ),
    ]),
    _system('Expanded Refrigerant Line Service', [
      _type(
        'Line Sets and Insulation',
        _hvacProducts(
          baseName: 'Refrigerant Line Material',
          unit: 'set',
          variants: [
            for (final pair in _hvacLineSetPairs)
              for (final length in ['15 ft', '25 ft', '35 ft', '50 ft'])
                '$pair x $length Line Set',
            for (final size in [
              '3/8 in',
              '1/2 in',
              '5/8 in',
              '3/4 in',
              '7/8 in',
            ])
              '$size Line Set Insulation',
          ],
          aliases: const ['line set', 'armaflex', 'copper line'],
        ),
      ),
      _type(
        'Mini Split Install Accessories',
        _hvacProducts(
          baseName: 'Mini Split Install Material',
          unit: 'each',
          variants: [
            for (final length in ['15 ft', '25 ft', '35 ft', '50 ft'])
              for (final size in ['1/4 x 3/8', '1/4 x 1/2', '1/4 x 5/8'])
                '$size x $length Mini Split Line Set',
            'Mini Split Wall Sleeve',
            'Mini Split Line Hide 3 in',
            'Mini Split Line Hide 4 in',
            'Mini Split Drain Hose 20 ft',
            'Mini Split Condensate Hose Adapter',
            'Mini Split Outdoor Wall Bracket',
            'Mini Split Ground Stand',
            'Mini Split Disconnect Box',
            'Mini Split Communication Cable 14/4 x 50 ft',
            'Mini Split Communication Cable 14/4 x 100 ft',
          ],
          aliases: const ['mini split', 'line hide', 'mini split line set'],
        ),
      ),
      _type(
        'Service Valves Caps and Cores',
        _hvacProducts(
          baseName: 'Refrigerant Service Part',
          unit: 'pack',
          variants: [
            for (final fitting in ['1/4 in flare', '5/16 in flare'])
              for (final item in [
                'Service Cap',
                'Schrader Core',
                'Core Removal Tool Gasket',
                'Access Tee',
                'Charging Adapter',
              ])
                '$fitting $item',
            'R410A Charging Adapter',
            'R32 Charging Adapter',
            'Service Valve Wrench',
            'Brass Service Tee',
            'Refrigerant Hose Gasket Pack',
            'Low Loss Hose Adapter',
          ],
          aliases: const ['schrader', 'service port', 'charging adapter'],
        ),
      ),
      _type(
        'Filter Driers and Brazing Supplies',
        _hvacProducts(
          baseName: 'Refrigerant Service Supply',
          unit: 'each',
          variants: const [
            '1/4 in Liquid Line Filter Drier',
            '3/8 in Liquid Line Filter Drier',
            '1/2 in Liquid Line Filter Drier',
            '5/8 in Suction Line Filter Drier',
            '15% Silver Brazing Rod',
            '5% Silver Brazing Rod',
            'Phos Copper Brazing Rod',
            'Nitrogen Purge Regulator Adapter',
            'Acid Test Kit',
            'Leak Detector Bubbles',
            'Equipment Pad 18 x 38',
            'Equipment Pad 24 x 24',
            'Equipment Pad 30 x 30',
            'Equipment Pad 36 x 36',
            'Condenser Tie Down Kit',
            'Condenser Wall Bracket',
          ],
          aliases: const ['filter drier', 'brazing rod', 'nitrogen purge'],
        ),
      ),
      _type(
        'Furnace Service Switches and Tubing',
        _hvacProducts(
          baseName: 'Furnace Diagnostic Part',
          unit: 'each',
          variants: const [
            'Round Pressure Switch Tubing',
            'Silicone Pressure Switch Tubing',
            'Furnace Door Safety Switch',
            'Rollout Switch Manual Reset',
            'Limit Switch 150 Degree',
            'Limit Switch 180 Degree',
            'Limit Switch 200 Degree',
            'Inducer Pressure Port Kit',
            'Combustion Blower Gasket',
            'Ignitor Wire Harness',
          ],
          aliases: const [
            'pressure switch tubing',
            'door switch',
            'rollout switch',
            'limit switch',
            'inducer gasket',
          ],
        ),
      ),
    ]),
    _system('Expanded Motors Ignition and Heat', [
      _type(
        'Motors and Blower Parts',
        _hvacProducts(
          baseName: 'HVAC Motor Part',
          unit: 'each',
          variants: [
            for (final hp in ['1/6 hp', '1/4 hp', '1/3 hp', '1/2 hp', '3/4 hp'])
              for (final part in [
                'PSC Blower Motor',
                'Condenser Fan Motor',
                'Motor Mount',
              ])
                '$hp $part',
            for (final size in ['10 x 8', '10 x 10', '11 x 10', '12 x 12'])
              '$size Blower Wheel',
            for (final size in ['18 in', '20 in', '22 in', '24 in'])
              '$size Condenser Fan Blade',
          ],
          aliases: const ['furnace motor', 'fan motor', 'squirrel cage'],
        ),
      ),
      _type(
        'Ignition Gas Heat and Sensors',
        _hvacProducts(
          baseName: 'Furnace Service Part',
          unit: 'each',
          variants: const [
            'Universal Hot Surface Ignitor',
            'Flat Hot Surface Ignitor',
            'Silicon Nitride Ignitor',
            'Straight Flame Sensor',
            'Bent Flame Sensor',
            'Single Port Pressure Switch',
            'Dual Port Pressure Switch',
            '24V Natural Gas Valve',
            '24V Propane Gas Valve',
            'Rollout Switch',
            'Limit Switch',
            'High Limit Switch',
            'Fan Limit Switch',
            'Draft Inducer Motor',
            'Furnace Control Board',
            'Integrated Furnace Control Board',
            'Pressure Switch Tubing',
            'Silicone Ignitor Wire',
            'Furnace Door Switch',
            'Gas Valve Adapter Harness',
            'Hot Surface Ignitor Bracket',
          ],
          aliases: const ['hsi', 'flame rod', 'pressure switch'],
        ),
      ),
    ]),
    _system('Expanded Tape Sealants and Hardware', [
      _type(
        'Tape Sealants and Fastening',
        _hvacProducts(
          baseName: 'HVAC Seal and Fasten Supply',
          unit: 'each',
          variants: const [
            '2 in x 50 yd UL 181 Foil Tape',
            '3 in x 50 yd UL 181 Foil Tape',
            '1 gal Duct Mastic',
            '2 gal Duct Mastic',
            '1/2 in x 100 ft Foam Tape',
            '1 in x 100 ft Foam Tape',
            '1/4 in x 100 ft Cork Tape',
            'Duct Strap Roll',
            'Panduit Strap Pack',
            'Zip Screw 1/2 in Pack',
            'Zip Screw 3/4 in Pack',
            'Duct Hanger Strap Roll',
            'Metal Hanging Strap Roll',
            'Drive Cleat 36 in',
            'S Cleat 36 in',
            'Duct Corner Pack',
            'Duct Access Door',
            'Sheet Metal Screw 1/2 in Pack',
            'Sheet Metal Screw 3/4 in Pack',
            'Nylon Cable Tie Pack',
            'Foam Gasket Tape',
          ],
          aliases: const ['foil tape', 'mastic', 'duct strap', 'zip screw'],
        ),
      ),
      _type(
        'Coil Cleaners and Service Chemicals',
        _hvacProducts(
          baseName: 'HVAC Service Chemical',
          unit: 'each',
          variants: const [
            'Aerosol Coil Cleaner',
            'No Rinse Evaporator Coil Cleaner',
            'Condenser Coil Cleaner 1 gal',
            'Pan Treatment Tablets',
            'Drain Line Cleaner 1 qt',
            'Acid Away Treatment',
            'Refrigerant Leak Detector Spray',
            'UV Dye Leak Detection Kit',
            'Vacuum Pump Oil 1 qt',
            'Thread Sealant for Refrigeration',
          ],
          aliases: const ['coil cleaner', 'pan tablets', 'leak detector'],
        ),
      ),
    ]),
    _system('Expanded Thermostats Zoning and IAQ', [
      _type(
        'Thermostats and Wall Controls',
        _hvacProducts(
          baseName: 'Thermostat or HVAC Control',
          unit: 'each',
          variants: const [
            'Non Programmable Thermostat',
            '5-2 Programmable Thermostat',
            '7 Day Programmable Thermostat',
            'WiFi Smart Thermostat',
            'Heat Pump Thermostat',
            'Millivolt Thermostat',
            'Line Voltage Thermostat',
            'Thermostat Wall Plate',
            'Thermostat Wire Guard',
            'Remote Indoor Sensor',
            'Outdoor Temperature Sensor',
          ],
          aliases: const [
            'thermostat',
            't stat',
            'wall control',
            'smart thermostat',
          ],
        ),
      ),
      _type(
        'Zoning Dampers and IAQ Service',
        _hvacProducts(
          baseName: 'HVAC Zoning or IAQ Part',
          unit: 'each',
          variants: [
            for (final size in ['6 in', '8 in', '10 in', '12 in'])
              '$size Round Zone Damper',
            'Zone Control Panel',
            'Bypass Damper',
            'Duct Temperature Sensor',
            'Whole House Humidifier Pad',
            'Humidifier Solenoid Valve',
            'Humidifier Water Panel',
            'UV Lamp Replacement Bulb',
            'Air Cleaner Cell Cleaner',
            'ERV Filter Kit',
            'HRV Core Filter Kit',
          ],
          aliases: const [
            'zone damper',
            'zoning panel',
            'humidifier pad',
            'uv lamp',
            'air cleaner',
          ],
        ),
      ),
    ]),
    _system('Expanded Duct Fabrication and Plenums', [
      _type(
        'Duct Board Plenums and Transitions',
        _hvacProducts(
          baseName: 'Duct Fabrication Material',
          unit: 'each',
          variants: [
            for (final size in ['2 ft x 4 ft', '4 ft x 8 ft'])
              '$size Foil Faced Duct Board',
            for (final size in ['16 x 20', '20 x 20', '20 x 25', '24 x 24'])
              '$size Return Air Box',
            'Supply Plenum 20 x 20 x 36',
            'Return Plenum 20 x 20 x 36',
            'Duct Transition 20 x 20 to 16 in Round',
            'Duct Transition 24 x 24 to 18 in Round',
            'Duct End Cap 8 in',
            'Duct End Cap 10 in',
            'Duct End Cap 12 in',
            'Duct Takeoff with Damper 6 in',
            'Duct Takeoff with Damper 8 in',
            'Duct Takeoff with Damper 10 in',
          ],
          aliases: const [
            'duct board',
            'return box',
            'supply plenum',
            'duct transition',
            'takeoff damper',
          ],
        ),
      ),
      _type(
        'Dryer Vent and Exhaust Hardware',
        _hvacProducts(
          baseName: 'Exhaust Vent Material',
          unit: 'each',
          variants: const [
            '4 in Dryer Vent Hood',
            '4 in Dryer Vent Elbow',
            '4 in Semi Rigid Dryer Duct',
            '4 in Dryer Vent Clamp',
            'Bathroom Fan Roof Cap',
            'Bathroom Fan Wall Cap',
            '3 in Exhaust Duct',
            '4 in Exhaust Duct',
            'Exhaust Duct Backdraft Damper',
          ],
          aliases: const [
            'dryer vent',
            'vent hood',
            'bath fan cap',
            'exhaust duct',
          ],
        ),
      ),
    ]),
    _system('Expanded Refrigerant Tools and Job Supplies', [
      _type(
        'Vacuum Charging and Refrigerant Tools',
        _hvacProducts(
          baseName: 'Refrigerant Service Tool',
          unit: 'each',
          variants: const [
            'Manifold Gauge Set',
            'Digital Refrigerant Scale',
            'Vacuum Pump 3 CFM',
            'Vacuum Pump 5 CFM',
            'Micron Gauge',
            'Core Removal Tool',
            'Flaring Tool Kit',
            'Swaging Tool Kit',
            'Tubing Cutter',
            'Deburring Tool',
            'Nitrogen Regulator',
            'Refrigerant Hose Set',
            'Low Loss Fitting Set',
          ],
          aliases: const [
            'manifold gauge',
            'refrigerant scale',
            'vacuum pump',
            'micron gauge',
            'core tool',
            'flare tool',
          ],
        ),
      ),
      _type(
        'HVAC Electrical Install Hardware',
        _hvacProducts(
          baseName: 'HVAC Electrical Install Material',
          unit: 'each',
          variants: [
            for (final size in ['30 Amp', '60 Amp'])
              '$size Non Fused AC Disconnect',
            for (final size in ['30 Amp', '60 Amp'])
              '$size Fused AC Disconnect',
            '3/4 in x 6 ft AC Whip',
            '1/2 in x 6 ft AC Whip',
            'Liquid Tight Connector 1/2 in',
            'Liquid Tight Connector 3/4 in',
            'Equipment Ground Lug',
            'Condenser Surge Protector',
            'Outdoor Disconnect Fuse 30 Amp',
            'Outdoor Disconnect Fuse 60 Amp',
          ],
          aliases: const [
            'ac disconnect',
            'disconnect box',
            'ac whip',
            'liquid tight connector',
            'surge protector',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacProducts({
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

const _hvacFilterDeepSizes = [
  '10 x 20 x 1',
  '12 x 12 x 1',
  '12 x 20 x 1',
  '14 x 20 x 1',
  '14 x 25 x 1',
  '16 x 20 x 1',
  '16 x 24 x 1',
  '16 x 25 x 1',
  '18 x 20 x 1',
  '20 x 20 x 1',
  '20 x 24 x 1',
  '20 x 25 x 1',
  '24 x 24 x 1',
];

const _hvacMediaFilterSizes = [
  '16 x 20',
  '16 x 25',
  '20 x 20',
  '20 x 25',
  '24 x 24',
];

const _hvacDualCapacitorValues = [
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

const _hvacSingleCapacitorValues = [
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

const _hvacRoundDuctSizes = [
  '4 in',
  '5 in',
  '6 in',
  '7 in',
  '8 in',
  '9 in',
  '10 in',
  '12 in',
  '14 in',
  '16 in',
];

const _hvacRegisterSizes = [
  '2 x 10',
  '2 x 12',
  '4 x 10',
  '4 x 12',
  '6 x 10',
  '6 x 12',
  '8 x 8',
  '10 x 10',
  '12 x 12',
  '14 x 20',
  '16 x 20',
  '20 x 20',
  '20 x 25',
];

const _hvacLineSetPairs = [
  '1/4 x 3/8',
  '1/4 x 1/2',
  '1/4 x 5/8',
  '3/8 x 3/4',
  '3/8 x 7/8',
  '1/2 x 1-1/8',
];
