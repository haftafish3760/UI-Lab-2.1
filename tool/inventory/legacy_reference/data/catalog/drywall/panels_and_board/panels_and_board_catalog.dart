part of '../../../work_supply_catalog.dart';

final drywallPanelsCategory = _category('Panels and Board', [
  _system('Drywall Sheets', [
    _type(
      'Regular Drywall',
      _variants(
        'Regular Drywall Sheet',
        'sheet',
        ['1/4 in 4 x 8', '3/8 in 4 x 8', '1/2 in 4 x 8', '1/2 in 4 x 12'],
        ['sheetrock', 'gypsum board'],
      ),
    ),
    _type(
      'Moisture Resistant Drywall',
      _variants(
        'Moisture Resistant Drywall Sheet',
        'sheet',
        ['1/2 in 4 x 8', '1/2 in 4 x 12', '5/8 in 4 x 8'],
        ['green board', 'bath drywall'],
      ),
    ),
    _type(
      'Fire Rated Drywall',
      _variants(
        'Fire Rated Drywall Sheet',
        'sheet',
        ['5/8 in 4 x 8', '5/8 in 4 x 10', '5/8 in 4 x 12'],
        ['type x drywall', 'firecode sheetrock'],
      ),
    ),
  ]),
]);
