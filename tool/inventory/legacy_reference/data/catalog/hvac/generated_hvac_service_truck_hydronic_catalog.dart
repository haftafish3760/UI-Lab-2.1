part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckHydronicCatalogCategory = _category(
  'HVAC Service Truck Hydronic and Boiler Stock',
  [
    _system('Boiler Water Loop Repair Stock', [
      _type(
        'Circulators Zone Valves and Hydronic Controls',
        _hvacTruckHydronicProducts(
          baseName: 'Hydronic Heating Service Part',
          unit: 'each',
          variants: [
            for (final size in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
              for (final item in [
                'Sweat Circulator Pump Flange Pair',
                'Threaded Circulator Pump Flange Pair',
                'Isolation Flange Valve Pair',
                'Zone Valve Sweat',
                'Zone Valve Threaded',
                'Motorized Ball Valve',
              ])
                '$size $item',
            for (final item in [
              'Universal Circulator Pump',
              'High Efficiency ECM Circulator Pump',
              'Zone Valve Power Head',
              'Zone Valve Motor',
              'Circulator Relay Control',
              'Multi Zone Relay Panel',
              'Aquastat Temperature Control',
              'Low Water Cutoff Control',
              'Boiler Temperature Sensor',
              'Outdoor Reset Sensor',
            ])
              item,
          ],
          aliases: const [
            'circulator pump',
            'pump flange',
            'isolation flange',
            'zone valve',
            'zone valve head',
            'zone valve motor',
            'aquastat',
            'low water cutoff',
            'boiler sensor',
            'outdoor reset',
          ],
        ),
      ),
      _type(
        'Expansion Tanks Relief Valves and Air Elimination',
        _hvacTruckHydronicProducts(
          baseName: 'Boiler Water Safety Part',
          unit: 'each',
          variants: [
            for (final size in ['15', '30', '60', '90'])
              'Hydronic Expansion Tank No $size',
            for (final size in ['1/8 in', '1/4 in', '1/2 in'])
              for (final item in [
                'Automatic Air Vent',
                'Manual Coin Vent',
                'Boiler Drain Valve',
                'Pressure Relief Valve 30 PSI',
                'Backflow Preventer',
                'Pressure Reducing Fill Valve',
              ])
                '$size $item',
            for (final item in [
              'Boiler Pressure Temperature Gauge',
              'Air Scoop',
              'Microbubble Air Separator',
              'Dirt Separator',
              'Expansion Tank Bracket',
              'Boiler Feed Valve Fast Fill Lever',
              'Hydronic System Cleaner Quart',
              'Hydronic Corrosion Inhibitor Quart',
              'Glycol Refractometer',
            ])
              item,
          ],
          aliases: const [
            'expansion tank',
            'air vent',
            'coin vent',
            'pressure relief valve',
            '30 psi relief valve',
            'backflow preventer',
            'pressure reducing valve',
            'fill valve',
            'boiler gauge',
            'air separator',
            'hydronic cleaner',
            'glycol refractometer',
          ],
        ),
      ),
    ]),
    _system('Baseboard Radiator and Radiant Heat Repair Stock', [
      _type(
        'Baseboard Radiator Repair Parts',
        _hvacTruckHydronicProducts(
          baseName: 'Hydronic Emitter Repair Part',
          unit: 'each',
          variants: [
            for (final length in ['2 ft', '3 ft', '4 ft', '6 ft', '8 ft'])
              for (final item in [
                'Baseboard Heating Element',
                'Baseboard Enclosure Front Cover',
                'Baseboard Damper',
              ])
                '$length $item',
            for (final item in [
              'Baseboard End Cap Left',
              'Baseboard End Cap Right',
              'Baseboard Inside Corner',
              'Baseboard Outside Corner',
              'Baseboard Wall Trim Plate',
              'Radiator Air Vent',
              'Radiator Angle Valve',
              'Radiator Union Tailpiece',
            ])
              item,
          ],
          aliases: const [
            'baseboard heat',
            'baseboard element',
            'baseboard cover',
            'baseboard damper',
            'baseboard end cap',
            'radiator vent',
            'radiator valve',
          ],
        ),
      ),
      _type(
        'Radiant Heat Service Fittings',
        _hvacTruckHydronicProducts(
          baseName: 'Radiant Heat Service Part',
          unit: 'each',
          variants: [
            for (final size in ['1/2 in', '5/8 in', '3/4 in'])
              for (final item in [
                'Oxygen Barrier PEX Coupling',
                'Oxygen Barrier PEX Elbow',
                'Radiant Manifold Adapter',
                'Radiant Loop Isolation Valve',
                'Radiant Compression Fitting',
              ])
                '$size $item',
            for (final item in [
              'Radiant Manifold Flow Meter',
              'Radiant Manifold Actuator',
              'Radiant Manifold Air Vent',
              'Radiant Thermostat Sensor',
              'PEX Bend Support',
            ])
              item,
          ],
          aliases: const [
            'radiant heat',
            'oxygen barrier pex',
            'radiant manifold',
            'flow meter',
            'manifold actuator',
            'radiant sensor',
            'pex bend support',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacTruckHydronicProducts({
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
