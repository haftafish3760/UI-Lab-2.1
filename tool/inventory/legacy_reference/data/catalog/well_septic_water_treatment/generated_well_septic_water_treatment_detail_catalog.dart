part of '../../work_supply_catalog.dart';

final wellSepticWaterTreatmentGeneratedDetailCatalogCategory = _category(
  'Well Septic Water Treatment Detail Stock',
  [
    _system('Well Pumps Pressure Tanks and Controls', [
      _type(
        'Well Pumps Jet Pumps and Pump Controls',
        _wellSepticProducts(
          baseName: 'Well Pump Part',
          unit: 'each',
          variants: [
            for (final hp in ['1/2 HP', '3/4 HP', '1 HP', '1-1/2 HP'])
              for (final voltage in ['115V', '230V'])
                for (final grade in _waterSystemGrades)
                  for (final item in [
                    'Shallow Well Jet Pump',
                    'Convertible Jet Pump',
                    'Submersible Well Pump',
                    'Booster Pump',
                    'Pump Control Box',
                  ])
                    '$grade $hp $voltage $item',
            for (final amp in ['20 Amp', '30 Amp', '40 Amp'])
              for (final item in [
                'Pump Pressure Switch',
                'Pump Control Relay',
                'Pump Start Capacitor',
                'Pump Run Capacitor',
              ])
                '$amp $item',
          ],
          aliases: const [
            'well pump',
            'jet pump',
            'submersible pump',
            'booster pump',
            'pump control box',
            'pressure switch',
          ],
        ),
      ),
      _type(
        'Pressure Tanks Gauges and Well Fittings',
        _wellSepticProducts(
          baseName: 'Well Pressure System Part',
          unit: 'each',
          variants: [
            for (final gallon in [
              '20 gal',
              '32 gal',
              '44 gal',
              '62 gal',
              '86 gal',
            ])
              for (final item in [
                'Vertical Pressure Tank',
                'Horizontal Pressure Tank',
                'Pre Charged Pressure Tank',
              ])
                '$gallon $item',
            for (final size in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
              for (final item in [
                'Well Tank Tee Kit',
                'Pressure Gauge',
                'Boiler Drain Valve',
                'Air Volume Control',
                'Pitless Adapter',
                'Well Seal',
                'Well Cap',
              ])
                '$size $item',
          ],
          aliases: const [
            'pressure tank',
            'well tank',
            'tank tee',
            'pressure gauge',
            'pitless adapter',
            'well seal',
            'well cap',
          ],
        ),
      ),
    ]),
    _system('Water Treatment Filtration Softening and UV', [
      _type(
        'Filter Housings Cartridges and Sediment Systems',
        _wellSepticProducts(
          baseName: 'Water Filter Part',
          unit: 'each',
          variants: [
            for (final size in [
              '2.5 x 10 in',
              '2.5 x 20 in',
              '4.5 x 10 in',
              '4.5 x 20 in',
            ])
              for (final micron in [
                '1 Micron',
                '5 Micron',
                '20 Micron',
                '50 Micron',
              ])
                for (final grade in ['Standard', 'High Capacity'])
                  for (final item in [
                    'Sediment Filter Cartridge',
                    'Carbon Filter Cartridge',
                    'String Wound Filter Cartridge',
                    'Pleated Filter Cartridge',
                  ])
                    '$grade $size $micron $item',
            for (final port in ['3/4 in', '1 in', '1-1/4 in'])
              for (final item in [
                'Whole House Filter Housing',
                'Filter Housing Wrench',
                'Filter Housing O Ring',
                'Spin Down Sediment Filter',
              ])
                '$port $item',
          ],
          aliases: const [
            'sediment filter',
            'water filter cartridge',
            'whole house filter',
            'filter housing',
            'spin down filter',
            'filter o ring',
          ],
        ),
      ),
      _type(
        'Softeners UV Reverse Osmosis and Treatment Supplies',
        _wellSepticProducts(
          baseName: 'Water Treatment Part',
          unit: 'each',
          variants: [
            for (final size in [
              '24K Grain',
              '32K Grain',
              '48K Grain',
              '64K Grain',
            ])
              for (final item in [
                'Water Softener',
                'Softener Resin Tank',
                'Brine Tank',
                'Bypass Valve',
                'Softener Resin Bag',
              ])
                '$size $item',
            for (final gpd in ['50 GPD', '75 GPD', '100 GPD'])
              for (final item in [
                'Reverse Osmosis Membrane',
                'RO Filter Set',
                'RO Storage Tank',
                'RO Faucet',
              ])
                '$gpd $item',
            for (final watt in ['12W', '25W', '40W'])
              for (final item in [
                'UV Lamp',
                'UV Quartz Sleeve',
                'UV Ballast',
                'UV Water Treatment System',
              ])
                '$watt $item',
          ],
          aliases: const [
            'water softener',
            'brine tank',
            'softener resin',
            'reverse osmosis',
            'ro membrane',
            'uv lamp',
            'uv sleeve',
          ],
        ),
      ),
    ]),
    _system('Septic Tank Risers Pumps and Drainfield Materials', [
      _type(
        'Septic Risers Lids Effluent Pumps and Alarms',
        _wellSepticProducts(
          baseName: 'Septic Tank Part',
          unit: 'each',
          variants: [
            for (final diameter in ['12 in', '16 in', '20 in', '24 in'])
              for (final height in ['6 in', '12 in', '18 in', '24 in'])
                for (final grade in ['Standard', 'Heavy Duty'])
                  for (final item in [
                    'Septic Tank Riser',
                    'Septic Riser Lid',
                    'Septic Riser Adapter Ring',
                  ])
                    '$grade $diameter x $height $item',
            for (final hp in ['1/3 HP', '1/2 HP', '3/4 HP'])
              for (final item in [
                'Effluent Pump',
                'Sewage Pump',
                'Septic Pump Float Switch',
                'High Water Alarm',
              ])
                '$hp $item',
          ],
          aliases: const [
            'septic riser',
            'riser lid',
            'adapter ring',
            'effluent pump',
            'sewage pump',
            'float switch',
            'high water alarm',
          ],
        ),
      ),
      _type(
        'Drainfield Pipe Chambers Fabric and Septic Supplies',
        _wellSepticProducts(
          baseName: 'Septic Drainfield Part',
          unit: 'each',
          variants: [
            for (final size in ['3 in', '4 in', '6 in'])
              for (final length in ['10 ft', '20 ft', '100 ft'])
                for (final item in [
                  'Perforated Drain Pipe',
                  'Solid Drain Pipe',
                  'Septic Header Pipe',
                ])
                  '$size x $length $item',
            for (final size in ['16 x 34 in', '22 x 48 in', '34 x 53 in'])
              for (final item in [
                'Leach Field Chamber',
                'Infiltrator Chamber',
                'Chamber End Cap',
                'Distribution Box',
              ])
                '$size $item',
            for (final width in ['3 ft', '4 ft', '6 ft'])
              for (final length in ['50 ft', '100 ft', '300 ft'])
                '$width x $length Septic Filter Fabric',
          ],
          aliases: const [
            'septic pipe',
            'perforated pipe',
            'drainfield pipe',
            'leach field chamber',
            'infiltrator chamber',
            'distribution box',
            'septic fabric',
          ],
        ),
      ),
    ]),
    _system('Water Storage Chemical Feed and Test Supplies', [
      _type(
        'Storage Tanks Chemical Feed and Water Testing',
        _wellSepticProducts(
          baseName: 'Water System Service Part',
          unit: 'each',
          variants: [
            for (final gallon in ['35 gal', '55 gal', '100 gal', '250 gal'])
              for (final item in [
                'Water Storage Tank',
                'Retention Tank',
                'Contact Tank',
                'Chemical Solution Tank',
              ])
                '$gallon $item',
            for (final output in ['10 GPD', '22 GPD', '45 GPD'])
              for (final item in [
                'Chemical Feed Pump',
                'Chlorine Injection Pump',
                'Pump Tubing Kit',
                'Injection Check Valve',
              ])
                '$output $item',
            for (final item in [
              'Water Hardness Test Kit',
              'Iron Test Kit',
              'pH Test Kit',
              'Bacteria Sample Bottle',
              'Chlorine Test Strips',
              'Septic Treatment Packet',
              'Septic Bacteria Additive',
              'Well Sanitizer Pellets',
            ])
              item,
          ],
          aliases: const [
            'storage tank',
            'retention tank',
            'chemical feed pump',
            'chlorine pump',
            'water test kit',
            'septic treatment',
            'well sanitizer',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _wellSepticProducts({
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

const _waterSystemGrades = ['Standard', 'Heavy Duty', 'Contractor Grade'];
