part of '../../work_supply_catalog.dart';

final carpentryGeneratedServiceCatalogCategory = _category(
  'Expanded Carpentry Service Stock',
  [
    _system('Expanded Lumber', [
      _type(
        'Dimensional Framing Lumber',
        _carpentryProducts(
          baseName: 'Dimensional Lumber',
          unit: 'piece',
          variants: [
            for (final size in _carpentryDimensionalSizes)
              for (final length in _carpentryBoardLengths) '$size x $length',
          ],
          aliases: const ['stud', 'framing lumber', 'kd lumber'],
        ),
      ),
      _type(
        'Pressure Treated Lumber',
        _carpentryProducts(
          baseName: 'Pressure Treated Lumber',
          unit: 'piece',
          variants: [
            for (final size in _carpentryTreatedSizes)
              for (final length in _carpentryOutdoorLengths) '$size x $length',
          ],
          aliases: const ['pt lumber', 'treated board', 'outdoor lumber'],
        ),
      ),
      _type(
        'Posts and Timbers',
        _carpentryProducts(
          baseName: 'Post or Timber',
          unit: 'piece',
          variants: [
            for (final size in ['4 x 4', '4 x 6', '6 x 6'])
              for (final length in ['8 ft', '10 ft', '12 ft', '16 ft'])
                '$size x $length Pressure Treated',
          ],
          aliases: const ['treated post', 'deck post', 'landscape timber'],
        ),
      ),
    ]),
    _system('Expanded Sheet Goods', [
      _type(
        'Plywood and OSB Panels',
        _carpentryProducts(
          baseName: 'Panel Sheet',
          unit: 'sheet',
          variants: [
            for (final material in ['CDX Plywood', 'Sanded Plywood', 'OSB'])
              for (final thickness in _carpentryPanelThicknesses)
                '$thickness 4 x 8 $material',
          ],
          aliases: const ['plywood', 'osb', 'sheathing'],
        ),
      ),
      _type(
        'Specialty Panels',
        _carpentryProducts(
          baseName: 'Specialty Panel',
          unit: 'sheet',
          variants: const [
            '1/4 in 4 x 8 Hardboard',
            '1/8 in 4 x 8 Tempered Hardboard',
            '3/4 in 4 x 8 Melamine',
            '1/2 in 4 x 8 MDF',
            '3/4 in 4 x 8 MDF',
            '1/2 in 4 x 8 Beadboard Panel',
            '5/8 in 4 x 8 T1-11 Siding',
          ],
          aliases: const ['mdf', 'hardboard', 'melamine', 'panel board'],
        ),
      ),
    ]),
    _system('Expanded Fasteners', [
      _type(
        'Wood Deck and Structural Screws',
        _carpentryProducts(
          baseName: 'Wood Screw',
          unit: 'box',
          variants: [
            for (final gauge in ['#8', '#9', '#10'])
              for (final length in _carpentryScrewLengths)
                '$gauge x $length Exterior',
            for (final length in ['3 in', '3-1/2 in', '4 in', '5 in', '6 in'])
              '1/4 x $length Structural',
            for (final length in ['4 in', '5 in', '6 in', '8 in'])
              '5/16 x $length Ledger',
          ],
          aliases: const ['deck screw', 'structural screw', 'ledger screw'],
        ),
      ),
      _type(
        'Nails and Brads',
        _carpentryProducts(
          baseName: 'Nail Fastener',
          unit: 'box',
          variants: [
            for (final size in ['6d', '8d', '10d', '12d', '16d'])
              for (final finish in ['bright common', 'galvanized common'])
                '$size $finish',
            for (final length in ['1 in', '1-1/4 in', '1-1/2 in', '2 in'])
              '18 ga x $length Brad Nails',
            for (final length in ['1-1/4 in', '1-1/2 in', '2 in', '2-1/2 in'])
              '15 ga x $length Finish Nails',
          ],
          aliases: const ['common nail', 'finish nail', 'brad nail'],
        ),
      ),
    ]),
    _system('Expanded Framing Connectors', [
      _type(
        'Joist Hangers and Ties',
        _carpentryProducts(
          baseName: 'Framing Connector',
          unit: 'each',
          variants: [
            for (final size in ['2 x 4', '2 x 6', '2 x 8', '2 x 10', '2 x 12'])
              for (final style in [
                'Face Mount Joist Hanger',
                'Concealed Flange Joist Hanger',
              ])
                '$size $style',
            for (final tie in [
              'H1 Hurricane Tie',
              'H2.5A Hurricane Tie',
              'A35 Angle',
              'L70 Angle',
            ])
              tie,
          ],
          aliases: const ['joist hanger', 'rafter tie', 'hurricane tie'],
        ),
      ),
      _type(
        'Post Bases Caps and Anchors',
        _carpentryProducts(
          baseName: 'Post Connector',
          unit: 'each',
          variants: [
            for (final size in ['4 x 4', '6 x 6'])
              for (final style in [
                'Post Base',
                'Standoff Post Base',
                'Post Cap',
                'Post Anchor',
              ])
                '$size $style',
          ],
          aliases: const ['post base', 'post cap', 'column base'],
        ),
      ),
    ]),
    _system('Expanded Trim and Finish', [
      _type(
        'Interior Trim Boards',
        _carpentryProducts(
          baseName: 'Interior Trim',
          unit: 'piece',
          variants: [
            for (final profile in [
              'Baseboard',
              'Casing',
              'Crown',
              'Quarter Round',
              'Shoe Moulding',
            ])
              for (final size in _carpentryTrimSizes) '$size $profile',
          ],
          aliases: const ['base trim', 'casing trim', 'moulding'],
        ),
      ),
      _type(
        'Door Hardware and Shims',
        _carpentryProducts(
          baseName: 'Finish Carpentry Hardware',
          unit: 'pack',
          variants: const [
            '3 in Satin Nickel Door Hinge',
            '3-1/2 in Satin Nickel Door Hinge',
            '4 in Satin Nickel Door Hinge',
            'Wood Shim Bundle',
            'Composite Shim Bundle',
            'Door Stop Moulding',
            'Strike Plate Pack',
            'Bi-Fold Door Hardware Kit',
          ],
          aliases: const ['door hinge', 'shim', 'door hardware'],
        ),
      ),
      _type(
        'Trim Repair and Installation Supplies',
        _carpentryProducts(
          baseName: 'Trim Installation Supply',
          unit: 'each',
          variants: [
            for (final size in ['1/16 in', '1/8 in', '3/16 in', '1/4 in'])
              '$size Plastic Spacer Pack',
            for (final size in ['1/8 in', '1/4 in', '3/8 in'])
              '$size Wood Dowel Pin Pack',
            for (final size in ['3/8 in', '1/2 in', '5/8 in'])
              '$size Wood Plug Pack',
            for (final size in ['2 in', '3 in', '4 in']) '$size Rosette Block',
            for (final size in ['4 in', '5 in', '6 in']) '$size Plinth Block',
            'Trim Puller Tool',
            'Miter Clamp Set',
            'Coping Saw Blade Pack',
            'Counter Sink Bit Set',
          ],
          aliases: const [
            'trim spacer',
            'wood dowel',
            'wood plug',
            'rosette block',
            'plinth block',
          ],
        ),
      ),
      _type(
        'Cabinet Hardware',
        _carpentryProducts(
          baseName: 'Cabinet Hardware',
          unit: 'each',
          variants: [
            for (final finish in _carpentryHardwareFinishes)
              for (final size in ['3 in', '3-3/4 in', '5 in'])
                '$size $finish Cabinet Pull',
            for (final finish in _carpentryHardwareFinishes)
              '$finish Cabinet Knob',
            for (final side in ['Left', 'Right'])
              '$side Soft Close Cabinet Hinge',
            for (final length in ['12 in', '14 in', '16 in', '18 in', '20 in'])
              '$length Soft Close Drawer Slide Pair',
          ],
          aliases: const [
            'cabinet pull',
            'cabinet knob',
            'cabinet hinge',
            'drawer slide',
          ],
        ),
      ),
      _type(
        'Closet and Shelving Hardware',
        _carpentryProducts(
          baseName: 'Shelving Hardware',
          unit: 'each',
          variants: [
            for (final depth in ['8 in', '10 in', '12 in', '16 in'])
              '$depth White Shelf Bracket',
            for (final length in ['24 in', '36 in', '48 in', '72 in'])
              '$length Closet Rod',
            for (final length in ['24 in', '36 in', '48 in'])
              '$length Melamine Shelf',
            'Closet Rod Socket Pair',
            'Heavy Duty Shelf Standard',
            'Shelf Support Peg Pack',
          ],
          aliases: const [
            'shelf bracket',
            'closet rod',
            'closet hardware',
            'shelf peg',
          ],
        ),
      ),
      _type(
        'Finish Boards and Project Panels',
        _carpentryProducts(
          baseName: 'Finish Board or Project Panel',
          unit: 'piece',
          variants: [
            for (final species in ['Pine', 'Poplar', 'Oak', 'PVC'])
              for (final size in ['1 x 2', '1 x 3', '1 x 4', '1 x 6'])
                for (final length in ['4 ft', '6 ft', '8 ft'])
                  '$size x $length $species Board',
            for (final species in ['Pine', 'Poplar', 'Oak'])
              for (final size in ['2 ft x 2 ft', '2 ft x 4 ft'])
                '$size $species Project Panel',
          ],
          aliases: const [
            'project board',
            'finish board',
            'craft board',
            'project panel',
          ],
        ),
      ),
      _type(
        'Stair Parts and Handrail',
        _carpentryProducts(
          baseName: 'Stair or Handrail Part',
          unit: 'each',
          variants: [
            for (final width in ['36 in', '42 in', '48 in'])
              '$width Oak Stair Tread',
            for (final width in ['36 in', '42 in', '48 in'])
              '$width Pine Stair Tread',
            for (final width in ['36 in', '42 in', '48 in'])
              '$width Stair Riser',
            for (final length in ['6 ft', '8 ft', '12 ft', '16 ft'])
              '$length Wood Handrail',
            for (final finish in _carpentryHardwareFinishes)
              '$finish Handrail Bracket',
            'Box Newel Post',
            'Plain Square Baluster',
            'Primed Stair Skirt Board',
            'Stair Nosing Moulding',
          ],
          aliases: const [
            'stair tread',
            'stair riser',
            'handrail',
            'handrail bracket',
            'baluster',
            'newel post',
          ],
        ),
      ),
      _type(
        'Door Locks and Entry Hardware',
        _carpentryProducts(
          baseName: 'Door Lock or Entry Hardware',
          unit: 'each',
          variants: [
            for (final finish in _carpentryHardwareFinishes)
              for (final style in [
                'Passage Door Knob',
                'Privacy Door Knob',
                'Entry Door Knob',
                'Single Cylinder Deadbolt',
                'Lever Handle Lockset',
              ])
                '$finish $style',
            'Sliding Door Pull Set',
            'Pocket Door Pull',
            'Door Latch Replacement Kit',
            'Adjustable Door Sweep',
            'Exterior Door Threshold',
          ],
          aliases: const [
            'door knob',
            'lockset',
            'deadbolt',
            'door latch',
            'door sweep',
            'threshold',
          ],
        ),
      ),
      _type(
        'Door Window Install Supplies',
        _carpentryProducts(
          baseName: 'Door or Window Install Supply',
          unit: 'each',
          variants: [
            for (final size in ['1/4 in', '3/8 in', '1/2 in'])
              '$size Composite Shim Pack',
            for (final width in ['4 in', '6 in', '9 in'])
              '$width Flashing Tape Roll',
            'Low Expansion Window and Door Foam',
            'Exterior Door Sill Pan',
            'Interior Door Installation Kit',
            'Prehung Door Installation Bracket Kit',
            'Kerf Door Weatherstrip Set',
            'Door Bottom Weatherstrip',
            'Adjustable Aluminum Threshold',
            'Window Sash Lock Pair',
            'Sliding Door Roller Kit',
            'Pocket Door Track Kit',
          ],
          aliases: const [
            'window door foam',
            'sill pan',
            'flashing tape',
            'weatherstrip',
            'door install kit',
          ],
        ),
      ),
    ]),
    _system('Expanded Framing Hardware and Anchors', [
      _type(
        'Structural Screws and Timber Fasteners',
        _carpentryProducts(
          baseName: 'Structural Fastener',
          unit: 'box',
          variants: [
            for (final length in [
              '1-1/2 in',
              '2-1/2 in',
              '3 in',
              '3-1/2 in',
              '4 in',
              '5 in',
              '6 in',
            ])
              '$length Connector Screw',
            for (final length in ['4 in', '6 in', '8 in', '10 in'])
              '1/4 x $length Timber Screw',
            for (final length in ['6 in', '8 in', '10 in'])
              '3/8 x $length Heavy Timber Screw',
          ],
          aliases: const [
            'connector screw',
            'timber screw',
            'structural fastener',
          ],
        ),
      ),
      _type(
        'Straps Plates and Braces',
        _carpentryProducts(
          baseName: 'Framing Brace',
          unit: 'each',
          variants: [
            for (final length in ['6 in', '8 in', '12 in', '18 in', '24 in'])
              '$length Strap Tie',
            for (final size in ['3 x 3', '4 x 4', '6 x 6', '8 x 8'])
              '$size Nail Plate',
            for (final size in ['2 x 4', '2 x 6', '2 x 8']) '$size Stud Shoe',
            'Mending Plate Pack',
            'T-Plate Connector',
            'Knee Brace Connector',
            'Ledger Board Spacer',
          ],
          aliases: const [
            'strap tie',
            'nail plate',
            'stud shoe',
            'mending plate',
          ],
        ),
      ),
      _type(
        'Blocking Bridging and Rough Framing Supplies',
        _carpentryProducts(
          baseName: 'Rough Framing Supply',
          unit: 'each',
          variants: [
            for (final size in ['2 x 6', '2 x 8', '2 x 10', '2 x 12'])
              '$size Solid Blocking Clip',
            for (final span in ['16 in', '18 in', '20 in', '24 in'])
              '$span Metal Bridging',
            for (final size in ['3 in', '4 in', '5 in']) '$size Bearing Plate',
            'Framing Layout Marker',
            'Stud Guard Plate Pack',
            'Sill Sealer Roll',
            'Framing Square',
          ],
          aliases: const [
            'blocking clip',
            'bridging',
            'bearing plate',
            'stud guard',
            'sill sealer',
          ],
        ),
      ),
      _type(
        'Concrete and Masonry Wood Anchors',
        _carpentryProducts(
          baseName: 'Wood Framing Anchor',
          unit: 'box',
          variants: [
            for (final diameter in ['1/4 in', '3/8 in', '1/2 in'])
              for (final length in ['2-1/4 in', '3 in', '3-3/4 in'])
                '$diameter x $length Wedge Anchor',
            for (final diameter in ['1/4 in', '3/8 in'])
              for (final length in ['1-3/4 in', '2-1/4 in', '3-1/4 in'])
                '$diameter x $length Concrete Screw',
            'Powder Actuated Fastener Pack',
          ],
          aliases: const [
            'wedge anchor',
            'concrete screw',
            'powder actuated fastener',
          ],
        ),
      ),
    ]),
    _system('Expanded Doors Windows and Openings', [
      _type(
        'Door Slabs Jambs and Frames',
        _carpentryProducts(
          baseName: 'Door Opening Material',
          unit: 'each',
          variants: [
            for (final width in ['24 in', '28 in', '30 in', '32 in', '36 in'])
              '$width Hollow Core Door Slab',
            for (final width in ['30 in', '32 in', '36 in'])
              '$width Solid Core Door Slab',
            for (final width in ['30 in', '32 in', '36 in'])
              '$width Exterior Prehung Door',
            'Interior Door Jamb Kit',
            'Exterior Door Jamb Kit',
            'Pocket Door Frame Kit',
            'Door Casing Kit',
          ],
          aliases: const [
            'door slab',
            'prehung door',
            'door jamb',
            'pocket door kit',
          ],
        ),
      ),
      _type(
        'Window and Sill Trim',
        _carpentryProducts(
          baseName: 'Window Trim Material',
          unit: 'piece',
          variants: [
            for (final length in ['6 ft', '8 ft', '12 ft'])
              '$length Primed Window Stool',
            for (final length in ['6 ft', '8 ft', '12 ft'])
              '$length Apron Moulding',
            for (final width in ['3-1/2 in', '5-1/2 in', '7-1/4 in'])
              '$width PVC Exterior Trim Board',
            'Brick Moulding Set',
            'Drip Cap Moulding',
          ],
          aliases: const [
            'window stool',
            'apron moulding',
            'pvc trim',
            'brick mould',
          ],
        ),
      ),
    ]),
    _system('Expanded Decking and Exterior', [
      _type(
        'Deck Boards and Fascia',
        _carpentryProducts(
          baseName: 'Decking Material',
          unit: 'piece',
          variants: [
            for (final material in [
              'Pressure Treated',
              'Cedar',
              'Composite',
              'PVC',
            ])
              for (final size in ['5/4 x 6', '2 x 6'])
                for (final length in [
                  '8 ft',
                  '10 ft',
                  '12 ft',
                  '16 ft',
                  '20 ft',
                ])
                  '$size x $length $material Deck Board',
            for (final material in ['Composite', 'PVC'])
              for (final length in ['12 ft', '16 ft'])
                '1 x 12 x $length $material Fascia',
          ],
          aliases: const ['deck board', 'decking board', 'fascia board'],
        ),
      ),
      _type(
        'Deck Hardware and Railing',
        _carpentryProducts(
          baseName: 'Deck Hardware',
          unit: 'each',
          variants: [
            for (final count in ['90 count', '175 count', '350 count'])
              '$count Hidden Deck Fasteners',
            for (final height in ['26 in', '29 in', '32 in'])
              '$height Aluminum Baluster Pack',
            for (final step in [
              '2 step',
              '3 step',
              '4 step',
              '5 step',
              '6 step',
            ])
              '$step Pressure Treated Stair Stringer',
            'Deck Ledger Flashing Roll',
            'Post Sleeve Kit',
            'Rail Bracket Kit',
          ],
          aliases: const ['deck clips', 'baluster', 'stair stringer'],
        ),
      ),
      _type(
        'Deck Railing Posts and Accessories',
        _carpentryProducts(
          baseName: 'Deck Railing Component',
          unit: 'each',
          variants: [
            for (final material in ['Pressure Treated', 'Composite', 'PVC'])
              for (final length in ['6 ft', '8 ft'])
                '$length $material Rail Kit',
            for (final material in ['Composite', 'PVC']) '$material Post Cap',
            for (final material in ['Composite', 'PVC']) '$material Post Skirt',
            'Cable Railing Tensioner',
            'Cable Railing End Fitting',
            'Deck Gate Hardware Kit',
          ],
          aliases: const [
            'rail kit',
            'post cap',
            'post skirt',
            'cable railing',
          ],
        ),
      ),
      _type(
        'Deck Flashing Framing and Repair Supplies',
        _carpentryProducts(
          baseName: 'Deck Framing Supply',
          unit: 'each',
          variants: const [
            'Deck Joist Tape Roll',
            'Deck Ledger Flashing Tape',
            'Copper Deck Ledger Flashing',
            'Zinc Deck Ledger Flashing',
            'Composite Deck Plug Kit',
            'Hidden Fastener Starter Clip Pack',
            'Deck Board Spacer Tool',
            'Deck Post Level',
            'Stair Stringer Connector',
            'Deck Drainage Tape Roll',
          ],
          aliases: const [
            'joist tape',
            'ledger flashing',
            'deck plug',
            'starter clip',
            'deck spacer',
          ],
        ),
      ),
    ]),
    _system('Expanded Adhesives Sealants and Repair', [
      _type(
        'Adhesives Fillers and Glue',
        _carpentryProducts(
          baseName: 'Carpentry Adhesive or Repair',
          unit: 'each',
          variants: const [
            '10 oz Subfloor Adhesive',
            '28 oz Subfloor Adhesive',
            '10 oz Panel Adhesive',
            '28 oz Panel Adhesive',
            '8 oz Wood Glue',
            '16 oz Wood Glue',
            '1 gal Wood Glue',
            '6 oz Wood Filler',
            '16 oz Wood Filler',
            '32 oz Wood Filler',
            'Two-Part Wood Epoxy',
            'Paintable Exterior Caulk',
          ],
          aliases: const ['construction adhesive', 'wood glue', 'wood filler'],
        ),
      ),
      _type(
        'Joinery and Cabinet Installation Supplies',
        _carpentryProducts(
          baseName: 'Joinery or Cabinet Install Supply',
          unit: 'pack',
          variants: [
            for (final size in ['#0', '#10', '#20']) '$size Wood Biscuit Pack',
            for (final size in ['1/4 in', '5/16 in', '3/8 in'])
              '$size Fluted Dowel Pack',
            for (final length in ['1 in', '1-1/4 in', '1-1/2 in'])
              '$length Pocket Hole Screws',
            'Pocket Hole Plug Pack',
            'Cabinet Installation Screw Pack',
            'Cabinet Leveler Pack',
            'Cabinet Shim Pack',
            'Toe Kick Clip Pack',
            'Scribe Moulding',
            'Cabinet Filler Strip',
          ],
          aliases: const [
            'wood biscuit',
            'fluted dowel',
            'pocket hole screw',
            'cabinet install screw',
            'cabinet shim',
          ],
        ),
      ),
    ]),
    _system('Expanded Cabinet Closet and Built-In Detail', [
      _type(
        'Cabinet Fillers Panels and Toe Kick',
        _carpentryProducts(
          baseName: 'Cabinet Finish Part',
          unit: 'piece',
          variants: [
            for (final finish in ['White', 'Unfinished', 'Oak', 'Maple'])
              for (final part in [
                '3 in Cabinet Filler Strip',
                '6 in Cabinet Filler Strip',
                'Toe Kick Board',
                'End Panel',
                'Light Rail Moulding',
                'Cabinet Crown Moulding',
              ])
                '$finish $part',
            'Toe Kick Vent Grille',
            'Toe Kick Saw Blade',
            'Cabinet Scribe Moulding',
          ],
          aliases: const [
            'cabinet filler',
            'toe kick',
            'cabinet end panel',
            'light rail',
          ],
        ),
      ),
      _type(
        'Cabinet Organizers and Shelf Hardware',
        _carpentryProducts(
          baseName: 'Cabinet Organizer Hardware',
          unit: 'each',
          variants: [
            for (final width in ['9 in', '12 in', '15 in', '18 in', '24 in'])
              for (final organizer in [
                'Pull Out Cabinet Organizer',
                'Pull Out Trash Can Kit',
                'Base Cabinet Wire Basket',
                'Drawer Organizer Insert',
              ])
                '$width $organizer',
            'Lazy Susan Bearing',
            'Lazy Susan Corner Cabinet Tray',
            'Cabinet Shelf Pin 25 Pack',
            'Shelf Support Clip 25 Pack',
            'Adjustable Shelf Standard',
          ],
          aliases: const [
            'cabinet organizer',
            'pull out trash',
            'lazy susan',
            'shelf pin',
          ],
        ),
      ),
      _type(
        'Closet Systems and Utility Shelving',
        _carpentryProducts(
          baseName: 'Closet Shelving Part',
          unit: 'each',
          variants: [
            for (final length in ['24 in', '36 in', '48 in', '72 in'])
              for (final part in [
                'White Wire Shelf',
                'Ventilated Closet Shelf',
                'Wood Closet Shelf',
                'Closet Rod',
              ])
                '$length $part',
            'Closet Rod Support Bracket',
            'Shelf Track Standard',
            'Shelf Track Bracket',
            'Closet Tower Drawer Kit',
          ],
          aliases: const [
            'wire shelf',
            'closet shelf',
            'closet rod support',
            'shelf track',
          ],
        ),
      ),
    ]),
    _system('Expanded Door Stair Trim and Deck Detail', [
      _type(
        'Door Repair Weatherproofing and Threshold Detail',
        _carpentryProducts(
          baseName: 'Door Repair Part',
          unit: 'each',
          variants: [
            for (final finish in ['White', 'Bronze', 'Mill', 'Satin Nickel'])
              for (final part in [
                'Adjustable Door Threshold',
                'Door Bottom Sweep',
                'Kerf Weatherstrip Set',
                'Door Jamb Weatherstrip Kit',
                'Door Drip Cap',
              ])
                '$finish $part',
            'Hinge Shim Pack',
            'Door Reinforcement Plate',
            'Latch Strike Reinforcer',
            'Door Security Strike Plate',
            'Door Jamb Repair Kit',
            'Pocket Door Roller Set',
          ],
          aliases: const [
            'door threshold',
            'door bottom',
            'kerf weatherstrip',
            'jamb repair',
            'strike plate',
          ],
        ),
      ),
      _type(
        'Stair Baluster Nosing and Rail Detail',
        _carpentryProducts(
          baseName: 'Stair Detail Part',
          unit: 'each',
          variants: [
            for (final finish in ['Primed', 'Oak', 'Pine', 'Poplar'])
              for (final part in [
                'Stair Nosing',
                'Retread Cap',
                'Stair Skirt Board',
                'Landing Tread',
                'Shoe Rail',
              ])
                '$finish $part',
            for (final finish in _carpentryHardwareFinishes)
              for (final part in [
                'Baluster Shoe',
                'Newel Post Fastener',
                'Handrail Rosette',
                'Rail Bolt Kit',
              ])
                '$finish $part',
          ],
          aliases: const [
            'stair nosing',
            'retread',
            'shoe rail',
            'baluster shoe',
            'rail bolt',
          ],
        ),
      ),
      _type(
        'Deck Railing Lighting and Repair Detail',
        _carpentryProducts(
          baseName: 'Deck Detail Accessory',
          unit: 'each',
          variants: [
            for (final finish in ['Black', 'White', 'Bronze'])
              for (final part in [
                'Deck Post Cap Light',
                'Deck Stair Light',
                'Deck Rail Connector',
                'Deck Gate Latch',
                'Deck Gate Hinge Set',
              ])
                '$finish $part',
            'Composite Deck Board Repair Clip',
            'Deck Board Straightener Tool',
            'Hidden Fastener Clip 90 Pack',
            'Deck Fascia Screw 100 Pack',
            'Deck Plug Cutter',
            'Deck Railing Touch Up Kit',
          ],
          aliases: const [
            'deck post cap light',
            'deck stair light',
            'deck gate latch',
            'deck repair clip',
            'fascia screw',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _carpentryProducts({
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

const _carpentryDimensionalSizes = [
  '1 x 2',
  '1 x 3',
  '1 x 4',
  '1 x 6',
  '1 x 8',
  '1 x 10',
  '1 x 12',
  '2 x 2',
  '2 x 3',
  '2 x 4',
  '2 x 6',
  '2 x 8',
  '2 x 10',
  '2 x 12',
];

const _carpentryTreatedSizes = ['2 x 4', '2 x 6', '2 x 8', '2 x 10', '2 x 12'];
const _carpentryBoardLengths = ['8 ft', '10 ft', '12 ft', '16 ft'];
const _carpentryOutdoorLengths = ['8 ft', '10 ft', '12 ft', '16 ft', '20 ft'];
const _carpentryPanelThicknesses = [
  '1/4 in',
  '3/8 in',
  '1/2 in',
  '5/8 in',
  '3/4 in',
];
const _carpentryScrewLengths = [
  '1-1/4 in',
  '1-5/8 in',
  '2 in',
  '2-1/2 in',
  '3 in',
  '3-1/2 in',
];
const _carpentryTrimSizes = [
  '2-1/4 in',
  '3-1/4 in',
  '4-1/4 in',
  '5-1/4 in',
  '7-1/4 in',
];
const _carpentryHardwareFinishes = [
  'Matte Black',
  'Satin Nickel',
  'Oil Rubbed Bronze',
  'Brushed Brass',
];
