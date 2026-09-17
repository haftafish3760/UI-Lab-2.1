part of '../../../work_supply_catalog.dart';

final hvacRefrigerantLinesCategory = _category('Refrigerant Lines', [
  _system('Line Sets', [
    _type(
      'Copper Line Sets',
      _variants(
        'Copper Line Set',
        'set',
        ['1/4 x 3/8', '1/4 x 1/2', '3/8 x 3/4', '3/8 x 7/8'],
        ['refrigerant line set'],
      ),
    ),
    _type(
      'Line Set Insulation',
      _variants(
        'Line Set Insulation',
        'stick',
        ['3/8 in', '1/2 in', '3/4 in', '7/8 in', '1-1/8 in'],
        ['armaflex'],
      ),
    ),
    _type(
      'ACR Copper Tubing',
      _variants(
        'ACR Copper Tubing',
        'coil',
        ['1/4 in', '3/8 in', '1/2 in', '5/8 in', '3/4 in', '7/8 in'],
        ['refrigeration copper tubing', 'soft acr copper'],
      ),
    ),
  ]),
]);
