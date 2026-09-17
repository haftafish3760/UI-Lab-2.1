part of '../../work_supply_catalog.dart';

final toolsSafetyGeneratedDetailCatalogCategory = _category(
  'Tools and Safety Detail Stock',
  [
    _system('Hand Tool Blade Bit and Fastening Detail', [
      _type('Hand Tool Detail', _toolsHandToolDetail()),
      _type('Blade Bit Abrasive Detail', _toolsBladeBitDetail()),
      _type('Fastening Install Helper Detail', _toolsInstallHelperDetail()),
    ]),
    _system('Trade Tool and Measuring Detail', [
      _type('Plumbing Electrical Finish Tool Detail', _toolsTradeToolDetail()),
      _type('Measuring Marking Layout Detail', _toolsLayoutDetail()),
    ]),
    _system('Safety Protection and Jobsite Detail', [
      _type('PPE Fall and Fire Safety Detail', _toolsSafetyDetail()),
      _type(
        'Dust Cleanup and Temporary Protection Detail',
        _toolsCleanupDetail(),
      ),
      _type(
        'Power Light Access and Temporary Gear Detail',
        _toolsJobsiteDetail(),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _toolsHandToolDetail() {
  return _toolsDetailProducts(
    baseName: 'Hand Tool Detail',
    unit: 'each',
    variants: [
      for (final size in ['6 in', '8 in', '10 in', '12 in', '15 in'])
        for (final tool in [
          'Adjustable Wrench',
          'Tongue and Groove Pliers',
          'Linesman Pliers',
          'Needle Nose Pliers',
          'Diagonal Cutting Pliers',
          'Locking Pliers',
        ])
          '$size $tool',
      for (final driver in [
        'Insulated Screwdriver Set',
        'Multi-Bit Screwdriver Set',
        'Precision Screwdriver Set',
        'Nut Driver Set',
        'Hex Key Set',
        'Torx Driver Set',
      ])
        driver,
      for (final tool in [
        '16 oz Claw Hammer',
        '20 oz Rip Hammer',
        '3 lb Drilling Hammer',
        'Flat Pry Bar',
        'Wonder Bar Pry Bar',
        'Tin Snips Straight Cut',
        'Tin Snips Left Cut',
        'Tin Snips Right Cut',
        'Folding Utility Knife',
        'Ratcheting Caulk Gun',
      ])
        tool,
    ],
    aliases: const [
      'crescent wrench',
      'channel lock',
      'linesman pliers',
      'screwdriver set',
      'utility knife',
    ],
  );
}

List<WorkSupplyItem> _toolsBladeBitDetail() {
  return _toolsDetailProducts(
    baseName: 'Blade Bit Abrasive Detail',
    unit: 'each',
    variants: [
      for (final size in ['6-1/2 in', '7-1/4 in', '10 in', '12 in'])
        for (final teeth in ['24T', '40T', '60T', '80T'])
          for (final blade in ['Circular Saw Blade', 'Fine Finish Saw Blade'])
            '$size $teeth $blade',
      for (final size in ['4-1/2 in', '5 in', '7 in'])
        for (final wheel in [
          'Metal Cut Off Wheel',
          'Masonry Cut Off Wheel',
          'Grinding Wheel',
          'Flap Disc',
        ])
          '$size $wheel',
      for (final set in [
        'Titanium Drill Bit Set',
        'Black Oxide Drill Bit Set',
        'Masonry Drill Bit Set',
        'SDS Plus Masonry Bit Set',
        'Spade Bit Set',
        'Step Drill Bit Set',
        'Hole Saw Kit',
        'Impact Driver Bit Set',
        'Nut Setter Set',
        'Oscillating Blade Assortment',
        'Metal Reciprocating Saw Blade Pack',
        'Wood Reciprocating Saw Blade Pack',
      ])
        set,
      for (final grit in [
        '40 grit',
        '60 grit',
        '80 grit',
        '120 grit',
        '220 grit',
      ])
        for (final item in ['Sanding Disc Pack', 'Sandpaper Sheet Pack'])
          '$grit $item',
    ],
    aliases: const [
      'saw blade',
      'drill bit set',
      'sds bit',
      'cut off wheel',
      'flap disc',
      'sandpaper',
    ],
  );
}

List<WorkSupplyItem> _toolsInstallHelperDetail() {
  return _toolsDetailProducts(
    baseName: 'Install Helper Detail',
    unit: 'each',
    variants: [
      for (final size in ['1/4 in', '5/16 in', '3/8 in', '7/16 in'])
        '$size Magnetic Nut Setter Set',
      for (final item in [
        'Drywall Screw Setter Bit Pack',
        'Hinge Bit Set',
        'Countersink Bit Set',
        'Rivet Gun',
        'Hand Staple Gun',
        'Hammer Tacker',
        'Powder Actuated Tool',
        'Concrete Nail Driver',
        'Magnetic Bit Holder',
        'Right Angle Drill Attachment',
        'Impact Socket Adapter Set',
        'Quick Change Bit Holder',
      ])
        item,
    ],
    aliases: const [
      'screw setter',
      'nut setter',
      'rivet gun',
      'staple gun',
      'powder actuated',
      'bit holder',
    ],
  );
}

List<WorkSupplyItem> _toolsTradeToolDetail() {
  return _toolsDetailProducts(
    baseName: 'Trade Tool Detail',
    unit: 'each',
    variants: [
      for (final size in ['1/2 in', '3/4 in', '1 in'])
        for (final tool in [
          'PEX Crimp Tool',
          'PEX Clamp Tool',
          'PEX Expansion Tool Head',
          'PEX Ring Cutter',
          'Pipe Threading Die',
          'EMT Bender',
        ])
          '$size $tool',
      for (final length in ['15 ft', '25 ft', '50 ft', '75 ft'])
        for (final auger in ['Hand Drain Auger', 'Closet Auger'])
          '$length $auger',
      for (final tool in [
        'Basin Wrench',
        'Tub Drain Wrench',
        'PVC Pipe Cutter',
        'Copper Tube Cutter',
        'Non Contact Voltage Tester',
        'Breaker Finder Kit',
        'Circuit Tracer Kit',
        'Wire Stripper',
        'Cable Ripper',
        'Conduit Reamer',
        'Concrete Finishing Trowel',
        'Magnesium Hand Float',
        'Grout Float',
        'Margin Trowel',
        'Roofing Tear Off Shovel',
        'Siding Removal Tool',
      ])
        tool,
    ],
    aliases: const [
      'pex crimp',
      'drain auger',
      'basin wrench',
      'emt bender',
      'voltage tester',
      'concrete trowel',
      'roofing shovel',
    ],
  );
}

List<WorkSupplyItem> _toolsLayoutDetail() {
  return _toolsDetailProducts(
    baseName: 'Layout Measuring Detail',
    unit: 'each',
    variants: [
      for (final length in ['16 ft', '25 ft', '30 ft', '35 ft', '100 ft'])
        '$length Tape Measure',
      for (final size in ['24 in', '48 in', '72 in'])
        for (final level in ['Box Level', 'I-Beam Level']) '$size $level',
      for (final color in ['Orange', 'Blue', 'Red', 'White', 'Pink'])
        for (final item in ['Marking Paint', 'Chalk Refill']) '$color $item',
      for (final item in [
        'Laser Level',
        'Cross Line Laser',
        'Chalk Line Reel',
        'Fine Point Marker Pack',
        'Carpenter Pencil Pack',
        'Soapstone Marker Pack',
        'Construction Crayon Pack',
        'Digital Angle Finder',
        'Stud Finder Deep Scan',
      ])
        item,
    ],
    aliases: const [
      'tape measure',
      'box level',
      'laser level',
      'chalk line',
      'marking paint',
      'carpenter pencil',
    ],
  );
}

List<WorkSupplyItem> _toolsSafetyDetail() {
  return _toolsDetailProducts(
    baseName: 'Safety PPE Detail',
    unit: 'each',
    variants: [
      for (final size in ['M', 'L', 'XL', '2XL'])
        for (final item in [
          'Nitrile Glove Box',
          'Leather Work Glove Pair',
          'Cut Resistant Glove Pair',
          'Knee Pad Pair',
          'High Visibility Safety Vest',
        ])
          '$size $item',
      for (final item in [
        'Clear Safety Glasses',
        'Tinted Safety Glasses',
        'Face Shield',
        'N95 Dust Mask 20 Pack',
        'Half Face Respirator',
        'P100 Respirator Cartridge Pack',
        'Hard Hat',
        'Ear Plug 100 Pack',
        'Roof Safety Kit',
        'Safety Harness and Lanyard',
        'Roof Anchor',
        'Vertical Lifeline',
        'Rope Grab',
        'Fire Extinguisher',
        'First Aid Kit',
        'Lockout Tagout Kit',
      ])
        item,
    ],
    aliases: const [
      'nitrile gloves',
      'safety glasses',
      'n95 mask',
      'respirator',
      'hard hat',
      'safety harness',
      'roof anchor',
    ],
  );
}

List<WorkSupplyItem> _toolsCleanupDetail() {
  return _toolsDetailProducts(
    baseName: 'Cleanup Temporary Protection Detail',
    unit: 'each',
    variants: [
      for (final size in [
        '8 x 10 ft',
        '10 x 12 ft',
        '12 x 16 ft',
        '20 x 30 ft',
      ])
        for (final item in ['Poly Tarp', 'Canvas Drop Cloth']) '$size $item',
      for (final size in ['31 gal', '42 gal', '55 gal'])
        '$size Contractor Trash Bags',
      for (final item in [
        'Shop Towels Roll',
        'Blue Shop Towels Box',
        'Microfiber Rag Pack',
        'Dust Barrier Kit',
        'Zip Door Dust Barrier',
        'Temporary Floor Protection Roll',
        'Carpet Protection Film',
        'Ram Board Floor Protection',
        'HEPA Vacuum Filter',
        'Shop Vacuum HEPA Filter',
        'Vacuum Dust Bag Pack',
        'Dust Shroud',
        'Small Spill Kit',
        'Oil Dry Absorbent Bag',
      ])
        item,
    ],
    aliases: const [
      'contractor trash bags',
      'drop cloth',
      'poly tarp',
      'dust barrier',
      'hepa filter',
      'spill kit',
    ],
  );
}

List<WorkSupplyItem> _toolsJobsiteDetail() {
  return _toolsDetailProducts(
    baseName: 'Jobsite Power Access Detail',
    unit: 'each',
    variants: [
      for (final gauge in ['12/3', '14/3'])
        for (final length in ['25 ft', '50 ft', '100 ft'])
          '$gauge $length Extension Cord',
      for (final item in [
        'Triple Tap Extension Cord',
        'GFCI Cord Adapter',
        'Cord Reel',
        'LED Work Light',
        'Tripod Work Light',
        'Rechargeable Headlamp',
        '6 ft Fiberglass Step Ladder',
        '8 ft Fiberglass Step Ladder',
        '16 ft Extension Ladder',
        '24 ft Extension Ladder',
        'Folding Work Platform',
        'Folding Sawhorse Pair',
        '20 in Box Fan',
        'Air Mover Fan',
        'Propane Jobsite Heater',
        'Electric Jobsite Heater',
      ])
        item,
    ],
    aliases: const [
      'extension cord',
      'gfci cord',
      'work light',
      'step ladder',
      'extension ladder',
      'box fan',
      'jobsite heater',
    ],
  );
}

List<WorkSupplyItem> _toolsDetailProducts({
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
