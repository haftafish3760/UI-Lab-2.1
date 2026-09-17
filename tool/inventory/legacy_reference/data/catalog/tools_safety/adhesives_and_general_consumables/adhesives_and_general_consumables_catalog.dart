part of '../../../work_supply_catalog.dart';

final toolsSafetyAdhesivesAndGeneralConsumablesCategory = _category(
  'Adhesives and General Consumables',
  [
    _system('Tapes', [
      _type(
        'Duct Tape',
        _variants(
          'Duct Tape',
          'roll',
          ['1.88 in x 45 yd', '2 in x 60 yd'],
          ['utility tape'],
        ),
      ),
      _type(
        'Masking Tape',
        _variants(
          'Masking Tape',
          'roll',
          ['1 in', '1-1/2 in', '2 in'],
          ['paper tape'],
        ),
      ),
    ]),
    _system('Cleaning Supplies', [
      _type(
        'Shop Towels',
        _variants('Shop Towels', 'roll', ['blue roll', 'box'], ['rags']),
      ),
      _type(
        'Contractor Trash Bags',
        _variants(
          'Contractor Trash Bags',
          'box',
          ['33 gal', '42 gal', '55 gal'],
          ['demo bags'],
        ),
      ),
    ]),
  ],
);
