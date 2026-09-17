part of '../../../work_supply_catalog.dart';

final electricalConnectorsAndConsumablesCategory = _category(
  'Connectors and Consumables',
  [
    _system('Wire Connectors', [
      _type(
        'Wire Nuts',
        _variants(
          'Wire Connector',
          'pack',
          ['small', 'medium', 'large', 'winged'],
          ['wire nut'],
        ),
      ),
    ]),
    _system('Tape and Fastening', [
      _type(
        'Electrical Tape',
        _variants(
          'Electrical Tape',
          'roll',
          ['3/4 in x 60 ft'],
          ['black tape', 'elec tape', 'electric tape'],
        ),
      ),
      _type(
        'Cable Staples',
        _variants(
          'Cable Staples',
          'pack',
          ['14/2-12/2', '10/2-8/2'],
          ['romex staple'],
        ),
      ),
    ]),
  ],
);
