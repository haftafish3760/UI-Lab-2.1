part of '../../../work_supply_catalog.dart';

List<WorkSupplyItem> _hvacDetailFurnaceProducts() {
  return _hvacDetailProducts(
    baseName: 'Furnace Service Detail',
    unit: 'each',
    variants: [
      for (final style in ['Universal', 'Flat', 'Round', 'Silicon Nitride'])
        '$style Hot Surface Ignitor',
      for (final style in ['Straight', 'Bent', 'Universal'])
        '$style Flame Sensor',
      for (final port in ['Single Port', 'Dual Port'])
        for (final rating in ['0.40 in WC', '0.60 in WC', '0.90 in WC'])
          '$port $rating Pressure Switch',
      for (final temp in [
        '150 Degree',
        '180 Degree',
        '200 Degree',
        '250 Degree',
      ])
        for (final item in ['Limit Switch', 'Rollout Switch']) '$temp $item',
      'Furnace Door Safety Switch',
      'Draft Inducer Motor',
      'Inducer Motor Gasket',
      'Combustion Blower Gasket',
      'Furnace Control Board',
      'Integrated Furnace Control Board',
      '24V Natural Gas Valve',
      '24V Propane Gas Valve',
      'Silicone Pressure Switch Tubing',
    ],
    aliases: const [
      'hot surface ignitor',
      'hsi',
      'flame sensor',
      'pressure switch',
      'limit switch',
      'rollout switch',
      'gas valve',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailMotorProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Motor Detail',
    unit: 'each',
    variants: [
      for (final hp in [
        '1/6 hp',
        '1/4 hp',
        '1/3 hp',
        '1/2 hp',
        '3/4 hp',
        '1 hp',
      ])
        for (final voltage in ['115V', '208-230V'])
          for (final item in [
            'PSC Blower Motor',
            'ECM Blower Motor',
            'Condenser Fan Motor',
            'Draft Inducer Motor',
          ])
            '$hp $voltage $item',
      for (final size in ['10 x 8', '10 x 10', '11 x 10', '12 x 12', '13 x 10'])
        '$size Blower Wheel',
      for (final size in ['18 in', '20 in', '22 in', '24 in', '26 in'])
        for (final pitch in ['22 Degree', '27 Degree', '33 Degree'])
          '$size $pitch Condenser Fan Blade',
    ],
    aliases: const [
      'blower motor',
      'condenser fan motor',
      'inducer motor',
      'blower wheel',
      'fan blade',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailConsumableProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Consumable Detail',
    unit: 'each',
    variants: [
      for (final size in ['1 qt', '1 gal', '2 gal'])
        for (final item in [
          'No Rinse Evaporator Coil Cleaner',
          'Condenser Coil Cleaner',
          'Alkaline Coil Cleaner',
          'Drain Line Cleaner',
        ])
          '$size $item',
      for (final size in ['2 in x 50 yd', '3 in x 50 yd', '4 in x 50 yd'])
        for (final item in ['UL 181 Foil Tape', 'Mastic Foil Tape'])
          '$size $item',
      for (final size in ['1 gal', '2 gal', '5 gal'])
        for (final item in ['Duct Mastic', 'Water Based Duct Sealant'])
          '$size $item',
      'Vacuum Pump Oil 1 qt',
      'Thread Sealant for Refrigeration',
      'Refrigerant Leak Detector Spray',
      'UV Dye Leak Detection Kit',
      'Pan Treatment Tablets',
      'Foam Gasket Tape',
      'Cork Insulation Tape',
      'Duct Strap Roll',
      'Metal Hanging Strap Roll',
    ],
    aliases: const [
      'coil cleaner',
      'duct mastic',
      'foil tape',
      'vacuum pump oil',
      'leak detector',
      'duct strap',
    ],
  );
}

List<WorkSupplyItem> _hvacDetailToolProducts() {
  return _hvacDetailProducts(
    baseName: 'HVAC Tool Accessory Detail',
    unit: 'each',
    variants: [
      for (final cfm in ['3 CFM', '5 CFM', '7 CFM']) '$cfm Vacuum Pump',
      for (final refrigerant in ['R22', 'R410A', 'R32', 'R454B'])
        for (final item in [
          'Manifold Gauge Set',
          'Charging Hose Set',
          'Charging Adapter',
        ])
          '$refrigerant $item',
      'Digital Refrigerant Scale',
      'Micron Gauge',
      'Core Removal Tool',
      'Flaring Tool Kit',
      'Swaging Tool Kit',
      'Tubing Cutter',
      'Deburring Tool',
      'Nitrogen Regulator',
      'Low Loss Fitting Set',
      'Service Valve Wrench',
    ],
    aliases: const [
      'vacuum pump',
      'manifold gauge',
      'refrigerant scale',
      'micron gauge',
      'core removal tool',
      'flare tool',
    ],
  );
}
