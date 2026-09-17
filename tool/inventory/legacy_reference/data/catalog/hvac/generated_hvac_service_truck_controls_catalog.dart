part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckControlsCatalogCategory = _category(
  'HVAC Service Truck Controls and Repair Stock',
  [
    _system('Thermostat Zoning and Low Voltage Service', [
      _type(
        'Thermostats Sensors and Wall Controls',
        _hvacTruckControlProducts(
          baseName: 'HVAC Wall Control',
          unit: 'each',
          variants: [
            for (final stage in ['1H/1C', '2H/1C', '2H/2C', '3H/2C'])
              for (final style in [
                'Non Programmable Thermostat',
                'Programmable Thermostat',
                'WiFi Thermostat',
                'Heat Pump Thermostat',
              ])
                '$stage $style',
            for (final item in [
              'Outdoor Temperature Sensor',
              'Remote Indoor Sensor',
              'Duct Temperature Sensor',
              'Thermostat Wall Plate',
              'Thermostat Wire Saver Module',
              'Thermostat Common Wire Adapter',
              'Equipment Interface Module',
              'Thermostat Locking Cover',
            ])
              item,
          ],
          aliases: const [
            'thermostat',
            't stat',
            'wifi thermostat',
            'heat pump thermostat',
            'outdoor sensor',
            'common wire adapter',
            'wire saver',
            'wall plate',
          ],
        ),
      ),
      _type(
        'Zone Boards Dampers and Accessories',
        _hvacTruckControlProducts(
          baseName: 'HVAC Zone Control',
          unit: 'each',
          variants: [
            for (final zones in ['2 Zone', '3 Zone', '4 Zone'])
              for (final type in ['Conventional', 'Heat Pump'])
                '$zones $type Zone Control Panel',
            for (final size in [
              '6 in',
              '7 in',
              '8 in',
              '10 in',
              '12 in',
              '14 in',
            ])
              for (final style in ['Round', 'Power Open Power Close'])
                '$size $style Motorized Zone Damper',
            for (final item in [
              'Bypass Damper Barometric',
              'Zone Damper Motor Actuator',
              'Zone Board Transformer',
              'Zone Panel Fuse Pack',
              'Discharge Air Sensor',
              'Fresh Air Damper Actuator',
            ])
              item,
          ],
          aliases: const [
            'zone board',
            'zone panel',
            'zone control panel',
            'motorized damper',
            'damper actuator',
            'bypass damper',
            'discharge air sensor',
          ],
        ),
      ),
    ]),
    _system('Control Boards Heat Pump and Defrost Service', [
      _type(
        'Furnace Air Handler and Fan Control Boards',
        _hvacTruckControlProducts(
          baseName: 'HVAC Control Board',
          unit: 'each',
          variants: [
            for (final voltage in ['24V', '120V'])
              for (final item in [
                'Universal Furnace Control Board',
                'Fan Center Relay Board',
                'Blower Time Delay Board',
                'Integrated Furnace Control Board',
                'Air Handler Control Board',
              ])
                '$voltage $item',
            for (final item in [
              'ECM Motor Module Tester',
              'ECM Surge Protector',
              'Furnace Board Mounting Standoff Pack',
              'Control Board Fuse Holder',
              'Low Voltage Terminal Strip',
              'Spade Terminal Repair Kit',
            ])
              item,
          ],
          aliases: const [
            'furnace control board',
            'ifc board',
            'fan center',
            'time delay board',
            'air handler board',
            'terminal strip',
            'spade terminal',
          ],
        ),
      ),
      _type(
        'Heat Pump Defrost and Outdoor Unit Controls',
        _hvacTruckControlProducts(
          baseName: 'Heat Pump Service Control',
          unit: 'each',
          variants: [
            for (final item in [
              'Universal Heat Pump Defrost Board',
              'Defrost Sensor',
              'Outdoor Ambient Sensor',
              'Low Pressure Switch',
              'High Pressure Switch',
              'Pressure Transducer',
              'Crankcase Heater Band',
              'Reversing Valve Coil',
              'Contactor Lug Repair Kit',
              'Compressor Terminal Repair Kit',
            ])
              item,
            for (final size in ['24 in', '36 in', '48 in'])
              '$size Crankcase Heater Strap',
          ],
          aliases: const [
            'defrost board',
            'defrost sensor',
            'ambient sensor',
            'low pressure switch',
            'high pressure switch',
            'pressure transducer',
            'reversing valve coil',
            'compressor terminal kit',
          ],
        ),
      ),
    ]),
    _system('Mini Split and Ductless Service Truck Stock', [
      _type(
        'Mini Split Controls Pumps and Line Hide Repair',
        _hvacTruckControlProducts(
          baseName: 'Mini Split Service Part',
          unit: 'each',
          variants: [
            for (final item in [
              'Mini Split Remote Control',
              'Mini Split Wall Controller',
              'Mini Split Communication Cable 50 ft',
              'Mini Split Condensate Pump',
              'Mini Split Drain Hose',
              'Mini Split Flare Nut Pack',
              'Mini Split Adapter Fitting Kit',
              'Mini Split Line Hide Coupling',
              'Mini Split Line Hide Elbow',
              'Mini Split Line Hide Wall Sleeve',
              'Mini Split Outdoor Stand Rubber Foot Pack',
            ])
              item,
            for (final size in ['1/4 in', '3/8 in', '1/2 in', '5/8 in'])
              '$size Mini Split Flare Union',
          ],
          aliases: const [
            'mini split remote',
            'ductless remote',
            'mini split pump',
            'mini split drain hose',
            'flare nut',
            'flare union',
            'line hide',
            'communication cable',
          ],
        ),
      ),
      _type(
        'Mini Split Cleaning and Maintenance Supplies',
        _hvacTruckControlProducts(
          baseName: 'Mini Split Cleaning Supply',
          unit: 'each',
          variants: [
            for (final size in ['1 qt', '1 gal'])
              for (final item in [
                'No Rinse Evaporator Cleaner',
                'Mini Split Coil Cleaner',
                'Drain Pan Treatment',
                'Condensate Drain Cleaner',
              ])
                '$size $item',
            for (final item in [
              'Mini Split Cleaning Bib Kit',
              'Mini Split Wash Bag',
              'Fin Comb Set',
              'Evaporator Brush Set',
              'Reusable Cleaning Cover',
            ])
              item,
          ],
          aliases: const [
            'mini split cleaning bib',
            'mini split wash bag',
            'coil cleaner',
            'evap cleaner',
            'fin comb',
            'evaporator brush',
          ],
        ),
      ),
    ]),
    _system('High Volume Filter and Service Consumable Restock', [
      _type(
        'Service Truck Filter Case Stock',
        _hvacTruckControlProducts(
          baseName: 'HVAC Filter Case',
          unit: 'case',
          variants: [
            for (final size in _hvacTruckControlFilterSizes)
              for (final merv in ['MERV 8', 'MERV 11', 'MERV 13'])
                for (final count in ['6 Pack', '12 Pack'])
                  '$size $merv Pleated Filter $count',
            for (final size in [
              '16 x 25 x 4',
              '16 x 25 x 5',
              '20 x 20 x 4',
              '20 x 25 x 4',
              '20 x 25 x 5',
            ])
              for (final merv in ['MERV 11', 'MERV 13'])
                '$size $merv Media Filter 2 Pack',
          ],
          aliases: const [
            'filter case',
            'pleated filter case',
            'merv filter',
            'media filter',
            'furnace filter case',
            'air filter 12 pack',
          ],
        ),
      ),
      _type(
        'Service Stickers Hardware and Small Consumables',
        _hvacTruckControlProducts(
          baseName: 'HVAC Truck Consumable',
          unit: 'pack',
          variants: [
            for (final item in [
              'Service Sticker Roll',
              'Equipment Tag Pack',
              'Wire Number Marker Book',
              'Low Voltage Wire Nut Pack',
              'Fork Terminal Assortment',
              'Female Spade Terminal Assortment',
              'Zip Tie Mount Pack',
              'UV Resistant Zip Tie Pack',
              'Foam Gasket Tape Roll',
              'Thumb Gum Sealant',
              'Electrical Tape Multi Pack',
              'No Ox Electrical Grease',
            ])
              item,
          ],
          aliases: const [
            'service sticker',
            'equipment tag',
            'wire marker',
            'low voltage wire nut',
            'spade terminal',
            'fork terminal',
            'zip tie',
            'thumb gum',
            'no ox grease',
          ],
        ),
      ),
    ]),
  ],
);

const _hvacTruckControlFilterSizes = [
  '10 x 20 x 1',
  '12 x 12 x 1',
  '12 x 20 x 1',
  '14 x 20 x 1',
  '14 x 25 x 1',
  '16 x 20 x 1',
  '16 x 25 x 1',
  '18 x 20 x 1',
  '20 x 20 x 1',
  '20 x 25 x 1',
  '24 x 24 x 1',
];

List<WorkSupplyItem> _hvacTruckControlProducts({
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
