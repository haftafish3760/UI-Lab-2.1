part of '../../../work_supply_catalog.dart';

final plumbingFittingsCastIronAndNoHubSystem = _system('Cast Iron and No-Hub', [
  _type(
    'No-Hub Couplings',
    _variants('No-Hub Coupling', 'each', _dwvSizes, [
      'shielded coupling',
      'cast iron coupling',
    ]),
  ),
  _type(
    'Reducing No-Hub Couplings',
    _variants('Reducing No-Hub Coupling', 'each', _dwvReducerSizes, [
      'no hub reducer',
      'shielded reducing coupling',
      'cast iron reducing coupling',
    ]),
  ),
  _type(
    'Compression Gaskets',
    _variants('Cast Iron Compression Gasket', 'each', _dwvSizes, [
      'cast iron gasket',
      'donut gasket',
      'service weight gasket',
      'soil pipe gasket',
    ]),
  ),
  _type(
    'No-Hub Bands',
    _variants('No-Hub Band Clamp', 'each', _dwvSizes, [
      'no hub band',
      'coupling band',
      'shielded band',
    ]),
  ),
]);
