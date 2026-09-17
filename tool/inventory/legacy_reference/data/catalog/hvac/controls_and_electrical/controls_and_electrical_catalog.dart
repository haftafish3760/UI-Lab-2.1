part of '../../../work_supply_catalog.dart';

final hvacControlsAndElectricalCategory = _category('Controls and Electrical', [
  _system('Capacitors and Contactors', [
    _type(
      'Run Capacitors',
      _variants(
        'Run Capacitor',
        'each',
        ['5 MFD', '7.5 MFD', '10 MFD', '35/5 MFD', '40/5 MFD', '45/5 MFD'],
        ['capacitor', 'dual run capacitor'],
      ),
    ),
    _type(
      'Contactors',
      _variants(
        'Contactor',
        'each',
        ['1 pole 24V', '2 pole 24V', '30 Amp', '40 Amp'],
        ['compressor contactor', '24v contactor', '2 pole contactor'],
      ),
    ),
  ]),
  _system('Thermostats', [
    _type(
      'Thermostats',
      _variants(
        'Thermostat',
        'each',
        ['basic heat cool', 'programmable', 'smart'],
        ['stat'],
      ),
    ),
    _type(
      'Thermostat Wire',
      _variants(
        'Thermostat Wire',
        'roll',
        ['18/2', '18/3', '18/5', '18/7', '18/8'],
        ['low voltage wire'],
      ),
    ),
  ]),
]);
