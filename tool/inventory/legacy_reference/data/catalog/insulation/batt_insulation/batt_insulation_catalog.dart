part of '../../../work_supply_catalog.dart';

final insulationBattInsulationCategory = _category('Batt Insulation', [
  _system('Fiberglass', [
    _type(
      'Wall Batts',
      _variants(
        'Fiberglass Batt Insulation',
        'bag',
        ['R-13 15 in x 93 in', 'R-15 15 in x 93 in', 'R-19 23 in x 93 in'],
        ['batt insulation'],
      ),
    ),
    _type(
      'Ceiling Batts',
      _variants(
        'Fiberglass Ceiling Batt',
        'bag',
        ['R-30 16 in', 'R-30 24 in', 'R-38 24 in'],
        ['attic batt'],
      ),
    ),
  ]),
  _system('Mineral Wool', [
    _type(
      'Fire and Sound Batts',
      _variants(
        'Mineral Wool Batt',
        'bag',
        ['R-15 15 in', 'R-23 23 in'],
        ['rock wool', 'sound batt'],
      ),
    ),
  ]),
]);
