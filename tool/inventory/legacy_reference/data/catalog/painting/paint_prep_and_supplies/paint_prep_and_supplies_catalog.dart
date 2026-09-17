part of '../../../work_supply_catalog.dart';

final drywallPaintPaintPrepAndSuppliesCategory = _category(
  'Paint Prep and Supplies',
  [
    _system('Abrasives', [
      _type(
        'Sanding Screens',
        _variants(
          'Drywall Sanding Screen',
          'pack',
          ['80 grit', '120 grit', '220 grit'],
          ['sanding mesh'],
        ),
      ),
      _type(
        'Sanding Sponges',
        _variants(
          'Sanding Sponge',
          'each',
          ['medium', 'fine', 'extra fine'],
          ['sponge sander'],
        ),
      ),
    ]),
    _system('Painting Supplies', [
      _type(
        'Paint Rollers',
        _variants(
          'Paint Roller Cover',
          'each',
          ['3/8 in nap', '1/2 in nap', '3/4 in nap'],
          ['roller sleeve'],
        ),
      ),
      _type(
        'Painter Tape',
        _variants(
          'Painter Tape',
          'roll',
          ['1 in', '1-1/2 in', '2 in'],
          ['masking tape'],
        ),
      ),
    ]),
  ],
);
