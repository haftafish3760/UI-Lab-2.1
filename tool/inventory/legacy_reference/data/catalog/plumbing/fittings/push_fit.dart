part of '../../../work_supply_catalog.dart';

final plumbingFittingsPushFitSystem = _system('Push-Fit', [
  _type(
    '90 Elbows',
    _variants('Push-Fit 90 Elbow', 'each', _pushFitSizes, [
      'push to connect 90',
      'push elbow',
    ]),
  ),
  _type(
    'Tees',
    _variants('Push-Fit Tee', 'each', _pushFitTeeSizes, [
      'push tee',
      'push to connect tee',
    ]),
  ),
  _type(
    'Couplings',
    _variants('Push-Fit Coupling', 'each', _pushFitSizes, [
      'push coupling',
      'slip coupling',
    ]),
  ),
  _type(
    'Slip Couplings',
    _variants('Push-Fit Slip Coupling', 'each', _pushFitSizes, [
      'slip repair coupling',
      'push repair coupling',
    ]),
  ),
  _type(
    'Reducing Couplings',
    _variants('Push-Fit Reducing Coupling', 'each', _reducerSizes, [
      'push reducer',
      'push reducing coupling',
    ]),
  ),
  _type(
    'Male Adapters',
    _variants('Push-Fit Male Adapter', 'each', _pushFitSizes, [
      'push male adapter',
      'push mip adapter',
    ]),
  ),
  _type(
    'Female Adapters',
    _variants('Push-Fit Female Adapter', 'each', _pushFitSizes, [
      'push female adapter',
      'push fip adapter',
    ]),
  ),
  _type(
    'Caps',
    _variants('Push-Fit Cap', 'each', _pushFitSizes, ['push cap', 'end cap']),
  ),
  _type(
    'Ball Valves',
    _variants('Push-Fit Ball Valve', 'each', _pushFitSizes, [
      'push ball valve',
      'push connect ball valve',
      'sharkbite ball valve',
      'push shutoff valve',
    ]),
  ),
  _type(
    'Supply Stops',
    _variants(
      'Push-Fit Supply Stop',
      'each',
      ['1/2 x 3/8', '1/2 x 1/4'],
      ['push angle stop', 'push shutoff'],
    ),
  ),
  ...plumbingGeneratedPushFitFittingTypes,
]);
