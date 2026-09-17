part of '../../../work_supply_catalog.dart';

final landscapingIrrigationCategory = _category('Irrigation', [
  _system('Pipe and Fittings', [
    _type(
      'Irrigation Pipe',
      _variants(
        'Irrigation Pipe',
        'roll',
        ['1/2 in', '3/4 in', '1 in'],
        ['poly pipe'],
      ),
    ),
    _type(
      'Drip Tubing',
      _variants(
        'Drip Irrigation Tubing',
        'roll',
        ['1/4 in x 50 ft', '1/2 in x 100 ft'],
        ['drip tubing', 'drip line'],
      ),
    ),
    _type(
      'Sprinkler Heads',
      _variants(
        'Sprinkler Head',
        'each',
        ['fixed spray', 'rotor', 'pop-up'],
        ['irrigation head'],
      ),
    ),
  ]),
]);
