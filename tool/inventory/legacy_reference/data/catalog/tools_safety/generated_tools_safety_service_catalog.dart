part of '../../work_supply_catalog.dart';

final toolsSafetyGeneratedServiceCatalogCategory = _category(
  'Expanded Tools and Safety Service Stock',
  [
    _system('Expanded Hand Tools and Power Tool Consumables', [
      _type('Hand Tools', _handToolProducts()),
      _type('Saw Blades Bits and Abrasives', _bladeBitAbrasiveProducts()),
      _type('Power Tool Accessories', _powerToolAccessoryProducts()),
      _type(
        'Clamps Fastening Helpers and Tool Storage',
        _toolSupportProducts(),
      ),
      _type('Specialty Trade Tools and Testers', _specialtyTradeToolProducts()),
      _type('Pipe Plumbing and Drain Tools', _pipeDrainToolProducts()),
      _type(
        'Electrical Test Pulling and Labeling Tools',
        _electricalToolProducts(),
      ),
      _type(
        'Concrete Masonry Flooring and Roofing Tools',
        _finishTradeToolProducts(),
      ),
      _type('Fastener Anchor and Install Helpers', _installHelperProducts()),
    ]),
    _system('Expanded Safety and PPE', [
      _type('Gloves Glasses and Respirators', _ppeProducts()),
      _type('Jobsite Protection', _jobsiteProtectionProducts()),
      _type('Fall Protection and Roof Safety', _fallProtectionProducts()),
      _type('Spill Control and Fire Safety', _spillFireSafetyProducts()),
    ]),
    _system('Expanded Measuring Marking and Layout', [
      _type('Measuring and Layout Tools', _measuringLayoutProducts()),
      _type('Markers Pencils and Layout Consumables', _markingProducts()),
    ]),
    _system('Expanded Tapes Cleaning and Jobsite Consumables', [
      _type('Tapes and Adhesives', _tapeAdhesiveProducts()),
      _type('Cleaning and Trash Supplies', _cleaningProducts()),
      _type('Dust Control HEPA and Vacuum Accessories', _dustControlProducts()),
      _type('Buckets Tarps and Temporary Protection', _temporaryProducts()),
    ]),
    _system('Expanded Jobsite Power Light and Access', [
      _type('Extension Cords and Work Lights', _powerLightProducts()),
      _type('Ladders Stands and Access', _ladderAccessProducts()),
      _type('Fans Heaters and Temporary Jobsite Gear', _temporaryJobsiteGear()),
    ]),
  ],
);

List<WorkSupplyItem> _handToolProducts() {
  final wrenchSizes = ['6 in', '8 in', '10 in', '12 in', '15 in'];
  final plierTypes = [
    'Tongue and Groove Pliers',
    'Linesman Pliers',
    'Needle Nose Pliers',
    'Diagonal Cutting Pliers',
    'Locking Pliers',
  ];
  final screwdriverTypes = [
    'Multi-Bit Screwdriver',
    'Phillips Screwdriver',
    'Slotted Screwdriver',
    'Cabinet Screwdriver',
    'Insulated Screwdriver',
  ];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Hand Tool',
    unit: 'each',
    variants: [
      for (final size in wrenchSizes) '$size Adjustable Wrench',
      for (final type in plierTypes)
        for (final size in ['6 in', '8 in', '10 in', '12 in']) '$size $type',
      for (final type in screwdriverTypes) type,
      '16 oz Claw Hammer',
      '20 oz Rip Hammer',
      '3 lb Sledge Hammer',
      '15 in Pry Bar',
      '24 in Pry Bar',
      'Flat Bar',
      'Utility Knife',
      'Folding Utility Knife',
      'Drywall Jab Saw',
      'Hacksaw',
      'Tin Snips',
      'Aviation Snips Left Cut',
      'Aviation Snips Right Cut',
      'Aviation Snips Straight Cut',
      'Pipe Cutter',
      'Tubing Cutter',
      'Caulk Gun',
      'Putty Knife Set',
    ],
    aliases: const ['crescent wrench', 'channel lock', 'screwdriver'],
  );
}

