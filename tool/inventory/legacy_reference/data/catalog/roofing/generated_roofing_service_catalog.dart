part of '../../work_supply_catalog.dart';

final roofingGeneratedServiceCatalogCategory = _category(
  'Expanded Roofing Service Stock',
  [
    _system('Expanded Roof Covering', [
      _type(
        'Asphalt Shingles',
        _roofingProducts(
          baseName: 'Asphalt Shingles',
          unit: 'bundle',
          variants: [
            for (final style in [
              '3-Tab',
              'Architectural',
              'Impact Resistant Architectural',
            ])
              for (final color in [
                'Black',
                'Weathered Wood',
                'Brown',
                'Gray',
                'Driftwood',
              ])
                '$color $style Bundle',
          ],
          aliases: const ['roof shingles', 'shingle bundle'],
        ),
      ),
      _type(
        'Roof Underlayment',
        _roofingProducts(
          baseName: 'Roof Underlayment',
          unit: 'roll',
          variants: const [
            '15 lb Felt',
            '30 lb Felt',
            'Synthetic 5 Square',
            'Synthetic 10 Square',
            'Ice and Water Shield 2 Square',
            'Ice and Water Shield 3 Square',
          ],
          aliases: const ['felt paper', 'synthetic underlayment', 'ice shield'],
        ),
      ),
    ]),
    _system('Expanded Flashing and Edge Metal', [
      _type(
        'Drip Edge and Rake Edge',
        _roofingProducts(
          baseName: 'Roof Edge Metal',
          unit: 'piece',
          variants: [
            for (final profile in [
              'D Style Drip Edge',
              'F Style Drip Edge',
              'Rake Edge',
            ])
              for (final color in ['White', 'Brown', 'Black', 'Galvanized'])
                '10 ft $color $profile',
          ],
          aliases: const ['drip edge', 'edge metal', 'rake edge'],
        ),
      ),
      _type(
        'Step and Valley Flashing',
        _roofingProducts(
          baseName: 'Roof Flashing',
          unit: 'piece',
          variants: [
            for (final flashing in [
              'Step Flashing',
              'Valley Flashing',
              'Apron Flashing',
            ])
              for (final finish in ['Galvanized', 'Aluminum', 'Brown Aluminum'])
                '$finish $flashing',
            '4 x 4 x 8 in Galvanized Step Flashing Pack',
            '5 x 7 in Galvanized Step Flashing Pack',
          ],
          aliases: const ['roof flashing', 'step flashing', 'valley metal'],
        ),
      ),
    ]),
    _system('Expanded Vents and Roof Penetrations', [
      _type(
        'Roof Vents',
        _roofingProducts(
          baseName: 'Roof Vent',
          unit: 'each',
          variants: [
            for (final vent in [
              'Static Box',
              'Slant Back',
              'Turbine',
              'Ridge Vent',
              'Bathroom Exhaust',
            ])
              for (final color in ['Black', 'Brown', 'Weathered Wood'])
                '$color $vent',
          ],
          aliases: const ['box vent', 'ridge vent', 'roof ventilation'],
        ),
      ),
      _type(
        'Pipe Boots and Penetration Flashing',
        _roofingProducts(
          baseName: 'Pipe Boot Flashing',
          unit: 'each',
          variants: [
            for (final size in ['1-1/2 in', '2 in', '3 in', '4 in'])
              for (final material in ['Rubber', 'Silicone', 'Lead'])
                '$size $material',
          ],
          aliases: const ['roof boot', 'pipe flashing', 'vent boot'],
        ),
      ),
    ]),
    _system('Expanded Gutters and Drainage', [
      _type(
        'Gutter Sections and Downspouts',
        _roofingProducts(
          baseName: 'Gutter Drainage Part',
          unit: 'piece',
          variants: [
            for (final color in ['White', 'Brown', 'Black', 'Galvanized'])
              for (final gutter in [
                '5 in x 10 ft K Style Gutter',
                '6 in x 10 ft K Style Gutter',
              ])
                '$color $gutter',
            for (final color in ['White', 'Brown', 'Black'])
              for (final size in ['2 x 3 x 10 ft', '3 x 4 x 10 ft'])
                '$color $size Downspout',
          ],
          aliases: const ['rain gutter', 'downspout', 'gutter section'],
        ),
      ),
      _type(
        'Gutter Fittings and Hangers',
        _roofingProducts(
          baseName: 'Gutter Fitting',
          unit: 'each',
          variants: [
            for (final size in ['2 x 3', '3 x 4'])
              for (final bend in ['A Elbow', 'B Elbow']) '$size $bend',
            '5 in Hidden Hanger',
            '6 in Hidden Hanger',
            '5 in End Cap',
            '6 in End Cap',
            '5 in Drop Outlet',
            '6 in Drop Outlet',
          ],
          aliases: const ['gutter elbow', 'hidden hanger', 'drop outlet'],
        ),
      ),
    ]),
    _system('Expanded Roofing Fasteners and Sealants', [
      _type(
        'Roofing Nails and Screws',
        _roofingProducts(
          baseName: 'Roofing Fastener',
          unit: 'box',
          variants: [
            for (final length in ['1 in', '1-1/4 in', '1-1/2 in', '1-3/4 in'])
              '$length Galvanized Roofing Nail',
            '1 in Plastic Cap Nail',
            '1-1/4 in Plastic Cap Nail',
            '2 in Metal Roofing Screw',
            '2-1/2 in Metal Roofing Screw',
          ],
          aliases: const ['roof nail', 'cap nail', 'metal roofing screw'],
        ),
      ),
      _type(
        'Roof Sealants and Cement',
        _roofingProducts(
          baseName: 'Roof Sealant',
          unit: 'tube',
          variants: const [
            '10 oz Black Roof Sealant',
            '10 oz Clear Roof Sealant',
            '28 oz Black Roof Sealant',
            '1 gal Plastic Roof Cement',
            '3.5 gal Plastic Roof Cement',
            'Fibered Roof Coating 1 gal',
            'Fibered Roof Coating 5 gal',
          ],
          aliases: const ['roof cement', 'flashing sealant', 'gutter sealant'],
        ),
      ),
    ]),
    _system('Bulk Roofing Receipt Variants', [
      _type(
        'Bulk Shingles Ridge and Starter',
        _roofingProducts(
          baseName: 'Roof Covering',
          unit: 'bundle',
          variants: [
            for (final color in [
              'Black',
              'Charcoal',
              'Weathered Wood',
              'Driftwood',
              'Brown',
              'Gray',
              'Shakewood',
              'Slate',
            ])
              for (final style in [
                '3-Tab Shingle Bundle',
                'Architectural Shingle Bundle',
                'Impact Resistant Shingle Bundle',
                'Hip and Ridge Cap Bundle',
                'Starter Strip Bundle',
              ])
                '$color $style',
            for (final panel in [
              '8 ft Galvanized Corrugated Panel',
              '10 ft Galvanized Corrugated Panel',
              '12 ft Galvanized Corrugated Panel',
              '8 ft Painted Metal Roof Panel',
              '10 ft Painted Metal Roof Panel',
              '12 ft Painted Metal Roof Panel',
            ])
              panel,
          ],
          aliases: const [
            'shingle bundle',
            'roof shingles',
            'ridge cap',
            'starter strip',
            'metal roofing',
          ],
        ),
      ),
      _type(
        'Bulk Underlayment Ice Barrier and Roll Roofing',
        _roofingProducts(
          baseName: 'Roof Roll Material',
          unit: 'roll',
          variants: [
            for (final roll in [
              '15 lb Felt',
              '30 lb Felt',
              'Synthetic 5 Square Underlayment',
              'Synthetic 10 Square Underlayment',
              'High Temp Synthetic Underlayment',
              '2 Square Ice and Water Shield',
              '3 Square Ice and Water Shield',
              'Granular Cap Sheet',
              'Smooth Roll Roofing',
              'Peel and Stick Roofing Membrane',
            ])
              roll,
          ],
          aliases: const [
            'felt paper',
            'roof felt',
            'synthetic underlayment',
            'ice shield',
            'roll roofing',
          ],
        ),
      ),
      _type(
        'Bulk Roof Flashing and Edge Metal',
        _roofingProducts(
          baseName: 'Roof Flashing Metal',
          unit: 'piece',
          variants: [
            for (final color in [
              'White',
              'Brown',
              'Black',
              'Bronze',
              'Galvanized',
              'Mill Finish',
            ])
              for (final edge in [
                '10 ft D Style Drip Edge',
                '10 ft F Style Drip Edge',
                '10 ft Rake Edge',
                '10 ft Gravel Stop',
              ])
                '$color $edge',
            for (final finish in ['Galvanized', 'Aluminum', 'Copper'])
              for (final flashing in [
                '4 x 4 x 8 in Step Flashing 50 Pack',
                '5 x 7 in Step Flashing 50 Pack',
                '10 ft Valley Flashing',
                '10 ft Apron Flashing',
                '10 ft Counter Flashing',
                'Kickout Flashing',
              ])
                '$finish $flashing',
          ],
          aliases: const [
            'drip edge',
            'rake edge',
            'step flashing',
            'valley metal',
            'kickout flashing',
          ],
        ),
      ),
    ]),
    _system('Bulk Roofing Vents Gutters and Consumables', [
      _type(
        'Bulk Roof Deck Repair Materials',
        _roofingProducts(
          baseName: 'Roof Deck Repair Material',
          unit: 'sheet',
          variants: [
            for (final thickness in [
              '7/16 in',
              '15/32 in',
              '19/32 in',
              '23/32 in',
            ])
              for (final material in ['OSB Sheathing', 'CDX Plywood'])
                '$thickness 4 x 8 $material',
            for (final width in ['2 x 4', '2 x 6', '2 x 8'])
              for (final length in ['8 ft', '10 ft', '12 ft'])
                '$width x $length Roof Framing Repair Board',
            'H-Clip Panel Spacer Pack',
            'Roof Deck Patch Panel',
          ],
          aliases: const [
            'roof decking',
            'roof sheathing',
            'osb sheathing',
            'cdx plywood',
            'h clip',
          ],
        ),
      ),
      _type(
        'Bulk Roof Vent and Penetration Parts',
        _roofingProducts(
          baseName: 'Roof Ventilation Part',
          unit: 'each',
          variants: [
            for (final color in ['Black', 'Brown', 'Weathered Wood', 'Mill'])
              for (final vent in [
                'Static Box Vent',
                'Slant Back Vent',
                'Turbine Vent',
                'Ridge Vent Section',
                'Bathroom Exhaust Vent',
                'Kitchen Exhaust Vent',
              ])
                '$color $vent',
            for (final size in ['1-1/2 in', '2 in', '3 in', '4 in'])
              for (final material in [
                'Rubber Pipe Boot',
                'Silicone Pipe Boot',
                'Lead Pipe Boot',
                'Retrofit Pipe Boot',
              ])
                '$size $material',
          ],
          aliases: const [
            'box vent',
            'ridge vent',
            'pipe boot',
            'roof boot',
            'vent flashing',
          ],
        ),
      ),
      _type(
        'Bulk Gutter Drainage Parts',
        _roofingProducts(
          baseName: 'Gutter Drainage Part',
          unit: 'piece',
          variants: [
            for (final color in ['White', 'Brown', 'Black', 'Bronze'])
              for (final part in [
                '5 in x 10 ft K Style Gutter',
                '6 in x 10 ft K Style Gutter',
                '2 x 3 x 10 ft Downspout',
                '3 x 4 x 10 ft Downspout',
                '5 in Outside Mitre',
                '5 in Inside Mitre',
                '6 in Outside Mitre',
                '6 in Inside Mitre',
                '5 in End Cap',
                '6 in End Cap',
                '5 in Drop Outlet',
                '6 in Drop Outlet',
              ])
                '$color $part',
            for (final size in ['2 x 3', '3 x 4'])
              for (final bend in ['A Elbow', 'B Elbow'])
                for (final color in ['White', 'Brown', 'Black'])
                  '$color $size $bend',
          ],
          aliases: const [
            'gutter',
            'downspout',
            'gutter elbow',
            'gutter hanger',
            'drop outlet',
          ],
        ),
      ),
      _type(
        'Bulk Roofing Fasteners Sealants and Coatings',
        _roofingProducts(
          baseName: 'Roofing Consumable',
          unit: 'each',
          variants: [
            for (final length in [
              '1 in',
              '1-1/4 in',
              '1-1/2 in',
              '1-3/4 in',
              '2 in',
            ])
              for (final pack in ['1 lb', '5 lb', '25 lb'])
                '$length Galvanized Roofing Nail $pack',
            for (final length in ['1 in', '1-1/4 in', '1-1/2 in'])
              for (final pack in ['1 lb', '5 lb'])
                '$length Plastic Cap Nail $pack',
            for (final color in ['Black', 'Clear', 'White', 'Gray'])
              for (final tube in ['10 oz', '28 oz'])
                '$tube $color Roof Sealant',
            for (final size in ['1 gal', '3.5 gal', '5 gal'])
              for (final material in [
                'Plastic Roof Cement',
                'Fibered Roof Coating',
                'Elastomeric Roof Coating',
                'Gutter Sealant',
              ])
                '$size $material',
          ],
          aliases: const [
            'roofing nail',
            'roof nail',
            'cap nail',
            'roof sealant',
            'roof cement',
          ],
        ),
      ),
      _type(
        'Bulk Metal Roofing Trim and Accessories',
        _roofingProducts(
          baseName: 'Metal Roofing Accessory',
          unit: 'piece',
          variants: [
            for (final color in ['Galvanized', 'White', 'Black', 'Brown'])
              for (final trim in [
                '10 ft Ridge Cap',
                '10 ft Rake Trim',
                '10 ft Eave Trim',
                '10 ft J-Channel',
                '10 ft Sidewall Flashing',
                '10 ft Endwall Flashing',
              ])
                '$color $trim',
            for (final color in ['White', 'Black', 'Brown'])
              for (final length in ['1 in', '1-1/2 in', '2 in'])
                '$length $color Metal Roofing Screw 250 Pack',
            'Butyl Tape Roll',
            'Foam Closure Strip Inside',
            'Foam Closure Strip Outside',
            'Metal Roof Touch Up Paint',
          ],
          aliases: const [
            'metal ridge cap',
            'rake trim',
            'eave trim',
            'metal roofing screw',
            'closure strip',
            'butyl tape',
          ],
        ),
      ),
      _type(
        'Soffit Fascia and Eave Trim',
        _roofingProducts(
          baseName: 'Roof Eave Trim',
          unit: 'piece',
          variants: [
            for (final color in ['White', 'Brown', 'Black', 'Almond'])
              for (final panel in [
                '12 in x 12 ft Vented Vinyl Soffit Panel',
                '12 in x 12 ft Solid Vinyl Soffit Panel',
                '16 in x 12 ft Vented Aluminum Soffit Panel',
                '16 in x 12 ft Solid Aluminum Soffit Panel',
              ])
                '$color $panel',
            for (final color in ['White', 'Brown', 'Black', 'Almond'])
              for (final size in ['6 in', '8 in', '10 in'])
                '$size x 12 ft $color Aluminum Fascia Cover',
            for (final color in ['White', 'Brown', 'Black'])
              for (final trim in [
                '12 ft F Channel',
                '12 ft J Channel',
                '12 ft Soffit Frieze Runner',
                '12 ft Undersill Trim',
              ])
                '$color $trim',
          ],
          aliases: const [
            'soffit panel',
            'vented soffit',
            'fascia cover',
            'f channel',
            'j channel',
          ],
        ),
      ),
      _type(
        'Low Slope Roof Repair Materials',
        _roofingProducts(
          baseName: 'Low Slope Roof Repair Supply',
          unit: 'each',
          variants: [
            for (final material in ['EPDM', 'TPO'])
              for (final repair in [
                'Patch Kit',
                'Seam Tape Roll',
                'Pipe Boot',
                'Primer Quart',
                'Bonding Adhesive Gallon',
              ])
                '$material $repair',
            for (final size in ['1 gal', '3.5 gal', '5 gal'])
              for (final coating in [
                'Silicone Roof Coating',
                'Elastomeric White Roof Coating',
                'Aluminum Roof Coating',
                'Fibered Asphalt Roof Coating',
              ])
                '$size $coating',
            'Modified Bitumen Cap Sheet Roll',
            'Peel and Stick Base Sheet Roll',
            'Cold Process Roof Adhesive Gallon',
          ],
          aliases: const [
            'epdm patch',
            'tpo patch',
            'roof coating',
            'low slope roof',
            'modified bitumen',
          ],
        ),
      ),
      _type(
        'Roof Jacks Collars and Specialty Flashing',
        _roofingProducts(
          baseName: 'Roof Penetration Flashing',
          unit: 'each',
          variants: [
            for (final size in ['2 in', '3 in', '4 in', '5 in'])
              for (final part in [
                'Galvanized Roof Jack',
                'Black Roof Jack',
                'Adjustable Roof Jack',
                'Storm Collar',
                'B-Vent Flashing',
                'Type B Gas Vent Flashing',
              ])
                '$size $part',
            for (final kit in [
              'Chimney Flashing Kit',
              'Skylight Step Flashing Kit',
              'Dormer Flashing Kit',
              'Wall Flashing Kit',
              'Roof Cricket Flashing Kit',
              'Rain Diverter Flashing',
              'Universal Vent Cap',
              'Galvanized Rain Cap',
            ])
              kit,
          ],
          aliases: const [
            'roof jack',
            'storm collar',
            'b vent flashing',
            'chimney flashing',
            'skylight flashing',
          ],
        ),
      ),
      _type(
        'Bulk Roof Repair and Accessory Stock',
        _roofingProducts(
          baseName: 'Roof Accessory',
          unit: 'each',
          variants: [
            for (final color in [
              'Black',
              'Brown',
              'White',
              'Gray',
              'Weathered Wood',
            ])
              for (final accessory in [
                'Roof Jack',
                'Gooseneck Vent',
                'Bath Vent Cap',
                'Kitchen Vent Cap',
                'Chimney Flashing Kit',
                'Skylight Flashing Kit',
                'Gable Vent',
                'Soffit Vent Strip',
              ])
                '$color $accessory',
            for (final width in ['4 in', '6 in', '9 in', '12 in'])
              for (final roll in [
                'Aluminum Flashing Roll',
                'Galvanized Flashing Roll',
                'Peel and Stick Flashing Tape',
              ])
                '$width $roll',
            for (final size in ['3 in x 25 ft', '4 in x 50 ft', '6 in x 50 ft'])
              for (final tape in [
                'Butyl Flashing Tape',
                'Roof Repair Tape',
                'Seam Tape',
              ])
                '$size $tape',
            for (final pack in ['10 Pack', '25 Pack', '50 Pack', '100 Pack'])
              for (final item in [
                'Gutter Screw',
                'Roofing Washer',
                'Neoprene Washer',
                'Pipe Boot Clamp',
                'Vent Cap Screw',
                'Soffit Vent Screw',
                'Flashing Screw',
                'Gutter Ferrule',
                'Gutter Spike',
                'Downspout Strap',
              ])
                '$item $pack',
            for (final length in ['3 ft', '4 ft', '5 ft', '6 ft'])
              for (final guard in [
                'Snap In Gutter Guard',
                'Micro Mesh Gutter Guard',
                'Foam Gutter Guard',
                'Brush Gutter Guard',
                'Downspout Extension',
                'Splash Block',
              ])
                '$length $guard',
          ],
          aliases: const [
            'roof jack',
            'vent cap',
            'skylight flashing',
            'flashing roll',
            'roof repair tape',
          ],
        ),
      ),
    ]),
    _system('Bulk Roof Repair Detail Stock', [
      _type(
        'Shingle Repair and Starter Detail',
        _roofingProducts(
          baseName: 'Shingle Repair Supply',
          unit: 'each',
          variants: [
            for (final color in [
              'Black',
              'Charcoal',
              'Weathered Wood',
              'Driftwood',
              'Brown',
            ])
              for (final repair in [
                '3-Tab Repair Shingle Bundle',
                'Architectural Repair Shingle Bundle',
                'Hip and Ridge Repair Bundle',
                'Starter Strip Repair Bundle',
                'Shingle Repair Patch Pack',
              ])
                '$color $repair',
            'Asphalt Shingle Sample Board',
            'Shingle Gauge Tool',
            'Roofing Granule Repair Jar',
          ],
          aliases: const [
            'repair shingle',
            'shingle repair',
            'starter repair',
            'ridge repair',
            'roof granules',
          ],
        ),
      ),
      _type(
        'Roof Patch Tapes and Flashing Rolls',
        _roofingProducts(
          baseName: 'Roof Patch Material',
          unit: 'roll',
          variants: [
            for (final width in ['4 in', '6 in', '9 in', '12 in', '18 in'])
              for (final material in [
                'Peel and Stick Roof Repair Tape',
                'Butyl Roof Flashing Tape',
                'Aluminum Roof Flashing Roll',
              ])
                '$width $material',
            '6 in x 25 ft EPDM Cover Tape',
            '6 in x 100 ft TPO Cover Tape',
            'Roof Seam Roller',
            'Flashing Primer Quart',
          ],
          aliases: const [
            'roof repair tape',
            'flashing roll',
            'cover tape',
            'seam roller',
            'flashing primer',
          ],
        ),
      ),
    ]),
    _system('Bulk Gutter Protection and Roof Safety', [
      _type(
        'Gutter Guards Heat Cable and Drain Protection',
        _roofingProducts(
          baseName: 'Gutter Protection Supply',
          unit: 'each',
          variants: [
            for (final length in ['3 ft', '4 ft', '5 ft', '6 ft'])
              for (final guard in [
                'Snap In Gutter Guard',
                'Micro Mesh Gutter Guard',
                'Foam Gutter Guard',
                'Brush Gutter Guard',
              ])
                '$length $guard',
            for (final length in [
              '30 ft',
              '60 ft',
              '80 ft',
              '100 ft',
              '120 ft',
            ])
              '$length Roof and Gutter Heat Cable',
            'Heat Cable Roof Clip 50 Pack',
            'Heat Cable Downspout Hanger 10 Pack',
            'Downspout Strainer 2 Pack',
            'Gutter Splash Block',
            'Downspout Extension Hinge Kit',
          ],
          aliases: const [
            'gutter guard',
            'heat cable',
            'roof deicing cable',
            'downspout strainer',
            'splash block',
          ],
        ),
      ),
      _type(
        'Roof Safety Anchors and Access Supplies',
        _roofingProducts(
          baseName: 'Roof Safety Accessory',
          unit: 'each',
          variants: const [
            'Reusable Roof Anchor',
            'Temporary Roof Anchor',
            'Permanent Roof Anchor',
            'Ridge Roof Anchor',
            'Roof Bracket 6/12 Pitch',
            'Roof Bracket 10/12 Pitch',
            'Pump Jack Roof Brace',
            'Toe Board Bracket',
            'Roof Walk Pad',
            'Roof Safety Warning Line Flag',
            'Roof Harness Anchor Kit',
            'Ladder Roof Hook Kit',
          ],
          aliases: const [
            'roof anchor',
            'roof bracket',
            'toe board bracket',
            'roof walk pad',
            'ladder hook',
          ],
        ),
      ),
    ]),
    _system('Bulk Chimney Skylight and Roof Opening Repair', [
      _type(
        'Chimney Skylight and Wall Flashing Repair',
        _roofingProducts(
          baseName: 'Roof Opening Flashing',
          unit: 'each',
          variants: [
            for (final finish in ['Galvanized', 'Aluminum', 'Copper', 'Black'])
              for (final part in [
                'Chimney Step Flashing Kit',
                'Chimney Counter Flashing',
                'Skylight Step Flashing Kit',
                'Sidewall Flashing',
                'Endwall Flashing',
              ])
                '$finish $part',
            'Chimney Cricket Flashing Kit',
            'Skylight Adhesive Underlayment Kit',
            'Skylight Saddle Flashing Kit',
            'Roof to Wall Flashing Kit',
            'Kickout Flashing Repair Kit',
          ],
          aliases: const [
            'chimney flashing',
            'counter flashing',
            'skylight flashing',
            'sidewall flashing',
            'endwall flashing',
          ],
        ),
      ),
      _type(
        'Vent Cap Screen and Chimney Rain Parts',
        _roofingProducts(
          baseName: 'Roof Vent Cap Supply',
          unit: 'each',
          variants: [
            for (final size in ['3 in', '4 in', '6 in', '8 in'])
              for (final cap in [
                'Galvanized Vent Cap',
                'Black Vent Cap',
                'Chimney Rain Cap',
                'Spark Arrestor Screen',
              ])
                '$size $cap',
            'Universal Chimney Cap',
            'Chimney Cap Mounting Strap',
            'Vent Cap Bird Screen',
            'Roof Vent Mesh Guard',
          ],
          aliases: const [
            'chimney cap',
            'rain cap',
            'vent cap',
            'spark arrestor',
            'bird screen',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _roofingProducts({
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
