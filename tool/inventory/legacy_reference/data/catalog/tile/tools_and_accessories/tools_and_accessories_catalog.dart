part of '../../../work_supply_catalog.dart';

final tileToolsAndAccessoriesCategory = _category('Tools and Accessories', [
  _system('Spacers and Leveling', [
    _type(
      'Tile Spacers',
      _variants(
        'Tile Spacers',
        'pack',
        ['1/16 in', '1/8 in', '3/16 in', '1/4 in'],
        ['tile spacer'],
      ),
    ),
    _type(
      'Leveling Clips',
      _variants(
        'Tile Leveling Clips',
        'pack',
        ['1/16 in', '1/8 in'],
        ['leveling system'],
      ),
    ),
  ]),
  _system('Trowels and Blades', [
    _type(
      'Notched Trowel',
      _variants(
        'Notched Trowel',
        'each',
        ['1/4 x 1/4 in', '1/4 x 3/8 in', '1/2 x 1/2 in'],
        ['tile trowel'],
      ),
    ),
    _type(
      'Tile Blade',
      _variants(
        'Wet Saw Tile Blade',
        'each',
        ['7 in', '10 in'],
        ['diamond blade'],
      ),
    ),
  ]),
]);