List<WorkSupplyItem> _bladeBitAbrasiveProducts() {
  final sawSizes = ['6-1/2 in', '7-1/4 in', '10 in', '12 in'];
  final toothCounts = ['24T', '40T', '60T', '80T'];
  final discs = ['4-1/2 in', '5 in', '7 in'];
  final grits = ['40 grit', '60 grit', '80 grit', '120 grit', '220 grit'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Power Tool Consumable',
    unit: 'each',
    variants: [
      for (final size in sawSizes)
        for (final teeth in toothCounts) '$size $teeth Circular Saw Blade',
      '10 in 60T Miter Saw Blade',
      '12 in 80T Miter Saw Blade',
      'Twist Drill Bit Set',
      'Masonry Drill Bit Set',
      'Spade Bit Set',
      'Forstner Bit Set',
      'Step Drill Bit Set',
      'Driver Bit Set',
      'Impact Driver Bit Set',
      'Nut Driver Bit Set',
      'Hole Saw Kit',
      'Oscillating Tool Blade Pack',
      'Wood Reciprocating Saw Blade Pack',
      'Metal Reciprocating Saw Blade Pack',
      'Utility Knife Blades 50 Pack',
      'Utility Knife Blades 100 Pack',
      for (final size in discs) '$size Cut-Off Wheel Pack',
      for (final size in discs) '$size Grinding Wheel',
      for (final grit in grits) '$grit Sanding Disc Pack',
      for (final grit in grits) '$grit Sandpaper Sheet Pack',
      'Flap Disc Pack',
      'Wire Wheel Brush',
    ],
    aliases: const ['saw blade', 'drill bits', 'driver bits', 'razor blades'],
  );
}

List<WorkSupplyItem> _powerToolAccessoryProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Power Tool Accessory',
    unit: 'each',
    variants: const [
      'Magnetic Bit Holder',
      'Right Angle Drill Attachment',
      'Drill Chuck Adapter',
      'Quick Change Bit Holder',
      'Impact Socket Adapter Set',
      'Dust Collection Bag',
      'Shop Vacuum Filter',
      'Shop Vacuum Dust Bag Pack',
      'Shop Vacuum Hose',
      'Shop Vacuum Crevice Tool',
      'Tool Battery 2Ah',
      'Tool Battery 4Ah',
      'Tool Battery Charger',
      'Jobsite Radio Battery Adapter',
    ],
    aliases: const ['bit holder', 'tool battery', 'shop vac filter'],
  );
}

List<WorkSupplyItem> _toolSupportProducts() {
  final clampSizes = ['2 in', '4 in', '6 in', '12 in', '24 in', '36 in'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Tool Support Item',
    unit: 'each',
    variants: [
      for (final size in clampSizes) '$size Bar Clamp',
      for (final size in clampSizes) '$size C-Clamp',
      for (final size in ['6 in', '12 in', '24 in']) '$size Quick Clamp',
      'Spring Clamp Pack',
      'Corner Clamp',
      'Magnetic Parts Tray',
      'Tool Belt',
      'Tool Pouch',
      'Tool Bag 12 in',
      'Tool Bag 16 in',
      'Tool Bag 20 in',
      'Small Parts Organizer',
      'Deep Parts Organizer',
      'Rolling Tool Box',
      'Stackable Tool Box',
      'Kneeling Pad',
      'Magnetic Pickup Tool',
      'Inspection Mirror',
      'Telescoping Magnet',
    ],
    aliases: const ['bar clamp', 'c clamp', 'tool bag', 'parts organizer'],
  );
}

