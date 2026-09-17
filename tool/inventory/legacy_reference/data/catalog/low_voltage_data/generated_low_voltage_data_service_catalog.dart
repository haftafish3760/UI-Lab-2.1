part of '../../work_supply_catalog.dart';

final lowVoltageDataGeneratedServiceCatalogCategory = _category(
  'Expanded Low Voltage and Data Service Stock',
  [
    _system('Expanded Cable and Wire', [
      _type('Network Cable', _networkCableProducts()),
      _type('Coax Security and Speaker Cable', _lowVoltageCableProducts()),
      _type('Fiber Patch Cables', _fiberProducts()),
    ]),
    _system('Expanded Terminations and Plates', [
      _type('RJ45 Plugs and Keystone Jacks', _dataTerminationProducts()),
      _type('Coax and Fiber Terminations', _coaxFiberTerminationProducts()),
      _type('Low Voltage Boxes and Plates', _boxPlateEnclosureProducts()),
      _type('AV Wall Plates and Adapters', _avPlateAdapterProducts()),
      _type('AV Cable and Audio Distribution', _avCableAudioProducts()),
      _type('Premade Patch Cords and AV Adapters', _patchCordAdapterProducts()),
    ]),
    _system('Expanded Security Cameras and Access', [
      _type('Camera Security and Doorbell Parts', _cameraSecurityProducts()),
      _type('Access Control and Alarm Parts', _accessAlarmProducts()),
      _type('Smart Home and Control Parts', _smartHomeControlProducts()),
      _type('Camera Mounts Storage and Doorbell Power', _cameraPowerProducts()),
    ]),
    _system('Expanded Testers and Termination Tools', [
      _type('Cable Testers and Toners', _testerProducts()),
      _type('Termination Tools', _terminationToolProducts()),
      _type('Cable Management and Labeling', _cableManagementProducts()),
      _type('Rack Power and Structured Wiring Hardware', _rackPowerProducts()),
      _type('Rack Cooling UPS and Service Hardware', _rackServiceProducts()),
    ]),
    _system('Pro Low Voltage Rough-In and Service Detail', [
      _type(
        'Structured Wiring Pathway and Enclosure Detail',
        _pathwayProducts(),
      ),
      _type(
        'Network Fiber and PoE Detail Stock',
        _networkFiberDetailProducts(),
      ),
      _type(
        'Security Access and Alarm Detail Stock',
        _securityAccessDetailProducts(),
      ),
      _type(
        'AV Smart Home and Audio Detail Stock',
        _avSmartHomeDetailProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _networkCableProducts() {
  final ratings = ['Cat5e', 'Cat6', 'Cat6A', 'Cat7'];
  final lengths = ['100 ft', '250 ft', '500 ft', '1000 ft'];
  final jackets = ['CMR', 'CMP Plenum', 'Riser', 'Outdoor Direct Burial'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Network Cable',
    unit: 'box',
    variants: [
      for (final rating in ratings)
        for (final length in lengths)
          for (final jacket in jackets) '$rating $length $jacket',
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final color in ['Blue', 'White', 'Gray', 'Black'])
          '$rating 1000 ft $color Data Cable',
      'Cat6 Shielded 1000 ft STP',
      'Cat6A Shielded 1000 ft STP',
      'Cat6 Outdoor Gel Filled 1000 ft',
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final length in [
          '1 ft',
          '3 ft',
          '5 ft',
          '7 ft',
          '10 ft',
          '25 ft',
          '50 ft',
        ])
          '$rating $length Patch Cable',
    ],
    aliases: const ['ethernet cable', 'data cable', 'network cable'],
  );
}

List<WorkSupplyItem> _lowVoltageCableProducts() {
  final lengths = ['100 ft', '250 ft', '500 ft', '1000 ft'];
  final securityGauges = ['18/2', '18/4', '22/2', '22/4', '22/6'];
  final speakerGauges = ['18/2', '16/2', '14/2', '12/2', '16/4'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Cable',
    unit: 'roll',
    variants: [
      for (final length in lengths) 'RG6 $length Coax Cable',
      for (final length in lengths) 'RG6 Quad Shield $length Coax Cable',
      for (final length in lengths) 'RG59 $length Coax Cable',
      for (final gauge in securityGauges)
        for (final length in lengths) '$gauge $length Security Cable',
      for (final gauge in speakerGauges)
        for (final length in lengths) '$gauge $length Speaker Wire',
      '18/5 250 ft Thermostat Wire',
      '18/8 250 ft Thermostat Wire',
      '18/10 250 ft Thermostat Wire',
      '500 ft Fire Alarm Cable',
      '500 ft Shielded Control Cable',
    ],
    aliases: const ['coaxial cable', 'security wire', 'speaker wire'],
  );
}

List<WorkSupplyItem> _fiberProducts() {
  final connectors = ['LC-LC', 'SC-SC', 'SC-LC', 'LC-ST'];
  final modes = ['Single Mode', 'Multimode OM3', 'Multimode OM4'];
  final lengths = ['1 m', '2 m', '3 m', '5 m', '10 m', '15 m'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Fiber Patch Cable',
    unit: 'each',
    variants: [
      for (final connector in connectors)
        for (final mode in modes)
          for (final length in lengths) '$connector $mode $length',
      'Single Mode Fiber Pigtail',
      'Multimode Fiber Pigtail',
      'Fiber Splice Sleeve Pack',
      'Fiber Cleaning Pen',
      'Fiber Cleaning Wipe Pack',
    ],
    aliases: const ['fiber jumper', 'fiber patch cord', 'fiber optic cable'],
  );
}

List<WorkSupplyItem> _dataTerminationProducts() {
  final ratings = ['Cat5e', 'Cat6', 'Cat6A'];
  final colors = ['White', 'Blue', 'Gray', 'Black', 'Ivory'];
  final ports = ['12 Port', '24 Port', '48 Port'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Data Termination',
    unit: 'pack',
    variants: [
      for (final rating in ratings) '$rating RJ45 Connector',
      for (final rating in ratings) '$rating Pass-Through RJ45 Connector',
      for (final rating in ratings) '$rating Shielded RJ45 Connector',
      for (final rating in ratings)
        for (final color in colors) '$rating $color Keystone Jack',
      for (final rating in ratings)
        for (final port in ports) '$rating Patch Panel $port',
      'RJ45 Strain Relief Boot Pack',
      'RJ45 Coupler',
      'Inline Ethernet Coupler',
      'Surface Mount Data Jack Box',
    ],
    aliases: const ['rj45', 'ethernet plug', 'keystone jack', 'patch panel'],
  );
}

List<WorkSupplyItem> _coaxFiberTerminationProducts() {
  final coaxTypes = ['RG6', 'RG59', 'RG6 Quad Shield'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Termination',
    unit: 'pack',
    variants: [
      for (final type in coaxTypes) '$type Compression Connector',
      for (final type in coaxTypes) '$type F Connector',
      for (final type in coaxTypes) '$type Coax Coupler',
      for (final type in coaxTypes) '$type Coax Splitter 2 Way',
      for (final type in coaxTypes) '$type Coax Splitter 4 Way',
      'Coax Ground Block',
      'Coax Wall Plate Insert',
      'LC Fiber Adapter',
      'SC Fiber Adapter',
      'ST Fiber Adapter',
      'Single Mode Fiber Coupler',
      'Multimode Fiber Coupler',
      'Fiber Keystone Insert',
      'Blank Keystone Insert',
    ],
    aliases: const ['coax connector', 'f connector', 'fiber adapter'],
  );
}

List<WorkSupplyItem> _boxPlateEnclosureProducts() {
  final gangs = ['1 Gang', '2 Gang', '3 Gang', '4 Gang'];
  final ports = ['1 Port', '2 Port', '3 Port', '4 Port', '6 Port'];
  final colors = ['White', 'Ivory', 'Light Almond', 'Black', 'Stainless'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Box or Plate',
    unit: 'each',
    variants: [
      for (final gang in gangs) '$gang Low Voltage Mounting Bracket',
      for (final gang in gangs) '$gang Low Voltage Old Work Ring',
      for (final port in ports)
        for (final color in colors) '$port $color Keystone Wall Plate',
      '1 Gang Brush Wall Plate',
      '2 Gang Brush Wall Plate',
      '14 in Structured Media Enclosure',
      '28 in Structured Media Enclosure',
      '42 in Structured Media Enclosure',
      'Structured Media Door',
      'Media Enclosure Power Kit',
      'Media Panel Cable Management Kit',
      'Media Enclosure Shelf',
      'Media Enclosure Module Bracket',
      'Structured Media Coax Module',
      'Structured Media Data Module',
    ],
    aliases: const ['lv bracket', 'mud ring', 'data plate', 'media enclosure'],
  );
}

List<WorkSupplyItem> _avPlateAdapterProducts() {
  final colors = ['White', 'Ivory', 'Black'];
  return _lowVoltageGeneratedVariants(
    baseName: 'AV Wall Plate or Adapter',
    unit: 'each',
    variants: [
      for (final color in colors) '$color HDMI Keystone Insert',
      for (final color in colors) '$color USB Keystone Insert',
      for (final color in colors) '$color RCA Keystone Insert',
      for (final color in colors) '$color Speaker Binding Post Wall Plate',
      for (final color in colors) '$color HDMI Wall Plate',
      for (final color in colors) '$color Cable Pass-Through Wall Plate',
      'HDMI Coupler',
      'USB-C Keystone Insert',
      '3.5 mm Audio Keystone Insert',
      'Banana Plug Speaker Connector Pack',
      'Speaker Wall Plate 2 Pair',
      'Speaker Wall Plate 4 Pair',
    ],
    aliases: const ['hdmi plate', 'speaker plate', 'keystone insert'],
  );
}

List<WorkSupplyItem> _avCableAudioProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'AV Cable or Audio Distribution',
    unit: 'each',
    variants: [
      for (final length in ['3 ft', '6 ft', '10 ft', '15 ft', '25 ft', '50 ft'])
        for (final type in [
          'HDMI Cable',
          'High Speed HDMI Cable',
          'USB-C Cable',
        ])
          '$length $type',
      for (final length in ['25 ft', '50 ft', '100 ft'])
        for (final type in ['In-Wall HDMI Cable', 'Optical Audio Cable'])
          '$length $type',
      for (final zone in ['Single Zone', '2 Zone', '4 Zone', '6 Zone'])
        '$zone Speaker Selector',
      for (final color in ['White', 'Ivory', 'Black'])
        '$color In-Wall Volume Control',
      'Banana Plug 12 Pack',
      'Speaker Wire Wall Bushing',
      'IR Repeater Kit',
      'IR Receiver Target',
      'IR Emitter Pack',
      'HDMI Extender Over Cat6',
      'USB Extender Over Cat6',
    ],
    aliases: const [
      'hdmi cable',
      'usb-c cable',
      'speaker selector',
      'volume control',
      'ir repeater',
    ],
  );
}

List<WorkSupplyItem> _patchCordAdapterProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Patch Cable or AV Adapter',
    unit: 'each',
    variants: [
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final length in ['1 ft', '3 ft', '5 ft', '7 ft', '10 ft', '15 ft'])
          for (final color in ['Blue', 'White', 'Black'])
            '$rating $length $color Patch Cord',
      'HDMI Female Female Coupler',
      'HDMI Right Angle Adapter',
      'USB-C to HDMI Adapter',
      '3.5 mm Keystone Coupler',
      'Optical Audio Coupler',
      'RCA Keystone Coupler',
      'Speaker Banana Plug 24 Pack',
      'In-Wall Speaker Pair 6.5 in',
      'In-Ceiling Speaker Pair 8 in',
      'Outdoor Speaker Pair',
    ],
    aliases: const [
      'patch cord',
      'ethernet patch cable',
      'hdmi coupler',
      'speaker pair',
      'banana plug',
    ],
  );
}

