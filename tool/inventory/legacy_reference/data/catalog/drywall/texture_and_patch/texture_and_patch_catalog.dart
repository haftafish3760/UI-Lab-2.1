part of '../../../work_supply_catalog.dart';

final drywallTextureAndPatchCategory = _category('Texture and Patch', [
  _system('Patch Materials', [
    _type(
      'Spackling Compound',
      _variants(
        'Spackling Compound',
        'tub',
        ['8 oz', '16 oz', '32 oz', '1 gal'],
        ['spackle', 'patch compound'],
      ),
    ),
    _type(
      'Drywall Repair Patch',
      _variants(
        'Drywall Repair Patch',
        'pack',
        ['4 x 4 in', '6 x 6 in', '8 x 8 in'],
        ['wall patch'],
      ),
    ),
  ]),
  _system('Texture', [
    _type(
      'Wall Texture Spray',
      _variants(
        'Wall Texture Spray',
        'can',
        ['orange peel', 'knockdown', 'popcorn'],
        ['texture can'],
      ),
    ),
    _type(
      'Texture Mix',
      _variants(
        'Drywall Texture Mix',
        'bag',
        ['15 lb', '25 lb', '40 lb'],
        ['wall texture powder'],
      ),
    ),
  ]),
]);