List<WorkSupplyItem> _specialtyTradeToolProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Specialty Trade Tool',
    unit: 'each',
    variants: [
      for (final length in ['25 ft', '50 ft', '100 ft', '200 ft'])
        '$length Fish Tape',
      for (final size in ['6 in', '10 in', '14 in', '18 in', '24 in'])
        '$size Pipe Wrench',
      for (final size in ['1/2 in', '3/4 in', '1 in']) '$size PEX Crimp Tool',
      for (final size in ['1/2 in', '3/4 in', '1 in']) '$size PEX Clamp Tool',
      for (final size in ['15 ft', '25 ft', '50 ft']) '$size Drain Auger',
      for (final range in ['0-100 PSI', '0-160 PSI', '0-300 PSI'])
        '$range Pressure Gauge',
      for (final tool in [
        'Digital Manifold Gauge Set',
        'Refrigerant Scale',
        'Combustible Gas Leak Detector',
        'Infrared Thermal Camera',
        'Moisture Meter Pin Type',
        'Moisture Meter Pinless',
        'Borescope Inspection Camera',
        'Outlet Circuit Analyzer',
        'Non Contact Voltage Tester',
        'Torque Screwdriver',
        'Torque Wrench',
        'Breaker Finder Kit',
        'Stud Sensor Deep Scan',
        'Tile Trowel Set',
        'Grout Float',
        'Margin Trowel',
        'Concrete Finishing Trowel',
        'Concrete Hand Float',
        'Masonry Line Block Set',
        'Brick Tongs',
        'Roofing Shingle Gauge',
        'Siding Removal Tool',
      ])
        tool,
    ],
    aliases: const [
      'fish tape',
      'pipe wrench',
      'pex crimp tool',
      'drain auger',
      'pressure gauge',
      'thermal camera',
    ],
  );
}

List<WorkSupplyItem> _pipeDrainToolProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Pipe Plumbing Tool',
    unit: 'each',
    variants: [
      for (final size in ['1/2 in', '3/4 in', '1 in'])
        for (final tool in [
          'PEX Expansion Tool Head',
          'PEX Crimp Ring Cutter',
          'PEX Clamp Ring Cutter',
          'Copper Tube Brush',
          'Pipe Deburring Tool',
        ])
          '$size $tool',
      for (final size in ['1/2 in', '3/4 in', '1 in', '1-1/4 in'])
        '$size Pipe Threading Die',
      for (final size in ['1/2 in', '3/4 in', '1 in'])
        '$size Pipe Threader Ratchet Head',
      for (final length in ['15 ft', '25 ft', '50 ft', '75 ft'])
        '$length Hand Drain Auger',
      for (final length in ['25 ft', '50 ft', '75 ft', '100 ft'])
        '$length Sewer Machine Cable',
      'Closet Auger',
      'Toilet Plunger',
      'Flange Plunger',
      'Basin Wrench',
      'Strap Wrench',
      'Faucet and Sink Installer Tool',
      'Garbage Disposal Wrench',
      'Pipe Reamer',
      'PVC Cable Saw',
      'PVC Ratcheting Cutter',
      'Cast Iron Snap Cutter',
      'Tub Drain Wrench',
      'Shower Valve Socket Set',
    ],
    aliases: const [
      'pex expansion head',
      'pex ring cutter',
      'pipe threading die',
      'closet auger',
      'basin wrench',
      'drain auger',
    ],
  );
}

List<WorkSupplyItem> _electricalToolProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Electrical Tool',
    unit: 'each',
    variants: [
      for (final length in ['50 ft', '100 ft', '200 ft', '240 ft'])
        '$length Steel Fish Tape',
      for (final length in ['100 ft', '200 ft', '500 ft'])
        '$length Pull String Bucket',
      for (final length in ['50 ft', '100 ft', '200 ft'])
        '$length Fiberglass Fish Rod Kit',
      for (final size in ['1/2 in', '3/4 in', '1 in']) '$size Conduit Reamer',
      for (final size in ['1/2 in', '3/4 in', '1 in']) '$size EMT Bender',
      'Circuit Breaker Finder',
      'GFCI Outlet Tester',
      'Receptacle Tester',
      'Clamp Meter',
      'Digital Multimeter',
      'Non Contact Voltage Tester',
      'Wire Stripper Cutter',
      'Cable Ripper',
      'MC Cable Cutter',
      'BX Cable Cutter',
      'Conduit Deburring Tool',
      'Wire Pulling Grip',
      'Cable Pulling Lubricant Quart',
      'Panel Schedule Label Pack',
      'Circuit Marker Book',
      'Wire Marker Dispenser',
      'Arc Flash Label Pack',
    ],
    aliases: const [
      'fish tape',
      'pull string',
      'fish rod',
      'emt bender',
      'breaker finder',
      'wire stripper',
    ],
  );
}

