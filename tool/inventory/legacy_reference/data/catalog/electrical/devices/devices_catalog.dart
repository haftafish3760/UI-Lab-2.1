part of '../../../work_supply_catalog.dart';

final electricalDevicesCategory = _category('Devices', [
  _system('Receptacles', [
    _type(
      'Duplex Receptacles',
      _variants(
        'Duplex Receptacle',
        'each',
        ['15 Amp', '20 Amp'],
        ['outlet', 'wall socket', 'plug'],
      ),
    ),
    _type(
      'GFCI Receptacles',
      _variants(
        'GFCI Outlet',
        'each',
        ['15 Amp', '20 Amp'],
        ['gfci receptacle', 'ground fault outlet'],
      ),
    ),
  ]),
  _system('Switches', [
    _type(
      'Toggle Switches',
      _variants(
        'Toggle Switch',
        'each',
        ['single pole', '3-way', '4-way', '20 Amp'],
        ['light switch', 'single pole switch', '3-way switch', '3 way switch'],
      ),
    ),
    _type(
      'Dimmer Switches',
      _variants(
        'Dimmer Switch',
        'each',
        ['single pole', '3-way', 'LED compatible'],
        ['dimmer'],
      ),
    ),
  ]),
]);
