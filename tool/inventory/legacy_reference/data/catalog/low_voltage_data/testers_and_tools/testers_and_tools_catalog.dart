part of '../../../work_supply_catalog.dart';

final lowVoltageDataTestersAndToolsCategory = _category('Testers and Tools', [
  _system('Cable Testing', [
    _type(
      'Network Cable Tester',
      _variants(
        'Network Cable Tester',
        'each',
        ['basic continuity', 'tone and trace', 'certifier'],
        ['ethernet tester'],
      ),
    ),
    _type(
      'Tone Generator',
      _variants(
        'Tone Generator and Probe',
        'set',
        ['standard', 'pro'],
        ['toner', 'fox and hound'],
      ),
    ),
  ]),
  _system('Termination Tools', [
    _type(
      'Punchdown Tool',
      _variants(
        'Punchdown Tool',
        'each',
        ['110 blade', '66 blade', 'multi blade'],
        ['punch tool'],
      ),
    ),
    _type(
      'Compression Tool',
      _variants(
        'Coax Compression Tool',
        'each',
        ['RG6', 'RG6/RG59 combo'],
        ['coax crimper'],
      ),
    ),
  ]),
]);