List<WorkSupplyItem> _finishTradeToolProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Finish Trade Tool',
    unit: 'each',
    variants: [
      for (final width in ['4 in', '6 in', '8 in', '10 in', '12 in'])
        '$width Taping Knife',
      for (final width in ['10 in', '12 in', '14 in']) '$width Drywall Mud Pan',
      for (final size in ['9 in', '12 in', '16 in'])
        '$size Concrete Finishing Trowel',
      for (final size in ['12 in', '16 in', '20 in'])
        '$size Magnesium Hand Float',
      for (final size in ['6 in', '8 in', '10 in']) '$size Margin Trowel',
      for (final size in ['1/4 x 1/4 in', '1/4 x 3/8 in', '1/2 x 1/2 in'])
        '$size Notched Tile Trowel',
      for (final size in ['18 in', '24 in', '36 in'])
        '$size Push Broom Concrete Finish Brush',
      'Drywall Hawk',
      'Texture Hopper Gun',
      'Pole Sander Head',
      'Hand Sander Block',
      'Mud Mixer Paddle',
      'Grout Float',
      'Rubber Grout Float',
      'Tile Sponge Pack',
      'Tile Nipper',
      'Manual Tile Cutter',
      'Tile Leveling Pliers',
      'Roofing Hatchet',
      'Roofing Tear Off Shovel',
      'Shingle Remover',
      'Roofing Nail Magnet',
      'Siding Gauge Tool',
    ],
    aliases: const [
      'taping knife',
      'mud pan',
      'concrete trowel',
      'margin trowel',
      'tile trowel',
      'roofing shovel',
    ],
  );
}

List<WorkSupplyItem> _installHelperProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Installation Helper',
    unit: 'each',
    variants: [
      for (final size in ['1/4 in', '3/8 in', '1/2 in'])
        for (final style in ['Drive Pin', 'Concrete Anchor Setting Tool'])
          '$size $style',
      for (final size in ['1/4 in', '5/16 in', '3/8 in'])
        '$size Nut Setter Set',
      for (final size in ['1/8 in', '3/16 in', '1/4 in', '5/16 in'])
        '$size Carbide Glass and Tile Bit',
      for (final size in ['1/4 in', '3/8 in', '1/2 in'])
        '$size Masonry Bit Long',
      for (final tool in [
        'Drywall Screw Setter Bit Pack',
        'Countersink Drill Bit Set',
        'Self Centering Hinge Bit Set',
        'Magnetic Screw Guide',
        'Flexible Bit Extension',
        'Right Angle Bit Holder',
        'Tap and Die Set',
        'Thread Repair Kit',
        'Rivet Gun',
        'Rivet Assortment Pack',
        'Staple Gun',
        'Heavy Duty Staples Pack',
        'Powder Actuated Tool',
        'Powder Load Strip Pack',
        'Concrete Nail Driver',
      ])
        tool,
    ],
    aliases: const [
      'screw setter',
      'nut setter',
      'masonry bit',
      'rivet gun',
      'staple gun',
      'powder actuated',
    ],
  );
}

