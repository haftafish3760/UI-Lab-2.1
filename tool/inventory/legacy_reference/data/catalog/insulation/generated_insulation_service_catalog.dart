part of '../../work_supply_catalog.dart';

final insulationGeneratedServiceCatalogCategory = _category(
  'Expanded Insulation Service Stock',
  [
    _system('Expanded Fiberglass and Mineral Wool', [
      _type(
        'Fiberglass Batt Insulation',
        _insulationProducts(
          baseName: 'Fiberglass Batt Insulation',
          unit: 'bag',
          variants: [
            for (final rValue in ['R-11', 'R-13', 'R-15', 'R-19'])
              for (final width in ['15 in', '23 in'])
                '$rValue $width x 93 in Kraft Faced',
            for (final rValue in ['R-30', 'R-38', 'R-49'])
              for (final width in ['16 in', '24 in'])
                '$rValue $width Unfaced Attic',
          ],
          aliases: const ['batt insulation', 'fiberglass batt', 'attic batt'],
        ),
      ),
      _type(
        'Mineral Wool Batts',
        _insulationProducts(
          baseName: 'Mineral Wool Batt',
          unit: 'bag',
          variants: [
            for (final rValue in ['R-15', 'R-23', 'R-30'])
              for (final width in ['15 in', '23 in'])
                '$rValue $width Fire and Sound',
          ],
          aliases: const ['rock wool', 'sound batt', 'fire batt'],
        ),
      ),
    ]),
    _system('Expanded Foam Board and Spray Foam', [
      _type(
        'Rigid Foam Board',
        _insulationProducts(
          baseName: 'Rigid Foam Board',
          unit: 'sheet',
          variants: [
            for (final thickness in ['1/2 in', '1 in', '1-1/2 in', '2 in'])
              for (final type in ['XPS', 'Polyiso', 'EPS'])
                '$thickness 4 x 8 ft $type',
          ],
          aliases: const ['foam board', 'rigid insulation', 'xps board'],
        ),
      ),
      _type(
        'Spray Foam and Sealant',
        _insulationProducts(
          baseName: 'Foam Sealant',
          unit: 'can',
          variants: const [
            '12 oz Gap and Crack Expanding Spray Foam',
            '16 oz Window and Door Expanding Spray Foam',
            '20 oz Fire Block Expanding Spray Foam',
            '24 oz Pest Block Expanding Spray Foam',
            'Two-Component Spray Foam Kit 200 Board Foot',
            'Two-Component Spray Foam Kit 600 Board Foot',
          ],
          aliases: const ['spray foam', 'foam sealant', 'fire block foam'],
        ),
      ),
    ]),
    _system('Expanded Blown Insulation', [
      _type(
        'Loose Fill Insulation',
        _insulationProducts(
          baseName: 'Loose Fill Insulation',
          unit: 'bag',
          variants: const [
            '19 lb Cellulose',
            '25 lb Cellulose',
            '25 lb Fiberglass',
            '30 lb Fiberglass',
            'Attic Blown Insulation Bag',
          ],
          aliases: const ['blown insulation', 'blown cellulose', 'loose fill'],
        ),
      ),
    ]),
    _system('Expanded Barriers Tape and Supports', [
      _type(
        'Vapor Barrier and House Wrap',
        _insulationProducts(
          baseName: 'Insulation Barrier',
          unit: 'roll',
          variants: const [
            '4 mil 10 x 100 ft Poly Vapor Barrier',
            '6 mil 10 x 100 ft Poly Vapor Barrier',
            '10 mil 20 x 100 ft Crawlspace Vapor Barrier',
            '3 ft x 100 ft House Wrap',
            '9 ft x 150 ft House Wrap',
          ],
          aliases: const ['vapor barrier', 'plastic sheeting', 'house wrap'],
        ),
      ),
      _type(
        'Insulation Tape and Supports',
        _insulationProducts(
          baseName: 'Insulation Accessory',
          unit: 'pack',
          variants: const [
            '1-7/8 in x 165 ft House Wrap Tape',
            '3 in x 165 ft Seam Tape',
            '16 in Insulation Support Wire',
            '24 in Insulation Support Wire',
            'Insulation Knife',
            'Tyvek Tape Roll',
          ],
          aliases: const ['seam tape', 'insulation hanger', 'support wire'],
        ),
      ),
      _type(
        'Weatherization Pipe and Duct Insulation',
        _weatherizationProducts(),
      ),
      _type('Acoustic and Sound Control Supplies', _acousticProducts()),
    ]),
    _system('Bulk Insulation Receipt Variants', [
      _type(
        'Bulk Fiberglass and Mineral Wool Batts',
        _insulationProducts(
          baseName: 'Insulation Batt',
          unit: 'bag',
          variants: [
            for (final rValue in [
              'R-11',
              'R-13',
              'R-15',
              'R-19',
              'R-21',
              'R-30',
              'R-38',
              'R-49',
              'R-60',
            ])
              for (final width in ['15 in', '16 in', '23 in', '24 in'])
                for (final facing in ['Kraft Faced', 'Unfaced', 'Foil Faced'])
                  '$rValue $width $facing Fiberglass',
            for (final rValue in ['R-15', 'R-23', 'R-30', 'R-38'])
              for (final width in ['15 in', '16 in', '23 in', '24 in'])
                for (final type in [
                  'Fire and Sound Mineral Wool',
                  'Soundproofing Mineral Wool',
                  'Rock Wool Batt',
                ])
                  '$rValue $width $type',
          ],
          aliases: const [
            'batt insulation',
            'fiberglass batt',
            'kraft batt',
            'unfaced batt',
            'mineral wool',
            'rockwool',
          ],
        ),
      ),
      _type(
        'Bulk Rigid Foam Board and Panels',
        _insulationProducts(
          baseName: 'Rigid Insulation Board',
          unit: 'sheet',
          variants: [
            for (final thickness in [
              '1/2 in',
              '3/4 in',
              '1 in',
              '1-1/2 in',
              '2 in',
              '3 in',
            ])
              for (final size in ['2 x 8 ft', '4 x 8 ft'])
                for (final type in [
                  'XPS Foam Board',
                  'EPS Foam Board',
                  'Polyiso Foam Board',
                  'Foil Faced Polyiso Board',
                  'R-Tech Foam Board',
                  'Fan Fold Foam Board',
                ])
                  '$thickness $size $type',
            for (final roll in [
              '4 ft x 50 ft Reflective Insulation Roll',
              '4 ft x 25 ft Radiant Barrier Roll',
              '16 in x 25 ft Duct Wrap Roll',
              '24 in x 25 ft Duct Wrap Roll',
            ])
              roll,
          ],
          aliases: const [
            'foam board',
            'rigid foam',
            'rigid insulation',
            'polyiso',
            'xps',
            'r tech',
          ],
        ),
      ),
    ]),
    _system('Bulk Air Sealing Blown In and Barriers', [
      _type(
        'Bulk Spray Foam Caulk and Air Sealing',
        _insulationProducts(
          baseName: 'Insulation Air Sealing Supply',
          unit: 'each',
          variants: [
            for (final size in ['12 oz', '16 oz', '20 oz', '24 oz'])
              for (final type in [
                'Gap and Crack Spray Foam',
                'Window and Door Spray Foam',
                'Fire Block Spray Foam',
                'Pest Block Spray Foam',
                'Big Gap Filler Spray Foam',
              ])
                '$size $type',
            for (final kit in [
              'Two-Component Spray Foam Kit 200 Board Foot',
              'Two-Component Spray Foam Kit 400 Board Foot',
              'Two-Component Spray Foam Kit 600 Board Foot',
            ])
              kit,
            for (final tube in ['10 oz', '28 oz'])
              for (final sealant in [
                'Firestop Sealant',
                'Acoustic Sealant',
                'Insulation Foam Adhesive',
              ])
                '$tube $sealant',
          ],
          aliases: const [
            'spray foam',
            'expanding foam',
            'foam sealant',
            'fireblock foam',
            'fire stop',
          ],
        ),
      ),
      _type(
        'Bulk Blown Insulation Bags',
        _insulationProducts(
          baseName: 'Blown Insulation Bag',
          unit: 'bag',
          variants: [
            for (final weight in ['19 lb', '25 lb', '30 lb'])
              for (final type in [
                'Cellulose',
                'Fiberglass',
                'Loose Fill Fiberglass',
                'Attic Fiberglass',
              ])
                '$weight $type',
            for (final rValue in ['R-30', 'R-38', 'R-49', 'R-60'])
              '$rValue Attic Blown Insulation',
          ],
          aliases: const [
            'blown insulation',
            'loose fill',
            'cellulose insulation',
            'attic blow in',
          ],
        ),
      ),
      _type(
        'Bulk Vapor Barrier House Wrap and Supports',
        _insulationProducts(
          baseName: 'Insulation Barrier and Support',
          unit: 'each',
          variants: [
            for (final mil in ['4 mil', '6 mil', '10 mil', '12 mil', '20 mil'])
              for (final size in ['10 x 100 ft', '12 x 100 ft', '20 x 100 ft'])
                '$mil $size Poly Vapor Barrier',
            for (final size in [
              '3 ft x 100 ft',
              '5 ft x 100 ft',
              '9 ft x 100 ft',
              '9 ft x 150 ft',
            ])
              for (final wrap in ['House Wrap', 'Drainable House Wrap'])
                '$size $wrap',
            for (final length in ['55 yd', '90 ft', '165 ft'])
              for (final tape in [
                'House Wrap Tape',
                'Seam Tape',
                'Flashing Tape',
              ])
                '3 in x $length $tape',
            for (final width in ['16 in', '24 in'])
              for (final pack in ['100 Pack', '250 Pack'])
                '$width Insulation Support Wire $pack',
            'Insulation Knife',
            'Staple Hammer',
            'Cap Staple 1000 Pack',
          ],
          aliases: const [
            'vapor barrier',
            'poly barrier',
            'house wrap',
            'seam tape',
            'insulation support wire',
          ],
        ),
      ),
      _type(
        'Bulk Attic Baffles Covers and Accessories',
        _insulationProducts(
          baseName: 'Insulation Accessory',
          unit: 'each',
          variants: [
            for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
              for (final item in [
                'Rafter Vent Baffle',
                'Soffit Vent Baffle',
                'Attic Vent Chute',
                'Foam Outlet Gasket',
                'Foam Switch Gasket',
                'Recessed Light Cover',
                'Attic Stair Cover',
                'Pipe Insulation Elbow',
                'Duct Insulation Strap',
                'Insulation Anchor',
                'Insulation Washer',
                'Vapor Barrier Cap Nail',
              ])
                '$item $pack',
            for (final diameter in ['1/2 in', '3/4 in', '1 in'])
              for (final length in ['3 ft', '6 ft'])
                '$diameter x $length Foam Pipe Insulation',
            for (final width in ['2 in', '3 in', '4 in'])
              '$width x 30 ft Foam Sill Seal',
            for (final size in ['10 oz', '28 oz'])
              for (final sealant in [
                'Air Sealant',
                'Window and Door Caulk',
                'Fireblock Caulk',
                'Acoustic Sealant',
                'Draft Stop Sealant',
              ])
                '$size $sealant',
            for (final size in ['16 in x 4 ft', '24 in x 4 ft', '48 in x 8 ft'])
              for (final shield in [
                'Attic Insulation Shield',
                'Cardboard Baffle',
                'Foam Baffle',
                'Knee Wall Insulation Panel',
              ])
                '$size $shield',
            for (final size in ['2 in x 15 ft', '2 in x 30 ft', '3 in x 30 ft'])
              for (final tape in [
                'Foil HVAC Tape',
                'Insulation Seam Tape',
                'Vapor Barrier Tape',
                'Butyl Flashing Tape',
              ])
                '$size $tape',
            for (final size in [
              '12 in x 25 ft',
              '16 in x 25 ft',
              '24 in x 25 ft',
            ])
              for (final wrap in [
                'Fiberglass Pipe Wrap',
                'Foil Duct Wrap',
                'Water Heater Blanket',
                'Garage Door Insulation Kit',
              ])
                '$size $wrap',
            for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
              for (final item in [
                'Insulation Retainer Clip',
                'Foam Board Washer',
                'Plastic Cap Nail',
                'Vapor Barrier Staple',
                'House Wrap Cap',
                'Furring Strip Spacer',
              ])
                '$item $pack',
          ],
          aliases: const [
            'rafter vent',
            'vent baffle',
            'attic baffle',
            'pipe insulation',
            'sill seal',
            'foam gasket',
          ],
        ),
      ),
      _type(
        'Crawlspace Encapsulation Accessories',
        _insulationProducts(
          baseName: 'Crawlspace Encapsulation Supply',
          unit: 'each',
          variants: [
            for (final mil in ['10 mil', '12 mil', '15 mil', '20 mil'])
              for (final size in [
                '4 ft x 50 ft',
                '10 ft x 100 ft',
                '12 ft x 100 ft',
              ])
                '$mil $size Crawlspace Liner',
            for (final width in ['3 in', '4 in', '6 in'])
              for (final length in ['50 ft', '90 ft', '180 ft'])
                '$width x $length Crawlspace Seam Tape',
            for (final size in ['10 oz', '28 oz'])
              for (final sealant in [
                'Crawlspace Sealant',
                'Vapor Barrier Sealant',
                'Foundation Air Sealant',
              ])
                '$size $sealant',
            'Foundation Wall Fastener Pack',
            'Vapor Barrier Termination Bar',
            'Crawlspace Drainage Mat Roll',
            'Crawlspace Door Weatherstrip Kit',
            'Crawlspace Dehumidifier Drain Hose',
            'Crawlspace Hygrometer',
            'Termite Inspection Gap Tape',
          ],
          aliases: const [
            'crawlspace liner',
            'crawlspace seam tape',
            'vapor barrier sealant',
            'termination bar',
            'drainage mat',
          ],
        ),
      ),
      _type(
        'Firestop Fireblock and Draft Stop Accessories',
        _insulationProducts(
          baseName: 'Firestop Insulation Supply',
          unit: 'each',
          variants: [
            for (final size in ['10 oz', '28 oz'])
              for (final sealant in [
                'Fireblock Sealant',
                'Firestop Sealant',
                'Draft Stop Sealant',
                'Smoke Seal Sealant',
                'Intumescent Sealant',
              ])
                '$size $sealant',
            for (final diameter in [
              '1/2 in',
              '3/4 in',
              '1 in',
              '2 in',
              '3 in',
              '4 in',
            ])
              for (final item in [
                'Firestop Collar',
                'Firestop Sleeve',
                'Pipe Firestop Wrap Strip',
              ])
                '$diameter $item',
            'Firestop Putty Pad Pack',
            'Electrical Box Fire Pad Pack',
            'Fire Blocking Mineral Wool Bag',
            'Draft Stop Foam Board Panel',
            'Fire Rated Spray Foam 24 oz',
            'Firestop Mortar Pail',
            'Firestop Identification Label Pack',
          ],
          aliases: const [
            'firestop collar',
            'firestop sealant',
            'fireblock sealant',
            'draft stop',
            'putty pad',
          ],
        ),
      ),
      _type(
        'Expanded Sound Isolation and Specialty Batts',
        _insulationProducts(
          baseName: 'Sound Isolation Insulation Supply',
          unit: 'each',
          variants: [
            for (final width in ['15 in', '16 in', '23 in', '24 in'])
              for (final rValue in ['R-13', 'R-15', 'R-19', 'R-23'])
                '$rValue $width Sound Control Batt',
            for (final size in ['2 x 4 ft', '4 x 8 ft'])
              for (final material in [
                'Mineral Wool Acoustic Board',
                'Fiberglass Acoustic Board',
                'Mass Loaded Vinyl Sheet',
                'Sound Deadening Panel',
              ])
                '$size $material',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              for (final channel in [
                'Resilient Channel',
                'Hat Channel',
                'Sound Isolation Track',
              ])
                '$length $channel',
            'Sound Isolation Clip 10 Pack',
            'Sound Isolation Clip 50 Pack',
            'Acoustic Putty Pad 10 Pack',
            'Door Jamb Sound Seal Kit',
            'Automatic Door Bottom Sound Seal',
            'Floor Underlayment Sound Mat Roll',
          ],
          aliases: const [
            'sound control batt',
            'acoustic board',
            'mass loaded vinyl',
            'sound isolation clip',
            'resilient channel',
          ],
        ),
      ),
      _type(
        'Bulk Crawlspace Radiant and Weatherization Stock',
        _insulationProducts(
          baseName: 'Insulation Weatherization Supply',
          unit: 'each',
          variants: [
            for (final size in [
              '4 ft x 25 ft',
              '4 ft x 50 ft',
              '4 ft x 100 ft',
              '48 in x 125 ft',
            ])
              for (final material in [
                'Radiant Barrier Roll',
                'Reflective Bubble Insulation Roll',
                'Foil Faced Vapor Barrier Roll',
              ])
                '$size $material',
            for (final width in ['2 in', '3 in', '4 in'])
              for (final length in ['15 ft', '30 ft', '50 ft'])
                '$width x $length Foil Seam Tape',
            for (final size in ['36 in', '48 in'])
              '$size Crawlspace Access Door Insulation Kit',
            for (final size in ['30 gal', '40 gal', '50 gal', '80 gal'])
              '$size Water Heater Insulation Blanket',
            for (final size in ['8 ft', '9 ft', '16 ft'])
              '$size Garage Door Insulation Kit',
            'Duct Board Hanging Strap Roll',
            'Foil Faced Duct Insulation Blanket',
            'Crawlspace Foundation Vent Cover',
            'Magnetic Vent Cover Pack',
          ],
          aliases: const [
            'radiant barrier',
            'reflective insulation',
            'water heater blanket',
            'garage door insulation',
            'vent cover',
          ],
        ),
      ),
      _type(
        'Attic Venting Air Sealing and Light Covers',
        _atticVentingAirSealingProducts(),
      ),
      _type(
        'Insulation Fasteners Netting and Membrane Detail',
        _insulationFastenerMembraneProducts(),
      ),
      _type(
        'Firestop and Sound Control Detail Stock',
        _firestopSoundDetailProducts(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _atticVentingAirSealingProducts() {
  return _insulationProducts(
    baseName: 'Insulation Air Control Supply',
    unit: 'each',
    variants: [
      for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
        for (final item in [
          'Rafter Vent Baffle',
          'Soffit Vent Baffle',
          'Attic Vent Chute',
          'Cardboard Vent Chute',
          'Foam Vent Chute',
          'Wind Wash Barrier',
          'Baffle Staple Tab',
          'Attic Insulation Dam',
          'Recessed Can Light Cover',
          'IC Rated Light Cover',
          'Foam Outlet Gasket',
          'Foam Switch Gasket',
          'Electrical Box Foam Gasket',
          'Bath Fan Air Seal Cover',
          'Attic Hatch Weatherstrip',
          'Attic Stair Insulation Cover',
        ])
          '$item $pack',
      for (final size in ['10 oz', '20 oz', '24 oz', '28 oz'])
        for (final sealant in [
          'Air Sealant',
          'Draft Stop Sealant',
          'Fireblock Foam Sealant',
          'Low Expansion Window Door Foam',
          'High Expansion Gap Foam',
        ])
          '$size $sealant',
      for (final size in ['2 in x 30 ft', '3 in x 30 ft', '4 in x 50 ft'])
        for (final tape in [
          'Foil Seam Tape',
          'Air Barrier Tape',
          'Vapor Barrier Tape',
          'House Wrap Seam Tape',
        ])
          '$size $tape',
    ],
    aliases: const [
      'rafter vent',
      'soffit baffle',
      'attic vent chute',
      'can light cover',
      'foam gasket',
      'air sealant',
    ],
  );
}

List<WorkSupplyItem> _insulationFastenerMembraneProducts() {
  return _insulationProducts(
    baseName: 'Insulation Attachment Supply',
    unit: 'pack',
    variants: [
      for (final pack in ['25 Pack', '50 Pack', '100 Pack', '250 Pack'])
        for (final item in [
          'Insulation Support Wire',
          'Insulation Retainer Clip',
          'Insulation Anchor',
          'Insulation Washer',
          'Foam Board Washer',
          'Plastic Cap Nail',
          'House Wrap Cap',
          'Vapor Barrier Cap Nail',
          'Crawlspace Wall Fastener',
          'Termination Bar Fastener',
          'Impaling Clip',
          'Stick Pin Insulation Hanger',
        ])
          '$item $pack',
      for (final size in [
        '4 ft x 100 ft',
        '8 ft x 100 ft',
        '12 ft x 100 ft',
        '20 ft x 100 ft',
      ])
        for (final membrane in [
          'Insulation Netting',
          'Blown In Mesh Netting',
          'Vapor Barrier Membrane',
          'Air Barrier Membrane',
          'Crawlspace Wall Liner',
        ])
          '$size $membrane',
      for (final length in ['4 ft', '6 ft', '8 ft', '10 ft'])
        for (final item in [
          'Vapor Barrier Termination Bar',
          'Crawlspace Termination Bar',
          'Foundation Liner Termination Bar',
        ])
          '$length $item',
    ],
    aliases: const [
      'insulation support',
      'cap nail',
      'foam board washer',
      'insulation netting',
      'termination bar',
      'impaling clip',
    ],
  );
}

List<WorkSupplyItem> _firestopSoundDetailProducts() {
  return _insulationProducts(
    baseName: 'Insulation Fire Sound Supply',
    unit: 'each',
    variants: [
      for (final size in ['10 oz', '20 oz', '28 oz'])
        for (final sealant in [
          'Firestop Sealant',
          'Fireblock Sealant',
          'Smoke Seal Sealant',
          'Intumescent Sealant',
          'Acoustic Sealant',
        ])
          '$size $sealant',
      for (final diameter in ['1/2 in', '3/4 in', '1 in', '2 in', '3 in'])
        for (final item in [
          'Firestop Collar',
          'Firestop Sleeve',
          'Firestop Wrap Strip',
          'Pipe Firestop Boot',
        ])
          '$diameter $item',
      for (final pack in ['10 Pack', '25 Pack', '50 Pack'])
        for (final item in [
          'Firestop Putty Pad',
          'Acoustic Putty Pad',
          'Sound Isolation Clip',
          'Sound Isolation Bracket',
          'Firestop Identification Label',
        ])
          '$item $pack',
      for (final length in ['8 ft', '10 ft', '12 ft'])
        for (final item in [
          'Resilient Channel',
          'Sound Isolation Track',
          'Hat Channel',
          'Acoustic Door Seal',
        ])
          '$length $item',
    ],
    aliases: const [
      'firestop sealant',
      'firestop wrap',
      'putty pad',
      'sound isolation clip',
      'resilient channel',
      'acoustic sealant',
    ],
  );
}

List<WorkSupplyItem> _weatherizationProducts() {
  return _insulationProducts(
    baseName: 'Weatherization Insulation Supply',
    unit: 'each',
    variants: [
      for (final diameter in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
        for (final length in ['3 ft', '6 ft'])
          '$diameter x $length Foam Pipe Insulation',
      for (final diameter in ['1/2 in', '3/4 in', '1 in'])
        '$diameter Rubber Pipe Insulation',
      for (final width in ['2 in', '3 in'])
        for (final length in ['15 ft', '30 ft'])
          '$width x $length Foil HVAC Tape',
      for (final size in ['10 ft', '17 ft', '20 ft'])
        '$size Door Weatherstrip Kit',
      for (final size in ['1/4 in', '3/8 in', '1/2 in'])
        '$size Foam Weatherstrip Tape',
      'Window Insulation Shrink Film Kit',
      'Outlet Foam Gasket Pack',
      'Switch Foam Gasket Pack',
      'Door Sweep',
      'Draft Stopper',
    ],
    aliases: const [
      'pipe insulation',
      'weatherstrip',
      'window insulation kit',
      'foam gasket',
      'door sweep',
    ],
  );
}

List<WorkSupplyItem> _acousticProducts() {
  return _insulationProducts(
    baseName: 'Acoustic Insulation Supply',
    unit: 'each',
    variants: [
      for (final size in ['24 x 48 in', '2 x 4 ft', '4 x 8 ft'])
        for (final material in [
          'Acoustic Panel',
          'Sound Dampening Panel',
          'Mass Loaded Vinyl Sheet',
        ])
          '$size $material',
      for (final size in ['10 oz', '28 oz']) '$size Acoustic Sealant',
      for (final width in ['1-3/8 in', '1-5/8 in', '2 in'])
        '$width Sound Isolation Clip',
      'Resilient Channel 12 ft',
      'Acoustic Putty Pad Pack',
      'Door Sound Seal Kit',
      'Floor Sound Underlayment Roll',
    ],
    aliases: const [
      'acoustic sealant',
      'sound panel',
      'mass loaded vinyl',
      'resilient channel',
      'sound clip',
    ],
  );
}

List<WorkSupplyItem> _insulationProducts({
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
