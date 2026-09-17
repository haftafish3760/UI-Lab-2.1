part of '../../../work_supply_catalog.dart';

final tileSettingMaterialsCategory = _category('Setting Materials', [
  _system('Mortar and Adhesive', [
    _type(
      'Thinset Mortar',
      _variants(
        'Thinset Mortar',
        'bag',
        ['white 50 lb', 'gray 50 lb', 'modified 50 lb'],
        ['thin set', 'tile mortar'],
      ),
    ),
    _type(
      'Mastic',
      _variants(
        'Tile Mastic',
        'bucket',
        ['1 gal', '3.5 gal'],
        ['tile adhesive'],
      ),
    ),
  ]),
  _system('Grout', [
    _type(
      'Sanded Grout',
      _variants('Sanded Grout', 'bag', ['10 lb', '25 lb'], ['tile grout']),
    ),
    _type(
      'Unsanded Grout',
      _variants(
        'Unsanded Grout',
        'bag',
        ['10 lb', '25 lb'],
        ['non sanded grout'],
      ),
    ),
    _type(
      'Grout Sealer',
      _variants('Grout Sealer', 'bottle', ['16 oz', '32 oz'], ['tile sealer']),
    ),
  ]),
]);
