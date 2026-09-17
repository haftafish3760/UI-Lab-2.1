part of '../../work_supply_catalog.dart';

final plumbingServiceTruckCategory = _category('Service Truck Stock', [
  _system('Stop Valve and Supply Repairs', [
    _type(
      'Quarter Turn Stops',
      _plumbingServiceMatrixItems(
        baseName: 'Quarter Turn Angle Stop',
        unit: 'each',
        variants: [
          for (final inlet in [
            '1/2 in FIP',
            '1/2 in CPVC',
            '1/2 in PEX crimp',
            '1/2 in PEX expansion',
            '1/2 in push-fit',
            '5/8 in OD compression',
          ])
            for (final outlet in ['3/8 in OD', '1/4 in OD'])
              for (final handle in ['oval handle', 'lever handle'])
                '$inlet x $outlet $handle',
        ],
        aliases: const [
          'angle stop',
          'supply stop',
          'quarter turn stop',
          'shutoff valve',
          'fixture stop',
        ],
      ),
    ),
    _type(
      'Straight Stops',
      _plumbingServiceMatrixItems(
        baseName: 'Quarter Turn Straight Stop',
        unit: 'each',
        variants: [
          for (final inlet in [
            '1/2 in FIP',
            '1/2 in CPVC',
            '1/2 in PEX crimp',
            '1/2 in push-fit',
            '5/8 in OD compression',
          ])
            for (final outlet in ['3/8 in OD', '1/4 in OD']) '$inlet x $outlet',
        ],
        aliases: const [
          'straight stop',
          'supply stop',
          'fixture shutoff',
          'quarter turn valve',
        ],
      ),
    ),
    _type(
      'Stop Repair Parts',
      _plumbingServiceMatrixItems(
        baseName: 'Supply Stop Repair Part',
        unit: 'pack',
        variants: [
          for (final part in [
            'handle screw',
            'oval handle',
            'compression sleeve puller',
            '5/8 in compression nut and ferrule',
            '3/8 in compression nut and ferrule',
            'stop valve escutcheon',
            'split escutcheon',
          ])
            for (final pack in ['single', '2 pack', '5 pack', '10 pack'])
              '$part $pack',
        ],
        aliases: const [
          'ferrule',
          'compression sleeve',
          'stop handle',
          'escutcheon',
          'valve repair',
        ],
      ),
    ),
  ]),
  _system('Water Heater Service Stock', [
    _type(
      'Water Heater Connectors Detail',
      _plumbingServiceMatrixItems(
        baseName: 'Water Heater Connector',
        unit: 'each',
        variants: [
          for (final connection in [
            '3/4 in FIP x 3/4 in FIP',
            '3/4 in push-fit x 3/4 in FIP',
            '3/4 in compression x 3/4 in FIP',
            '3/4 in sweat x 3/4 in FIP',
          ])
            for (final length in ['12 in', '15 in', '18 in', '24 in'])
              '$connection $length corrugated stainless',
        ],
        aliases: const [
          'water heater supply',
          'water heater line',
          'heater connector',
          'corrugated connector',
        ],
      ),
    ),
    _type(
      'Water Heater Repair Parts',
      _plumbingServiceMatrixItems(
        baseName: 'Water Heater Repair Part',
        unit: 'each',
        variants: [
          for (final part in [
            '4500 watt screw-in element',
            '5500 watt screw-in element',
            'upper thermostat',
            'lower thermostat',
            'thermostat and element tune-up kit',
            '24 in magnesium anode rod',
            '42 in magnesium anode rod',
            '42 in aluminum zinc anode rod',
            '3/4 in brass drain valve',
            '3/4 in ball drain valve',
            '3/4 in T and P relief valve',
            '3/4 in dielectric union',
            '3/4 in dielectric nipple pair',
          ])
            part,
        ],
        aliases: const [
          'heater element',
          'water heater element',
          'thermostat',
          'anode rod',
          't&p valve',
          'tpr valve',
          'heater drain',
          'dielectric union',
        ],
      ),
    ),
    _type(
      'Water Heater Install Accessories',
      _plumbingServiceMatrixItems(
        baseName: 'Water Heater Install Accessory',
        unit: 'each',
        variants: [
          for (final part in [
            '20 in drain pan with fitting',
            '22 in drain pan with fitting',
            '24 in drain pan with fitting',
            '26 in drain pan with fitting',
            '2 gal thermal expansion tank',
            '4.5 gal thermal expansion tank',
            'expansion tank mounting bracket',
            'earthquake strap kit',
            'gas sediment trap kit',
            '3/4 in vacuum relief valve',
          ])
            part,
        ],
        aliases: const [
          'heater pan',
          'water heater pan',
          'expansion tank',
          'seismic strap',
          'sediment trap',
          'vacuum relief',
        ],
      ),
    ),
  ]),
  _system('Tubular Drain Service Stock', [
    _type(
      'Trap and Tailpiece Detail',
      _plumbingServiceMatrixItems(
        baseName: 'Tubular Drain Part',
        unit: 'each',
        variants: [
          for (final size in ['1-1/4 in', '1-1/2 in'])
            for (final finish in ['white plastic', 'chrome', 'brass'])
              for (final part in [
                'P-trap',
                'J-bend',
                'wall tube',
                'flanged tailpiece',
                'extension tube',
                'slip joint elbow',
              ])
                '$size $finish $part',
        ],
        aliases: const [
          'p trap',
          'j bend',
          'tailpiece',
          'extension tube',
          'sink drain',
          'slip joint',
        ],
      ),
    ),
    _type(
      'Drain Repair Kits',
      _plumbingServiceMatrixItems(
        baseName: 'Drain Repair Kit',
        unit: 'kit',
        variants: [
          for (final item in [
            'kitchen sink center outlet waste',
            'kitchen sink end outlet waste',
            'continuous waste with dishwasher branch',
            'disposal install kit with elbow',
            'sink basket strainer stainless',
            'sink basket strainer deep cup',
            'pop-up drain assembly chrome',
            'pop-up drain assembly brushed nickel',
            'lavatory drain less overflow',
            'lavatory drain with overflow',
          ])
            item,
        ],
        aliases: const [
          'continuous waste',
          'dishwasher branch',
          'disposal kit',
          'basket strainer',
          'pop up drain',
          'lav drain',
        ],
      ),
    ),
    _type(
      'Slip Joint Hardware',
      _plumbingServiceMatrixItems(
        baseName: 'Slip Joint Hardware',
        unit: 'pack',
        variants: [
          for (final size in ['1-1/4 in', '1-1/2 in'])
            for (final part in [
              'rubber washers',
              'poly washers',
              'beveled washers',
              'slip nuts',
              'nut and washer kit',
            ])
              for (final pack in ['2 pack', '5 pack', '10 pack'])
                '$size $part $pack',
        ],
        aliases: const [
          'slip nut',
          'slip washer',
          'trap washer',
          'beveled washer',
          'drain washer',
        ],
      ),
    ),
  ]),
  _system('Toilet Service Stock', [
    _type(
      'Toilet Tank Parts Detail',
      _plumbingServiceMatrixItems(
        baseName: 'Toilet Tank Repair Part',
        unit: 'each',
        variants: [
          for (final part in [
            'universal fill valve',
            'quiet fill valve',
            '3 in flush valve',
            '2 in flush valve',
            'flapper 2 in universal',
            'flapper 3 in universal',
            'tank lever chrome',
            'tank lever brushed nickel',
            'tank to bowl bolt kit',
            'tank to bowl gasket kit',
            'sponge gasket kit',
            'closet bolt kit brass',
            'closet bolt kit stainless',
            'toilet seat bolt set',
          ])
            part,
        ],
        aliases: const [
          'fill valve',
          'flush valve',
          'toilet flapper',
          'tank lever',
          'tank bolt',
          'closet bolt',
          'seat bolt',
          'toilet seat bolt',
          'toilet gasket',
        ],
      ),
    ),
    _type(
      'Toilet Flange and Seal Detail',
      _plumbingServiceMatrixItems(
        baseName: 'Toilet Flange and Seal Part',
        unit: 'each',
        variants: [
          for (final part in [
            'standard wax ring',
            'extra thick wax ring',
            'wax ring with horn',
            'wax-free toilet seal',
            'closet flange spacer 1/4 in',
            'closet flange spacer 1/2 in',
            'stainless flange repair ring',
            'split flange repair ring',
            'PVC offset closet flange',
            'inside pipe closet flange',
          ])
            part,
        ],
        aliases: const [
          'wax ring',
          'toilet seal',
          'flange spacer',
          'flange repair',
          'closet flange',
        ],
      ),
    ),
  ]),
  _system('Fixture and Faucet Service Stock', [
    _type(
      'Aerators and Adapters',
      _plumbingServiceMatrixItems(
        baseName: 'Faucet Aerator and Adapter',
        unit: 'each',
        variants: [
          for (final thread in [
            '15/16-27 male',
            '55/64-27 female',
            '13/16-27 male',
            '3/4-27 female',
          ])
            for (final finish in ['chrome', 'brushed nickel', 'matte black'])
              for (final flow in ['1.2 gpm', '1.5 gpm', '2.2 gpm'])
                '$thread $finish $flow',
        ],
        aliases: const [
          'faucet aerator',
          'aerator adapter',
          'lav aerator',
          'faucet screen',
        ],
      ),
    ),
    _type(
      'Faucet Repair Assortments',
      _plumbingServiceMatrixItems(
        baseName: 'Faucet Repair Assortment',
        unit: 'pack',
        variants: [
          for (final part in [
            'seat washer assortment',
            'o-ring assortment',
            'cartridge clip assortment',
            'ceramic cartridge hot',
            'ceramic cartridge cold',
            'single handle cartridge',
            'stem packing',
            'bonnet nut assortment',
          ])
            for (final pack in ['single', '2 pack', '10 pack']) '$part $pack',
        ],
        aliases: const [
          'faucet stem',
          'cartridge',
          'seat washer',
          'o ring',
          'stem packing',
          'faucet repair',
        ],
      ),
    ),
  ]),
  _system('Pump and Discharge Service Stock', [
    _type(
      'Flexible Drain Repair Couplings',
      _plumbingServiceMatrixItems(
        baseName: 'Flexible Drain Repair Coupling',
        unit: 'each',
        variants: [
          for (final size in ['1-1/2 in', '2 in', '3 in', '4 in'])
            '$size straight Fernco-style rubber coupling',
          for (final size in ['2 x 1-1/2 in', '3 x 2 in', '4 x 3 in'])
            '$size reducing Fernco-style rubber coupling',
        ],
        aliases: const [
          'fernco',
          'fernco coupling',
          'rubber coupling',
          'flexible coupling',
          'flex drain coupling',
          'drain repair coupling',
          'red cplg',
        ],
      ),
    ),
    _type(
      'Sump Pump Discharge Parts',
      _plumbingServiceMatrixItems(
        baseName: 'Sump Pump Discharge Part',
        unit: 'each',
        variants: [
          for (final size in ['1-1/4 in', '1-1/2 in'])
            for (final part in [
              'quiet check valve',
              'standard check valve',
              'rubber coupling',
              'discharge hose kit',
              'PVC adapter',
              'barbed adapter',
            ])
              '$size $part',
        ],
        aliases: const [
          'sump pump check valve',
          'pump check',
          'discharge hose',
          'pump adapter',
          'sump pump adapter',
          'barbed adapter',
          'sump pump barbed adapter',
          'rubber coupling',
        ],
      ),
    ),
    _type(
      'Pump Controls and Alarms',
      _plumbingServiceMatrixItems(
        baseName: 'Pump Control Part',
        unit: 'each',
        variants: [
          for (final part in [
            'piggyback float switch',
            'vertical float switch',
            'tethered float switch',
            'high water alarm',
            'condensate pump safety switch',
            'battery backup sensor',
          ])
            part,
        ],
        aliases: const [
          'float switch',
          'pump switch',
          'high water alarm',
          'pump alarm',
          'backup sensor',
        ],
      ),
    ),
  ]),
  _system('Water Treatment Service Stock', [
    _type(
      'Whole House Filter Service Parts',
      _plumbingServiceMatrixItems(
        baseName: 'Water Filter Service Part',
        unit: 'each',
        variants: [
          for (final size in [
            '2.5 x 10 in',
            '2.5 x 20 in',
            '4.5 x 10 in',
            '4.5 x 20 in',
          ])
            for (final micron in ['1 micron', '5 micron', '20 micron'])
              for (final media in [
                'sediment filter cartridge',
                'carbon filter cartridge',
                'pleated filter cartridge',
              ])
                '$size $micron $media',
          for (final port in ['3/4 in', '1 in'])
            for (final part in [
              'whole house filter housing',
              'spin down sediment filter',
              'filter housing wrench',
              'filter housing o-ring',
            ])
              '$port $part',
        ],
        aliases: const [
          'water filter',
          'sediment filter',
          'whole house filter',
          'filter cartridge',
          'water filter cartridge',
          'filter housing',
          'spin down filter',
        ],
      ),
    ),
    _type(
      'Water Softener and Treatment Service Parts',
      _plumbingServiceMatrixItems(
        baseName: 'Water Treatment Service Part',
        unit: 'each',
        variants: [
          for (final size in ['24K grain', '32K grain', '48K grain'])
            for (final part in [
              'water softener bypass valve',
              'water softener control valve seal kit',
              'water softener brine valve',
              'water softener brine line flow control',
              'water softener distributor tube',
              'water softener resin tank o-ring',
              'water softener injector screen',
            ])
              '$size $part',
          for (final bag in ['40 lb', '50 lb'])
            for (final salt in [
              'solar salt crystals',
              'water softener salt pellets',
              'potassium chloride softener pellets',
              'rust remover softener salt',
            ])
              '$bag $salt',
          for (final resin in ['0.5 cu ft', '1 cu ft', '1.5 cu ft'])
            '$resin cation softener resin bag',
          for (final ro in ['50 GPD', '75 GPD', '100 GPD'])
            for (final part in [
              'reverse osmosis sediment prefilter',
              'reverse osmosis carbon prefilter',
              'reverse osmosis membrane',
              'reverse osmosis post filter',
              'reverse osmosis tank shutoff valve',
            ])
              '$ro $part',
          for (final watt in ['12W', '25W'])
            for (final part in [
              'uv water treatment lamp',
              'uv quartz sleeve',
              'uv sleeve o-ring',
            ])
              '$watt $part',
        ],
        aliases: const [
          'water softener',
          'softener salt',
          'salt pellets',
          'solar salt',
          'potassium chloride pellets',
          'brine tank',
          'brine valve',
          'softener resin',
          'resin bag',
          'bypass valve',
          'ro filter',
          'reverse osmosis',
          'ro membrane',
          'uv lamp',
          'uv sleeve',
          'water treatment',
        ],
      ),
    ),
  ]),
  plumbingServiceTruckToolsSystem,
]);

List<WorkSupplyItem> _plumbingServiceMatrixItems({
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
          baseName,
          variant,
          ..._plumbingReceiptShorthand(variant),
        ],
      ),
  ];
}

List<String> _plumbingReceiptShorthand(String variant) {
  final normalized = variant.toLowerCase();
  final terms = <String>[];
  if (normalized.contains('quarter turn')) terms.add('1/4 turn');
  if (normalized.contains('push-fit')) terms.add('push connect');
  if (normalized.contains('3/8 in od')) terms.add('3/8 od');
  if (normalized.contains('1/4 in od')) terms.add('1/4 od');
  if (normalized.contains('15/16-27')) terms.add('15/16 aerator');
  if (normalized.contains('55/64-27')) terms.add('55/64 aerator');
  if (normalized.contains('1-1/2 in')) terms.add('1-1/2');
  if (normalized.contains('1-1/4 in')) terms.add('1-1/4');
  if (normalized.contains('t and p')) terms.add('tp relief');
  if (normalized.contains('wax-free')) terms.add('wax free');
  return terms;
}
