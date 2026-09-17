part of '../../../work_supply_catalog.dart';

final plumbingValvesCategory = _category('Valves', [
  _system('Shutoff', [
    _type(
      'Ball Valves',
      _variants('Ball Valve', 'each', _supplySizes, [
        'shutoff valve',
        'full port valve',
      ]),
    ),
    _type(
      'Threaded Ball Valves',
      _variants('Threaded Ball Valve', 'each', _threadedSizes, [
        'ips ball valve',
        'fip ball valve',
        'gas ball valve',
      ]),
    ),
    _type(
      'PVC Ball Valves',
      _variants('PVC Ball Valve', 'each', _pipeSizes, [
        'pvc shutoff',
        'slip ball valve',
      ]),
    ),
    _type(
      'Angle Stops',
      _variants(
        'Angle Stop Valve',
        'each',
        [
          '3/8 x 1/2 in',
          '3/8 x 5/8 in',
          '3/8 x 3/8 in',
          '1/4 x 1/2 in',
          '1/4 x 3/8 in',
        ],
        ['angle valve', 'stop valve', 'angle stop', 'supply stop'],
      ),
    ),
    _type(
      'Straight Stops',
      _variants(
        'Straight Stop Valve',
        'each',
        ['3/8 x 1/2 in', '3/8 x 5/8 in', '1/4 x 1/2 in'],
        ['straight valve', 'supply stop'],
      ),
    ),
    _type(
      'Gate Valves',
      _variants('Gate Valve', 'each', _supplySizes, ['water valve']),
    ),
    _type(
      'Hose Bibbs',
      _variants(
        'Hose Bibb',
        'each',
        ['1/2 in', '3/4 in'],
        ['spigot', 'sillcock', 'outside faucet'],
      ),
    ),
    _type(
      'Frost-Free Sillcocks',
      _variants(
        'Frost-Free Sillcock',
        'each',
        [
          '1/2 in x 8 in',
          '1/2 in x 10 in',
          '1/2 in x 12 in',
          '3/4 in x 10 in',
          '3/4 in x 12 in',
        ],
        ['frost free hose bibb', 'anti siphon sillcock'],
      ),
    ),
  ]),
  _system('Protection', [
    _type(
      'Pressure Reducing Valves',
      _variants(
        'Pressure Reducing Valve',
        'each',
        ['1/2 in', '3/4 in', '1 in'],
        ['prv'],
      ),
    ),
    _type(
      'Vacuum Breakers',
      _variants(
        'Vacuum Breaker',
        'each',
        ['3/4 in', '1 in'],
        ['hose bibb vacuum breaker', 'backflow preventer'],
      ),
    ),
    _type(
      'Check Valves',
      _variants('Check Valve', 'each', _pipeSizes, ['one way valve']),
    ),
    _type(
      'Backwater Valves',
      _variants(
        'Backwater Valve',
        'each',
        ['3 in', '4 in', '6 in'],
        ['sewer check valve', 'drain backflow valve'],
      ),
    ),
  ]),
]);