List<WorkSupplyItem> _cameraSecurityProducts() {
  final cameraTypes = ['Dome', 'Bullet', 'Turret', 'Floodlight', 'PTZ'];
  final resolutions = ['2MP', '4MP', '5MP', '8MP'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Security Camera Material',
    unit: 'each',
    variants: [
      for (final type in cameraTypes)
        for (final resolution in resolutions) '$resolution PoE $type Camera',
      'Video Doorbell',
      'Doorbell Transformer',
      'PoE Camera Junction Box',
      'Camera Mounting Bracket',
      'NVR 4 Channel',
      'NVR 8 Channel',
      'NVR 16 Channel',
      'PoE Injector',
      '4 Port PoE Switch',
      '8 Port PoE Switch',
      '16 Port PoE Switch',
      'Security Camera Cable Tester',
    ],
    aliases: const ['poe camera', 'security camera', 'video doorbell', 'nvr'],
  );
}

List<WorkSupplyItem> _accessAlarmProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Access and Alarm Material',
    unit: 'each',
    variants: [
      'Door Contact Sensor',
      'Window Contact Sensor',
      'Recessed Door Contact',
      'Motion Detector',
      'Glass Break Sensor',
      'Alarm Keypad',
      'Alarm Siren',
      'Magnetic Door Lock',
      'Electric Strike',
      'Request to Exit Button',
      'Access Control Keypad',
      'RFID Card Reader',
      'Access Control Power Supply',
      '18/2 Alarm Wire Splice Connector Pack',
      'Gel Filled Low Voltage Splice Pack',
    ],
    aliases: const ['door contact', 'alarm sensor', 'access control'],
  );
}

