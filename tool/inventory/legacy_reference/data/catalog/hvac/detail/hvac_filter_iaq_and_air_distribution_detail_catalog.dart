part of '../../../work_supply_catalog.dart';

List<WorkSupplyItem> _hvacDetailFilterProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Filter Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '10 x 20',
        '12 x 12',
        '12 x 20',
        '14 x 14',
        '14 x 20',
        '14 x 25',
        '16 x 16',
        '16 x 20',
        '16 x 24',
        '16 x 25',
        '18 x 20',
        '18 x 24',
        '20 x 20',
        '20 x 24',
        '20 x 25',
        '24 x 24',
        '24 x 30',
      ])
        for (final depth in ['1 in', '2 in', '4 in', '5 in'])
          for (final rating in ['MERV 8', 'MERV 11', 'MERV 13', 'MERV 16'])
            for (final item in [
              'Pleated Furnace Filter',
              'Return Air Filter',
              'Media Cabinet Filter',
            ])
              '$size x $depth $rating $item',
    ],
    aliases: const [
      'air filter',
      'furnace filter',
      'return filter',
      'media filter',
      'merv filter',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailIaqProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC IAQ Detail',
    unit: 'each',
    variants: [
      for (final size in ['10 in', '12 in', '14 in', '16 in'])
        for (final item in [
          'Bypass Humidifier Pad',
          'Humidifier Water Panel',
          'Electronic Air Cleaner Cell',
          'Media Air Cleaner Cabinet',
        ])
          '$size $item',
      for (final voltage in ['24V', '120V'])
        for (final item in [
          'UV Lamp Ballast',
          'UV Air Purifier Bulb',
          'Humidifier Solenoid Valve',
          'Duct Mounted Humidistat',
        ])
          '$voltage $item',
      'ERV Filter Kit',
      'HRV Filter Kit',
      'Whole House Dehumidifier Filter',
      'IAQ Equipment Door Switch',
    ],
    aliases: const [
      'humidifier pad',
      'water panel',
      'uv bulb',
      'air cleaner',
      'erv filter',
      'hrv filter',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailRoundDuctProducts() {
  return _hvacDetailProducts(
    baseName: 'Round Duct Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '3 in',
        '4 in',
        '5 in',
        '6 in',
        '7 in',
        '8 in',
        '9 in',
        '10 in',
        '12 in',
        '14 in',
        '16 in',
        '18 in',
      ])
        for (final gauge in ['26 Gauge', '28 Gauge', '30 Gauge'])
          for (final item in [
            'Round Duct Pipe',
            'Adjustable Elbow',
            'Pressed 90 Elbow',
            'Start Collar',
            'Takeoff Collar',
            'Spin In Takeoff',
            'Manual Damper',
            'Backdraft Damper',
            'End Cap',
            'Round Reducer',
            'Round Wye',
            'Round Tee',
          ])
            '$size $gauge $item',
    ],
    aliases: const [
      'round duct',
      'duct pipe',
      'sheet metal elbow',
      'start collar',
      'takeoff',
      'manual damper',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailAirDistributionProducts() {
  return _hvacDetailProducts(
    baseName: 'Air Distribution Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '2 x 10',
        '2 x 12',
        '4 x 10',
        '4 x 12',
        '6 x 10',
        '6 x 12',
        '8 x 8',
        '10 x 10',
        '12 x 12',
        '14 x 14',
        '20 x 20',
        '20 x 25',
      ])
        for (final finish in ['White', 'Brown', 'Black', 'Brushed Nickel'])
          for (final item in [
            'Floor Register',
            'Ceiling Register',
            'Sidewall Register',
            'Return Air Grille',
            'Filter Return Grille',
            'Baseboard Diffuser',
          ])
            '$size $finish $item',
      for (final face in ['4 x 10', '4 x 12', '6 x 10', '6 x 12', '8 x 8'])
        for (final throat in ['5 in', '6 in', '7 in', '8 in'])
          for (final item in ['Straight Register Boot', 'Angle Register Boot'])
            '$face x $throat $item',
    ],
    aliases: const [
      'floor register',
      'ceiling register',
      'return grille',
      'filter grille',
      'register boot',
      'diffuser',
    ],
  );
}
