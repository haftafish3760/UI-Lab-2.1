part of '../../../work_supply_catalog.dart';

final carpentrySheetGoodsCategory = _category('Sheet Goods', [
  _system('Panels', [
    _type(
      'Plywood',
      _variants(
        'Plywood Sheet',
        'sheet',
        ['1/4 in 4 x 8', '1/2 in 4 x 8', '3/4 in 4 x 8'],
        ['plywood'],
      ),
    ),
    _type(
      'OSB',
      _variants(
        'OSB Sheet',
        'sheet',
        ['7/16 in 4 x 8', '1/2 in 4 x 8', '3/4 in 4 x 8'],
        ['osb'],
      ),
    ),
  ]),
]);