List<WorkSupplyItem> _smartHomeControlProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Smart Home Control Material',
    unit: 'each',
    variants: [
      for (final type in ['Wi-Fi', 'Z-Wave', 'Zigbee'])
        for (final device in [
          'Smart Lock',
          'Smart Dimmer',
          'Smart Switch',
          'Smart Plug',
          'Smart Thermostat',
          'Water Leak Sensor',
          'Door Window Sensor',
          'Motion Sensor',
        ])
          '$type $device',
      'Smart Home Hub',
      'Garage Door Controller',
      'Smart Smoke Alarm',
      'Smart Carbon Monoxide Alarm',
      'Smart Siren',
      'Smart Keypad',
      '24V Doorbell Transformer',
      'Doorbell Chime Module',
      'Thermostat C-Wire Adapter',
      'Low Voltage Relay Module',
    ],
    aliases: const [
      'smart lock',
      'smart switch',
      'smart thermostat',
      'leak sensor',
      'c-wire adapter',
    ],
  );
}

List<WorkSupplyItem> _cameraPowerProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Camera Doorbell or Accessory',
    unit: 'each',
    variants: const [
      'Security Camera Junction Box',
      'Security Camera Pole Mount',
      'Security Camera Corner Mount',
      'Security Camera Pendant Mount',
      'Weatherproof Camera Enclosure',
      '12V CCTV Power Supply',
      '24V AC CCTV Power Supply',
      'Security DVR Hard Drive 2TB',
      'Security DVR Hard Drive 4TB',
      'Doorbell Chime Kit',
      'Doorbell Power Kit',
      'Doorbell Angle Mount',
      'Video Doorbell Wedge Kit',
      'Exit Button Stainless',
      'Emergency Exit Pull Station',
      'Request to Exit Motion Sensor',
      'Door Loop Armored Cable',
      'Access Control Battery Backup',
    ],
    aliases: const [
      'camera junction box',
      'camera mount',
      'cctv power supply',
      'doorbell chime',
      'doorbell power kit',
      'exit button',
      'request to exit',
    ],
  );
}