List<WorkSupplyItem> _ppeProducts() {
  final sizes = ['Small', 'Medium', 'Large', 'X-Large', 'XX-Large'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Safety PPE',
    unit: 'each',
    variants: [
      for (final size in sizes) '$size Work Gloves',
      for (final size in sizes) '$size Cut Resistant Gloves',
      for (final size in sizes) '$size Nitrile Disposable Gloves 100 Count',
      for (final size in sizes) '$size Leather Palm Gloves',
      'Clear Safety Glasses',
      'Tinted Safety Glasses',
      'Anti-Fog Safety Glasses',
      'Chemical Splash Goggles',
      'Face Shield',
      'N95 Dust Mask Pack',
      'KN95 Dust Mask Pack',
      'Half Face Respirator',
      'Full Face Respirator',
      'Organic Vapor Cartridge Pack',
      'P100 Filter Cartridge Pack',
      'Hard Hat',
      'Bump Cap',
      'Ear Plug Pack',
      'Ear Muff Hearing Protection',
      'Knee Pads',
      'High Visibility Safety Vest',
      'Disposable Coverall',
    ],
    aliases: const ['safety gloves', 'nitrile gloves', 'eye pro', 'dust mask'],
  );
}

List<WorkSupplyItem> _jobsiteProtectionProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Jobsite Safety Material',
    unit: 'each',
    variants: const [
      'Caution Tape Roll',
      'Danger Tape Roll',
      'Orange Safety Cone',
      'Safety Cone 28 in',
      'Wet Floor Sign',
      'First Aid Kit',
      'Fire Extinguisher',
      'Barricade Tape',
      'Temporary Guardrail Tape',
      'Floor Protection Film',
      'Dust Barrier Zipper Door',
      'Plastic Sheeting Dust Wall',
      'ZipWall Pole Kit',
      'Dust Barrier Pole Kit',
      'Shoe Cover Pack',
      'Disposable Boot Cover Pack',
      'Temporary Floor Mat',
      'Traffic Safety Vest',
    ],
    aliases: const ['caution tape', 'safety cone', 'first aid kit'],
  );
}

List<WorkSupplyItem> _fallProtectionProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Fall Protection Safety Gear',
    unit: 'each',
    variants: [
      for (final size in ['Small Medium', 'Large X-Large', 'XX-Large'])
        '$size Full Body Safety Harness',
      for (final length in ['4 ft', '6 ft', '8 ft'])
        '$length Shock Absorbing Lanyard',
      for (final length in ['25 ft', '50 ft', '100 ft'])
        '$length Vertical Lifeline',
      for (final length in ['6 ft', '10 ft', '20 ft'])
        '$length Self Retracting Lifeline',
      'Reusable Roof Anchor',
      'Temporary Roof Anchor',
      'Standing Seam Roof Anchor',
      'D-Ring Anchor Plate',
      'Rope Grab',
      'Harness and Lanyard Kit',
      'Roof Safety Kit',
      'Warning Line Flag Pack',
      'Safety Rope Bag',
      'Carabiner Locking Pack',
      'Beam Anchor Strap',
      'Cross Arm Strap',
      'Fall Protection Storage Bag',
      'Trauma Relief Strap Pair',
    ],
    aliases: const [
      'safety harness',
      'roof anchor',
      'lifeline',
      'rope grab',
      'fall protection kit',
    ],
  );
}

List<WorkSupplyItem> _measuringLayoutProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Measuring Layout Tool',
    unit: 'each',
    variants: const [
      '16 ft Tape Measure',
      '25 ft Tape Measure',
      '35 ft Tape Measure',
      '100 ft Tape Measure',
      '9 in Torpedo Level',
      '24 in Level',
      '48 in Level',
      '72 in Level',
      'Laser Level',
      'Rotary Laser Level',
      'Laser Distance Measurer',
      '50 ft Chalk Line Reel',
      '100 ft Chalk Line Reel',
      'Framing Square',
      'Speed Square',
      'Combination Square',
      'Angle Finder',
      'Stud Finder',
      'Moisture Meter',
      'Infrared Thermometer',
      'Digital Multimeter',
      'Voltage Tester',
      'Outlet Tester',
      'Clamp Meter',
      'Inspection Camera',
      'Digital Caliper',
      'Line Laser Target Card',
      'Laser Level Tripod',
    ],
    aliases: const ['tape measure', 'spirit level', 'snap line'],
  );
}

