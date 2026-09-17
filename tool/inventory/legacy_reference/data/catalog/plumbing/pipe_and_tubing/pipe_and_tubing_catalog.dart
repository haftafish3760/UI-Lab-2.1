part of '../../../work_supply_catalog.dart';

final plumbingPipeAndTubingCategory = _category('Pipe and Tubing', [
  _system('Supply Pipe', [
    _type(
      'Copper Pipe',
      _variants('Copper Pipe', 'stick', _supplyPipe, [
        'type l copper',
        'type m copper',
        'hard copper',
        'copper stick',
      ]),
    ),
    _type(
      'Soft Copper Tubing',
      _variants(
        'Soft Copper Tubing',
        'roll',
        [
          '1/4 in x 10 ft',
          '1/4 in x 20 ft',
          '3/8 in x 20 ft',
          '1/2 in x 20 ft',
          '3/4 in x 20 ft',
          '1 in x 20 ft',
        ],
        ['copper roll', 'refrigeration copper', 'soft copper'],
      ),
    ),
    _type(
      'PEX Tubing',
      _variants('PEX Tubing', 'roll', _pexRolls, [
        'pex pipe',
        'pex roll',
        'pex a',
        'pex b',
      ]),
    ),
    _type(
      'CPVC Pipe',
      _variants('CPVC Pipe', 'stick', _supplyPipe, ['cpvc stick', 'cpvc pipe']),
    ),
    _type(
      'PVC Schedule 40 Pipe',
      _variants('PVC Schedule 40 Pipe', 'stick', _supplyPipe, [
        'pressure pipe',
        'sch40 pipe',
      ]),
    ),
  ]),
  _system('Drain Pipe', [
    _type(
      'PVC DWV Pipe',
      _variants('PVC DWV Pipe', 'stick', _dwvSizes, [
        'drain pipe',
        'sewer pipe',
      ]),
    ),
    _type(
      'ABS DWV Pipe',
      _variants('ABS DWV Pipe', 'stick', _dwvSizes, [
        'abs pipe',
        'black drain pipe',
      ]),
    ),
    _type(
      'Corrugated Drain Pipe',
      _variants(
        'Corrugated Drain Pipe',
        'roll',
        [
          '3 in x 10 ft',
          '4 in x 10 ft',
          '4 in x 25 ft',
          '4 in x 50 ft',
          '6 in x 20 ft',
        ],
        ['corrugated pipe', 'yard drain pipe', 'flex drain pipe'],
      ),
    ),
  ]),
]);
