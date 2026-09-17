part of '../../../work_supply_catalog.dart';

final tileWaterproofingCategory = _category('Waterproofing', [
  _system('Membranes', [
    _type(
      'Waterproofing Membrane',
      _variants(
        'Waterproofing Membrane',
        'roll',
        ['3 ft x 16 ft', '3 ft x 33 ft'],
        ['shower membrane', 'uncoupling membrane'],
      ),
    ),
    _type(
      'Backer Board',
      _variants(
        'Tile Backer Board',
        'sheet',
        ['1/4 in 3 x 5 ft', '1/2 in 3 x 5 ft'],
        ['cement board', 'backerboard'],
      ),
    ),
  ]),
  _system('Shower Systems', [
    _type(
      'Shower Pan Kit',
      _variants(
        'Tile Shower Pan Kit',
        'kit',
        ['48 x 48 in', '60 x 32 in', '60 x 36 in'],
        ['shower base kit'],
      ),
    ),
    _type(
      'Linear Drain',
      _variants(
        'Linear Shower Drain',
        'each',
        ['24 in', '36 in', '48 in'],
        ['shower drain'],
      ),
    ),
  ]),
]);