List<WorkSupplyItem> _markingProducts() {
  final colors = ['Black', 'Red', 'Blue', 'Silver', 'White'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Layout Marking Consumable',
    unit: 'pack',
    variants: [
      for (final color in colors) '$color Jobsite Marker Pack',
      for (final color in colors) '$color Permanent Marker Pack',
      'Carpenter Pencil Pack',
      'Mechanical Carpenter Pencil',
      'Blue Chalk Refill',
      'Red Chalk Refill',
      'White Chalk Refill',
      'Marking Crayon Pack',
      'Soapstone Marker Pack',
      'Lumber Crayon Pack',
      'Flagging Tape Roll',
      'Marking Flag Pack',
      'Marking Paint White',
      'Marking Paint Orange',
      'Marking Paint Pink',
      'Marking Paint Blue',
      'Marking Paint Green',
      'Marking Paint Yellow',
      'Permanent Paint Marker Pack',
      'Dry Erase Marker Pack',
      'Grease Pencil Pack',
      'Numbered Tag Pack',
      'Caution Tag Pack',
    ],
    aliases: const ['sharpie style marker', 'carpenter pencil', 'chalk refill'],
  );
}

List<WorkSupplyItem> _tapeAdhesiveProducts() {
  final widths = ['1 in', '1-1/2 in', '1.88 in', '2 in', '3 in'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Jobsite Tape or Adhesive',
    unit: 'each',
    variants: [
      for (final width in widths) '$width x 60 yd Duct Tape',
      for (final width in widths) '$width Masking Tape',
      for (final width in widths) '$width Blue Painter Tape',
      for (final width in widths) '$width Green Painter Tape',
      'Electrical Tape Black',
      'Foil Tape Roll',
      'Double Sided Mounting Tape',
      '10 oz Construction Adhesive',
      '28 oz Construction Adhesive',
      'Super Glue Gel',
      'Threadlocker Blue',
      'Threadlocker Red',
      'Spray Adhesive',
      'Hot Glue Stick Pack',
      'Zip Tie Mount Adhesive Pack',
      'Spray Foam Cleaner',
      'Painter Tape and Plastic Dispenser',
      'Carpet Tape Roll',
      'Red Sheathing Tape Roll',
      'Clear Repair Tape Roll',
      'General Purpose Silicone 10 oz',
      'Latex Caulk 10 oz',
      'Painter Caulk 10 oz',
    ],
    aliases: const ['duct tape', 'masking tape', 'construction adhesive'],
  );
}

List<WorkSupplyItem> _cleaningProducts() {
  final bagSizes = ['33 gal', '42 gal', '55 gal'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Jobsite Consumable',
    unit: 'box',
    variants: [
      'Blue Shop Towels Roll',
      'Shop Towels Box',
      'Cotton Rag Box',
      'Microfiber Towel Pack',
      for (final size in bagSizes) '$size Contractor Trash Bags',
      for (final size in bagSizes) '$size Demo Bags',
      '5 gal Bucket',
      '5 gal Bucket Lid',
      'Contractor Broom',
      'Push Broom',
      'Dustpan',
      'Mop Head',
      'Spray Bottle',
      'Degreaser Spray Bottle',
      'All Purpose Cleaner',
      'Glass Cleaner',
      'Hand Cleaner Wipes',
      'Disinfecting Wipes',
      'Dust Mask Cleaning Wipes',
      'Contractor Sponge Pack',
      'Scrub Brush',
      'Wire Brush',
      'Trash Can 32 gal',
      'Trash Can 44 gal',
      'Wet Dry Vacuum Filter',
      'Wet Dry Vacuum Dust Bag',
    ],
    aliases: const ['rags', 'demo bags', 'trash bags', 'shop towels'],
  );
}

