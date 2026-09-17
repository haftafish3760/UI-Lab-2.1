part of '../../../work_supply_catalog.dart';

final landscapingDrainageAndErosionCategory = _category(
  'Drainage and Erosion',
  [
    _system('Landscape Drainage', [
      _type(
        'Corrugated Drain Pipe',
        _variants(
          'Corrugated Drain Pipe',
          'roll',
          ['3 in x 10 ft', '4 in x 10 ft', '4 in x 100 ft'],
          ['french drain pipe'],
        ),
      ),
      _type(
        'Catch Basins',
        _variants(
          'Catch Basin',
          'each',
          ['9 x 9 in', '12 x 12 in', '18 x 18 in'],
          ['drain box'],
        ),
      ),
    ]),
    _system('Erosion Control', [
      _type(
        'Straw Wattle',
        _variants(
          'Straw Wattle',
          'roll',
          ['9 in x 10 ft', '12 in x 10 ft'],
          ['erosion wattle'],
        ),
      ),
    ]),
  ],
);
