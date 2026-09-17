part of '../../../work_supply_catalog.dart';

final hvacIgnitionAndGasHeatCategory = _category('Ignition and Gas Heat', [
  _system('Ignition', [
    _type(
      'Hot Surface Ignitors',
      _variants(
        'Hot Surface Ignitor',
        'each',
        ['flat style', 'silicon nitride', 'universal'],
        ['hsi', 'furnace ignitor'],
      ),
    ),
    _type(
      'Flame Sensors',
      _variants(
        'Flame Sensor',
        'each',
        ['straight', 'bent', 'universal'],
        ['flame rod'],
      ),
    ),
  ]),
  _system('Gas Train', [
    _type(
      'Gas Valves',
      _variants(
        'HVAC Gas Valve',
        'each',
        ['24V natural gas', '24V propane'],
        ['furnace gas valve'],
      ),
    ),
    _type(
      'Pressure Switches',
      _variants(
        'Furnace Pressure Switch',
        'each',
        ['Single Port', 'Dual Port'],
        ['draft pressure switch'],
      ),
    ),
  ]),
]);
