part of '../../../work_supply_catalog.dart';

final insulationFoamAndAirSealingCategory = _category('Foam and Air Sealing', [
  _system('Spray Foam', [
    _type(
      'Canned Foam',
      _variants(
        'Expanding Spray Foam',
        'can',
        ['12 oz gap and crack', '16 oz window and door'],
        ['foam sealant'],
      ),
    ),
  ]),
  _system('Foam Board', [
    _type(
      'Rigid Foam Board',
      _variants(
        'Rigid Foam Board',
        'sheet',
        ['1/2 in 4 x 8', '1 in 4 x 8', '2 in 4 x 8'],
        ['foam board'],
      ),
    ),
  ]),
]);
