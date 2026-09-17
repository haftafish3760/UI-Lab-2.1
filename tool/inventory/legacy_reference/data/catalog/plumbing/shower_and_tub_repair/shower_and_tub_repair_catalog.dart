part of '../../../work_supply_catalog.dart';

final plumbingShowerAndTubRepairCategory = _category('Shower and Tub Repair', [
  _system('Tub and Shower Trim', [
    _type(
      'Shower Cartridges',
      _variants(
        'Shower Cartridge',
        'each',
        ['single handle', 'pressure balance', 'thermostatic'],
        ['mixing valve cartridge', 'shower stem'],
      ),
    ),
    _type(
      'Shower Valve Trim Kits',
      _variants(
        'Shower Valve Trim Kit',
        'kit',
        ['single handle', 'pressure balance', 'diverter'],
        ['shower trim', 'trim kit'],
      ),
    ),
    _type(
      'Tub Spouts',
      _variants(
        'Tub Spout',
        'each',
        ['slip fit', 'threaded'],
        ['diverter spout'],
      ),
    ),
    _type(
      'Shower Heads',
      _variants(
        'Shower Head',
        'each',
        ['fixed', 'handheld', 'rain'],
        ['showerhead'],
      ),
    ),
    _type(
      'Shower Arms',
      _variants(
        'Shower Arm',
        'each',
        ['6 in', '8 in', '12 in'],
        ['shower pipe'],
      ),
    ),
  ]),
  _system('Tub Drain', [
    _type(
      'Waste and Overflow',
      _variants(
        'Tub Waste and Overflow Kit',
        'kit',
        ['trip lever', 'toe touch', 'lift and turn'],
        ['tub drain kit'],
      ),
    ),
    _type(
      'Tub Drain Shoes',
      _variants(
        'Tub Drain Shoe',
        'each',
        ['1-1/2 in', 'trip lever', 'toe touch'],
        ['drain shoe', 'tub shoe'],
      ),
    ),
    _type(
      'Tub Drain Stoppers',
      _variants(
        'Tub Drain Stopper',
        'each',
        ['toe touch', 'lift and turn', 'trip lever'],
        ['tub stopper', 'drain stopper'],
      ),
    ),
  ]),
]);