List<WorkSupplyItem> _testerProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Tester',
    unit: 'each',
    variants: const [
      'Basic Network Cable Tester',
      'PoE Network Cable Tester',
      'Tone Generator and Probe Set',
      'Pro Tone Generator and Probe Set',
      'Network Cable Certifier',
      'Coax Cable Tester',
      'Fiber Visual Fault Locator',
      'Fiber Power Meter',
      'Wire Tracer',
      'Continuity Tester',
      'Outlet Ethernet Tester',
      'PoE Detector',
    ],
    aliases: const ['ethernet tester', 'toner', 'fox and hound', 'vfl'],
  );
}

List<WorkSupplyItem> _terminationToolProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Tool',
    unit: 'each',
    variants: const [
      '110 Punchdown Tool',
      '66 Punchdown Tool',
      'Multi Blade Punchdown Tool',
      'Impact Punchdown Tool',
      'RJ45 Crimp Tool',
      'Pass-Through RJ45 Crimp Tool',
      'Modular Plug Crimp Tool',
      'Coax Compression Tool RG6',
      'Coax Compression Tool RG6 RG59 Combo',
      'Cable Jacket Stripper',
      'UTP Cable Stripper',
      'Coax Cable Stripper',
      'Fiber Stripper',
      'Kevlar Fiber Shears',
      'Fish Tape Low Voltage',
      'Glow Rod Kit',
      'Cable Staple Gun',
      'Low Voltage Cable Staple Pack',
    ],
    aliases: const ['punchdown', 'rj45 crimper', 'coax crimper', 'stripper'],
  );
}

