part of '../../../work_supply_catalog.dart';

final electricalBreakersCategory = _category('Breakers', [
  _system('Standard Breakers', [
    _type(
      'Single-Pole Breakers',
      _variants(
        'Single-Pole Breaker',
        'each',
        ['15 Amp', '20 Amp', '30 Amp'],
        ['1 pole breaker'],
      ),
    ),
    _type(
      'Double-Pole Breakers',
      _variants(
        'Double-Pole Breaker',
        'each',
        ['20 Amp', '30 Amp', '40 Amp', '50 Amp', '60 Amp'],
        ['2 pole breaker'],
      ),
    ),
  ]),
  _system('Protection Breakers', [
    _type(
      'GFCI Breakers',
      _variants(
        'GFCI Breaker',
        'each',
        ['15 Amp Single-Pole', '20 Amp Single-Pole', '30 Amp Double-Pole'],
        ['ground fault breaker'],
      ),
    ),
    _type(
      'AFCI Breakers',
      _variants(
        'AFCI Breaker',
        'each',
        ['15 Amp Single-Pole', '20 Amp Single-Pole'],
        ['arc fault breaker'],
      ),
    ),
  ]),
]);
