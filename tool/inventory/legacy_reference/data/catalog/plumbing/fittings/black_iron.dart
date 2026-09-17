part of '../../../work_supply_catalog.dart';

final plumbingFittingsBlackIronSystem = _system('Black Iron', [
  _type(
    '90 Elbows',
    _variants('Black Iron 90 Elbow', 'each', _threadedSizes, [
      'iron 90',
      'threaded 90',
      'black pipe elbow',
    ]),
  ),
  _type(
    'Street 90 Elbows',
    _variants('Black Iron Street 90 Elbow', 'each', _threadedSizes, [
      'street 90',
      'street elbow',
    ]),
  ),
  _type(
    '45 Elbows',
    _variants('Black Iron 45 Elbow', 'each', _threadedSizes, [
      'iron 45',
      'threaded 45',
      'black pipe 45',
    ]),
  ),
  _type(
    'Tees',
    _variants('Black Iron Tee', 'each', _threadedSizes, [
      'threaded tee',
      'black pipe tee',
    ]),
  ),
  _type(
    'Couplings',
    _variants('Black Iron Coupling', 'each', _threadedSizes, [
      'threaded coupling',
      'black pipe coupling',
    ]),
  ),
  _type(
    'Reducer Bushings',
    _variants('Black Iron Reducer Bushing', 'each', _reducerSizes, [
      'black bushing',
      'threaded bushing',
      'reducing bushing',
    ]),
  ),
  _type(
    'Caps',
    _variants('Black Iron Cap', 'each', _threadedSizes, [
      'threaded cap',
      'black pipe cap',
    ]),
  ),
  _type(
    'Plugs',
    _variants('Black Iron Plug', 'each', _threadedSizes, [
      'threaded plug',
      'black pipe plug',
    ]),
  ),
  _type(
    'Unions',
    _variants('Black Iron Union', 'each', _threadedSizes, ['threaded union']),
  ),
  _type(
    'Nipples',
    _variants('Black Iron Nipple', 'each', _nippleSizes, [
      'pipe nipple',
      'threaded nipple',
    ]),
  ),
  _type(
    'Floor Flanges',
    _variants('Black Iron Floor Flange', 'each', _threadedSizes, [
      'pipe flange',
      'threaded flange',
      'floor flange',
    ]),
  ),
  ...plumbingGeneratedBlackIronFittingTypes,
]);
