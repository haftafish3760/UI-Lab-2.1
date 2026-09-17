part of '../../../work_supply_catalog.dart';

final plumbingFittingsPexSystem = _system('PEX', [
  _type(
    '90 Elbows',
    _variants('PEX 90 Elbow', 'each', _supplySizes, [
      'pex 90',
      'pex ell',
      'pex elb',
      'pex 90d',
      'crimp elbow',
      'crimp ell',
      'crimp elb',
      'elbow',
    ]),
  ),
  _type(
    'Tees',
    _variants('PEX Tee', 'each', _teeSizes, [
      'tee',
      't',
      'pex t',
      'crimp tee',
      'reducing tee',
    ]),
  ),
  _type(
    'Couplings',
    _variants('PEX Coupling', 'each', _supplySizes, [
      'coupler',
      'crimp coupling',
    ]),
  ),
  _type(
    'Male Adapters',
    _variants('PEX Male Adapter', 'each', _supplySizes, [
      'pex male adapter',
      'pex mip adapter',
      'crimp male adapter',
    ]),
  ),
  _type(
    'Female Adapters',
    _variants('PEX Female Adapter', 'each', _supplySizes, [
      'pex female adapter',
      'pex fip adapter',
      'crimp female adapter',
    ]),
  ),
  _type(
    'Drop-Ear Elbows',
    _variants(
      'PEX Drop-Ear Elbow',
      'each',
      ['1/2 in', '3/4 in'],
      ['drop ear', 'shower elbow', 'stub out elbow'],
    ),
  ),
  _type(
    'Transition Couplings',
    _variants('PEX Transition Coupling', 'each', _supplySizes, [
      'pex transition',
      'pex copper coupling',
    ]),
  ),
  _type(
    'Crimp Rings',
    _variants(
      'PEX Crimp Ring',
      'each',
      ['3/8 in', '1/2 in', '3/4 in', '1 in'],
      ['copper crimp ring', 'pex ring'],
    ),
  ),
  _type(
    'Clamp Rings',
    _variants(
      'PEX Clamp Ring',
      'each',
      ['3/8 in', '1/2 in', '3/4 in', '1 in'],
      ['stainless clamp ring', 'cinch ring'],
    ),
  ),
  ...plumbingGeneratedPexFittingTypes,
]);
