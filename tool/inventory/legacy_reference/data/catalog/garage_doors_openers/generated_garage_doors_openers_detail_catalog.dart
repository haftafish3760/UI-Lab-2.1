part of '../../work_supply_catalog.dart';

final garageDoorsOpenersGeneratedDetailCatalogCategory = _category(
  'Garage Doors Openers Detail Stock',
  [
    _system('Garage Door Sections Tracks and Hardware', [
      _type(
        'Residential Garage Door Sections',
        _garageDoorProducts(
          baseName: 'Garage Door Section',
          unit: 'section',
          variants: [
            for (final width in ['8 ft', '9 ft', '10 ft', '12 ft', '16 ft'])
              for (final height in ['7 ft', '8 ft'])
                for (final style in _garageDoorStyles)
                  for (final color in _garageDoorColors)
                    for (final build in [
                      'Non Insulated',
                      'Insulated Steel',
                      'Polyurethane Insulated',
                    ])
                      '$color $width x $height $build $style Door Section',
          ],
          aliases: const [
            'garage door section',
            'replacement section',
            'door panel',
            'garage panel',
          ],
        ),
      ),
      _type(
        'Tracks Hinges Rollers and Brackets',
        _garageDoorProducts(
          baseName: 'Garage Door Track Hardware',
          unit: 'piece',
          variants: [
            for (final lift in ['Standard Lift', 'Low Headroom'])
              for (final radius in ['12 in Radius', '15 in Radius'])
                for (final side in ['Left', 'Right'])
                  '$lift $radius $side Vertical Track',
            for (final size in ['1-3/4 in', '2 in', '3 in'])
              for (final item in [
                'Nylon Roller 10 Pack',
                'Steel Roller 10 Pack',
                'Top Roller Bracket',
                'Bottom Fixture Bracket',
                'Flag Bracket Pair',
              ])
                '$size $item',
            for (final gauge in ['14 ga', '11 ga'])
              for (final number in ['Number 1', 'Number 2', 'Number 3'])
                '$gauge $number Garage Door Hinge',
          ],
          aliases: const [
            'garage door track',
            'vertical track',
            'garage door roller',
            'garage door hinge',
            'bottom bracket',
            'flag bracket',
          ],
        ),
      ),
    ]),
    _system('Springs Cables Drums and Balancing Parts', [
      _type(
        'Torsion and Extension Springs',
        _garageDoorProducts(
          baseName: 'Garage Door Spring',
          unit: 'each',
          variants: [
            for (final wire in _springWireSizes)
              for (final length in ['24 in', '28 in', '32 in', '36 in'])
                for (final wind in ['Left Wind', 'Right Wind'])
                  '$wire x $length Torsion Spring $wind',
            for (final doorWeight in [
              '90 lb',
              '110 lb',
              '130 lb',
              '150 lb',
              '170 lb',
            ])
              for (final length in ['25 in', '27 in', '29 in'])
                '$doorWeight $length Extension Spring Pair',
          ],
          aliases: const [
            'torsion spring',
            'extension spring',
            'garage spring',
            'left wind spring',
            'right wind spring',
          ],
        ),
      ),
      _type(
        'Cables Drums Bearings and Shaft Parts',
        _garageDoorProducts(
          baseName: 'Garage Door Balance Part',
          unit: 'each',
          variants: [
            for (final height in ['7 ft', '8 ft', '10 ft'])
              for (final cable in [
                'Lift Cable Pair',
                'Safety Cable Pair',
                'Cable Drum Pair',
              ])
                '$height $cable',
            for (final diameter in ['1 in', '1-1/4 in'])
              for (final item in [
                'Torsion Tube',
                'End Bearing Plate',
                'Center Bearing Plate',
                'Cable Drum',
                'Set Screw Collar',
              ])
                '$diameter $item',
          ],
          aliases: const [
            'lift cable',
            'safety cable',
            'cable drum',
            'torsion tube',
            'bearing plate',
          ],
        ),
      ),
    ]),
    _system('Openers Rails Controls and Safety Devices', [
      _type(
        'Garage Door Openers and Rail Kits',
        _garageDoorProducts(
          baseName: 'Garage Door Opener',
          unit: 'each',
          variants: [
            for (final drive in ['Chain Drive', 'Belt Drive', 'Screw Drive'])
              for (final horsepower in ['1/2 HP', '3/4 HP', '1 HP'])
                for (final feature in [
                  'Standard',
                  'Battery Backup',
                  'Wi-Fi Smart',
                ])
                  '$horsepower $drive $feature Opener',
            for (final height in ['7 ft', '8 ft', '10 ft'])
              for (final drive in ['Chain Drive', 'Belt Drive'])
                '$height $drive Opener Rail Extension Kit',
          ],
          aliases: const [
            'garage door opener',
            'chain drive opener',
            'belt drive opener',
            'opener rail',
            'rail extension',
          ],
        ),
      ),
      _type(
        'Remotes Wall Controls and Safety Sensors',
        _garageDoorProducts(
          baseName: 'Garage Door Opener Control',
          unit: 'each',
          variants: [
            for (final frequency in ['315 MHz', '390 MHz', 'Universal'])
              for (final item in [
                'Remote Control',
                'Keypad',
                'Wall Console',
                'Safety Sensor Pair',
                'Photo Eye Bracket Pair',
              ])
                '$frequency $item',
            for (final item in [
              'Smart Garage Hub',
              'Opener Logic Board',
              'Opener Gear and Sprocket Kit',
              'Opener Belt Kit',
              'Opener Chain Kit',
            ])
              item,
          ],
          aliases: const [
            'garage remote',
            'opener remote',
            'garage keypad',
            'wall console',
            'safety sensor',
            'photo eye',
          ],
        ),
      ),
    ]),
    _system('Seals Struts Locks and Installation Supplies', [
      _type(
        'Weather Seals Bottom Rubber and Stop Molding',
        _garageDoorProducts(
          baseName: 'Garage Door Seal',
          unit: 'piece',
          variants: [
            for (final length in ['8 ft', '9 ft', '10 ft', '16 ft', '18 ft'])
              for (final profile in [
                'T Style Bottom Seal',
                'Bulb Bottom Seal',
                'Threshold Seal',
                'Vinyl Stop Molding',
                'Side Weather Seal',
                'Top Weather Seal',
              ])
                '$length $profile',
          ],
          aliases: const [
            'garage door seal',
            'bottom seal',
            'threshold seal',
            'stop molding',
            'weather seal',
          ],
        ),
      ),
      _type(
        'Struts Locks Handles and Install Fasteners',
        _garageDoorProducts(
          baseName: 'Garage Door Install Supply',
          unit: 'each',
          variants: [
            for (final width in ['8 ft', '9 ft', '10 ft', '16 ft'])
              '$width Door Reinforcement Strut',
            for (final item in [
              'Inside Slide Lock',
              'T Handle Lock Kit',
              'Emergency Release Lock',
              'Decorative Handle Set',
              'Garage Door Lube Spray',
              'Lag Screw Track Fastener Pack',
              'Carriage Bolt Hinge Fastener Pack',
              'Track Bolt and Flange Nut Pack',
              'Self Drilling Opener Bracket Screw Pack',
              'Concrete Screw Jamb Anchor Pack',
              'Punched Angle Opener Hanger',
              'Spring Winding Bar Pair',
              'Garage Door Cable Pulley',
              'Extension Spring Pulley',
            ])
              item,
          ],
          aliases: const [
            'door strut',
            'reinforcement strut',
            'garage lock',
            't handle lock',
            'garage door lube',
            'winding bar',
            'lag screw',
            'carriage bolt',
            'track bolt',
            'self drilling screw',
            'tapcon',
            'concrete screw',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _garageDoorProducts({
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

const _garageDoorStyles = [
  'Raised Panel',
  'Short Panel',
  'Long Panel',
  'Carriage House',
  'Flush Panel',
];

const _garageDoorColors = ['White', 'Almond', 'Sandstone', 'Brown', 'Black'];

const _springWireSizes = [
  '0.207 in',
  '0.218 in',
  '0.225 in',
  '0.234 in',
  '0.243 in',
  '0.250 in',
  '0.262 in',
];