List<WorkSupplyItem> _cableManagementProducts() {
  final lengths = ['6 in', '8 in', '11 in', '12 in', '18 in'];
  final colors = ['Black', 'White', 'Natural'];
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Cable Management',
    unit: 'pack',
    variants: [
      for (final length in lengths)
        for (final color in colors) '$length $color Cable Tie Pack',
      'Hook and Loop Cable Tie Roll',
      'Velcro Cable Tie Roll',
      'Low Voltage Cable Label Pack',
      'Wire Marker Book',
      'Cable Identification Tag Pack',
      '1 in Cable Raceway',
      '1-1/2 in Cable Raceway',
      'Corner Cable Raceway Fitting',
      'Surface Mount Raceway Box',
      'J-Hook Cable Support Pack',
      'Bridle Ring Cable Support Pack',
      'Cable D-Ring Pack',
      'Rack Cable Manager 1U',
      'Rack Cable Manager 2U',
      '12U Wall Mount Network Rack',
      '6U Wall Mount Network Rack',
      'Patch Cable Organizer',
    ],
    aliases: const ['cable tie', 'velcro tie', 'cable label', 'j hook'],
  );
}

List<WorkSupplyItem> _rackPowerProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Rack and Structured Wiring Hardware',
    unit: 'each',
    variants: [
      for (final size in ['1U', '2U', '3U'])
        for (final item in ['Rack Shelf', 'Vent Panel', 'Cable Manager'])
          '$size $item',
      for (final size in ['6U', '9U', '12U', '18U'])
        '$size Wall Mount Network Rack',
      for (final port in ['4 Port', '8 Port', '16 Port', '24 Port'])
        '$port Patch Panel',
      for (final outlet in ['6 Outlet', '8 Outlet', '12 Outlet'])
        '$outlet Rack PDU',
      for (final power in ['30W', '60W', '90W']) '$power PoE Injector',
      for (final port in ['4 Port', '8 Port', '16 Port']) '$port PoE Switch',
      'PoE Splitter',
      'PoE Extender',
      'Fiber Distribution Box',
      'Fiber Splice Tray',
      'DIN Rail Low Voltage Enclosure',
      'Structured Wiring Ground Bar',
      'Cable Ladder Bracket',
      'Rack Screw Cage Nut Pack',
    ],
    aliases: const [
      'network rack',
      'rack shelf',
      'rack pdu',
      'poe splitter',
      'fiber distribution box',
    ],
  );
}

