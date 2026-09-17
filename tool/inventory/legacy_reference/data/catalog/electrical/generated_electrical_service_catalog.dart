part of '../../work_supply_catalog.dart';

final electricalGeneratedServiceCatalogCategory = _category(
  'Expanded Electrical Service Stock',
  [
    _system('Expanded Wire and Cable', [
      _type(
        'Expanded NM-B Cable Rolls',
        _electricalProducts(
          baseName: 'NM-B Cable Roll',
          unit: 'roll',
          variants: [
            for (final cable in _electricalNmbCableSizes)
              for (final length in _electricalCommonCableLengths)
                '$cable x $length',
          ],
          aliases: const ['romex', 'nmb', 'house wire', 'with ground', 'wg'],
        ),
      ),
      _type(
        'Expanded UF-B Cable Rolls',
        _electricalProducts(
          baseName: 'UF-B Cable Roll',
          unit: 'roll',
          variants: [
            for (final cable in _electricalUfbCableSizes)
              for (final length in ['25 ft', '50 ft', '100 ft', '250 ft'])
                '$cable x $length',
          ],
          aliases: const ['uf cable', 'underground feeder', 'direct burial'],
        ),
      ),
      _type(
        'Expanded THHN Copper Wire Rolls',
        _electricalProducts(
          baseName: 'THHN Copper Wire',
          unit: 'roll',
          variants: [
            for (final gauge in _electricalThhnGauges)
              for (final color in _electricalWireColors)
                for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
                  '$gauge $color $length',
          ],
          aliases: const [
            'building wire',
            'thwn',
            'stranded wire',
            'solid wire',
          ],
        ),
      ),
      _type(
        'Expanded Service Entrance Cable',
        _electricalProducts(
          baseName: 'Service Entrance Cable',
          unit: 'foot',
          variants: [
            for (final cable in _electricalServiceCableSizes)
              for (final style in ['SER', 'SEU']) '$cable $style',
          ],
          aliases: const ['ser cable', 'seu cable', 'service cable'],
        ),
      ),
      _type(
        'Expanded Low Voltage Cable',
        _electricalProducts(
          baseName: 'Low Voltage Cable',
          unit: 'roll',
          variants: [
            for (final cable in [
              '18/2',
              '18/4',
              '18/5',
              '18/7',
              '16/2',
              '14/2',
            ])
              for (final length in ['50 ft', '100 ft', '250 ft', '500 ft'])
                '$cable x $length',
          ],
          aliases: const ['control wire', 'doorbell wire', 'landscape wire'],
        ),
      ),
    ]),
    _system('Expanded Breakers and Disconnects', [
      _type(
        'Expanded Standard Breakers',
        _electricalProducts(
          baseName: 'Circuit Breaker',
          unit: 'each',
          variants: [
            for (final amps in [
              '15 Amp',
              '20 Amp',
              '25 Amp',
              '30 Amp',
              '40 Amp',
              '50 Amp',
              '60 Amp',
            ])
              for (final pole in ['Single-Pole', 'Double-Pole']) '$amps $pole',
          ],
          aliases: const ['breaker', 'brkr', 'circuit breaker'],
        ),
      ),
      _type(
        'Expanded Specialty Breakers',
        _electricalProducts(
          baseName: 'Specialty Circuit Breaker',
          unit: 'each',
          variants: [
            for (final amps in [
              '15 Amp',
              '20 Amp',
              '30 Amp',
              '40 Amp',
              '50 Amp',
            ])
              for (final style in ['GFCI', 'AFCI', 'Dual Function'])
                '$amps $style Single-Pole',
            for (final amps in ['20 Amp', '30 Amp', '40 Amp', '50 Amp'])
              '$amps GFCI Double-Pole',
          ],
          aliases: const [
            'gfci breaker',
            'afci breaker',
            'dual function breaker',
          ],
        ),
      ),
      _type(
        'Expanded Disconnects',
        _electricalProducts(
          baseName: 'Electrical Disconnect',
          unit: 'each',
          variants: const [
            '30 Amp Non-Fusible AC Disconnect',
            '60 Amp Non-Fusible AC Disconnect',
            '30 Amp Fusible AC Disconnect',
            '60 Amp Fusible AC Disconnect',
            '100 Amp Safety Switch',
            '200 Amp Safety Switch',
          ],
          aliases: const [
            'ac disconnect',
            'safety switch',
            'pullout disconnect',
          ],
        ),
      ),
    ]),
    _system('Expanded Devices and Plates', [
      _type(
        'Expanded Receptacles',
        _electricalProducts(
          baseName: 'Receptacle',
          unit: 'each',
          variants: [
            for (final amps in ['15 Amp', '20 Amp'])
              for (final style in [
                'Duplex',
                'Tamper Resistant',
                'GFCI',
                'Weather Resistant GFCI',
                'USB',
              ])
                for (final color in _electricalDeviceColors)
                  '$amps $style $color',
          ],
          aliases: const ['outlet', 'plug', 'wall receptacle', 'gfi'],
        ),
      ),
      _type(
        'Expanded Switches',
        _electricalProducts(
          baseName: 'Wall Switch',
          unit: 'each',
          variants: [
            for (final style in [
              'Single-Pole',
              '3-Way',
              '4-Way',
              'Dimmer',
              'Timer',
              'Occupancy Sensor',
            ])
              for (final color in _electricalDeviceColors) '$style $color',
          ],
          aliases: const ['light switch', 'toggle switch', 'decorator switch'],
        ),
      ),
      _type(
        'Expanded Smart Controls and Sensors',
        _electricalProducts(
          baseName: 'Smart Control Device',
          unit: 'each',
          variants: [
            for (final control in [
              'Smart Dimmer',
              'Smart Switch',
              'Smart Fan Control',
              'Motion Sensor Switch',
              'Occupancy Sensor Switch',
              'Vacancy Sensor Switch',
              'Timer Switch',
              'Countdown Timer Switch',
            ])
              for (final color in _electricalDeviceColors) '$control $color',
          ],
          aliases: const [
            'smart switch',
            'smart dimmer',
            'motion switch',
            'occupancy sensor',
            'timer switch',
          ],
        ),
      ),
      _type(
        'Expanded Safety and Alarm Devices',
        _electricalProducts(
          baseName: 'Electrical Safety Device',
          unit: 'each',
          variants: const [
            'Hardwired Smoke Alarm',
            'Hardwired Smoke Alarm with Battery Backup',
            'Hardwired Carbon Monoxide Alarm',
            'Combination Smoke and Carbon Monoxide Alarm',
            'Photoelectric Smoke Alarm',
            'Ionization Smoke Alarm',
            'Heat Alarm',
            'Doorbell Transformer',
            'Doorbell Chime',
            'Video Doorbell Power Kit',
          ],
          aliases: const [
            'smoke alarm',
            'smoke detector',
            'co alarm',
            'carbon monoxide',
            'doorbell transformer',
          ],
        ),
      ),
      _type(
        'Expanded Wall Plates',
        _electricalProducts(
          baseName: 'Wall Plate',
          unit: 'each',
          variants: [
            for (final gangs in ['1 Gang', '2 Gang', '3 Gang', '4 Gang'])
              for (final opening in ['Toggle', 'Decorator', 'Duplex', 'Blank'])
                for (final color in _electricalDeviceColors)
                  '$gangs $opening $color',
          ],
          aliases: const ['cover plate', 'device plate', 'switch plate'],
        ),
      ),
      _type(
        'Expanded Fan and Fixture Support Boxes',
        _electricalProducts(
          baseName: 'Fixture Support Box',
          unit: 'each',
          variants: [
            for (final style in [
              'Ceiling Fan Rated',
              'Ceiling Fan Brace',
              'Round Ceiling',
              'Pancake Ceiling',
              'Octagon Ceiling',
              'Adjustable Bar Hanger',
            ])
              for (final work in ['New Work', 'Old Work', 'Remodel'])
                '$work $style',
          ],
          aliases: const [
            'fan box',
            'ceiling box',
            'fixture box',
            'bar hanger',
            'fan brace',
          ],
        ),
      ),
      _type(
        'Expanded Box Accessories',
        _electricalProducts(
          baseName: 'Electrical Box Accessory',
          unit: 'each',
          variants: [
            for (final size in ['1/2 in', '3/4 in', '1 in'])
              for (final part in [
                'Knockout Seal',
                'Reducing Washer',
                'Locknut',
                'Plastic Bushing',
                'Grounding Clip',
                'Box Extender',
              ])
                '$size $part',
            'Single Gang Box Extender',
            'Two Gang Box Extender',
            'Mud Ring 1 Gang',
            'Mud Ring 2 Gang',
          ],
          aliases: const [
            'ko seal',
            'knockout seal',
            'mud ring',
            'box extender',
            'locknut',
          ],
        ),
      ),
    ]),
    _system('Expanded Boxes and Covers', [
      _type(
        'Expanded Device Boxes',
        _electricalProducts(
          baseName: 'Electrical Box',
          unit: 'each',
          variants: [
            for (final material in ['Plastic', 'Metal'])
              for (final work in ['New Work', 'Old Work'])
                for (final gang in ['1 Gang', '2 Gang', '3 Gang', '4 Gang'])
                  '$material $work $gang',
          ],
          aliases: const ['junction box', 'switch box', 'outlet box'],
        ),
      ),
      _type(
        'Expanded Junction Boxes',
        _electricalProducts(
          baseName: 'Junction Box',
          unit: 'each',
          variants: [
            for (final size in [
              '4 in Square',
              '4-11/16 in Square',
              '6 x 6 x 4',
              '8 x 8 x 4',
            ])
              for (final depth in ['1-1/2 in Deep', '2-1/8 in Deep', 'Deep'])
                '$size $depth',
          ],
          aliases: const ['j box', 'pull box', 'metal box'],
        ),
      ),
      _type(
        'Expanded Weatherproof Boxes and Covers',
        _electricalProducts(
          baseName: 'Weatherproof Electrical Part',
          unit: 'each',
          variants: [
            for (final gang in ['1 Gang', '2 Gang'])
              for (final part in [
                'Box',
                'In-Use Cover',
                'Blank Cover',
                'GFCI Cover',
              ])
                '$gang $part',
          ],
          aliases: const [
            'bell box',
            'outdoor cover',
            'weatherproof cover',
            'wp cover',
            'in use cover',
            'in-use cover',
            'bubble cover',
          ],
        ),
      ),
    ]),
    _system('Expanded Raceway and Fittings', [
      _type(
        'Expanded EMT Fittings',
        _electricalProducts(
          baseName: 'EMT Raceway Part',
          unit: 'each',
          variants: [
            for (final size in _electricalRacewaySizes)
              for (final part in _electricalEmtParts) '$size $part',
          ],
          aliases: const [
            'emt',
            'thinwall',
            'set screw',
            'compression fitting',
          ],
        ),
      ),
      _type(
        'Expanded PVC Electrical Fittings',
        _electricalProducts(
          baseName: 'PVC Electrical Raceway Part',
          unit: 'each',
          variants: [
            for (final size in _electricalRacewaySizes)
              for (final part in _electricalPvcRacewayParts) '$size $part',
          ],
          aliases: const ['gray pvc', 'electrical pvc', 'terminal adapter'],
        ),
      ),
      _type(
        'Expanded Conduit Bodies and Covers',
        _electricalProducts(
          baseName: 'Conduit Body Assembly',
          unit: 'each',
          variants: [
            for (final material in ['EMT', 'Rigid', 'PVC'])
              for (final size in _electricalRacewaySizes)
                for (final body in ['LB', 'LL', 'LR', 'T', 'C'])
                  '$material $size $body Body',
            for (final size in _electricalRacewaySizes)
              for (final body in ['LB', 'LL', 'LR', 'T', 'C'])
                '$size $body Body Cover and Gasket',
          ],
          aliases: const [
            'lb body',
            'll body',
            'lr body',
            'conduit body',
            'body cover',
          ],
        ),
      ),
      _type(
        'Expanded Raceway Hangers and Supports',
        _electricalProducts(
          baseName: 'Raceway Support',
          unit: 'each',
          variants: [
            for (final size in _electricalRacewaySizes)
              for (final support in [
                'Mini Strap',
                'One Hole Strap',
                'Two Hole Strap',
                'Minerallac Strap',
                'Conduit Hanger',
                'Beam Clamp',
                'Strut Clamp',
              ])
                '$size $support',
          ],
          aliases: const [
            'conduit strap',
            'one hole strap',
            'mini strap',
            'conduit hanger',
            'beam clamp',
          ],
        ),
      ),
      _type(
        'Expanded Flexible Raceway',
        _electricalProducts(
          baseName: 'Flexible Raceway Part',
          unit: 'each',
          variants: [
            for (final size in [
              '3/8 in',
              '1/2 in',
              '3/4 in',
              '1 in',
              '1-1/4 in',
              '1-1/2 in',
              '2 in',
            ])
              for (final part in [
                'FMC Connector',
                'FMC Conduit',
                'Liquidtight Connector',
                'Liquidtight Conduit',
              ])
                '$size $part',
          ],
          aliases: const ['flex conduit', 'liquid tight', 'sealtite', 'fmc'],
        ),
      ),
      _type(
        'Expanded Panel Accessories',
        _electricalProducts(
          baseName: 'Panel Accessory',
          unit: 'each',
          variants: [
            for (final amps in ['100 Amp', '125 Amp', '150 Amp', '200 Amp'])
              for (final part in [
                'Main Breaker Kit',
                'Main Lug Kit',
                'Ground Bar Kit',
                'Neutral Bar Kit',
                'Generator Interlock Kit',
                'Surge Protective Device',
              ])
                '$amps $part',
            'Panel Filler Plate Pack',
            'Breaker Filler Plate Pack',
            'Circuit Directory Label Pack',
            'Panel Schedule Label Pack',
            'Outdoor Hub Kit',
            'Meter Socket Hub Kit',
          ],
          aliases: const [
            'ground bar',
            'neutral bar',
            'breaker filler',
            'panel label',
            'interlock kit',
          ],
        ),
      ),
      _type(
        'Expanded Service Entrance Accessories',
        _electricalProducts(
          baseName: 'Service Entrance Accessory',
          unit: 'each',
          variants: [
            for (final size in ['1 in', '1-1/4 in', '1-1/2 in', '2 in'])
              for (final part in [
                'Service Entrance Head',
                'Service Mast Clamp',
                'Weatherhead',
                'Insulated Service Bushing',
                'Service Conduit Strap',
              ])
                '$size $part',
            'Meter Socket Hub',
            'Ground Bridge',
            'Intersystem Bonding Terminal',
            'Service Mast Flashing',
          ],
          aliases: const [
            'weatherhead',
            'service head',
            'mast clamp',
            'ground bridge',
            'bonding terminal',
          ],
        ),
      ),
    ]),
    _system('Expanded Connectors Grounding and Consumables', [
      _type(
        'Expanded Wire Connectors',
        _electricalProducts(
          baseName: 'Wire Connector',
          unit: 'pack',
          variants: [
            for (final size in [
              'Small',
              'Medium',
              'Large',
              'Red',
              'Yellow',
              'Blue',
              'Tan',
            ])
              for (final count in [
                '25 Pack',
                '50 Pack',
                '100 Pack',
                '250 Pack',
              ])
                '$size $count',
            for (final port in ['2 Port', '3 Port', '5 Port'])
              for (final count in ['10 Pack', '25 Pack', '50 Pack'])
                '$port Lever Connector $count',
            for (final count in ['10 Pack', '25 Pack'])
              for (final item in [
                'Inline Splice Connector',
                'Push-In Wire Connector',
                'Waterproof Wire Connector',
                'Butt Splice Connector',
                'Closed End Splice Connector',
                'Grounding Wire Connector',
                'Ideal Style Twister Wire Connector',
                'Compact Splicing Connector',
              ])
                '$item $count',
          ],
          aliases: const [
            'wire nut',
            'wirenut',
            'twist connector',
            'lever connector',
            'push in connector',
            'splice connector',
            'butt splice',
            'closed end splice',
            'compact connector',
            'grounding connector',
          ],
        ),
      ),
      _type(
        'Expanded Grounding',
        _electricalProducts(
          baseName: 'Grounding Part',
          unit: 'each',
          variants: [
            for (final wire in [
              '14 AWG',
              '12 AWG',
              '10 AWG',
              '8 AWG',
              '6 AWG',
              '4 AWG',
            ])
              '$wire Bare Copper Ground Wire',
            for (final size in ['1/2 in', '5/8 in', '3/4 in'])
              '$size Ground Rod Clamp',
            '8 ft Copper Ground Rod',
            'Grounding Pigtail Pack',
            'Green Ground Screw Pack',
            'Bonding Jumper',
          ],
          aliases: const [
            'ground wire',
            'ground rod',
            'bonding',
            'ground clamp',
          ],
        ),
      ),
      _type(
        'Expanded Electrical Consumables',
        _electricalProducts(
          baseName: 'Electrical Consumable',
          unit: 'pack',
          variants: const [
            '3/4 in Electrical Tape',
            'Color Coding Tape Pack',
            'Pull String 500 ft',
            'Fish Tape 50 ft',
            'Anti-Oxidant Compound',
            'Noalox Compound',
            'Cable Staples 100 Pack',
            'NM Cable Connector Pack',
            'Plastic Bushings Pack',
            'Reducing Washer Kit',
          ],
          aliases: const ['electric tape', 'pull string', 'cable staple'],
        ),
      ),
      _type(
        'Residential Electrical Service Repair Stock',
        _electricalProducts(
          baseName: 'Electrical Service Repair Part',
          unit: 'pack',
          variants: [
            for (final size in ['1/2 in', '3/4 in', '1 in'])
              for (final part in [
                'NM Cable Connector',
                'Romex Connector',
                'Metal Cable Clamp Connector',
                'Plastic Snap-In Connector',
                'FMC Connector',
                'Liquidtight Connector',
                'Reducing Washer Pair',
                'Conduit Locknut',
                'Insulated Bushing',
                'Knockout Seal',
              ])
                '$size $part',
            for (final color in ['Green', 'White', 'Black', 'Red'])
              for (final gauge in ['14 AWG', '12 AWG'])
                '$gauge $color Solid Pigtail 10 Pack',
            for (final item in [
              'Device Screw Assortment',
              'Wall Plate Screw Assortment',
              'Ground Screw 50 Pack',
              'Ground Pigtail 25 Pack',
              'Green Wire Nut 25 Pack',
              'Red Wire Connector 100 Pack',
              'Yellow Wire Connector 100 Pack',
              'Blue Wire Connector 100 Pack',
              'Outlet Spacer Shim Pack',
              'Receptacle Tester',
              'GFCI Tester',
              'Circuit Breaker Lockout',
              'Panel Filler Plate Pack',
              'Breaker Filler Plate Pack',
              'Wire Pulling Lubricant Quart',
              'Electrical Putty Pad',
              'Anti Short Bushing Assortment',
              'MC Anti Short Bushing 100 Pack',
              'Cable Ripper Tool',
              'Circuit Directory Label Pack',
              'Blank Panel Directory Card',
              'Voltage Detector Pen',
              'Continuity Tester',
              'Outlet Polarity Tester',
              'Wire Marker Number Book',
              'Panel Screw Assortment',
              'Device Yoke Repair Clip Pack',
              'Old Work Box Support Clip Pack',
            ])
              item,
          ],
          aliases: const [
            'romex connector',
            'nm connector',
            'wire connector',
            'wire nut',
            'ground pigtail',
            'ground screw',
            'device screw',
            'plate screw',
            'outlet spacer',
            'receptacle tester',
            'gfci tester',
            'breaker filler',
            'panel filler',
            'wire pulling lube',
            'putty pad',
            'anti short bushing',
            'red head bushing',
            'cable ripper',
            'circuit directory',
            'panel label',
            'voltage detector',
            'polarity tester',
            'wire marker',
            'yoke repair',
            'box support clip',
          ],
        ),
      ),
    ]),
    _system('Expanded Lighting and Lamps', [
      _type(
        'Expanded Residential Fixtures',
        _electricalProducts(
          baseName: 'Lighting Fixture',
          unit: 'each',
          variants: [
            for (final style in [
              'Flush Mount',
              'Vanity',
              'Recessed Trim',
              'Outdoor Wall',
              'Flood Light',
            ])
              for (final finish in [
                'White',
                'Black',
                'Bronze',
                'Brushed Nickel',
              ])
                '$style $finish',
          ],
          aliases: const ['light fixture', 'luminaire', 'recessed light'],
        ),
      ),
      _type(
        'Residential Lighting Service Parts',
        _electricalProducts(
          baseName: 'Lighting Service Part',
          unit: 'each',
          variants: [
            for (final style in [
              'Keyless Lampholder',
              'Pull Chain Lampholder',
              'Porcelain Lampholder',
              'Weatherproof Lampholder',
              'Fixture Crossbar',
              'Fixture Strap',
              'Fixture Stud Kit',
              'Canopy Screw Kit',
              'Ceiling Medallion Bracket',
              'Recessed Trim Spring Clip Pack',
              'Recessed Can Remodel Clip Pack',
              'T8 Tombstone Socket Pair',
              'T5 Tombstone Socket Pair',
              'Fluorescent Starter',
              'Lamp Cord Grip',
              'Pendant Cord Grip',
              'Fixture Chain Connector',
              'Photocell Button',
              'Outdoor Fixture Gasket',
              'Landscape Lighting Connector Pack',
            ])
              style,
          ],
          aliases: const [
            'lampholder',
            'porcelain lampholder',
            'fixture strap',
            'fixture crossbar',
            'recessed trim clip',
            'tombstone socket',
            'fluorescent starter',
            'photocell',
            'fixture gasket',
            'landscape connector',
          ],
        ),
      ),
      _type(
        'Expanded Lamps and LED Supplies',
        _electricalProducts(
          baseName: 'Lamp and LED Supply',
          unit: 'each',
          variants: [
            for (final shape in ['A19', 'BR30', 'PAR38', 'T8', 'T5'])
              for (final temp in ['2700K', '3000K', '4000K', '5000K'])
                '$shape $temp LED Lamp',
            '4 ft LED Shop Light',
            'LED Tape Light Kit',
            'LED Driver 12V',
            'LED Driver 24V',
          ],
          aliases: const ['bulb', 'lamp', 'led driver', 'tube light'],
        ),
      ),
    ]),
  ],
);
