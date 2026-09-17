part of '../../../work_supply_catalog.dart';

final plumbingFittingsCpvcSystem = _system('CPVC', [
  _type(
    '90 Elbows',
    _variants('CPVC 90 Elbow', 'each', _supplySizes, [
      'cpvc 90',
      'elbow',
      'ell',
    ]),
  ),
  _type(
    'Tees',
    _variants('CPVC Tee', 'each', _teeSizes, [
      'tee',
      't',
      'cpvc t',
      'reducing tee',
    ]),
  ),
  _type(
    'Couplings',
    _variants('CPVC Coupling', 'each', _supplySizes, ['coupler', 'cpvc cplg']),
  ),
  _type(
    'Male Adapters',
    _variants('CPVC Male Adapter', 'each', _supplySizes, [
      'cpvc male adapter',
      'cpvc mip adapter',
    ]),
  ),
  _type(
    'Female Adapters',
    _variants('CPVC Female Adapter', 'each', _supplySizes, [
      'cpvc female adapter',
      'cpvc fip adapter',
    ]),
  ),
  _type(
    'Transition Adapters',
    _variants('CPVC Transition Adapter', 'each', _supplySizes, [
      'cpvc transition',
      'cpvc copper adapter',
    ]),
  ),
  _type(
    'Caps',
    _variants('CPVC Cap', 'each', _supplySizes, ['cpvc cap', 'end cap']),
  ),
  _type(
    'Reducer Bushings',
    _variants('CPVC Reducer Bushing', 'each', _reducerSizes, [
      'cpvc bushing',
      'reducing bushing',
    ]),
  ),
  ...plumbingGeneratedCpvcFittingTypes,
]);
