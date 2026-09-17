part of '../../../work_supply_catalog.dart';

final drywallPaintCaulkAndPatchCategory = _category('Caulk and Patch', [
  _system('Patching', [
    _type(
      'Spackling Compound',
      _variants(
        'Spackling Compound',
        'tub',
        ['8 oz', '16 oz', '32 oz'],
        ['spackle'],
      ),
    ),
    _type(
      'Texture Repair',
      _variants(
        'Wall Texture Spray',
        'can',
        ['orange peel', 'knockdown', 'popcorn'],
        ['texture can'],
      ),
    ),
  ]),
  _system('Caulk', [
    _type(
      'Paintable Caulk',
      _variants(
        'Paintable Caulk',
        'tube',
        ['10 oz white', '10 oz clear'],
        ['acrylic latex caulk'],
      ),
    ),
  ]),
]);
