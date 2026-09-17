part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckRtuCatalogCategory = _category(
  'HVAC Service Truck Rooftop and Package Unit Stock',
  [
    _system('Rooftop Unit Belts Filters and Panel Service', [
      _type(
        'Rooftop Belts Filters and Access Repair',
        _hvacTruckRtuProducts(
          baseName: 'Rooftop Unit Service Part',
          unit: 'each',
          variants: [
            for (final belt in [
              'A28',
              'A30',
              'A32',
              'A34',
              'A36',
              'A38',
              'A40',
              'A42',
              'B34',
              'B36',
              'B38',
              'B40',
              'B42',
              'B44',
              'BX38',
              'BX40',
              'BX42',
              'BX44',
            ])
              '$belt Cogged Blower Belt',
            for (final size in [
              '16 x 20 x 2',
              '16 x 25 x 2',
              '20 x 20 x 2',
              '20 x 25 x 2',
              '24 x 24 x 2',
              '12 x 24 x 2',
            ])
              '$size Pleated Rooftop Unit Filter',
            for (final item in [
              'Rooftop Unit Filter Clips 20 Pack',
              'Rooftop Unit Panel Screw Kit',
              'Rooftop Unit Door Latch',
              'Rooftop Unit Access Panel Gasket',
              'Rooftop Unit Hail Guard Panel',
              'Condenser Coil Guard Fastener Kit',
              'RTU Condensate Drain Trap Kit',
            ])
              item,
          ],
          aliases: const [
            'rooftop unit',
            'rtu',
            'package unit',
            'blower belt',
            'cogged belt',
            'rtu filter',
            'filter clips',
            'panel screw',
            'door latch',
            'hail guard',
            'drain trap',
          ],
        ),
      ),
      _type(
        'Package Unit Electrical and Heater Service',
        _hvacTruckRtuProducts(
          baseName: 'Package Unit Electrical Part',
          unit: 'each',
          variants: [
            for (final voltage in ['24V', '120V', '208/230V'])
              for (final item in [
                'Package Unit Fan Relay',
                'RTU Time Delay Relay',
                'Economizer Relay',
                'Compressor Lockout Control',
              ])
                '$voltage $item',
            for (final watt in ['40W', '70W', '100W'])
              for (final voltage in ['120V', '208/230V'])
                '$watt $voltage Crankcase Heater',
            for (final item in [
              'RTU Phase Monitor',
              'Compressor Terminal Repair Kit',
              'Compressor Plug Harness',
              'Condenser Fan Motor Plug',
              'Package Unit Transformer 40VA',
              'Package Unit Transformer 75VA',
            ])
              item,
          ],
          aliases: const [
            'package unit relay',
            'rtu relay',
            'time delay relay',
            'compressor lockout',
            'crankcase heater',
            'phase monitor',
            'compressor terminal kit',
            'transformer',
          ],
        ),
      ),
    ]),
    _system('Economizer Damper and Sensor Service Stock', [
      _type(
        'Economizer Actuators Sensors and Hardware',
        _hvacTruckRtuProducts(
          baseName: 'Economizer Service Part',
          unit: 'each',
          variants: [
            for (final torque in ['35 in-lb', '45 in-lb', '88 in-lb'])
              for (final signal in ['2-10V', 'Spring Return', 'Floating'])
                '$torque $signal Economizer Damper Actuator',
            for (final item in [
              'Economizer Logic Module',
              'Economizer Enthalpy Sensor',
              'Economizer Mixed Air Sensor',
              'Economizer Outdoor Air Sensor',
              'Economizer Return Air Sensor',
              'Economizer Damper Linkage Kit',
              'Economizer Damper Blade Seal',
              'Minimum Position Potentiometer',
              'Barometric Relief Damper',
              'Fresh Air Hood Filter',
              'Fresh Air Hood Bird Screen',
            ])
              item,
          ],
          aliases: const [
            'economizer',
            'economizer actuator',
            'damper actuator',
            'enthalpy sensor',
            'mixed air sensor',
            'outdoor air sensor',
            'return air sensor',
            'damper linkage',
            'minimum position',
            'barometric relief',
            'fresh air hood',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacTruckRtuProducts({
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
