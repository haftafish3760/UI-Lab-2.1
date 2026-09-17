part of '../../../work_supply_catalog.dart';

final hvacMotorsAndBlowerPartsCategory = _category('Motors and Blower Parts', [
  _system('Motors', [
    _type(
      'Blower Motors',
      _variants(
        'Blower Motor',
        'each',
        ['1/4 hp', '1/3 hp', '1/2 hp', '3/4 hp'],
        ['furnace motor', 'air handler motor'],
      ),
    ),
    _type(
      'Condenser Fan Motors',
      _variants(
        'Condenser Fan Motor',
        'each',
        ['1/6 hp', '1/4 hp', '1/3 hp'],
        ['outdoor fan motor'],
      ),
    ),
  ]),
  _system('Motor Parts', [
    _type(
      'Blower Wheels',
      _variants(
        'Blower Wheel',
        'each',
        ['10 x 8', '10 x 10', '11 x 10', '12 x 12'],
        ['squirrel cage'],
      ),
    ),
    _type(
      'Fan Blades',
      _variants(
        'Condenser Fan Blade',
        'each',
        ['18 in', '20 in', '22 in', '24 in'],
        ['fan propeller'],
      ),
    ),
  ]),
]);
