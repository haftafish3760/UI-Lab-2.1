part of '../../../work_supply_catalog.dart';

final plumbingFittingsPvcSchedule40System = _system('PVC Schedule 40', [
  _type(
    '90 Elbows',
    _variants('PVC Schedule 40 90 Elbow', 'each', _pipeSizes, [
      'pvc 90',
      'elbow',
      'ell',
    ]),
  ),
  _type(
    'Street 90 Elbows',
    _variants('PVC Schedule 40 Street 90 Elbow', 'each', _pipeSizes, [
      'street 90',
      'street elbow',
    ]),
  ),
  _type(
    '45 Elbows',
    _variants('PVC Schedule 40 45 Elbow', 'each', _pipeSizes, ['45', 'elbow']),
  ),
  _type(
    'Tees',
    _variants('PVC Schedule 40 Tee', 'each', _teeSizes, [
      'tee',
      't',
      't fitting',
      'pvc t',
      'reducing tee',
      'sch40 tee',
    ]),
  ),
  _type(
    'Couplings',
    _variants('PVC Schedule 40 Coupling', 'each', _pipeSizes, ['coupler']),
  ),
  _type(
    'Male Adapters',
    _variants('PVC Schedule 40 Male Adapter', 'each', _pipeSizes, [
      'pvc male adapter',
      'mip adapter',
      'slip x mip',
    ]),
  ),
  _type(
    'Female Adapters',
    _variants('PVC Schedule 40 Female Adapter', 'each', _pipeSizes, [
      'pvc female adapter',
      'fip adapter',
      'slip x fip',
    ]),
  ),
  _type(
    'Reducer Bushings',
    _variants('PVC Schedule 40 Reducer Bushing', 'each', _reducerSizes, [
      'pvc bushing',
      'reducing bushing',
      'spigot bushing',
    ]),
  ),
  _type(
    'Reducing Couplings',
    _variants('PVC Schedule 40 Reducing Coupling', 'each', _reducerSizes, [
      'pvc reducer',
      'pvc reducing coupling',
    ]),
  ),
  _type(
    'Caps',
    _variants('PVC Schedule 40 Cap', 'each', _pipeSizes, [
      'pvc cap',
      'slip cap',
    ]),
  ),
  _type(
    'Plugs',
    _variants('PVC Schedule 40 Plug', 'each', _pipeSizes, [
      'pvc plug',
      'threaded plug',
    ]),
  ),
  ...plumbingGeneratedPvcSchedule40FittingTypes,
]);
