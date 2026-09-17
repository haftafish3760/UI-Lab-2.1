part of '../../../work_supply_catalog.dart';

final roofingGuttersAndDrainageCategory = _category('Gutters and Drainage', [
  _system('Gutter Parts', [
    _type(
      'Gutter Section',
      _variants(
        'Gutter Section',
        'piece',
        ['5 in x 10 ft', '6 in x 10 ft'],
        ['rain gutter'],
      ),
    ),
    _type(
      'Downspout',
      _variants(
        'Downspout',
        'piece',
        ['2 x 3 x 10 ft', '3 x 4 x 10 ft'],
        ['gutter down pipe'],
      ),
    ),
  ]),
  _system('Gutter Fittings', [
    _type(
      'Gutter Elbow',
      _variants(
        'Gutter Elbow',
        'each',
        ['2 x 3 A elbow', '2 x 3 B elbow', '3 x 4 A elbow'],
        ['downspout elbow'],
      ),
    ),
  ]),
]);
