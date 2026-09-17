part of '../../../work_supply_catalog.dart';

final plumbingFittingsGalvanizedSteelSystem = _system('Galvanized Steel', [
  _type(
    '90 Elbows',
    _variants('Galvanized 90 Elbow', 'each', _threadedSizes, [
      'galv 90',
      'threaded galvanized elbow',
    ]),
  ),
  _type(
    '45 Elbows',
    _variants('Galvanized 45 Elbow', 'each', _threadedSizes, [
      'galv 45',
      'threaded galvanized 45',
    ]),
  ),
  _type(
    'Tees',
    _variants('Galvanized Tee', 'each', _threadedSizes, [
      'galv tee',
      'threaded galvanized tee',
    ]),
  ),
  _type(
    'Couplings',
    _variants('Galvanized Coupling', 'each', _threadedSizes, [
      'galv coupling',
      'threaded coupling',
    ]),
  ),
  _type(
    'Reducer Bushings',
    _variants('Galvanized Reducer Bushing', 'each', _reducerSizes, [
      'galv bushing',
      'galvanized bushing',
      'reducing bushing',
    ]),
  ),
  _type(
    'Caps',
    _variants('Galvanized Cap', 'each', _threadedSizes, [
      'galv cap',
      'threaded cap',
    ]),
  ),
  _type(
    'Plugs',
    _variants('Galvanized Plug', 'each', _threadedSizes, [
      'galv plug',
      'threaded plug',
    ]),
  ),
  _type(
    'Nipples',
    _variants('Galvanized Nipple', 'each', _nippleSizes, [
      'galv nipple',
      'threaded nipple',
    ]),
  ),
  _type(
    'Unions',
    _variants('Galvanized Union', 'each', _threadedSizes, [
      'galv union',
      'threaded union',
    ]),
  ),
  ...plumbingGeneratedGalvanizedFittingTypes,
]);
