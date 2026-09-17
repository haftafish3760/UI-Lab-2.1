part of '../../../work_supply_catalog.dart';

final masonryConcreteAnchorsAndRepairCategory = _category(
  'Anchors and Repair',
  [
    _system('Anchors', [
      _type(
        'Wedge Anchors',
        _variants(
          'Wedge Anchor',
          'pack',
          ['1/4 x 2-1/4 in', '3/8 x 3 in', '1/2 x 4-1/4 in'],
          ['concrete anchor'],
        ),
      ),
      _type(
        'Tapcon Screws',
        _variants(
          'Concrete Screw Anchor',
          'box',
          ['3/16 x 1-1/4 in', '1/4 x 2-3/4 in'],
          ['tapcon'],
        ),
      ),
    ]),
    _system('Concrete Repair', [
      _type(
        'Concrete Patch',
        _variants(
          'Concrete Patch',
          'tub',
          ['1 qt', '1 gal', '20 lb'],
          ['patch compound'],
        ),
      ),
    ]),
  ],
);
