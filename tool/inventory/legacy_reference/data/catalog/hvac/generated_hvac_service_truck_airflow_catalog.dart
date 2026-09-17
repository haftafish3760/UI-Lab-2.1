part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckAirflowCatalogCategory = _category(
  'HVAC Service Truck Airflow and Duct Repair Stock',
  [
    _system('Flex Duct Collars and Takeoffs', [
      _type(
        'Flex Duct and Insulated Duct Repair',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Flex Duct Stock',
          unit: 'each',
          variants: [
            for (final size in _hvacTruckRoundSizes)
              for (final r in ['R6', 'R8'])
                for (final length in ['25 ft', '50 ft'])
                  '$size $r Insulated Flex Duct $length',
            for (final size in _hvacTruckRoundSizes)
              for (final length in ['25 ft', '50 ft'])
                '$size Non Insulated Flex Duct $length',
            for (final size in _hvacTruckRoundSizes)
              '$size Flex Duct Repair Sleeve',
          ],
          aliases: const [
            'flex duct',
            'insulated flex',
            'r6 flex duct',
            'r8 flex duct',
            'duct repair sleeve',
            'flex duct sleeve',
          ],
        ),
      ),
      _type(
        'Start Collars Takeoffs and Spin Ins',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Duct Takeoff',
          unit: 'each',
          variants: [
            for (final size in _hvacTruckRoundSizes)
              for (final item in [
                'Start Collar',
                'Start Collar With Damper',
                'Spin In Takeoff',
                'Spin In Takeoff With Damper',
                'Saddle Tap Takeoff',
                'Sheet Metal Collar',
              ])
                '$size $item',
            for (final size in ['6 in', '8 in', '10 in', '12 in'])
              '$size Ceiling Box Takeoff',
          ],
          aliases: const [
            'start collar',
            'takeoff',
            'spin in',
            'spin-in',
            'saddle tap',
            'collar with damper',
            'sheet metal collar',
          ],
        ),
      ),
    ]),
    _system('Boots Registers Grilles and Return Repair', [
      _type(
        'Register Boots and Stack Boots',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Register Boot',
          unit: 'each',
          variants: [
            for (final face in [
              '2 x 10',
              '2 x 12',
              '4 x 10',
              '4 x 12',
              '6 x 10',
              '6 x 12',
            ])
              for (final round in ['4 in', '5 in', '6 in', '7 in', '8 in'])
                '$face x $round Straight Register Boot',
            for (final face in ['4 x 10', '4 x 12', '6 x 10', '6 x 12'])
              for (final round in ['6 in', '7 in', '8 in'])
                '$face x $round End Register Boot',
            for (final width in ['3-1/4 x 10', '3-1/4 x 12'])
              for (final item in [
                'Wall Stack Boot',
                'Wall Stack Head',
                'Wall Stack Elbow',
              ])
                '$width $item',
          ],
          aliases: const [
            'register boot',
            'duct boot',
            'end boot',
            'straight boot',
            'wall stack',
            'stack head',
            'stack elbow',
          ],
        ),
      ),
      _type(
        'Registers Grilles and Filter Grilles',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Air Distribution Face',
          unit: 'each',
          variants: [
            for (final size in [
              '2 x 10',
              '2 x 12',
              '4 x 10',
              '4 x 12',
              '6 x 10',
              '6 x 12',
            ])
              for (final finish in ['White', 'Brown', 'Brushed Nickel'])
                '$size $finish Floor Register',
            for (final size in [
              '10 x 10',
              '12 x 12',
              '14 x 20',
              '16 x 20',
              '20 x 20',
              '20 x 25',
            ])
              for (final item in [
                'Return Air Grille',
                'Return Filter Grille',
                'Ceiling Diffuser',
                'Eggcrate Return Grille',
              ])
                '$size $item',
            for (final size in ['14 x 20', '16 x 20', '20 x 20', '20 x 25'])
              '$size Filter Grille Replacement Door',
          ],
          aliases: const [
            'floor register',
            'return grille',
            'return air grille',
            'filter grille',
            'ceiling diffuser',
            'eggcrate grille',
            'filter grille door',
          ],
        ),
      ),
    ]),
    _system('Duct Adapters Dampers Reducers and Repair Metal', [
      _type(
        'Reducers Elbows and Round Pipe Repair',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Round Duct Repair',
          unit: 'each',
          variants: [
            for (final size in _hvacTruckRoundSizes)
              for (final gauge in ['26 Gauge', '30 Gauge'])
                for (final item in [
                  'Round Snap Lock Pipe',
                  'Adjustable Round Elbow',
                  'Round Duct Coupling',
                  'Manual Balancing Damper',
                  'Backdraft Damper',
                ])
                  '$size $gauge $item',
            for (final from in ['8 in', '10 in', '12 in'])
              for (final to in ['6 in', '8 in', '10 in'])
                if (from != to) '$from to $to Round Duct Reducer',
          ],
          aliases: const [
            'round pipe',
            'snap lock pipe',
            'adjustable elbow',
            'duct coupling',
            'manual damper',
            'balancing damper',
            'backdraft damper',
            'duct reducer',
          ],
        ),
      ),
      _type(
        'Duct Repair Sheet Metal and Access Panels',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Sheet Metal Repair',
          unit: 'each',
          variants: [
            for (final size in ['12 x 24', '24 x 24', '24 x 36', '36 x 48'])
              for (final gauge in ['26 Gauge', '30 Gauge'])
                '$size $gauge Galvanized Sheet Metal',
            for (final size in ['8 x 8', '10 x 10', '12 x 12', '16 x 16'])
              '$size Duct Access Door',
            for (final item in [
              'Duct Repair Patch Plate',
              'S Cleat Pack',
              'Drive Cleat Pack',
              'Duct Corner Pack',
            ])
              item,
          ],
          aliases: const [
            'sheet metal',
            'galvanized sheet',
            'duct access door',
            's cleat',
            'drive cleat',
            'duct corner',
          ],
        ),
      ),
      _type(
        'Duct Fasteners and Hanger Strap',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Duct Fastener',
          unit: 'each',
          variants: [
            for (final item in [
              'Sheet Metal Screw 1/2 in 100 Pack',
              'Sheet Metal Screw 3/4 in 100 Pack',
              'Sheet Metal Screw 1 in 100 Pack',
              '#8 Zip Screw 1/2 in 100 Pack',
              '#10 Tek Screw 3/4 in 100 Pack',
              '#10 Self Drilling Screw 1 in 100 Pack',
              'Duct Hanger Strap Roll',
              'Perforated Hanger Strap Roll',
            ])
              item,
          ],
          aliases: const [
            'sheet metal screw',
            'zip screw',
            'tek screw',
            'self drilling screw',
            'self tapping screw',
            'duct strap',
            'hanger strap',
          ],
        ),
      ),
    ]),
    _system('Duct Seal Airflow Service Consumables', [
      _type(
        'Tape Mastic Strap and Seal Stock',
        _hvacTruckAirflowProducts(
          baseName: 'HVAC Duct Consumable',
          unit: 'each',
          variants: [
            for (final width in ['2 in', '3 in', '4 in'])
              for (final length in ['50 yd', '100 yd'])
                '$width x $length UL181 Foil Tape',
            for (final size in ['1 gal', '2 gal', '5 gal'])
              for (final item in [
                'Water Based Duct Mastic',
                'Fiber Reinforced Duct Mastic',
                'Duct Sealant',
              ])
                '$size $item',
            for (final item in [
              'Duct Mastic Brush Pack',
              'Nylon Duct Strap Roll',
              'Panduit Strap Roll',
              'Flex Duct Zip Tie 36 in 25 Pack',
              'Duct Leakage Smoke Pencil',
              'Foam Gasket Tape Roll',
            ])
              item,
          ],
          aliases: const [
            'ul181 tape',
            'foil tape',
            'duct mastic',
            'duct sealant',
            'mastic brush',
            'duct strap',
            'panduit strap',
            'flex duct zip tie',
            'foam gasket tape',
          ],
        ),
      ),
    ]),
  ],
);

const _hvacTruckRoundSizes = [
  '4 in',
  '5 in',
  '6 in',
  '7 in',
  '8 in',
  '9 in',
  '10 in',
  '12 in',
  '14 in',
];

List<WorkSupplyItem> _hvacTruckAirflowProducts({
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
        aliases: [
          ...aliases,
          variant,
          variant.toLowerCase(),
          '$variant $baseName',
        ],
      ),
  ];
}
