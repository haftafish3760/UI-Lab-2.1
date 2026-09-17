part of '../../../work_supply_catalog.dart';

final carpentryFastenersCategory = _category('Fasteners', [
  _system('Screws', [
    _type(
      'Wood Screws',
      _variants(
        'Wood Screws',
        'box',
        ['#8 x 1-1/4 in', '#8 x 1-5/8 in', '#10 x 2 in'],
        ['wood screw', 'wood screws'],
      ),
    ),
    _type(
      'Deck Screws',
      _variants(
        'Deck Screws',
        'box',
        ['#8 x 1-5/8 in', '#9 x 2-1/2 in', '#10 x 3 in'],
        ['porch screws'],
      ),
    ),
    _type(
      'Drywall Screws',
      _variants(
        'Drywall Screws',
        'box',
        ['#6 x 1-1/4 in', '#6 x 1-5/8 in', '#8 x 2 in'],
        ['sheetrock screws'],
      ),
    ),
  ]),
  _system('Nails', [
    _type(
      'Framing Nails',
      _variants('Framing Nails', 'box', ['8d', '10d', '16d'], ['common nail']),
    ),
  ]),
]);
