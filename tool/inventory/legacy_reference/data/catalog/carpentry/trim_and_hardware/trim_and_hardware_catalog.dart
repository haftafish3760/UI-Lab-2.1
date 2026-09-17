part of '../../../work_supply_catalog.dart';

final carpentryTrimAndHardwareCategory = _category('Trim and Hardware', [
  _system('Trim', [
    _type(
      'Baseboard',
      _variants(
        'Baseboard',
        'foot',
        ['3-1/4 in', '5-1/4 in', '7-1/4 in'],
        ['base trim'],
      ),
    ),
    _type(
      'Casing',
      _variants(
        'Door Casing',
        'foot',
        ['2-1/4 in', '3-1/4 in'],
        ['window casing'],
      ),
    ),
  ]),
  _system('Door Hardware', [
    _type(
      'Hinges',
      _variants(
        'Door Hinge',
        'pack',
        ['3 in', '3-1/2 in', '4 in'],
        ['butt hinge'],
      ),
    ),
    _type(
      'Locksets',
      _variants(
        'Door Lockset',
        'each',
        ['passage', 'privacy', 'entry'],
        ['door knob'],
      ),
    ),
  ]),
]);
