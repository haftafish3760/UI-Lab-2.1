part of '../../work_supply_catalog.dart';

final cabinetsCountertopsGeneratedDetailCatalogCategory = _category(
  'Cabinets Countertops Detail Stock',
  [
    _system('Kitchen Cabinets and Cabinet Components', [
      _type(
        'Base Wall and Tall Cabinets',
        _cabinetCountertopProducts(
          baseName: 'Kitchen Cabinet',
          unit: 'each',
          variants: [
            for (final finish in _cabinetFinishes)
              for (final width in [
                '9 in',
                '12 in',
                '15 in',
                '18 in',
                '21 in',
                '24 in',
                '30 in',
                '36 in',
              ])
                for (final cabinet in [
                  'Base Cabinet',
                  'Drawer Base Cabinet',
                  'Sink Base Cabinet',
                  'Wall Cabinet',
                  'Glass Door Wall Cabinet',
                ])
                  '$finish $width $cabinet',
            for (final finish in _cabinetFinishes)
              for (final width in ['18 in', '24 in', '30 in'])
                for (final cabinet in [
                  'Pantry Cabinet',
                  'Oven Cabinet',
                  'Utility Cabinet',
                ])
                  '$finish $width $cabinet',
          ],
          aliases: const [
            'base cabinet',
            'wall cabinet',
            'sink base cabinet',
            'drawer base',
            'pantry cabinet',
            'utility cabinet',
            'kitchen cabinet',
          ],
        ),
      ),
      _type(
        'Cabinet Panels Fillers and Toe Kick',
        _cabinetCountertopProducts(
          baseName: 'Cabinet Finish Part',
          unit: 'piece',
          variants: [
            for (final finish in _cabinetFinishes)
              for (final width in ['3 in', '6 in'])
                '$finish $width Cabinet Filler Strip',
            for (final finish in _cabinetFinishes)
              for (final panel in [
                'Base End Panel',
                'Wall End Panel',
                'Refrigerator End Panel',
                'Dishwasher End Panel',
                'Toe Kick',
                'Light Rail Molding',
                'Crown Molding',
                'Scribe Molding',
              ])
                '$finish $panel',
          ],
          aliases: const [
            'cabinet filler',
            'filler strip',
            'end panel',
            'toe kick',
            'light rail',
            'cabinet crown',
            'scribe molding',
          ],
        ),
      ),
    ]),
    _system('Bathroom Vanities and Medicine Cabinets', [
      _type(
        'Vanity Cabinets and Tops',
        _cabinetCountertopProducts(
          baseName: 'Bathroom Vanity',
          unit: 'each',
          variants: [
            for (final finish in _cabinetFinishes)
              for (final width in ['18 in', '24 in', '30 in', '36 in', '48 in'])
                for (final style in [
                  'Vanity Cabinet Only',
                  'Vanity with Cultured Marble Top',
                  'Vanity with Quartz Top',
                  'Vanity with Ceramic Top',
                  'Freestanding Vanity',
                ])
                  '$finish $width $style',
            for (final width in ['24 in', '30 in', '36 in', '48 in'])
              for (final material in [
                'Cultured Marble Vanity Top',
                'Quartz Vanity Top',
                'Granite Vanity Top',
                'Ceramic Vanity Top',
              ])
                '$width $material',
          ],
          aliases: const [
            'vanity',
            'vanity cabinet',
            'vanity top',
            'bathroom vanity',
            'cultured marble top',
            'quartz vanity top',
          ],
        ),
      ),
      _type(
        'Medicine Cabinets and Bath Storage',
        _cabinetCountertopProducts(
          baseName: 'Bath Storage Cabinet',
          unit: 'each',
          variants: [
            for (final finish in ['White', 'Gray', 'Espresso', 'Oak'])
              for (final size in ['16 x 20 in', '20 x 26 in', '24 x 30 in'])
                '$finish $size Medicine Cabinet',
            for (final finish in _cabinetFinishes)
              for (final storage in [
                'Over Toilet Cabinet',
                'Linen Tower Cabinet',
                'Wall Storage Cabinet',
              ])
                '$finish $storage',
          ],
          aliases: const [
            'medicine cabinet',
            'bath storage',
            'linen cabinet',
            'over toilet cabinet',
          ],
        ),
      ),
    ]),
    _system('Countertop Slabs Blanks and Surface Materials', [
      _type(
        'Laminate Butcher Block and Solid Surface Tops',
        _cabinetCountertopProducts(
          baseName: 'Countertop Surface',
          unit: 'piece',
          variants: [
            for (final finish in _countertopFinishes)
              for (final length in ['4 ft', '6 ft', '8 ft', '10 ft', '12 ft'])
                for (final edge in ['Square Edge', 'Finished Edge'])
                  '$finish $length Laminate Countertop $edge',
            for (final wood in ['Birch', 'Acacia', 'Maple', 'Hevea', 'Walnut'])
              for (final length in ['4 ft', '6 ft', '8 ft'])
                '$wood $length Butcher Block Countertop',
            for (final finish in _countertopFinishes)
              for (final length in ['4 ft', '6 ft', '8 ft'])
                '$finish $length Solid Surface Countertop',
          ],
          aliases: const [
            'countertop',
            'laminate countertop',
            'butcher block',
            'solid surface countertop',
            'worktop',
            'finished edge top',
          ],
        ),
      ),
      _type(
        'Stone Quartz and Countertop Accessories',
        _cabinetCountertopProducts(
          baseName: 'Countertop Stone Accessory',
          unit: 'piece',
          variants: [
            for (final finish in _stoneCountertopFinishes)
              for (final length in [
                '25 in',
                '31 in',
                '37 in',
                '49 in',
                '61 in',
              ])
                '$finish Quartz Countertop Sample $length',
            for (final finish in _stoneCountertopFinishes)
              for (final length in ['25 in', '31 in', '37 in', '49 in'])
                '$finish Granite Vanity Side Splash $length',
            for (final item in [
              'Countertop Build Up Strip',
              'Countertop End Cap Kit',
              'Countertop Miter Bolt Kit',
              'Countertop Joint Fastener',
              'Countertop Seam Filler',
              'Countertop Router Template',
            ])
              item,
          ],
          aliases: const [
            'quartz countertop',
            'granite top',
            'side splash',
            'end cap kit',
            'miter bolt',
            'seam filler',
          ],
        ),
      ),
    ]),
    _system('Backsplash Panels Supports and Installation Supplies', [
      _type(
        'Backsplash and Wall Panels',
        _cabinetCountertopProducts(
          baseName: 'Countertop Backsplash Panel',
          unit: 'piece',
          variants: [
            for (final finish in _countertopFinishes)
              for (final length in ['4 ft', '6 ft', '8 ft'])
                '$finish Laminate Backsplash $length',
            for (final finish in ['White', 'Carrara', 'Gray', 'Stainless'])
              for (final size in ['18 x 24 in', '24 x 48 in', '30 x 30 in'])
                '$finish Peel and Stick Backsplash Panel $size',
            for (final finish in ['Stainless', 'Black Stainless', 'White'])
              for (final size in ['24 x 30 in', '30 x 30 in', '36 x 30 in'])
                '$finish Range Backsplash Panel $size',
          ],
          aliases: const [
            'backsplash',
            'laminate backsplash',
            'peel and stick backsplash',
            'range backsplash',
            'backsplash panel',
          ],
        ),
      ),
      _type(
        'Cabinet Countertop Install Supplies',
        _cabinetCountertopProducts(
          baseName: 'Cabinet Countertop Install Supply',
          unit: 'each',
          variants: [
            for (final item in [
              'Cabinet Installation Screw 100 Pack',
              'Cabinet Shim Pack',
              'Cabinet Leveler 4 Pack',
              'Countertop Support Bracket',
              'Floating Countertop Bracket',
              'Island Countertop Support Bracket',
              'Countertop Adhesive Tube',
              'Silicone Countertop Sealant',
              'Undermount Sink Clip Kit',
              'Sink Rail Support Kit',
              'Dishwasher Bracket Kit',
              'Cabinet Drawer Repair Kit',
              'Soft Close Cabinet Hinge 10 Pack',
              'Drawer Slide Pair',
              'Lazy Susan Hardware Kit',
            ])
              item,
          ],
          aliases: const [
            'cabinet screw',
            'cabinet shim',
            'countertop support',
            'countertop adhesive',
            'sink clips',
            'dishwasher bracket',
            'soft close hinge',
            'drawer slide',
            'lazy susan',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _cabinetCountertopProducts({
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

const _cabinetFinishes = [
  'White Shaker',
  'Gray Shaker',
  'Espresso',
  'Natural Oak',
  'Hickory',
  'Unfinished',
  'Navy Shaker',
  'Maple',
];

const _countertopFinishes = [
  'Carrara Marble Look',
  'Calacatta White',
  'Black Granite Look',
  'Travertine Look',
  'Concrete Gray',
  'White Laminate',
  'Walnut Laminate',
  'Soapstone Look',
];

const _stoneCountertopFinishes = [
  'Carrara',
  'Calacatta',
  'Sparkling White',
  'Black Galaxy',
  'Luna Pearl',
  'Arctic White',
  'Gray Expo',
  'River White',
];
