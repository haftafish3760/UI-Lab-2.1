part of '../../work_supply_catalog.dart';

final lowVoltageDataGeneratedDetailCatalogCategory = _category(
  'Low Voltage and Data Detail Stock',
  [
    _system('Network Cable Termination and Pathway Detail', [
      _type('Network Cable Color and Jacket Detail', _lowVoltageCableDetail()),
      _type(
        'Keystone Patch Panel and Plug Detail',
        _lowVoltageTerminationDetail(),
      ),
      _type('Pathway Support and Labeling Detail', _lowVoltagePathwayDetail()),
    ]),
    _system('Security Access Camera and Doorbell Detail', [
      _type('Camera Network and Power Detail', _lowVoltageCameraDetail()),
      _type('Alarm Access and Door Hardware Detail', _lowVoltageAccessDetail()),
    ]),
    _system('Audio Video Smart Home and Rack Detail', [
      _type('AV Plate Cable and Audio Detail', _lowVoltageAvDetail()),
      _type('Rack Power Cooling and Service Detail', _lowVoltageRackDetail()),
    ]),
  ],
);

List<WorkSupplyItem> _lowVoltageCableDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'Low Voltage Cable Detail',
    unit: 'box',
    variants: [
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final jacket in [
          'CMR Riser',
          'CMP Plenum',
          'Outdoor Direct Burial',
        ])
          for (final color in ['Blue', 'White', 'Gray', 'Black', 'Yellow'])
            '$rating 1000 ft $color $jacket Data Cable',
      for (final gauge in ['18/2', '18/4', '22/2', '22/4', '22/6'])
        for (final length in ['250 ft', '500 ft', '1000 ft'])
          '$gauge $length CL2 Security Cable',
      for (final gauge in ['16/2', '14/2', '12/2', '16/4'])
        for (final length in ['100 ft', '250 ft', '500 ft'])
          '$gauge $length CL3 Speaker Wire',
      for (final coax in ['RG6', 'RG6 Quad Shield', 'RG59'])
        for (final length in ['100 ft', '250 ft', '500 ft', '1000 ft'])
          '$coax $length Coax Cable',
    ],
    aliases: const [
      'cat6 cable',
      'ethernet cable',
      'data cable',
      'security cable',
      'speaker wire',
      'coax cable',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageTerminationDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'Low Voltage Termination Detail',
    unit: 'pack',
    variants: [
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final color in ['White', 'Blue', 'Black', 'Ivory', 'Light Almond'])
          for (final jack in [
            'Slim Keystone Jack',
            'Toolless Keystone Jack',
            'Punchdown Keystone Jack',
          ])
            '$rating $color $jack',
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final plug in [
          'Pass Through RJ45 Plug 50 Pack',
          'Shielded RJ45 Plug 25 Pack',
          'RJ45 Strain Relief Boot 50 Pack',
        ])
          '$rating $plug',
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final port in ['12 Port', '24 Port', '48 Port'])
          '$rating $port Patch Panel',
      for (final coax in ['RG6', 'RG6 Quad Shield', 'RG59'])
        for (final part in [
          'Compression F Connector 50 Pack',
          'Coax Coupler 10 Pack',
          'Ground Block',
          '2 Way Splitter',
          '4 Way Splitter',
        ])
          '$coax $part',
    ],
    aliases: const [
      'keystone jack',
      'rj45 plug',
      'patch panel',
      'f connector',
      'coax splitter',
    ],
  );
}

