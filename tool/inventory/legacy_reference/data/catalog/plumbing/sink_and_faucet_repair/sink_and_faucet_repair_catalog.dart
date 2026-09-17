part of '../../../work_supply_catalog.dart';

final plumbingSinkAndFaucetRepairCategory = _category(
  'Sink and Faucet Repair',
  [
    _system('Faucet and Shower Repair', [
      _type(
        'Cartridges',
        _variants(
          'Faucet Cartridge',
          'each',
          ['single handle', 'hot stem', 'cold stem'],
          ['stem'],
        ),
      ),
      _type(
        'Faucet Stems',
        _variants(
          'Faucet Stem',
          'each',
          ['hot', 'cold', 'diverter', 'ceramic'],
          ['stem assembly', 'faucet valve stem'],
        ),
      ),
      _type(
        'O-Rings and Seats',
        _variants(
          'Faucet O-Ring and Seat Kit',
          'kit',
          ['assorted', 'small', 'large'],
          ['seat washer kit', 'faucet repair kit', 'o ring kit'],
        ),
      ),
      _type(
        'Aerators',
        _variants(
          'Faucet Aerator',
          'each',
          ['15/16-27 male', '55/64-27 female'],
          ['faucet screen'],
        ),
      ),
      _type(
        'Pop-Up Assemblies',
        _variants(
          'Lavatory Pop-Up Assembly',
          'each',
          ['chrome', 'brushed nickel', 'plastic'],
          [
            'pop up drain',
            'pop up assembly',
            'pop up rod kit',
            'lav pop up',
            'lavatory pop up',
            'sink stopper',
          ],
        ),
      ),
      _type(
        'Basket Strainers',
        _variants(
          'Kitchen Sink Basket Strainer',
          'each',
          ['stainless', 'chrome', 'deep cup'],
          ['sink strainer', 'sink repair kit', 'basket drain'],
        ),
      ),
      _type(
        'Sink Repair Kits',
        _variants(
          'Sink Repair Kit',
          'kit',
          ['universal', 'lavatory', 'kitchen'],
          [
            'sink repair kit',
            'lavatory repair kit',
            'basin repair kit',
            'kit reparacion lavabo',
            'kit reparacion fregadero',
          ],
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
    ]),
  ],
);
