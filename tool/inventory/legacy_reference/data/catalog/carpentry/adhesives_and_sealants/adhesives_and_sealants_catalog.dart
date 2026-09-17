part of '../../../work_supply_catalog.dart';

final carpentryAdhesivesAndSealantsCategory = _category(
  'Adhesives and Sealants',
  [
    _system('Construction Adhesive', [
      _type(
        'Subfloor Adhesive',
        _variants(
          'Subfloor Adhesive',
          'tube',
          ['10 oz', '28 oz'],
          ['construction adhesive'],
        ),
      ),
      _type(
        'Panel Adhesive',
        _variants(
          'Panel Adhesive',
          'tube',
          ['10 oz', '28 oz'],
          ['foam board adhesive'],
        ),
      ),
    ]),
    _system('Wood Repair', [
      _type(
        'Wood Filler',
        _variants('Wood Filler', 'tub', ['6 oz', '16 oz', '32 oz'], ['putty']),
      ),
      _type(
        'Wood Glue',
        _variants(
          'Wood Glue',
          'bottle',
          ['8 oz', '16 oz', '1 gal'],
          ['carpenter glue'],
        ),
      ),
    ]),
  ],
);