List<WorkSupplyItem> _lowVoltagePathwayDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'Low Voltage Pathway Detail',
    unit: 'each',
    variants: [
      for (final size in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
        for (final length in ['25 ft', '50 ft', '100 ft'])
          '$size $length Smurf Tube Flexible Raceway',
      for (final width in ['1 in', '1-1/2 in', '2 in'])
        for (final fitting in [
          'Surface Raceway',
          'Raceway Inside Corner',
          'Raceway Outside Corner',
          'Raceway Tee Fitting',
          'Raceway Coupler',
          'Raceway End Cap',
        ])
          '$width $fitting',
      for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
        for (final item in [
          'J-Hook Cable Support',
          'Bridle Ring Cable Support',
          'Cable D-Ring',
          'Beam Clamp Cable Hanger',
          'Low Voltage Cable Staple',
          'Cable Identification Tag',
          'Wire Marker Label',
        ])
          '$item $pack',
    ],
    aliases: const [
      'smurf tube',
      'flexible raceway',
      'j-hook',
      'bridle ring',
      'wire marker',
      'cable label',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageCameraDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'Camera Network Detail',
    unit: 'each',
    variants: [
      for (final mp in ['2MP', '4MP', '5MP', '8MP'])
        for (final style in ['Dome', 'Bullet', 'Turret', 'PTZ'])
          '$mp PoE $style Camera',
      for (final port in ['4 Port', '8 Port', '16 Port', '24 Port'])
        for (final item in ['PoE Switch', 'NVR Recorder']) '$port $item',
      for (final watts in ['30W', '60W', '90W']) '$watts PoE Injector',
      for (final item in [
        'PoE Splitter',
        'PoE Extender',
        'Security Camera Junction Box',
        'Security Camera Pendant Mount',
        'Doorbell Power Kit',
        '24V Doorbell Transformer',
        'Video Doorbell Wedge Kit',
        'Security DVR Hard Drive 4TB',
      ])
        item,
    ],
    aliases: const [
      'poe camera',
      'security camera',
      'poe switch',
      'nvr',
      'poe injector',
      'doorbell power kit',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageAccessDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'Alarm Access Detail',
    unit: 'each',
    variants: [
      for (final item in [
        'Recessed Door Contact Sensor',
        'Surface Door Contact Sensor',
        'Window Contact Sensor',
        'Glass Break Sensor',
        'Motion Detector',
        'Alarm Keypad',
        'Alarm Backup Battery',
        'Alarm Siren',
        'Magnetic Door Lock',
        'Electric Door Strike',
        'Request To Exit Button',
        'No Touch Exit Button',
        'RFID Card Reader',
        'Access Control Power Supply',
        'Door Loop Armored Cable',
        'Gel Filled Alarm Splice Connector 25 Pack',
        'B Connector Alarm Splice 100 Pack',
      ])
        item,
    ],
    aliases: const [
      'door contact',
      'alarm battery',
      'electric strike',
      'request to exit',
      'rfid reader',
      'alarm splice',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageAvDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'AV Smart Home Detail',
    unit: 'each',
    variants: [
      for (final length in ['6 ft', '10 ft', '15 ft', '25 ft', '50 ft'])
        for (final cable in [
          '8K HDMI Cable',
          'Active HDMI Cable',
          'Optical HDMI Cable',
        ])
          '$length $cable',
      for (final color in ['White', 'Ivory', 'Black'])
        for (final plate in [
          'Brush Pass Through Plate',
          'HDMI Keystone Insert',
          'USB-C Keystone Insert',
          'Speaker Binding Post Plate',
          'In-Wall Volume Control',
        ])
          '$color $plate',
      for (final item in [
        'HDMI Extender Over Cat6',
        'IR Repeater Kit',
        'IR Receiver Target',
        'IR Emitter Pack',
        'In-Ceiling Speaker Pair 8 in',
        'In-Wall Speaker Pair 6.5 in',
        'Smart Home Hub',
        'Thermostat C-Wire Adapter',
      ])
        item,
    ],
    aliases: const [
      '8k hdmi',
      'brush plate',
      'pass through plate',
      'volume control',
      'ir repeater',
      'speaker pair',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageRackDetail() {
  return _lowVoltageDetailProducts(
    baseName: 'Rack Service Detail',
    unit: 'each',
    variants: [
      for (final size in ['1U', '2U', '4U'])
        for (final item in [
          'Rack Drawer',
          'Rack Shelf',
          'Blank Panel',
          'Brush Panel',
          'Vent Panel',
          'Fan Panel',
        ])
          '$size $item',
      for (final size in ['6U', '9U', '12U', '18U'])
        '$size Wall Mount Network Rack',
      for (final outlet in ['6 Outlet', '8 Outlet', '12 Outlet'])
        '$outlet Rack PDU',
      'Rack Mount UPS 750VA',
      'Rack Mount UPS 1500VA',
      'Rack Screw 50 Pack',
      'Cage Nut 50 Pack',
      'Velcro One Wrap Roll',
      'Fiber Distribution Box',
      'Fiber Splice Tray',
    ],
    aliases: const [
      'network rack',
      'rack pdu',
      'rack ups',
      'blank panel',
      'cage nut',
      'fiber distribution',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageDetailProducts({
  required String baseName,
  required String unit,
  required List<String> variants,
  required List<String> aliases,
}) {
  return [
    for (final variant in variants)
      WorkSupplyItem(
        id: '',
        name: '$variant $baseName',
        trade: '',
        category: '',
        system: '',
        itemType: '',
        variant: variant,
        unit: unit,
        aliases: aliases,
      ),
  ];
}
