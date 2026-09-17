part of '../../../work_supply_catalog.dart';

List<WorkSupplyItem> _hvacDetailTrunkPlenumProducts() {
  return _hvacDetailProducts(
    baseName: 'Duct Fabrication Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '8 x 8',
        '10 x 10',
        '12 x 12',
        '14 x 14',
        '16 x 16',
        '16 x 20',
        '20 x 20',
        '20 x 25',
        '24 x 24',
      ])
        for (final item in [
          'Return Air Box',
          'Supply Plenum',
          'Return Plenum',
          'Duct Transition',
          'Duct End Cap',
          'Duct Access Door',
        ])
          '$size $item',
      for (final size in ['2 ft x 4 ft', '4 ft x 8 ft'])
        for (final thickness in ['1 in', '1-1/2 in', '2 in'])
          '$size x $thickness Foil Faced Duct Board',
      for (final length in ['36 in', '48 in', '60 in'])
        for (final item in ['Drive Cleat', 'S Cleat', 'Standing S Cleat'])
          '$length $item',
    ],
    aliases: const [
      'supply plenum',
      'return plenum',
      'return box',
      'duct board',
      'drive cleat',
      's cleat',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailControlProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Control Detail',
    unit: 'each',
    variants: [
      for (final mfd in [
        '20/5 MFD',
        '25/5 MFD',
        '30/5 MFD',
        '35/5 MFD',
        '40/5 MFD',
        '45/5 MFD',
        '50/5 MFD',
        '55/5 MFD',
        '60/5 MFD',
        '70/5 MFD',
        '80/5 MFD',
      ])
        for (final volts in ['370V', '440V']) '$mfd $volts Dual Run Capacitor',
      for (final mfd in [
        '5 MFD',
        '7.5 MFD',
        '10 MFD',
        '15 MFD',
        '20 MFD',
        '25 MFD',
        '30 MFD',
        '35 MFD',
        '40 MFD',
      ])
        for (final volts in ['370V', '440V'])
          '$mfd $volts Single Run Capacitor',
      for (final pole in ['1 Pole', '2 Pole', '3 Pole'])
        for (final amp in ['25 Amp', '30 Amp', '40 Amp', '50 Amp'])
          for (final coil in ['24V Coil', '120V Coil'])
            '$pole $amp $coil Contactor',
      '40VA 24V Transformer',
      '50VA 24V Transformer',
      '75VA 24V Transformer',
      'Fan Relay 24V',
      'Defrost Relay 24V',
      'Hard Start Kit',
      'Compressor Saver Kit',
      'Time Delay Relay',
    ],
    aliases: const [
      'run capacitor',
      'dual cap',
      'single cap',
      'contactor',
      'relay',
      'hard start',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailElectricalProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Electrical Detail',
    unit: 'each',
    variants: [
      for (final amp in ['30 Amp', '60 Amp'])
        for (final style in ['Fused', 'Non Fused', 'Pullout'])
          '$amp $style AC Disconnect',
      for (final size in ['1/2 in', '3/4 in', '1 in'])
        for (final length in ['4 ft', '6 ft', '8 ft'])
          '$size x $length AC Whip',
      for (final conductor in ['18/2', '18/3', '18/5', '18/7', '18/8'])
        for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
          '$conductor x $length Thermostat Wire',
      '3 Amp Low Voltage Fuse',
      '5 Amp Low Voltage Fuse',
      'Low Voltage Fuse Holder',
      'Single Phase Surge Protector',
      'Equipment Ground Lug',
      'Liquid Tight Connector 1/2 in',
      'Liquid Tight Connector 3/4 in',
    ],
    aliases: const [
      'ac disconnect',
      'disconnect box',
      'ac whip',
      'stat wire',
      'thermostat wire',
      'low voltage fuse',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailLineSetProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Line Set Detail',
    unit: 'each',
    variants: [
      for (final pair in [
        '1/4 x 3/8',
        '1/4 x 1/2',
        '1/4 x 5/8',
        '3/8 x 3/4',
        '3/8 x 7/8',
      ])
        for (final length in ['15 ft', '25 ft', '35 ft', '50 ft', '65 ft'])
          for (final item in ['Line Set', 'Mini Split Line Set'])
            '$pair x $length $item',
      for (final size in ['3 in', '4 in', '5 in'])
        for (final color in ['White', 'Ivory', 'Brown', 'Black'])
          for (final part in [
            'Line Set Cover',
            'Line Hide Wall Cap',
            'Line Hide Coupling',
            'Line Hide Elbow',
            'Line Hide End Cap',
          ])
            '$size $color $part',
    ],
    aliases: const [
      'line set',
      'mini split line set',
      'line hide',
      'line set cover',
      'copper line',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailCondensateProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Condensate Detail',
    unit: 'each',
    variants: [
      for (final voltage in ['115V', '230V'])
        for (final item in [
          'Condensate Pump',
          'Mini Condensate Pump',
          'High Lift Condensate Pump',
        ])
          '$voltage $item',
      for (final size in [
        '24 x 24',
        '24 x 30',
        '30 x 30',
        '30 x 36',
        '36 x 48',
      ])
        for (final item in ['Secondary Drain Pan', 'Plastic Drain Pan'])
          '$size $item',
      for (final size in ['3/4 in', '1 in'])
        for (final part in [
          'PVC Condensate Pipe',
          'PVC Condensate 90 Elbow',
          'PVC Condensate Tee',
          'PVC Condensate Trap',
          'PVC Condensate Cleanout Tee',
        ])
          '$size $part',
      'Inline Float Switch',
      'Secondary Pan Float Switch',
      'Wet Switch',
      'Condensate Overflow Alarm',
      'Drain Pan Treatment Tablets',
      'Drain Line Cleaner 1 qt',
    ],
    aliases: const [
      'condensate pump',
      'cond pump',
      'drain pan',
      'float switch',
      'wet switch',
      'condensate drain',
    ],
  );
}
