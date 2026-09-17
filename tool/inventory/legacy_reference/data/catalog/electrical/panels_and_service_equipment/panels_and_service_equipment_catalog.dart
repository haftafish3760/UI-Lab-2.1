part of '../../../work_supply_catalog.dart';

final electricalPanelsAndServiceEquipmentCategory = _category(
  'Panels and Service Equipment',
  [
    _system('Load Centers', [
      _type(
        'Main Lug Panels',
        _variants(
          'Main Lug Load Center',
          'each',
          ['100 Amp 12 space', '125 Amp 20 space', '200 Amp 30 space'],
          ['sub panel', 'load center'],
        ),
      ),
      _type(
        'Main Breaker Panels',
        _variants(
          'Main Breaker Load Center',
          'each',
          ['100 Amp 20 space', '150 Amp 30 space', '200 Amp 40 space'],
          ['breaker panel'],
        ),
      ),
    ]),
    _system('Service Hardware', [
      _type(
        'Panel Covers',
        _variants(
          'Panel Cover',
          'each',
          ['12 space', '20 space', '30 space', '40 space'],
          ['dead front', 'load center cover'],
        ),
      ),
      _type(
        'Neutral and Ground Bars',
        _variants(
          'Neutral Ground Bar Kit',
          'kit',
          ['small', 'medium', 'large'],
          ['ground bar', 'neutral bar'],
        ),
      ),
    ]),
  ],
);