List<WorkSupplyItem> _dustControlProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Dust Control Vacuum Supply',
    unit: 'each',
    variants: [
      for (final size in ['1-1/4 in', '1-7/8 in', '2-1/2 in'])
        '$size Shop Vacuum Hose',
      for (final type in [
        'HEPA Vacuum Filter',
        'Fine Dust Vacuum Filter',
        'Wet Dry Vacuum Cartridge Filter',
        'Foam Sleeve Filter',
      ])
        type,
      for (final size in ['5 gal', '9 gal', '12 gal', '16 gal'])
        '$size Dust Collection Bag Pack',
      for (final accessory in [
        'Dust Deputy Separator',
        'Dust Extractor Fleece Bag Pack',
        'Dust Extractor HEPA Filter',
        'Concrete Grinder Dust Shroud',
        'Drywall Sander Vacuum Adapter',
        'Miter Saw Dust Bag',
        'Table Saw Dust Port Adapter',
        'Vacuum Crevice Tool',
        'Vacuum Floor Nozzle',
        'Vacuum Brush Attachment',
        'Anti Static Vacuum Hose',
        'Dust Collection Elbow Adapter',
        'Dust Collection Coupler',
        'Dust Collection Blast Gate',
        'Shop Vacuum Muffler Diffuser',
      ])
        accessory,
    ],
    aliases: const [
      'hepa filter',
      'vacuum filter',
      'dust bag',
      'dust shroud',
      'shop vac hose',
    ],
  );
}

List<WorkSupplyItem> _temporaryProducts() {
  final tarpSizes = ['6 x 8 ft', '8 x 10 ft', '10 x 12 ft', '12 x 16 ft'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Temporary Protection Material',
    unit: 'each',
    variants: [
      for (final size in tarpSizes) '$size Poly Tarp',
      for (final size in tarpSizes) '$size Canvas Drop Cloth',
      '9 x 12 ft Plastic Drop Cloth',
      '10 x 25 ft Plastic Sheeting',
      '20 x 100 ft Plastic Sheeting',
      'Ram Board Floor Protection Roll',
      'Surface Protection Film Roll',
      'Carpet Protection Film Roll',
      'Moving Blanket',
      'Furniture Pad',
      'Painters Plastic Roll',
      for (final size in ['3 x 100 ft', '4 x 100 ft', '6 x 100 ft'])
        '$size Floor Protection Film',
      for (final size in ['24 in x 50 ft', '36 in x 50 ft'])
        '$size Builder Paper Roll',
      'Red Rosin Paper Roll',
      'Masking Film Roll',
      'Temporary Door Cover',
    ],
    aliases: const ['poly tarp', 'drop cloth', 'floor protection'],
  );
}

List<WorkSupplyItem> _powerLightProducts() {
  final lengths = ['25 ft', '50 ft', '100 ft'];
  final gauges = ['12/3', '14/3', '16/3'];
  return _toolsSafetyGeneratedVariants(
    baseName: 'Jobsite Power and Light',
    unit: 'each',
    variants: [
      for (final gauge in gauges)
        for (final length in lengths) '$gauge $length Extension Cord',
      'Triple Tap Extension Cord',
      'GFCI Extension Cord',
      'Portable GFCI Adapter',
      'Cord Reel',
      'Temporary Work Light',
      'LED Work Light',
      'Tripod Work Light',
      'String Work Light',
      'Headlamp',
      'Flashlight',
      'AAA Battery Pack',
      'AA Battery Pack',
      '9V Battery Pack',
      'D Battery Pack',
      'C Battery Pack',
      'Rechargeable Battery Pack',
      'Portable Power Station',
      'Temporary Power Adapter',
      'Jobsite Power Strip',
      'Surge Protector Power Strip',
      'GFCI Protected Power Strip',
      'Three Outlet Adapter',
      'Light Bulb Cage Guard',
    ],
    aliases: const ['extension cord', 'work light', 'gfci adapter'],
  );
}

