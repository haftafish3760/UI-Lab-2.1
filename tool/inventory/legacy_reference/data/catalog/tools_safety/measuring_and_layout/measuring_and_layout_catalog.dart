part of '../../../work_supply_catalog.dart';

final toolsSafetyMeasuringAndLayoutCategory = _category(
  'Measuring and Layout',
  [
    _system('Measuring', [
      _type(
        'Tape Measures',
        _variants(
          'Tape Measure',
          'each',
          ['16 ft', '25 ft', '35 ft'],
          ['measuring tape'],
        ),
      ),
      _type(
        'Levels',
        _variants(
          'Level',
          'each',
          ['9 in torpedo', '24 in', '48 in', '72 in'],
          ['spirit level'],
        ),
      ),
    ]),
    _system('Marking', [
      _type(
        'Markers',
        _variants(
          'Jobsite Marker',
          'pack',
          ['black', 'red', 'silver'],
          ['sharpie style marker'],
        ),
      ),
      _type(
        'Chalk Line',
        _variants(
          'Chalk Line Reel',
          'each',
          ['50 ft', '100 ft'],
          ['snap line'],
        ),
      ),
    ]),
  ],
);
