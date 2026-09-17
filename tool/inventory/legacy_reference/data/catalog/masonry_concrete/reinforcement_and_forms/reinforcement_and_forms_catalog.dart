part of '../../../work_supply_catalog.dart';

final masonryConcreteReinforcementAndFormsCategory = _category(
  'Reinforcement and Forms',
  [
    _system('Rebar and Mesh', [
      _type(
        'Rebar',
        _variants(
          'Rebar',
          'piece',
          ['#3 x 10 ft', '#4 x 10 ft', '#5 x 10 ft'],
          ['reinforcing bar'],
        ),
      ),
      _type(
        'Wire Mesh',
        _variants(
          'Concrete Wire Mesh',
          'sheet',
          ['42 x 84 in', '5 x 10 ft'],
          ['remesh'],
        ),
      ),
    ]),
    _system('Forms', [
      _type(
        'Form Board',
        _variants(
          'Concrete Form Board',
          'piece',
          ['1 x 4 x 8 ft', '2 x 4 x 8 ft', '2 x 6 x 8 ft'],
          ['form lumber'],
        ),
      ),
    ]),
  ],
);
