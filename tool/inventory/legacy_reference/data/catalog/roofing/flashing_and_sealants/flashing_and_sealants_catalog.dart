part of '../../../work_supply_catalog.dart';

final roofingFlashingAndSealantsCategory = _category('Flashing and Sealants', [
  _system('Flashing', [
    _type(
      'Step Flashing',
      _variants(
        'Step Flashing',
        'pack',
        ['4 x 4 x 8 in', '5 x 7 in'],
        ['roof flashing'],
      ),
    ),
    _type(
      'Drip Edge',
      _variants(
        'Drip Edge',
        'piece',
        ['10 ft white', '10 ft brown', '10 ft galvanized'],
        ['edge metal'],
      ),
    ),
  ]),
  _system('Sealants', [
    _type(
      'Roof and Gutter Sealant',
      _variants(
        'Roof and Gutter Sealant',
        'tube',
        ['10 oz', '28 oz'],
        ['gutter sealant', 'roof sealant', 'flashing sealant'],
      ),
    ),
  ]),
]);
