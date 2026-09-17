part of '../../../work_supply_catalog.dart';

final electricalGroundingAndBondingCategory = _category(
  'Grounding and Bonding',
  [
    _system('Grounding Electrode', [
      _type(
        'Ground Rods',
        _variants(
          'Copper Ground Rod',
          'each',
          ['5/8 in x 8 ft', '3/4 in x 10 ft'],
          ['grounding rod'],
        ),
      ),
      _type(
        'Ground Clamps',
        _variants(
          'Ground Clamp',
          'each',
          ['1/2 in', '5/8 in', '3/4 in', '1 in'],
          ['acorn clamp', 'bonding clamp'],
        ),
      ),
    ]),
    _system('Bonding Conductors', [
      _type(
        'Bare Copper Ground Wire',
        _variants(
          'Bare Copper Ground Wire',
          'roll',
          ['14 AWG', '12 AWG', '10 AWG', '8 AWG', '6 AWG', '4 AWG'],
          ['bare copper', 'ground wire'],
        ),
      ),
      _type(
        'Bonding Jumpers',
        _variants(
          'Bonding Jumper',
          'each',
          ['6 in', '8 in', '12 in'],
          ['bond jumper'],
        ),
      ),
    ]),
  ],
);
