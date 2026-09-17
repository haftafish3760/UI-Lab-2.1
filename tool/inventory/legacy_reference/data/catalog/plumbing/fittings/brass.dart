part of '../../../work_supply_catalog.dart';

final plumbingFittingsBrassSystem = _system('Brass', [
  _type(
    'Male Adapters',
    _variants('Brass Male Adapter', 'each', _supplySizes, [
      'brass adapter',
      'brass mip adapter',
      'male iron pipe adapter',
    ]),
  ),
  _type(
    'Female Adapters',
    _variants('Brass Female Adapter', 'each', _supplySizes, [
      'brass adapter',
      'brass fip adapter',
      'female iron pipe adapter',
    ]),
  ),
  _type(
    'Bushings',
    _variants('Brass Bushing', 'each', _reducerSizes, [
      'brass reducer',
      'reducing bushing',
    ]),
  ),
  _type(
    'Compression Unions',
    _variants('Brass Compression Union', 'each', _supplySizes, [
      'compression coupling',
      'brass compression fitting',
    ]),
  ),
  _type(
    'Compression Adapters',
    _variants('Brass Compression Adapter', 'each', _supplySizes, [
      'compression male adapter',
      'compression fitting',
    ]),
  ),
  _type(
    'Flare Fittings',
    _variants('Brass Flare Fitting', 'each', _supplySizes, [
      'flare adapter',
      'gas flare fitting',
    ]),
  ),
  _type(
    'Barbed Fittings',
    _variants('Brass Barb Fitting', 'each', _supplySizes, [
      'hose barb',
      'barb adapter',
    ]),
  ),
  _type(
    'Unions',
    _variants('Brass Union', 'each', _supplySizes, ['brass union']),
  ),
  _type(
    'Caps and Plugs',
    _variants('Brass Cap or Plug', 'each', _supplySizes, [
      'brass cap',
      'brass plug',
    ]),
  ),
  ...plumbingGeneratedBrassFittingTypes,
]);
