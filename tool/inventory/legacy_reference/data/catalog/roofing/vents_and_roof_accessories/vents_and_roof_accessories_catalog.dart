part of '../../../work_supply_catalog.dart';

final roofingVentsAndRoofAccessoriesCategory = _category(
  'Vents and Roof Accessories',
  [
    _system('Roof Vents', [
      _type(
        'Static Roof Vent',
        _variants(
          'Static Roof Vent',
          'each',
          ['50 sq in', '60 sq in', '75 sq in'],
          ['box vent'],
        ),
      ),
      _type(
        'Ridge Vent',
        _variants(
          'Ridge Vent',
          'bundle',
          ['20 ft', '30 ft'],
          ['ridge ventilation'],
        ),
      ),
    ]),
    _system('Pipe Flashing', [
      _type(
        'Pipe Boot Flashing',
        _variants(
          'Pipe Boot Flashing',
          'each',
          ['1-1/2 in', '2 in', '3 in', '4 in'],
          ['roof boot'],
        ),
      ),
    ]),
  ],
);
