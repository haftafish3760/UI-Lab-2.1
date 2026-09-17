part of '../../../work_supply_catalog.dart';

final electricalWireAndCableCategory = _category('Wire and Cable', [
  _system('NM-B Cable', [
    _type(
      'Residential Cable',
      _variants(
        'NM-B Cable',
        'roll',
        ['14/2', '14/3', '12/2', '12/3', '10/2', '10/3'],
        ['romex', 'house wire', 'with ground', 'w ground', 'wg'],
      ),
    ),
  ]),
  _system('Conduit Wire', [
    _type(
      'THHN Wire',
      _variants(
        'THHN Wire',
        'roll',
        ['14 AWG', '12 AWG', '10 AWG', '8 AWG', '6 AWG'],
        ['stranded wire', 'solid wire'],
      ),
    ),
  ]),
]);
