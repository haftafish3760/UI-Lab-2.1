part of '../../../work_supply_catalog.dart';

final insulationBlownInsulationCategory = _category('Blown Insulation', [
  _system('Loose Fill', [
    _type(
      'Cellulose Insulation',
      _variants(
        'Cellulose Loose Fill Insulation',
        'bag',
        ['19 lb', '25 lb'],
        ['blown cellulose'],
      ),
    ),
    _type(
      'Fiberglass Loose Fill',
      _variants(
        'Fiberglass Loose Fill Insulation',
        'bag',
        ['25 lb', '30 lb'],
        ['blown fiberglass'],
      ),
    ),
  ]),
]);
