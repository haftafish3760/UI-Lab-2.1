part of '../../../work_supply_catalog.dart';

final lowVoltageDataCableCategory = _category('Cable', [
  _system('Network Cable', [
    _type(
      'Ethernet Cable',
      _variants(
        'Ethernet Cable',
        'box',
        ['Cat5e 1000 ft', 'Cat6 1000 ft', 'Cat6A 1000 ft'],
        ['data cable', 'network cable'],
      ),
    ),
  ]),
  _system('Coax and Fiber', [
    _type(
      'Coax Cable',
      _variants(
        'Coax Cable',
        'roll',
        ['RG6 500 ft', 'RG6 1000 ft'],
        ['coaxial cable'],
      ),
    ),
    _type(
      'Fiber Patch Cable',
      _variants(
        'Fiber Patch Cable',
        'each',
        ['LC-LC single mode', 'SC-SC single mode', 'LC-LC multimode'],
        ['fiber jumper'],
      ),
    ),
  ]),
]);
