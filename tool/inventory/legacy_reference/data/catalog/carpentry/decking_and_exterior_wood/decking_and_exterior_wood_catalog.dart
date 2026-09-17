part of '../../../work_supply_catalog.dart';

final carpentryDeckingAndExteriorWoodCategory = _category(
  'Decking and Exterior Wood',
  [
    _system('Deck Boards', [
      _type(
        'Pressure Treated Deck Board',
        _variants(
          'Pressure Treated Deck Board',
          'piece',
          [
            '5/4 x 6 x 8 ft',
            '5/4 x 6 x 10 ft',
            '5/4 x 6 x 12 ft',
            '5/4 x 6 x 16 ft',
            '2 x 6 x 8 ft',
            '2 x 6 x 12 ft',
            '2 x 6 x 16 ft',
          ],
          ['decking board', 'deck board'],
        ),
      ),
      _type(
        'Composite Deck Board',
        _variants(
          'Composite Deck Board',
          'piece',
          ['12 ft', '16 ft', '20 ft', 'grooved 12 ft', 'grooved 16 ft'],
          ['composite decking', 'trex style board'],
        ),
      ),
      _type(
        'PVC Deck Board',
        _variants(
          'PVC Deck Board',
          'piece',
          ['12 ft', '16 ft', '20 ft'],
          ['cellular pvc decking'],
        ),
      ),
    ]),
    _system('Deck Framing', [
      _type(
        'Pressure Treated Joist',
        _variants(
          'Pressure Treated Joist',
          'piece',
          ['2 x 6 x 8 ft', '2 x 8 x 10 ft', '2 x 8 x 12 ft', '2 x 10 x 12 ft'],
          ['deck joist'],
        ),
      ),
      _type(
        'Ledger Board',
        _variants(
          'Pressure Treated Ledger Board',
          'piece',
          ['2 x 8 x 12 ft', '2 x 10 x 12 ft', '2 x 12 x 12 ft'],
          ['deck ledger'],
        ),
      ),
      _type(
        'Deck Post',
        _variants(
          'Pressure Treated Deck Post',
          'piece',
          ['4 x 4 x 8 ft', '4 x 4 x 10 ft', '6 x 6 x 8 ft', '6 x 6 x 10 ft'],
          ['treated post'],
        ),
      ),
    ]),
    _system('Deck Fasteners', [
      _type(
        'Exterior Deck Screws',
        _variants(
          'Exterior Deck Screws',
          'box',
          ['#8 x 1-5/8 in', '#9 x 2-1/2 in', '#10 x 3 in', '#10 x 3-1/2 in'],
          ['decking screws', 'porch screws'],
        ),
      ),
      _type(
        'Hidden Deck Fasteners',
        _variants(
          'Hidden Deck Fasteners',
          'box',
          ['90 count', '175 count', '350 count'],
          ['deck clips', 'grooved board fasteners'],
        ),
      ),
      _type(
        'Structural Deck Screws',
        _variants(
          'Structural Deck Screws',
          'box',
          ['1/4 x 3 in', '1/4 x 4 in', '5/16 x 5 in'],
          ['ledger screws', 'structural screws'],
        ),
      ),
    ]),
    _system('Railing and Stairs', [
      _type(
        'Deck Baluster',
        _variants(
          'Deck Baluster',
          'pack',
          ['26 in aluminum', '29 in aluminum', '32 in aluminum'],
          ['spindle'],
        ),
      ),
      _type(
        'Stair Stringer',
        _variants(
          'Pressure Treated Stair Stringer',
          'piece',
          ['2 step', '3 step', '4 step', '5 step', '6 step'],
          ['deck stringer'],
        ),
      ),
      _type(
        'Stair Tread',
        _variants(
          'Deck Stair Tread',
          'piece',
          ['2 x 12 x 4 ft', '2 x 12 x 6 ft', '5/4 x 12 x 4 ft'],
          ['deck tread'],
        ),
      ),
    ]),
    _system('Exterior Trim and Protection', [
      _type(
        'PVC Trim Board',
        _variants(
          'PVC Trim Board',
          'piece',
          ['1 x 4 x 8 ft', '1 x 6 x 8 ft', '1 x 8 x 8 ft', '1 x 12 x 8 ft'],
          ['azek style trim'],
        ),
      ),
      _type(
        'Joist Tape',
        _variants(
          'Deck Joist Tape',
          'roll',
          ['2 in x 50 ft', '4 in x 50 ft', '6 in x 50 ft'],
          ['butyl joist tape', 'flashing tape'],
        ),
      ),
    ]),
  ],
);
