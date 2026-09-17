part of '../../../work_supply_catalog.dart';

final drywallPaintPaintCategory = _category('Paint', [
  _system('Coatings', [
    _type(
      'Interior Paint',
      _variants(
        'Interior Paint',
        'can',
        ['quart', '1 gal', '5 gal'],
        ['wall paint'],
      ),
    ),
    _type(
      'Primer',
      _variants('Primer', 'can', ['quart', '1 gal', '5 gal'], ['paint primer']),
    ),
  ]),
]);
