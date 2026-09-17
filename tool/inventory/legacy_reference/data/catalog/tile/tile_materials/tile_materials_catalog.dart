part of '../../../work_supply_catalog.dart';

final tileTileMaterialsCategory = _category('Tile Materials', [
  _system('Ceramic Tile', [
    _type(
      'Wall Tile',
      _variants(
        'Ceramic Wall Tile',
        'box',
        ['3 x 6 in', '4 x 4 in', '12 x 24 in'],
        ['subway tile', 'ceramic tile'],
      ),
    ),
    _type(
      'Floor Tile',
      _variants(
        'Ceramic Floor Tile',
        'box',
        ['12 x 12 in', '12 x 24 in', '18 x 18 in'],
        ['ceramic floor'],
      ),
    ),
  ]),
  _system('Porcelain Tile', [
    _type(
      'Floor Tile',
      _variants(
        'Porcelain Floor Tile',
        'box',
        ['12 x 24 in', '24 x 24 in', '6 x 36 in plank'],
        ['porcelain tile'],
      ),
    ),
    _type(
      'Mosaic Tile',
      _variants(
        'Porcelain Mosaic Tile',
        'sheet',
        ['2 x 2 in', 'hexagon', 'penny round'],
        ['mosaic sheet'],
      ),
    ),
  ]),
]);
