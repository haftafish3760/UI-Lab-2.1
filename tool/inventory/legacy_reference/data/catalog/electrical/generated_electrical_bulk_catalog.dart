part of '../../work_supply_catalog.dart';

final electricalGeneratedBulkCatalogCategory = _category(
  'Bulk Electrical Catalog Pack',
  [
    _system('Bulk Wire by Size Color and Length', [
      _type(
        'Bulk Copper THHN THWN Wire',
        _electricalProducts(
          baseName: 'Copper THHN THWN Wire',
          unit: 'roll',
          variants: [
            for (final gauge in [
              ..._electricalThhnGauges,
              ..._electricalLargeWireSizes,
            ])
              for (final color in _electricalBulkWireColors)
                for (final length in [
                  '25 ft',
                  '50 ft',
                  '100 ft',
                  '250 ft',
                  '500 ft',
                  '1000 ft',
                ])
                  '$gauge $color $length',
          ],
          aliases: const ['thhn', 'thwn', 'building wire', 'single conductor'],
        ),
      ),
      _type(
        'Bulk Aluminum XHHW Wire',
        _electricalProducts(
          baseName: 'Aluminum XHHW Wire',
          unit: 'roll',
          variants: [
            for (final gauge in _electricalLargeWireSizes)
              for (final color in ['Black', 'White', 'Red', 'Green'])
                for (final length in ['25 ft', '50 ft', '100 ft', '250 ft'])
                  '$gauge $color $length',
          ],
          aliases: const ['xhhw', 'aluminum wire', 'service wire'],
        ),
      ),
      _type(
        'Bulk Armored Cable',
        _electricalProducts(
          baseName: 'Armored Cable',
          unit: 'roll',
          variants: [
            for (final cable in [
              '14/2',
              '14/3',
              '12/2',
              '12/3',
              '10/2',
              '10/3',
              '8/2',
              '8/3',
            ])
              for (final style in ['MC', 'AC', 'Greenfield'])
                for (final length in ['25 ft', '50 ft', '100 ft', '250 ft'])
                  '$cable $style $length',
          ],
          aliases: const ['mc cable', 'ac cable', 'armored cable', 'bx'],
        ),
      ),
    ]),
    _system('Bulk Raceway Fittings by Material', [
      _type(
        'Bulk Raceway Bodies and Fittings',
        _electricalProducts(
          baseName: 'Raceway Fitting',
          unit: 'each',
          variants: [
            for (final material in [
              'EMT',
              'Rigid',
              'IMC',
              'PVC Schedule 40',
              'PVC Schedule 80',
            ])
              for (final size in _electricalBulkRacewaySizes)
                for (final part in [
                  'Conduit',
                  '90 Elbow',
                  '45 Elbow',
                  'Coupling',
                  'Connector',
                  'Compression Connector',
                  'Set Screw Connector',
                  'Strap',
                  'Offset Nipple',
                  'Chase Nipple',
                  'Locknut',
                  'Bushing',
                  'Insulated Bushing',
                  'LB Body',
                  'LL Body',
                  'LR Body',
                  'T Body',
                  'C Body',
                  'Expansion Coupling',
                  'Reducing Washer',
                ])
                  '$material $size $part',
          ],
          aliases: const ['conduit fitting', 'raceway', 'pipe fitting'],
        ),
      ),
      _type(
        'Bulk Flexible Raceway',
        _electricalProducts(
          baseName: 'Flexible Raceway Material',
          unit: 'each',
          variants: [
            for (final material in [
              'FMC',
              'Liquidtight',
              'Flexible Metal',
              'Nonmetallic Liquidtight',
            ])
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
                  'Conduit',
                  'Straight Connector',
                  '90 Connector',
                  'Coupling',
                  'Strap',
                  'Whip Kit',
                ])
                  '$material $size $part',
          ],
          aliases: const ['flex', 'sealtite', 'liquid tight', 'fmc'],
        ),
      ),
    ]),
    _system('Bulk Boxes Covers and Plates', [
      _type(
        'Bulk Device and Junction Boxes',
        _electricalProducts(
          baseName: 'Electrical Box',
          unit: 'each',
          variants: [
            for (final material in [
              'Plastic',
              'Metal',
              'Fiberglass',
              'Weatherproof',
            ])
              for (final work in ['New Work', 'Old Work', 'Surface Mount'])
                for (final gang in [
                  '1 Gang',
                  '2 Gang',
                  '3 Gang',
                  '4 Gang',
                  '5 Gang',
                  '6 Gang',
                ])
                  for (final depth in [
                    'Shallow',
                    'Standard',
                    'Deep',
                    'Extra Deep',
                  ])
                    '$material $work $gang $depth',
          ],
          aliases: const ['outlet box', 'switch box', 'junction box', 'j box'],
        ),
      ),
      _type(
        'Bulk Covers and Wall Plates',
        _electricalProducts(
          baseName: 'Electrical Cover Plate',
          unit: 'each',
          variants: [
            for (final gang in [
              '1 Gang',
              '2 Gang',
              '3 Gang',
              '4 Gang',
              '5 Gang',
              '6 Gang',
            ])
              for (final opening in [
                'Toggle',
                'Decorator',
                'Duplex',
                'GFCI',
                'Blank',
                'Round',
                'Single Receptacle',
                'Combination',
              ])
                for (final color in _electricalBulkDeviceColors)
                  for (final material in ['Nylon', 'Metal', 'Weatherproof'])
                    '$gang $opening $color $material',
          ],
          aliases: const [
            'wall plate',
            'cover',
            'switch plate',
            'device plate',
          ],
        ),
      ),
    ]),
    _system('Bulk Devices and Controls', [
      _type(
        'Bulk Receptacles Switches and Controls',
        _electricalProducts(
          baseName: 'Wiring Device',
          unit: 'each',
          variants: [
            for (final amps in ['15 Amp', '20 Amp'])
              for (final style in [
                'Duplex Receptacle',
                'Tamper Resistant Receptacle',
                'Weather Resistant Receptacle',
                'GFCI Receptacle',
                'AFCI Receptacle',
                'USB Receptacle',
                'Single-Pole Switch',
                '3-Way Switch',
                '4-Way Switch',
                'Dimmer',
                'Timer Switch',
                'Occupancy Sensor',
                'Motion Switch',
                'Fan Control',
                'Pilot Light Switch',
              ])
                for (final grade in [
                  'Residential',
                  'Commercial',
                  'Spec Grade',
                  'Decorator',
                ])
                  for (final color in _electricalBulkDeviceColors)
                    for (final pack in [
                      'Single',
                      '2 Pack',
                      '5 Pack',
                      '10 Pack',
                      'Contractor Pack',
                    ])
                      '$amps $style $grade $color $pack',
          ],
          aliases: const ['outlet', 'receptacle', 'switch', 'device', 'gfi'],
        ),
      ),
      _type(
        'Bulk Specialty Controls',
        _electricalProducts(
          baseName: 'Electrical Control Device',
          unit: 'each',
          variants: [
            for (final volts in ['120V', '240V', '277V'])
              for (final control in [
                'Photocell',
                'Time Clock',
                'Contactor',
                'Relay',
                'Doorbell Transformer',
                'Low Voltage Transformer',
                'Fan Speed Control',
                'Motor Rated Switch',
              ])
                for (final rating in ['15 Amp', '20 Amp', '30 Amp', '40 Amp'])
                  '$volts $rating $control',
          ],
          aliases: const ['control', 'relay', 'photocell', 'time clock'],
        ),
      ),
    ]),
    _system('Bulk Breakers Panels and Service', [
      _type(
        'Bulk Breakers',
        _electricalProducts(
          baseName: 'Breaker Catalog Item',
          unit: 'each',
          variants: [
            for (final amps in [
              '15 Amp',
              '20 Amp',
              '25 Amp',
              '30 Amp',
              '35 Amp',
              '40 Amp',
              '45 Amp',
              '50 Amp',
              '60 Amp',
              '70 Amp',
              '80 Amp',
              '90 Amp',
              '100 Amp',
            ])
              for (final poles in ['Single-Pole', 'Double-Pole', 'Triple-Pole'])
                for (final function in [
                  'Standard',
                  'GFCI',
                  'AFCI',
                  'Dual Function',
                  'Tandem',
                  'Quad',
                ])
                  '$amps $poles $function',
          ],
          aliases: const ['breaker', 'brkr', 'circuit breaker'],
        ),
      ),
      _type(
        'Bulk Panel Service Parts',
        _electricalProducts(
          baseName: 'Panel and Service Part',
          unit: 'each',
          variants: [
            for (final amps in [
              '100 Amp',
              '125 Amp',
              '150 Amp',
              '200 Amp',
              '225 Amp',
              '400 Amp',
            ])
              for (final part in [
                'Main Breaker Panel',
                'Main Lug Panel',
                'Meter Main',
                'Outdoor Panel',
                'Indoor Panel',
                'Load Center',
                'Sub Panel',
                'Panel Cover',
              ])
                '$amps $part',
          ],
          aliases: const ['panel', 'load center', 'service equipment'],
        ),
      ),
    ]),
    _system('Bulk Lighting Lamps and Supplies', [
      _type(
        'Bulk Lamps',
        _electricalProducts(
          baseName: 'Lamp',
          unit: 'each',
          variants: [
            for (final shape in [
              'A19',
              'A21',
              'BR30',
              'BR40',
              'PAR20',
              'PAR30',
              'PAR38',
              'T8',
              'T5',
              'MR16',
            ])
              for (final temp in [
                '2700K',
                '3000K',
                '3500K',
                '4000K',
                '5000K',
                '6500K',
              ])
                for (final watt in ['6W', '9W', '12W', '15W', '18W', '24W'])
                  '$shape $temp $watt LED',
          ],
          aliases: const ['bulb', 'lamp', 'led bulb', 'tube'],
        ),
      ),
      _type(
        'Bulk Fixtures',
        _electricalProducts(
          baseName: 'Light Fixture',
          unit: 'each',
          variants: [
            for (final style in [
              'Recessed',
              'Flush Mount',
              'Vanity',
              'Pendant',
              'Outdoor Wall',
              'Flood',
              'Area',
              'Shop',
              'Strip',
              'Emergency',
            ])
              for (final finish in [
                'White',
                'Black',
                'Bronze',
                'Nickel',
                'Chrome',
              ])
                for (final temp in ['3000K', '4000K', '5000K'])
                  '$style $finish $temp',
          ],
          aliases: const ['fixture', 'luminaire', 'light'],
        ),
      ),
    ]),
    _system('Bulk Fasteners Grounding and Consumables', [
      _type(
        'Bulk Wire Connector Packs',
        _electricalProducts(
          baseName: 'Wire Connector',
          unit: 'pack',
          variants: [
            for (final style in [
              'Winged',
              'Standard',
              'Push-In',
              'Lever',
              'Gel-Filled',
              'High Temp',
            ])
              for (final color in [
                'Yellow',
                'Red',
                'Blue',
                'Tan',
                'Orange',
                'Gray',
              ])
                for (final pack in [
                  '25 Pack',
                  '50 Pack',
                  '100 Pack',
                  '250 Pack',
                ])
                  '$style $color $pack',
          ],
          aliases: const [
            'wire nut',
            'wire nuts',
            'wirenut',
            'winged wire nut',
            'twist connector',
            'wire connector',
          ],
        ),
      ),
      _type(
        'Bulk Electrical Fasteners and Consumables',
        _electricalProducts(
          baseName: 'Electrical Consumable',
          unit: 'pack',
          variants: [
            for (final item in [
              'Cable Staple',
              'Conduit Strap Screw',
              'Ground Screw',
              'Machine Screw',
              'Self Tapping Screw',
              'Toggle Bolt',
              'Plastic Anchor',
              'Wire Connector',
              'Crimp Connector',
              'Spade Terminal',
              'Ring Terminal',
              'Butt Splice',
              'Heat Shrink',
              'Electrical Tape',
              'Pull String',
              'Wire Marker',
              'Zip Tie',
              'Cable Clamp',
              'Anti Oxidant Compound',
              'Duct Seal',
            ])
              for (final size in [
                'Small',
                'Medium',
                'Large',
                '1/2 in',
                '3/4 in',
                '1 in',
                '#6',
                '#8',
                '#10',
                '1/4 in',
              ])
                for (final pack in [
                  '10 Pack',
                  '25 Pack',
                  '50 Pack',
                  '100 Pack',
                  '250 Pack',
                ])
                  '$size $item $pack',
          ],
          aliases: const [
            'electrical supply',
            'connector',
            'fastener',
            'sheet metal screw',
            'tek screw',
            'zip screw',
            'self tapping screw',
            'wall anchor',
            'masonry screw',
          ],
        ),
      ),
      _type(
        'Bulk Grounding and Bonding',
        _electricalProducts(
          baseName: 'Grounding and Bonding Part',
          unit: 'each',
          variants: [
            for (final size in [
              '14 AWG',
              '12 AWG',
              '10 AWG',
              '8 AWG',
              '6 AWG',
              '4 AWG',
              '2 AWG',
              '1/0 AWG',
              '2/0 AWG',
              '4/0 AWG',
            ])
              for (final part in [
                'Bare Copper Wire',
                'Green Insulated Wire',
                'Bonding Jumper',
                'Ground Pigtail',
              ])
                '$size $part',
            for (final rod in ['1/2 in', '5/8 in', '3/4 in'])
              for (final part in [
                'Ground Rod',
                'Ground Rod Clamp',
                'Acorn Clamp',
                'Split Bolt',
              ])
                '$rod $part',
          ],
          aliases: const ['ground', 'bonding', 'ground rod', 'ground clamp'],
        ),
      ),
    ]),
  ],
);
