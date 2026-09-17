part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckVentGasCatalogCategory = _category(
  'HVAC Service Truck Venting and Gas Heat Stock',
  [
    _system('Furnace PVC Vent and Combustion Air Repair', [
      _type(
        'PVC Furnace Vent Fittings',
        _hvacTruckVentGasProducts(
          baseName: 'Furnace PVC Vent Part',
          unit: 'each',
          variants: [
            for (final size in ['2 in', '3 in', '4 in'])
              for (final item in [
                'Schedule 40 PVC Furnace Vent Pipe 2 ft',
                'Schedule 40 PVC Furnace Vent Pipe 5 ft',
                'PVC Long Sweep 90 Vent Elbow',
                'PVC 45 Vent Elbow',
                'PVC Vent Coupling',
                'PVC Vent Tee',
                'PVC Vent Reducer',
                'PVC Vent Bird Screen',
                'PVC Vent Termination Elbow',
              ])
                '$size $item',
            for (final item in [
              '2 in x 3 in Furnace Vent Reducer',
              '3 in x 2 in Furnace Vent Reducer',
              'Concentric Vent Kit 2 in',
              'Concentric Vent Kit 3 in',
              'PVC Vent Condensate Drain Tee',
            ])
              item,
          ],
          aliases: const [
            'furnace pvc vent',
            'pvc vent elbow',
            'combustion air pipe',
            'concentric vent',
            'vent termination',
            'vent bird screen',
            'condensing furnace vent',
          ],
        ),
      ),
      _type(
        'PVC Vent Cement Primer and Support',
        _hvacTruckVentGasProducts(
          baseName: 'Furnace Vent Consumable',
          unit: 'each',
          variants: [
            for (final size in ['8 oz', '16 oz', '32 oz'])
              for (final item in [
                'PVC Clear Cement',
                'PVC Purple Primer',
                'Low VOC PVC Cement',
              ])
                '$size $item',
            for (final item in [
              'PVC Vent Pipe Strap 10 Pack',
              'Vent Support Clamp',
              'Wall Thimble Seal',
              'Exterior Vent Sealant',
              'Intake Exhaust Label Pack',
            ])
              item,
          ],
          aliases: const [
            'pvc cement',
            'purple primer',
            'vent pipe strap',
            'vent support clamp',
            'wall thimble',
            'vent sealant',
          ],
        ),
      ),
    ]),
    _system('B Vent Flue and Combustion Exhaust Stock', [
      _type(
        'B Vent Pipe Fittings and Caps',
        _hvacTruckVentGasProducts(
          baseName: 'Gas Vent Service Part',
          unit: 'each',
          variants: [
            for (final size in ['3 in', '4 in', '5 in', '6 in', '7 in', '8 in'])
              for (final item in [
                'B Vent Pipe 1 ft',
                'B Vent Pipe 2 ft',
                'B Vent Pipe 3 ft',
                'B Vent Adjustable Length',
                'B Vent 90 Elbow',
                'B Vent 45 Elbow',
                'B Vent Tee',
                'B Vent Firestop Spacer',
                'B Vent Storm Collar',
                'B Vent Rain Cap',
              ])
                '$size $item',
            for (final item in [
              'B Vent Roof Flashing 0/12 to 6/12',
              'B Vent Roof Flashing 7/12 to 12/12',
              'Draft Hood Connector',
              'Flue Pipe Adapter',
            ])
              item,
          ],
          aliases: const [
            'b vent',
            'b-vent',
            'gas vent',
            'flue pipe',
            'vent cap',
            'storm collar',
            'draft hood',
            'roof flashing',
          ],
        ),
      ),
      _type(
        'Single Wall Flue and Draft Repair',
        _hvacTruckVentGasProducts(
          baseName: 'Flue Repair Part',
          unit: 'each',
          variants: [
            for (final size in ['3 in', '4 in', '5 in', '6 in', '7 in', '8 in'])
              for (final item in [
                'Single Wall Flue Pipe 2 ft',
                'Single Wall Flue Pipe 5 ft',
                'Adjustable Flue Elbow',
                'Flue Pipe Crimped Elbow',
                'Flue Pipe Draft Hood Connector',
                'Flue Pipe Increaser',
              ])
                '$size $item',
            for (final item in [
              'High Temperature Foil Tape',
              'Furnace Cement Tub',
              'Flue Pipe Screw Pack',
              'Draft Gauge Hose Kit',
            ])
              item,
          ],
          aliases: const [
            'single wall flue',
            'flue pipe',
            'draft hood connector',
            'flue increaser',
            'furnace cement',
            'high temp foil tape',
          ],
        ),
      ),
    ]),
    _system('Gas Connector Shutoff and Sediment Trap Stock', [
      _type(
        'Gas Connectors Valves and Drip Leg Parts',
        _hvacTruckVentGasProducts(
          baseName: 'HVAC Gas Connection Part',
          unit: 'each',
          variants: [
            for (final length in ['24 in', '36 in', '48 in', '60 in'])
              for (final size in ['1/2 in', '3/4 in'])
                '$size x $length Gas Appliance Connector',
            for (final size in ['1/2 in', '3/4 in'])
              for (final item in [
                'Gas Ball Valve',
                'Gas Shutoff Valve',
                'Black Iron Tee',
                'Black Iron Cap',
                'Black Iron Drip Leg Nipple',
                'Gas Union',
                'Sediment Trap Kit',
              ])
                '$size $item',
            for (final item in [
              'Yellow Gas Thread Seal Tape',
              'Gas Rated Pipe Dope',
              'Gas Leak Detector Spray',
              'Gas Connector Fitting Adapter Kit',
            ])
              item,
          ],
          aliases: const [
            'gas connector',
            'gas appliance connector',
            'gas shutoff',
            'gas ball valve',
            'drip leg',
            'sediment trap',
            'yellow gas tape',
            'gas pipe dope',
          ],
        ),
      ),
    ]),
    _system('Exhaust Vent Caps Dryer Bath and Wall Penetrations', [
      _type(
        'Wall Caps Roof Caps and Exhaust Repair',
        _hvacTruckVentGasProducts(
          baseName: 'HVAC Exhaust Vent Part',
          unit: 'each',
          variants: [
            for (final size in ['3 in', '4 in', '5 in', '6 in', '8 in'])
              for (final item in [
                'Dryer Vent Hood',
                'Bath Fan Wall Cap',
                'Roof Vent Cap',
                'Backdraft Damper',
                'Bird Screen Wall Cap',
                'Louvered Wall Cap',
              ])
                '$size $item',
            for (final item in [
              'Dryer Vent Clamp Pair',
              'Semi Rigid Dryer Duct 8 ft',
              'Dryer Vent Periscope',
              'Bath Fan Roof Jack',
              'Exhaust Wall Sleeve',
              'Exterior Vent Mounting Block',
            ])
              item,
          ],
          aliases: const [
            'dryer vent hood',
            'bath fan wall cap',
            'roof cap',
            'vent cap',
            'backdraft damper',
            'wall cap',
            'dryer duct',
            'vent clamp',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacTruckVentGasProducts({
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
