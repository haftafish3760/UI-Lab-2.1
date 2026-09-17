part of '../../../work_supply_catalog.dart';

final carpentryConnectorsAndFramingHardwareCategory = _category(
  'Connectors and Framing Hardware',
  [
    _system('Joist and Beam Hardware', [
      _type(
        'Joist Hangers',
        _variants(
          'Joist Hanger',
          'each',
          ['2 x 6', '2 x 8', '2 x 10', '2 x 12'],
          ['hanger bracket'],
        ),
      ),
      _type(
        'Post Bases',
        _variants('Post Base', 'each', ['4 x 4', '6 x 6'], ['column base']),
      ),
    ]),
    _system('Angles and Ties', [
      _type(
        'Hurricane Ties',
        _variants(
          'Hurricane Tie',
          'each',
          ['left', 'right', 'universal'],
          ['rafter tie'],
        ),
      ),
      _type(
        'Angle Brackets',
        _variants(
          'Angle Bracket',
          'each',
          ['2 in', '3 in', '4 in'],
          ['l bracket'],
        ),
      ),
    ]),
  ],
);