List<WorkSupplyItem> _rackServiceProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Rack Service Hardware',
    unit: 'each',
    variants: [
      for (final size in ['1U', '2U', '4U']) '$size Rack Drawer',
      for (final size in ['1U', '2U']) '$size Brush Panel',
      for (final size in ['1U', '2U']) '$size Blank Panel',
      for (final size in ['1U', '2U']) '$size Rack Fan Panel',
      'Rack Mount UPS 750VA',
      'Rack Mount UPS 1500VA',
      'Rack Grounding Bar',
      'Rack Shelf Deep',
      'Rack Shelf Vented',
      'Rack Screw 50 Pack',
      'Cage Nut 50 Pack',
      'Cable Ladder Wall Bracket',
      'Ladder Rack J-Bolt Kit',
      'Velcro One Wrap Roll',
    ],
    aliases: const [
      'rack drawer',
      'brush panel',
      'blank panel',
      'rack fan',
      'rack ups',
      'cage nut',
      'velcro wrap',
    ],
  );
}

List<WorkSupplyItem> _pathwayProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Low Voltage Pathway Supply',
    unit: 'each',
    variants: [
      for (final size in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
        for (final length in ['25 ft', '50 ft', '100 ft'])
          '$size $length Smurf Tube Flexible Raceway',
      for (final size in ['1 in', '1-1/2 in', '2 in'])
        for (final fitting in [
          'Cable Raceway',
          'Raceway Inside Corner',
          'Raceway Outside Corner',
          'Raceway Tee Fitting',
          'Raceway Coupler',
          'Raceway End Cap',
        ])
          '$size $fitting',
      for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
        for (final item in [
          'J-Hook Cable Support',
          'Bridle Ring Cable Support',
          'Cable D-Ring',
          'Beam Clamp Cable Hanger',
          'Low Voltage Cable Staple',
          'Cable Nail Plate',
          'Pull String Dispenser',
          'Cable Identification Tag',
        ])
          '$item $pack',
      for (final size in ['14 in', '28 in', '42 in'])
        for (final item in [
          'Structured Media Enclosure',
          'Structured Media Hinged Door',
          'Structured Media Trim Ring',
          'Structured Media Power Module',
          'Structured Media Shelf',
        ])
          '$size $item',
    ],
    aliases: const [
      'smurf tube',
      'flexible raceway',
      'j hook',
      'bridle ring',
      'structured media enclosure',
      'pull string',
    ],
  );
}

List<WorkSupplyItem> _networkFiberDetailProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Network Fiber Detail Supply',
    unit: 'each',
    variants: [
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final port in ['6 Port', '12 Port', '24 Port', '48 Port'])
          '$rating $port Patch Panel',
      for (final rating in ['Cat5e', 'Cat6', 'Cat6A'])
        for (final color in ['White', 'Blue', 'Black', 'Orange', 'Green'])
          '$rating $color Slim Keystone Jack',
      for (final type in ['LC', 'SC', 'ST'])
        for (final mode in ['Single Mode', 'Multimode OM3', 'Multimode OM4'])
          '$type $mode Fiber Coupler',
      for (final type in ['LC', 'SC'])
        for (final mode in ['Single Mode', 'Multimode'])
          '$type $mode Fiber Pigtail 6 Pack',
      for (final item in [
        'Fiber Distribution Panel',
        'Fiber Splice Cassette',
        'Fiber Splice Sleeve 100 Pack',
        'Fiber Cleaning Pen',
        'Fiber Cleaning Wipe 50 Pack',
        'SFP Transceiver 1G',
        'SFP Plus Transceiver 10G',
        'PoE Injector 30W',
        'PoE Injector 60W',
        'PoE Injector 90W',
        'PoE Splitter 12V',
        'PoE Extender Outdoor',
      ])
        item,
    ],
    aliases: const [
      'patch panel',
      'slim keystone',
      'fiber coupler',
      'fiber pigtail',
      'sfp transceiver',
      'poe injector',
    ],
  );
}

