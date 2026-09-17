part of '../../../work_supply_catalog.dart';

final roofingRoofCoveringCategory = _category('Roof Covering', [
  _system('Shingles', [
    _type(
      'Asphalt Shingles',
      _variants(
        'Asphalt Shingles',
        'bundle',
        ['3-tab bundle', 'architectural bundle'],
        ['roof shingles'],
      ),
    ),
  ]),
  _system('Underlayment', [
    _type(
      'Roof Underlayment',
      _variants(
        'Roof Underlayment',
        'roll',
        ['synthetic 10 sq', 'felt 15 lb', 'felt 30 lb'],
        ['felt paper'],
      ),
    ),
  ]),
]);
