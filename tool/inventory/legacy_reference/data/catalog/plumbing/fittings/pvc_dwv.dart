part of '../../../work_supply_catalog.dart';

final plumbingFittingsPvcDwvSystem = _system('PVC DWV', [
  _type(
    '90 Elbows',
    _variants('PVC DWV 90 Elbow', 'each', _dwvSizes, ['dwv 90', 'drain elbow']),
  ),
  _type(
    '45 Elbows',
    _variants('PVC DWV 45 Elbow', 'each', _dwvSizes, ['dwv 45', 'drain 45']),
  ),
  _type(
    'Wyes',
    _variants('PVC DWV Wye', 'each', _dwvSizes, [
      'y fitting',
      'wye fitting',
      'why fitting',
    ]),
  ),
  _type(
    'Sanitary Tees',
    _variants('PVC DWV Sanitary Tee', 'each', _dwvSizes, [
      'san tee',
      'sanitary t',
    ]),
  ),
  _type(
    'Reducing Sanitary Tees',
    _variants('PVC DWV Reducing Sanitary Tee', 'each', _teeSizes, [
      'reducing san tee',
      'reducing sanitary t',
    ]),
  ),
  _type(
    'Couplings',
    _variants('PVC DWV Coupling', 'each', _dwvSizes, [
      'dwv coupling',
      'drain coupling',
    ]),
  ),
  _type(
    'Reducing Couplings',
    _variants('PVC DWV Reducing Coupling', 'each', _dwvReducerSizes, [
      'dwv reducer',
      'drain reducer',
    ]),
  ),
  _type(
    'Trap Adapters',
    _variants(
      'PVC DWV Trap Adapter',
      'each',
      ['1-1/2 in', '2 in'],
      ['trap adapter', 'marvel adapter'],
    ),
  ),
  _type(
    'Cleanouts',
    _variants('PVC DWV Cleanout', 'each', _dwvSizes, [
      'clean out',
      'cleanout plug',
    ]),
  ),
  _type(
    'Test Tees',
    _variants('PVC DWV Test Tee', 'each', _dwvSizes, [
      'test tee',
      'cleanout tee',
    ]),
  ),
  ...plumbingGeneratedPvcDwvFittingTypes,
]);
