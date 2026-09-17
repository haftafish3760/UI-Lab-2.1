part of '../../../work_supply_catalog.dart';

final toolsSafetyToolsCategory = _category('Tools', [
  _system('Hand Tools', [
    _type(
      'Wrenches',
      _variants(
        'Adjustable Wrench',
        'each',
        ['6 in', '8 in', '10 in', '12 in'],
        ['crescent wrench'],
      ),
    ),
    _type(
      'Hex Keys',
      _variants(
        'Hex Key Set',
        'set',
        ['SAE', 'metric', 'SAE and metric'],
        ['allen wrench'],
      ),
    ),
  ]),
  _system('Power Tool Consumables', [
    _type(
      'Saw Blades',
      _variants(
        'Circular Saw Blade',
        'each',
        ['6-1/2 in 24T', '7-1/4 in 24T', '7-1/4 in 60T'],
        ['skill saw blade'],
      ),
    ),
    _type(
      'Drill Bits',
      _variants(
        'Drill Bit Set',
        'set',
        ['twist bit', 'masonry bit', 'spade bit'],
        ['bits'],
      ),
    ),
    _type(
      'Utility Knife Blades',
      _variants(
        'Utility Knife Blades',
        'pack',
        ['10 pack', '50 pack', '100 pack'],
        ['razor blades', 'knife blade'],
      ),
    ),
  ]),
]);
