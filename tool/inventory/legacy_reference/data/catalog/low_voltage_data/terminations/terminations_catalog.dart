part of '../../../work_supply_catalog.dart';

final lowVoltageDataTerminationsCategory = _category('Terminations', [
  _system('Connectors', [
    _type(
      'RJ45 Connectors',
      _variants(
        'RJ45 Connector',
        'pack',
        ['Cat5e', 'Cat6', 'Cat6A'],
        ['ethernet plug'],
      ),
    ),
    _type(
      'Keystone Jacks',
      _variants(
        'Keystone Jack',
        'each',
        ['Cat5e', 'Cat6', 'Cat6A'],
        ['data jack'],
      ),
    ),
  ]),
]);
