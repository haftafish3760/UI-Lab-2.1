part of '../../../work_supply_catalog.dart';

final hvacRefrigerantServiceCategory = _category('Refrigerant Service', [
  _system('Service Fittings', [
    _type(
      'Service Caps',
      _variants(
        'Refrigerant Service Cap',
        'pack',
        ['1/4 in flare', '5/16 in flare'],
        ['schrader cap'],
      ),
    ),
    _type(
      'Schrader Cores',
      _variants(
        'Schrader Valve Core',
        'pack',
        ['standard', 'high flow'],
        ['valve core'],
      ),
    ),
  ]),
  _system('Brazing and Nitrogen', [
    _type(
      'Brazing Rod',
      _variants(
        'Brazing Rod',
        'tube',
        ['15% silver', '5% silver', 'phos copper'],
        ['silfos', 'braze rod'],
      ),
    ),
    _type(
      'Nitrogen Regulator Fittings',
      _variants(
        'Nitrogen Service Fitting',
        'each',
        ['1/4 in flare', '5/16 in flare'],
        ['purge fitting'],
      ),
    ),
  ]),
]);
