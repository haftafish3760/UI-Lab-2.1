part of '../../../work_supply_catalog.dart';

final masonryConcreteMasonryMaterialsCategory = _category('Masonry Materials', [
  _system('Block and Brick', [
    _type(
      'Concrete Block',
      _variants(
        'Concrete Block',
        'each',
        ['8 x 8 x 16 in', '4 x 8 x 16 in'],
        ['cmu', 'cinder block'],
      ),
    ),
    _type(
      'Brick',
      _variants('Clay Brick', 'each', ['modular', 'queen'], ['red brick']),
    ),
  ]),
]);