List<WorkSupplyItem> _ladderAccessProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Jobsite Access Equipment',
    unit: 'each',
    variants: const [
      '2 ft Step Stool',
      '4 ft Fiberglass Step Ladder',
      '6 ft Fiberglass Step Ladder',
      '8 ft Fiberglass Step Ladder',
      '10 ft Fiberglass Step Ladder',
      '16 ft Extension Ladder',
      '24 ft Extension Ladder',
      'Ladder Stabilizer',
      'Ladder Leveler',
      'Sawhorse Pair',
      'Folding Work Platform',
      'Portable Work Bench',
      'Material Support Stand',
      'Roller Stand',
      'Drywall Panel Lift',
      'Material Cart',
      'Hand Truck',
      'Appliance Dolly',
      'Furniture Dolly',
      'Scaffold Platform',
      'Pump Jack Brace',
      'Ladder Hook Pair',
    ],
    aliases: const ['step ladder', 'extension ladder', 'sawhorse'],
  );
}

List<WorkSupplyItem> _temporaryJobsiteGear() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Temporary Jobsite Gear',
    unit: 'each',
    variants: const [
      '20 in Box Fan',
      '24 in Drum Fan',
      '36 in Drum Fan',
      'Air Mover Fan',
      'Jobsite Heater',
      'Propane Heater',
      'Kerosene Heater',
      'Extension Cord Reel Stand',
      'Temporary Thermometer',
      'Portable Dehumidifier',
      'Dust Extractor Bag Pack',
      'Jobsite Radio',
      'Portable Folding Table',
      'Contractor Clipboard',
      'Permit Document Holder',
      'Water Cooler 5 gal',
      'Traffic Cone Light',
      'Temporary Warning Light',
      'Portable Jobsite Sink',
      'Jobsite Water Jug',
      'Cooling Towel Pack',
      'Portable Shade Canopy',
    ],
    aliases: const ['box fan', 'drum fan', 'jobsite heater', 'clipboard'],
  );
}

List<WorkSupplyItem> _spillFireSafetyProducts() {
  return _toolsSafetyGeneratedVariants(
    baseName: 'Spill and Fire Safety Material',
    unit: 'each',
    variants: const [
      'Oil Absorbent Pad Pack',
      'Universal Absorbent Pad Pack',
      'Spill Kit Small',
      'Spill Kit Medium',
      'Oil Dry Absorbent Bag',
      'Safety Data Sheet Binder',
      'Flammable Storage Cabinet Label',
      'Fire Extinguisher Bracket',
      'Smoke Alarm',
      'Carbon Monoxide Alarm',
      'Emergency Eyewash Bottle',
      'Burn Gel First Aid Pack',
      'Bloodborne Pathogen Kit',
      'Lockout Tagout Kit',
      'Lockout Padlock Pack',
      'Safety Harness',
      'Roof Anchor Kit',
      'Lanyard Fall Protection',
      'Confined Space Warning Sign',
      'No Smoking Sign',
      'Respirator Fit Test Kit',
      'Safety Harness Bag',
      'Reusable Ear Plug Pack',
      'Class 2 Safety Vest',
      'Class 3 Safety Vest',
      'Safety Whistle Pack',
      'Emergency Blanket',
      'Chemical Resistant Apron',
      'Chemical Resistant Gloves',
      'Fire Blanket',
      'Eye Wash Station Sign',
      'First Aid Refill Pack',
      'CPR Face Shield Pack',
      'Safety Data Sheet Station',
      'Lockout Hasps Pack',
      'Arc Flash Warning Label Pack',
    ],
    aliases: const ['spill kit', 'absorbent pad', 'lockout tagout'],
  );
}

List<WorkSupplyItem> _toolsSafetyGeneratedVariants({
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
