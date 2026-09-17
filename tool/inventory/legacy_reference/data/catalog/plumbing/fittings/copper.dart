part of '../../../work_supply_catalog.dart';

final plumbingFittingsCopperSystem = _system('Copper', [
  _type(
    '90 Elbows',
    _variants('Copper 90 Elbow', 'each', _supplySizes, [
      '90',
      'elbow',
      'ell',
      'sweat 90',
    ]),
  ),
  _type(
    'Street 90 Elbows',
    _variants('Copper Street 90 Elbow', 'each', _supplySizes, [
      'street 90',
      'street elbow',
      'street ell',
    ]),
  ),
  _type(
    '45 Elbows',
    _variants('Copper 45 Elbow', 'each', _supplySizes, [
      '45',
      'elbow',
      'sweat 45',
    ]),
  ),
  _type(
    'Street 45 Elbows',
    _variants('Copper Street 45 Elbow', 'each', _supplySizes, [
      'street 45',
      'street ell',
      'sweat street 45',
    ]),
  ),
  _type(
    '22.5 Elbows',
    _variants('Copper 22.5 Elbow', 'each', _supplySizes, [
      '22',
      'twenty two',
      'eighth bend',
      'sweat 22',
    ]),
  ),
  _type(
    'Tees',
    _variants('Copper Tee', 'each', _teeSizes, [
      'tee',
      't',
      't fitting',
      'reducing tee',
      'sweat tee',
      'copper t',
    ]),
  ),
  _type(
    'Crosses',
    _variants('Copper Cross', 'each', _supplySizes, [
      'four way',
      '4 way',
      'sweat cross',
      'copper four way',
    ]),
  ),
  _type(
    'Couplings',
    _variants('Copper Coupling', 'each', _supplySizes, [
      'coupler',
      'sweat coupling',
    ]),
  ),
  _type(
    'Repair Couplings',
    _variants('Copper Repair Coupling', 'each', _supplySizes, [
      'slip coupling',
      'repair coupling',
      'coupling without stop',
      'no stop coupling',
      'sweat repair coupling',
    ]),
  ),
  _type(
    'Reducers',
    _variants('Copper Reducer', 'each', _reducerSizes, [
      'reducing coupling',
      'copper reducing coupling',
      'bushing',
    ]),
  ),
  _type(
    'Reducing Couplings',
    _variants('Copper Reducing Coupling', 'each', _reducerSizes, [
      'copper reducer',
      'reducing coupling',
      'sweat reducer',
    ]),
  ),
  _type(
    'Caps',
    _variants('Copper Cap', 'each', _supplySizes, ['sweat cap', 'end cap']),
  ),
  _type(
    'Male Adapters',
    _variants('Copper Male Adapter', 'each', _supplySizes, [
      'sweat male adapter',
      'copper mip adapter',
      'copper adapter',
    ]),
  ),
  _type(
    'Female Adapters',
    _variants('Copper Female Adapter', 'each', _supplySizes, [
      'sweat female adapter',
      'copper fip adapter',
      'copper adapter',
    ]),
  ),
  _type(
    'Unions',
    _variants('Copper Union', 'each', _supplySizes, ['sweat union']),
  ),
  _type(
    'Dielectric Unions',
    _variants(
      'Copper Dielectric Union',
      'each',
      ['1/2 in', '3/4 in', '1 in'],
      ['dielectric union', 'water heater union', 'copper steel union'],
    ),
  ),
  _type(
    'Drop-Ear Elbows',
    _variants(
      'Copper Drop-Ear 90 Elbow',
      'each',
      ['1/2 in', '3/4 in'],
      [
        'drop ear',
        'drop ear 90',
        'shower elbow',
        'stub out elbow',
        'wing elbow',
      ],
    ),
  ),
  _type(
    'Stub-Outs',
    _variants(
      'Copper Stub-Out',
      'each',
      ['1/2 in x 6 in', '1/2 in x 8 in', '1/2 in x 12 in', '3/4 in x 12 in'],
      ['stub out', 'copper stub', 'toilet stub out', 'lav stub out'],
    ),
  ),
  ...plumbingGeneratedCopperFittingTypes,
]);
