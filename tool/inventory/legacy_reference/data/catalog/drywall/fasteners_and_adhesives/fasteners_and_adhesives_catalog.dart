part of '../../../work_supply_catalog.dart';

final drywallFastenersAndAdhesivesCategory = _category(
  'Fasteners and Adhesives',
  [
    _system('Fasteners', [
      _type(
        'Coarse Thread Drywall Screws',
        _variants(
          'Coarse Thread Drywall Screws',
          'box',
          ['#6 x 1 in', '#6 x 1-1/4 in', '#6 x 1-5/8 in', '#8 x 2 in'],
          ['wood stud drywall screws'],
        ),
      ),
      _type(
        'Fine Thread Drywall Screws',
        _variants(
          'Fine Thread Drywall Screws',
          'box',
          ['#6 x 1 in', '#6 x 1-1/4 in', '#6 x 1-5/8 in'],
          ['metal stud drywall screws'],
        ),
      ),
      _type(
        'Drywall Nails',
        _variants(
          'Drywall Nails',
          'box',
          ['1-1/4 in', '1-3/8 in', '1-5/8 in'],
          ['sheetrock nails'],
        ),
      ),
    ]),
    _system('Adhesives', [
      _type(
        'Drywall Adhesive',
        _variants(
          'Drywall Adhesive',
          'tube',
          ['10 oz', '28 oz'],
          ['panel adhesive', 'sheetrock adhesive'],
        ),
      ),
    ]),
  ],
);
