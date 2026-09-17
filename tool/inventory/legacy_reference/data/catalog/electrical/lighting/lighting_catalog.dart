part of '../../../work_supply_catalog.dart';

final electricalLightingCategory = _category('Lighting', [
  _system('Fixtures', [
    _type(
      'Recessed Lighting',
      _variants(
        'Recessed LED Light',
        'each',
        ['4 in', '6 in', '8 in'],
        ['can light', 'wafer light'],
      ),
    ),
    _type(
      'Lampholders',
      _variants(
        'Lampholder',
        'each',
        ['keyless', 'pull chain', 'weatherproof'],
        ['porcelain lampholder'],
      ),
    ),
  ]),
  _system('Lamps and Drivers', [
    _type(
      'LED Bulbs',
      _variants(
        'LED Bulb',
        'each',
        ['A19 60W equivalent', 'BR30', 'PAR38'],
        ['lamp', 'light bulb'],
      ),
    ),
    _type(
      'LED Drivers',
      _variants(
        'LED Driver',
        'each',
        ['12V', '24V', 'constant current'],
        ['power supply'],
      ),
    ),
  ]),
]);
