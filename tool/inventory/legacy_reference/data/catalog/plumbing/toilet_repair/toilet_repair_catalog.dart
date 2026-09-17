part of '../../../work_supply_catalog.dart';

final plumbingToiletRepairCategory = _category('Toilet Repair', [
  _system('Toilet Repair', [
    _type(
      'Wax Rings',
      _variants(
        'Toilet Wax Ring',
        'each',
        ['standard', 'extra thick', 'with horn', 'wax free'],
        ['closet seal', 'toilet seal'],
      ),
    ),
    _type(
      'Fill Valves',
      _variants(
        'Toilet Fill Valve',
        'each',
        ['universal', 'quiet fill', 'high performance'],
        ['ballcock', 'fill valve kit', 'toilet repair kit'],
      ),
    ),
    _type(
      'Flush Valves',
      _variants(
        'Toilet Flush Valve',
        'each',
        ['2 in', '3 in', 'dual flush'],
        ['flush valve kit', 'tank valve', 'toilet repair kit'],
      ),
    ),
    _type(
      'Flappers',
      _variants(
        'Toilet Flapper',
        'each',
        ['2 in', '3 in'],
        ['flush valve seal'],
      ),
    ),
    _type(
      'Tank Levers',
      _variants(
        'Toilet Tank Lever',
        'each',
        ['front mount', 'side mount', 'universal'],
        ['toilet handle', 'flush handle'],
      ),
    ),
    _type(
      'Tank Bolts and Gaskets',
      _variants(
        'Toilet Tank Bolt Kit',
        'kit',
        ['standard', 'heavy duty'],
        ['tank to bowl bolts', 'tank gasket', 'toilet repair kit'],
      ),
    ),
  ]),
  _system('Closet Hardware', [
    _type(
      'Closet Flanges',
      _variants('Toilet Flange', 'each', _dwvSizes, [
        'closet flange',
        'floor flange',
      ]),
    ),
    _type(
      'Closet Bolts',
      _variants(
        'Closet Bolt Set',
        'pack',
        ['standard', 'extra long'],
        ['toilet bolts', 'johnny bolts'],
      ),
    ),
    _type(
      'Flange Repair Rings',
      _variants(
        'Toilet Flange Repair Ring',
        'each',
        ['stainless', 'plastic', 'split ring'],
        ['closet flange repair', 'flange repair', 'toilet repair kit'],
      ),
    ),
    _type(
      'Flange Spacers',
      _variants(
        'Toilet Flange Spacer',
        'each',
        ['1/4 in', '1/2 in', '3/4 in'],
        ['closet flange spacer', 'flange extender'],
      ),
    ),
  ]),
]);
