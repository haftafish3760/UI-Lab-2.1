part of '../../../work_supply_catalog.dart';

final plumbingFittingsAbsDwvSystem = _system('ABS DWV', [
  _type(
    '90 Elbows',
    _variants('ABS DWV 90 Elbow', 'each', _dwvSizes, [
      'abs 90',
      'black drain elbow',
      'abs elbow',
    ]),
  ),
  _type(
    '45 Elbows',
    _variants('ABS DWV 45 Elbow', 'each', _dwvSizes, [
      'abs 45',
      'black drain 45',
    ]),
  ),
  _type(
    'Wyes',
    _variants('ABS DWV Wye', 'each', _dwvSizes, [
      'abs wye',
      'black drain wye',
      'y fitting',
    ]),
  ),
  _type(
    'Sanitary Tees',
    _variants('ABS DWV Sanitary Tee', 'each', _dwvSizes, [
      'abs san tee',
      'black drain san tee',
      'sanitary t',
    ]),
  ),
  _type(
    'Couplings',
    _variants('ABS DWV Coupling', 'each', _dwvSizes, [
      'abs coupling',
      'black drain coupling',
    ]),
  ),
  _type(
    'Trap Adapters',
    _variants(
      'ABS DWV Trap Adapter',
      'each',
      ['1-1/2 in', '2 in'],
      ['abs trap adapter', 'black trap adapter'],
    ),
  ),
  _type(
    'Cleanouts',
    _variants('ABS DWV Cleanout', 'each', _dwvSizes, [
      'abs cleanout',
      'black cleanout',
      'cleanout plug',
    ]),
  ),
  ...plumbingGeneratedAbsDwvFittingTypes,
]);
