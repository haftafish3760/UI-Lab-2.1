part of '../../../work_supply_catalog.dart';

final drywallTapeBeadAndTrimCategory = _category('Tape Bead and Trim', [
  _system('Tape', [
    _type(
      'Paper Tape',
      _variants(
        'Paper Drywall Tape',
        'roll',
        ['75 ft', '250 ft', '500 ft'],
        ['joint tape'],
      ),
    ),
    _type(
      'Mesh Tape',
      _variants(
        'Fiberglass Mesh Tape',
        'roll',
        ['75 ft', '150 ft', '300 ft'],
        ['mesh joint tape'],
      ),
    ),
  ]),
  _system('Corner Bead', [
    _type(
      'Metal Corner Bead',
      _variants(
        'Metal Corner Bead',
        'piece',
        ['8 ft', '10 ft', '12 ft'],
        ['outside corner bead'],
      ),
    ),
    _type(
      'Vinyl Corner Bead',
      _variants(
        'Vinyl Corner Bead',
        'piece',
        ['8 ft', '10 ft', '12 ft'],
        ['plastic corner bead'],
      ),
    ),
    _type(
      'J Bead',
      _variants(
        'Drywall J Bead',
        'piece',
        ['8 ft', '10 ft', '12 ft'],
        ['j trim', 'edge bead'],
      ),
    ),
  ]),
]);