List<WorkSupplyItem> _securityAccessDetailProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'Security Access Detail Supply',
    unit: 'each',
    variants: [
      for (final type in ['Surface Mount', 'Recessed', 'Overhead Door'])
        for (final device in ['Door Contact', 'Window Contact'])
          '$type $device Sensor',
      for (final device in [
        'Glass Break Sensor',
        'PIR Motion Detector',
        'Dual Tech Motion Detector',
        'Panic Button',
        'Alarm Siren',
        'Alarm Strobe',
        'Alarm Keypad',
        'Alarm Backup Battery',
        'Alarm Panel Transformer',
        '2 Wire Smoke Detector',
        '4 Wire Smoke Detector',
        'Heat Detector',
        'Water Leak Sensor',
      ])
        device,
      for (final device in [
        'RFID Card Reader',
        'Keypad Card Reader',
        'Magnetic Door Lock',
        'Electric Door Strike',
        'Request To Exit Button',
        'Request To Exit Motion Sensor',
        'Door Loop Armored Cable',
        'Access Control Power Supply',
        'Access Control Battery Backup',
        'Exit Pull Station',
      ])
        device,
      for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
        for (final item in [
          'Gel Filled Alarm Splice',
          'B Connector Alarm Splice',
          'End Of Line Resistor',
          'Security Cable Label',
        ])
          '$item $pack',
    ],
    aliases: const [
      'door contact',
      'glass break',
      'motion detector',
      'alarm battery',
      'card reader',
      'electric strike',
      'request to exit',
    ],
  );
}

List<WorkSupplyItem> _avSmartHomeDetailProducts() {
  return _lowVoltageGeneratedVariants(
    baseName: 'AV Smart Home Detail Supply',
    unit: 'each',
    variants: [
      for (final color in ['White', 'Ivory', 'Black'])
        for (final item in [
          'HDMI Keystone Insert',
          'USB-C Keystone Insert',
          'RCA Keystone Insert',
          'Speaker Binding Post Plate',
          'Brush Pass Through Plate',
          'Cable Pass Through Plate',
        ])
          '$color $item',
      for (final length in ['6 ft', '10 ft', '15 ft', '25 ft', '50 ft'])
        for (final cable in [
          '8K HDMI Cable',
          'Active HDMI Cable',
          'Optical HDMI Cable',
          'USB-C Video Cable',
          'Optical Audio Cable',
        ])
          '$length $cable',
      for (final zone in ['2 Zone', '4 Zone', '6 Zone', '8 Zone'])
        for (final item in ['Speaker Selector', 'Speaker Volume Control'])
          '$zone $item',
      for (final item in [
        'In-Wall Speaker Pair 6.5 in',
        'In-Wall Speaker Pair 8 in',
        'In-Ceiling Speaker Pair 6.5 in',
        'In-Ceiling Speaker Pair 8 in',
        'Outdoor Speaker Pair',
        'IR Repeater Kit',
        'IR Receiver Target',
        'IR Emitter 4 Pack',
        'Smart Hub',
        'Smart Keypad',
        'Garage Door Controller',
        'Doorbell Chime Module',
        'Doorbell Angle Mount',
        'Video Doorbell Wedge Kit',
        'Thermostat C-Wire Adapter',
        'Low Voltage Relay Module',
      ])
        item,
    ],
    aliases: const [
      'hdmi keystone',
      'pass through plate',
      '8k hdmi',
      'speaker selector',
      'in wall speaker',
      'ir repeater',
      'smart hub',
      'doorbell wedge',
    ],
  );
}

List<WorkSupplyItem> _lowVoltageGeneratedVariants({
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
