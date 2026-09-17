part of '../../../work_supply_catalog.dart';

final plumbingWaterHeaterCategory = _category('Water Heater', [
  _system('Water Heater Connections', [
    _type(
      'Supply Connectors',
      _variants(
        'Water Heater Supply Connector',
        'each',
        ['3/4 x 12 in', '3/4 x 18 in', '3/4 x 24 in'],
        ['water heater line'],
      ),
    ),
    _type(
      'Dielectric Nipples',
      _variants(
        'Water Heater Dielectric Nipple',
        'each',
        ['3/4 x 2 in', '3/4 x 3 in', '3/4 x 4 in'],
        ['dielectric nipple', 'water heater nipple'],
      ),
    ),
    _type(
      'Relief Valves',
      _variants(
        'Temperature and Pressure Relief Valve',
        'each',
        ['3/4 in'],
        ['t&p valve', 'tpr valve'],
      ),
    ),
    _type(
      'Drain Valves',
      _variants(
        'Water Heater Drain Valve',
        'each',
        ['3/4 in plastic', '3/4 in brass'],
        ['boiler drain', 'heater drain valve'],
      ),
    ),
    _type(
      'Expansion Tanks',
      _variants(
        'Expansion Tank',
        'each',
        ['2 gal', '4.5 gal'],
        ['thermal expansion tank'],
      ),
    ),
    _type(
      'Water Heater Pans',
      _variants(
        'Water Heater Drain Pan',
        'each',
        ['20 in plastic', '22 in plastic', '24 in aluminum', '26 in aluminum'],
        ['heater pan', 'drain pan'],
      ),
    ),
    _type(
      'Water Heater Straps',
      _variants(
        'Water Heater Restraint Strap',
        'kit',
        ['18 in', '24 in', 'universal'],
        [
          'seismic strap',
          'heater strap',
          'water heater strap',
          'restraint strap',
          'earthquake strap',
          'wtr htr strap',
          'wtr htr restraint strap',
          'universal water heater strap',
          'universal wtr htr strap',
        ],
      ),
    ),
    _type(
      'Gas Water Heater Connectors',
      _variants(
        'Gas Water Heater Connector',
        'each',
        ['1/2 x 18 in', '1/2 x 24 in', '3/4 x 24 in'],
        ['gas appliance connector', 'water heater gas line'],
      ),
    ),
    _type(
      'Water Heater Service Fittings',
      _variants(
        'Water Heater Service Fitting',
        'each',
        ['3/4 in vacuum relief valve', '3/4 in mixing valve', '3/4 in union'],
        ['vacuum relief', 'mixing valve', 'water heater union'],
      ),
    ),
  ]),
]);
