part of '../../../work_supply_catalog.dart';

final carpentryLumberCategory = _category('Lumber', [
  _system('Dimensional Lumber', [
    _type(
      'Studs and Framing',
      _variants(
        'Dimensional Lumber',
        'piece',
        ['2 x 4 x 8 ft', '2 x 4 x 10 ft', '2 x 6 x 8 ft', '2 x 6 x 12 ft'],
        ['stud', 'kd stud', 'kiln dried stud', 'framing lumber'],
      ),
    ),
    _type(
      'Posts',
      _variants(
        'Pressure Treated Post',
        'piece',
        ['4 x 4 x 8 ft', '4 x 4 x 10 ft', '6 x 6 x 8 ft'],
        ['deck post'],
      ),
    ),
  ]),
]);
