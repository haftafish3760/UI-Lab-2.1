part of '../../work_supply_catalog.dart';

final applianceInstallationRepairGeneratedDetailCatalogCategory = _category(
  'Appliance Installation Repair Detail Stock',
  [
    _system('Dishwasher Disposal and Sink Appliance Connections', [
      _type(
        'Dishwasher Install Kits and Repair Parts',
        _applianceProducts(
          baseName: 'Dishwasher Install Part',
          unit: 'each',
          variants: [
            for (final length in ['4 ft', '5 ft', '6 ft', '8 ft', '10 ft'])
              for (final grade in _applianceGrades)
                for (final connection in [
                  '3/8 in Compression Braided Supply Line',
                  '3/8 in Compression Dishwasher Connector Kit',
                  '90 Degree Dishwasher Elbow',
                  'Dishwasher Drain Hose',
                  'Corrugated Dishwasher Drain Hose',
                ])
                  '$grade $length $connection',
            for (final length in ['4 ft', '5 ft', '6 ft', '8 ft'])
              for (final connection in [
                'Universal Dishwasher Installation Kit',
                'Braided Dishwasher Supply Kit',
                'Dishwasher Drain Extension Kit',
              ])
                '$length $connection',
            for (final finish in ['White', 'Black', 'Stainless'])
              for (final item in [
                'Dishwasher Air Gap',
                'Dishwasher Tailpiece',
                'Dishwasher Mounting Bracket Kit',
                'Dishwasher Side Mount Kit',
                'Dishwasher Power Cord Kit',
              ])
                '$finish $item',
          ],
          aliases: const [
            'dishwasher supply',
            'dishwasher connector',
            'dishwasher elbow',
            'dishwasher drain hose',
            'dishwasher air gap',
            'dishwasher bracket',
            'dishwasher cord',
          ],
        ),
      ),
      _type(
        'Garbage Disposal Install and Service Parts',
        _applianceProducts(
          baseName: 'Disposal Install Part',
          unit: 'each',
          variants: [
            for (final hp in ['1/3 HP', '1/2 HP', '3/4 HP', '1 HP'])
              for (final grade in _applianceGrades)
                for (final item in [
                  'Garbage Disposal Mounting Assembly',
                  'Garbage Disposal Power Cord Kit',
                  'Garbage Disposal Splash Guard',
                  'Garbage Disposal Stopper',
                  'Garbage Disposal Discharge Tube Kit',
                ])
                  '$grade $hp $item',
            for (final finish in ['Chrome', 'Black', 'White'])
              '$finish Disposal Air Switch Kit',
          ],
          aliases: const [
            'garbage disposal',
            'disposal mount',
            'disposal cord',
            'splash guard',
            'discharge tube',
            'air switch',
          ],
        ),
      ),
    ]),
    _system('Laundry Appliance Supply Drain and Venting', [
      _type(
        'Washer Hoses Valves and Drain Parts',
        _applianceProducts(
          baseName: 'Laundry Appliance Part',
          unit: 'each',
          variants: [
            for (final length in ['4 ft', '5 ft', '6 ft', '8 ft', '10 ft'])
              for (final grade in _applianceGrades)
                for (final hose in [
                  'Stainless Washer Hose Pair',
                  'Rubber Washer Hose Pair',
                  'Steam Dryer Inlet Hose',
                  'Washing Machine Drain Hose',
                  'Washer Discharge Hose',
                ])
                  '$grade $length $hose',
            for (final length in ['6 ft', '8 ft', '10 ft', '12 ft'])
              for (final item in [
                'Washer Drain Hose Extension',
                'Washer Fill Hose Extension',
                'Washer Pan Drain Hose',
              ])
                '$length $item',
            for (final item in [
              'Washing Machine Outlet Box',
              'Single Lever Washing Machine Valve',
              'Washer Hose Y Connector',
              'Washer Hose Screen Pack',
              'Washer Drain Hose Hook',
            ])
              item,
          ],
          aliases: const [
            'washer hose',
            'washing machine hose',
            'washer drain hose',
            'washer outlet box',
            'washing machine valve',
            'steam dryer hose',
          ],
        ),
      ),
      _type(
        'Dryer Venting Cords and Gas Connections',
        _applianceProducts(
          baseName: 'Dryer Install Part',
          unit: 'each',
          variants: [
            for (final length in ['4 ft', '5 ft', '6 ft', '8 ft', '10 ft'])
              for (final grade in _applianceGrades)
                for (final item in [
                  'Semi Rigid Dryer Duct',
                  'Flexible Dryer Vent Hose',
                  'Dryer Gas Connector',
                  'Dryer Vent Periscope',
                ])
                  '$grade $length $item',
            for (final amp in ['30 Amp'])
              for (final prong in ['3 Prong', '4 Prong'])
                for (final length in ['4 ft', '6 ft', '8 ft'])
                  for (final grade in _applianceGrades)
                    '$grade $amp $prong $length Dryer Cord',
            for (final item in [
              'Dryer Vent Wall Box',
              'Dryer Vent Hood',
              'Dryer Vent Clamp Pair',
              'Dryer Lint Trap Kit',
              'Dryer Booster Fan',
            ])
              item,
          ],
          aliases: const [
            'dryer vent',
            'dryer duct',
            'dryer hose',
            'dryer cord',
            'dryer gas connector',
            'dryer clamp',
          ],
        ),
      ),
    ]),
    _system('Kitchen Range Refrigerator and Microwave Installs', [
      _type(
        'Range Oven and Cooktop Connections',
        _applianceProducts(
          baseName: 'Range Appliance Part',
          unit: 'each',
          variants: [
            for (final amp in ['40 Amp', '50 Amp'])
              for (final prong in ['3 Prong', '4 Prong'])
                for (final length in ['4 ft', '6 ft', '8 ft'])
                  for (final grade in _applianceGrades)
                    '$grade $amp $prong $length Range Cord',
            for (final length in ['24 in', '36 in', '48 in', '60 in', '72 in'])
              for (final grade in _applianceGrades)
                for (final item in [
                  'Gas Range Connector',
                  'Gas Appliance Connector',
                  'Flexible Gas Connector',
                ])
                  '$grade $length $item',
            for (final item in [
              'Range Anti Tip Bracket',
              'Cooktop Foam Tape',
              'Range Hood Damper',
              'Range Hood Wall Cap',
              'Range Hood Roof Cap',
            ])
              item,
          ],
          aliases: const [
            'range cord',
            'oven cord',
            'stove cord',
            'gas range connector',
            'anti tip bracket',
            'range hood damper',
          ],
        ),
      ),
      _type(
        'Refrigerator Water Lines and Ice Maker Parts',
        _applianceProducts(
          baseName: 'Refrigerator Install Part',
          unit: 'each',
          variants: [
            for (final length in ['5 ft', '10 ft', '15 ft', '20 ft', '25 ft'])
              for (final grade in _applianceGrades)
                for (final item in [
                  'Braided Refrigerator Water Line',
                  'Poly Ice Maker Line',
                  'Copper Ice Maker Line',
                  'Ice Maker Supply Kit',
                ])
                  '$grade $length $item',
            for (final item in [
              'Refrigerator Water Filter Bypass Plug',
              'Ice Maker Saddle Valve Kit',
              'Ice Maker Outlet Box',
              'Refrigerator Drip Tray',
              'Refrigerator Water Line Union',
            ])
              item,
          ],
          aliases: const [
            'refrigerator water line',
            'fridge water line',
            'ice maker line',
            'ice maker kit',
            'saddle valve',
            'fridge filter bypass',
          ],
        ),
      ),
      _type(
        'Microwave Dishwasher and Built In Appliance Trim',
        _applianceProducts(
          baseName: 'Built In Appliance Install Part',
          unit: 'each',
          variants: [
            for (final finish in ['White', 'Black', 'Stainless'])
              for (final size in ['24 in', '27 in', '30 in', '36 in'])
                for (final item in [
                  'Over Range Microwave Mounting Bracket',
                  'Microwave Vent Damper',
                  'Microwave Charcoal Filter',
                  'Microwave Grease Filter',
                  'Dishwasher Trim Kit',
                  'Built In Oven Trim Kit',
                ])
                  '$finish $size $item',
            for (final size in ['24 in', '27 in', '30 in', '36 in'])
              for (final item in [
                'Appliance Filler Trim',
                'Appliance Gap Cover',
                'Cooktop Trim Ring',
              ])
                '$size $item',
          ],
          aliases: const [
            'microwave bracket',
            'microwave damper',
            'microwave filter',
            'dishwasher trim',
            'oven trim kit',
            'appliance filler',
          ],
        ),
      ),
    ]),
    _system('Service Parts Leveling Protection and Installation Supplies', [
      _type(
        'Common Appliance Repair and Wear Parts',
        _applianceProducts(
          baseName: 'Appliance Repair Part',
          unit: 'each',
          variants: [
            for (final appliance in [
              'Dishwasher',
              'Washer',
              'Dryer',
              'Range',
              'Refrigerator',
              'Microwave',
            ])
              for (final grade in _applianceGrades)
                for (final item in [
                  'Door Gasket',
                  'Leveling Leg',
                  'Mounting Screw Kit',
                  'Terminal Block',
                  'Thermal Fuse',
                  'Door Switch',
                  'Handle Screw Kit',
                  'Anti Vibration Pad Set',
                ])
                  '$grade $appliance $item',
          ],
          aliases: const [
            'appliance gasket',
            'leveling leg',
            'terminal block',
            'thermal fuse',
            'door switch',
            'anti vibration pad',
          ],
        ),
      ),
      _type(
        'Appliance Protection Moving and Finish Supplies',
        _applianceProducts(
          baseName: 'Appliance Install Supply',
          unit: 'each',
          variants: [
            for (final size in ['24 in', '27 in', '30 in', '36 in'])
              for (final grade in _applianceGrades)
                for (final item in [
                  'Appliance Drip Pan',
                  'Washer Drain Pan',
                  'Range Gap Cover Pair',
                  'Appliance Slide Mat',
                  'Appliance Floor Protector',
                ])
                  '$grade $size $item',
            for (final item in [
              'Appliance Touch Up Paint White',
              'Appliance Touch Up Paint Black',
              'Stainless Appliance Polish',
              'Appliance Installation Screw Pack',
              'Appliance Dolly Strap',
              'Appliance Moving Pads',
            ])
              item,
          ],
          aliases: const [
            'appliance drip pan',
            'washer pan',
            'range gap cover',
            'appliance touch up',
            'appliance screw',
            'appliance strap',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _applianceProducts({
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

const _applianceGrades = ['Universal', 'Standard', 'Heavy Duty', 'Premium'];
