part of '../../../work_supply_catalog.dart';

final landscapingHardscapeCategory = _category('Hardscape', [
  _system('Pavers and Base', [
    _type(
      'Paver Stone',
      _variants(
        'Paver Stone',
        'each',
        ['4 x 8 in', '6 x 9 in', '12 x 12 in'],
        ['patio paver'],
      ),
    ),
    _type(
      'Paver Base',
      _variants('Paver Base', 'bag', ['0.5 cu ft', '40 lb'], ['patio base']),
    ),
  ]),
  _system('Mulch and Soil', [
    _type(
      'Mulch',
      _variants(
        'Bagged Mulch',
        'bag',
        ['2 cu ft black', '2 cu ft brown', '2 cu ft natural'],
        ['landscape mulch'],
      ),
    ),
    _type(
      'Topsoil',
      _variants('Topsoil', 'bag', ['40 lb', '0.75 cu ft'], ['dirt']),
    ),
  ]),
]);
