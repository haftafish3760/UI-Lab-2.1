part of '../../work_supply_catalog.dart';

final hvacGeneratedServiceTruckDiagnosticsCatalogCategory = _category(
  'HVAC Service Truck Diagnostics Cleaning and Recovery Stock',
  [
    _system('Diagnostic Gauges Probes and Recovery Tools', [
      _type(
        'Vacuum Recovery and Diagnostic Tools',
        _hvacTruckDiagnosticProducts(
          baseName: 'HVAC Diagnostic Tool',
          unit: 'each',
          variants: [
            for (final item in [
              'Analog Manifold Gauge Set',
              'Digital Manifold Gauge Set',
              'Manifold Gauge Hose Set 36 in',
              'Manifold Gauge Hose Set 60 in',
              'Low Loss Refrigerant Hose Set',
              'Ball Valve Charging Hose Set',
              'Refrigerant Charging Scale 220 lb',
              'Compact Refrigerant Scale',
              'Recovery Machine Filter Drier',
              'Refrigerant Recovery Tank 30 lb',
              'Core Removal Tool 1/4 in',
              'Core Removal Tool 5/16 in',
              'Micron Gauge',
              'Vacuum Pump Oil Quart',
              'Vacuum Pump Oil Gallon',
              'Vacuum Pump Exhaust Filter',
              'Tubing Cutter 1/8 in to 1-1/8 in',
              'Mini Tubing Cutter',
              'Eccentric Flaring Tool',
              'Deburring Tool',
            ])
              item,
          ],
          aliases: const [
            'manifold gauge',
            'gauge set',
            'refrigerant scale',
            'charging scale',
            'recovery tank',
            'recovery machine filter',
            'micron gauge',
            'vacuum pump oil',
            'core removal tool',
            'flaring tool',
            'tubing cutter',
          ],
        ),
      ),
      _type(
        'Meters Thermometers and Refrigerant Test Instruments',
        _hvacTruckDiagnosticProducts(
          baseName: 'HVAC Test Instrument',
          unit: 'each',
          variants: [
            for (final item in [
              'Clamp Meter',
              'True RMS Multimeter',
              'Dual Port Manometer',
              'Digital Psychrometer',
              'Temperature Clamp Probe Pair',
              'Pipe Clamp Thermometer',
              'Infrared Thermometer',
              'Static Pressure Tip Kit',
              'Pitot Tube Static Pressure Probe',
              'Combustion Analyzer Filter Pack',
              'Combustion Analyzer Printer Paper',
              'Carbon Monoxide Meter',
              'Refrigerant Identifier Hose Adapter',
              'Low Voltage Test Leads',
              'Alligator Clip Test Lead Set',
            ])
              item,
          ],
          aliases: const [
            'clamp meter',
            'multimeter',
            'manometer',
            'psychrometer',
            'temperature clamp',
            'pipe clamp thermometer',
            'infrared thermometer',
            'static pressure tip',
            'combustion analyzer',
            'co meter',
            'test leads',
          ],
        ),
      ),
    ]),
    _system('Leak Detection Coil Cleaning and Drain Service Stock', [
      _type(
        'Leak Detection Dye and Refrigerant Service Consumables',
        _hvacTruckDiagnosticProducts(
          baseName: 'HVAC Leak Detection Supply',
          unit: 'each',
          variants: [
            for (final item in [
              'Electronic Refrigerant Leak Detector',
              'Heated Diode Leak Detector Sensor',
              'Ultrasonic Leak Detector',
              'UV Leak Detection Dye Cartridge',
              'UV Dye Injector Hose',
              'UV Leak Detection Flashlight',
              'Bubble Leak Detector Spray',
              'Nylog Blue Thread Sealant',
              'Nylog Red Thread Sealant',
              'Refrigerant Cap Gasket Kit',
              'Schrader Core Assortment',
              'Valve Core Removal Gasket Kit',
              'Low Side Service Cap 10 Pack',
              'High Side Service Cap 10 Pack',
            ])
              item,
          ],
          aliases: const [
            'leak detector',
            'refrigerant leak detector',
            'uv dye',
            'dye injector',
            'bubble leak spray',
            'nylog',
            'schrader core',
            'service cap',
            'core gasket',
          ],
        ),
      ),
      _type(
        'Coil Cleaning and Condensate Drain Service Chemicals',
        _hvacTruckDiagnosticProducts(
          baseName: 'HVAC Cleaning Supply',
          unit: 'each',
          variants: [
            for (final size in ['18 oz', '32 oz', '1 gal'])
              for (final item in [
                'Foaming Evaporator Coil Cleaner',
                'Condenser Coil Cleaner',
                'No Rinse Evaporator Cleaner',
                'Alkaline Coil Cleaner',
                'Drain Line Cleaner',
              ])
                '$size $item',
            for (final item in [
              'Condensate Pan Tablet Bottle',
              'Condensate Pan Strip Pack',
              'Drain Line Brush Kit',
              'Condensate Drain Gun Cartridge',
              'Nitrogen Drain Blowout Adapter',
              'Fin Comb Set',
              'Coil Brush',
              'Spray Wand Pump Bottle',
              'Wet Dry Vacuum Hose Adapter',
            ])
              item,
          ],
          aliases: const [
            'coil cleaner',
            'evap cleaner',
            'condenser cleaner',
            'no rinse cleaner',
            'drain line cleaner',
            'pan tablets',
            'pan strips',
            'drain brush',
            'fin comb',
            'coil brush',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _hvacTruckDiagnosticProducts({
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
