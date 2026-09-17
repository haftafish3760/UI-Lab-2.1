part of '../../../work_supply_catalog.dart';

final insulationVaporBarriersAndAccessoriesCategory = _category(
  'Vapor Barriers and Accessories',
  [
    _system('Barriers', [
      _type(
        'Poly Vapor Barrier',
        _variants(
          'Poly Vapor Barrier',
          'roll',
          ['4 mil 10 x 100 ft', '6 mil 10 x 100 ft'],
          ['plastic sheeting'],
        ),
      ),
      _type(
        'House Wrap Tape',
        _variants(
          'House Wrap Tape',
          'roll',
          ['1-7/8 in x 165 ft', '3 in x 165 ft'],
          ['seam tape'],
        ),
      ),
    ]),
    _system('Fastening', [
      _type(
        'Insulation Supports',
        _variants(
          'Insulation Support Wire',
          'pack',
          ['16 in', '24 in'],
          ['insulation hanger'],
        ),
      ),
    ]),
  ],
);
