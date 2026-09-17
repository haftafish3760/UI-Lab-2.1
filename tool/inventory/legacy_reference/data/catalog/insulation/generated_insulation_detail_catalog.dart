part of '../../work_supply_catalog.dart';

final insulationGeneratedDetailCatalogCategory = _category(
  'Insulation Detail Stock',
  [
    _system('Batt Foam Board and Loose Fill Detail', [
      _type(
        'Batt and Roll Detail',
        _insulationProducts(
          baseName: 'Insulation Batt Detail',
          unit: 'bag',
          variants: [
            for (final rValue in [
              'R-11',
              'R-13',
              'R-15',
              'R-19',
              'R-21',
              'R-30',
              'R-38',
            ])
              for (final width in ['15 in', '16 in', '23 in', '24 in'])
                for (final facing in [
                  'Kraft Faced Fiberglass Batt',
                  'Unfaced Fiberglass Batt',
                  'Foil Faced Fiberglass Batt',
                  'Sound Control Mineral Wool Batt',
                  'Fire and Sound Mineral Wool Batt',
                ])
                  '$rValue $width $facing',
          ],
          aliases: const [
            'batt insulation',
            'fiberglass batt',
            'mineral wool batt',
            'rock wool batt',
            'sound control batt',
          ],
        ),
      ),
      _type(
        'Foam Board and Loose Fill Detail',
        _insulationProducts(
          baseName: 'Rigid and Loose Insulation Detail',
          unit: 'each',
          variants: [
            for (final thickness in [
              '1/2 in',
              '1 in',
              '1-1/2 in',
              '2 in',
              '3 in',
            ])
              for (final board in [
                'XPS Foam Board',
                'Foil Faced Polyiso Board',
                'EPS Foam Board',
              ])
                '$thickness 4 x 8 ft $board',
            for (final weight in ['19 lb', '25 lb', '30 lb'])
              for (final material in [
                'Cellulose Loose Fill',
                'Fiberglass Loose Fill',
              ])
                '$weight $material',
          ],
          aliases: const [
            'xps foam board',
            'polyiso board',
            'eps foam board',
            'loose fill insulation',
            'blown cellulose',
          ],
        ),
      ),
    ]),
    _system('Air Sealing Vapor Barrier and Crawlspace Detail', [
      _type(
        'Foam Sealant Housewrap and Vapor Detail',
        _insulationProducts(
          baseName: 'Air Sealing Detail',
          unit: 'each',
          variants: [
            for (final size in ['12 oz', '16 oz', '20 oz', '24 oz'])
              for (final foam in [
                'Window and Door Spray Foam',
                'Fire Block Spray Foam',
                'Pest Block Spray Foam',
                'Big Gap Spray Foam',
              ])
                '$size $foam',
            for (final mil in ['4 mil', '6 mil', '10 mil', '12 mil'])
              for (final size in ['10 x 25 ft', '10 x 100 ft', '20 x 100 ft'])
                '$mil $size Vapor Barrier',
            for (final width in ['3 in', '4 in', '6 in'])
              for (final length in ['50 ft', '165 ft'])
                '$width x $length House Wrap Tape',
          ],
          aliases: const [
            'spray foam',
            'fireblock foam',
            'vapor barrier',
            'poly sheeting',
            'house wrap tape',
          ],
        ),
      ),
      _type(
        'Crawlspace and Firestop Detail',
        _insulationProducts(
          baseName: 'Crawlspace Firestop Detail',
          unit: 'each',
          variants: [
            for (final mil in ['10 mil', '12 mil', '20 mil'])
              for (final size in ['10 x 100 ft', '12 x 100 ft', '20 x 100 ft'])
                '$mil $size Crawlspace Liner',
            for (final width in ['3 in', '4 in', '6 in'])
              '$width Crawlspace Seam Tape',
            for (final size in ['1-1/2 in', '2 in', '3 in', '4 in'])
              for (final item in ['Firestop Collar', 'Firestop Wrap Strip'])
                '$size $item',
            for (final item in [
              'Firestop Putty Pad Pack',
              'Draft Stop Sealant',
              'Smoke Sealant',
            ])
              item,
          ],
          aliases: const [
            'crawlspace liner',
            'crawl space liner',
            'crawlspace seam tape',
            'firestop collar',
            'firestop wrap',
            'putty pad',
          ],
        ),
      ),
    ]),
    _system('Weatherization Acoustic and Fastener Detail', [
      _type(
        'Weatherization Detail',
        _insulationProducts(
          baseName: 'Weatherization Detail',
          unit: 'each',
          variants: [
            for (final size in ['1/2 in', '3/4 in', '1 in'])
              '$size x 6 ft Foam Pipe Insulation',
            for (final width in ['3/8 in', '1/2 in', '3/4 in'])
              for (final type in [
                'Foam Weatherstrip Tape',
                'Rubber Weatherstrip Tape',
              ])
                '$width $type',
            for (final size in ['4 x 25 ft', '4 x 50 ft', '4 x 100 ft'])
              '$size Radiant Barrier Roll',
            for (final width in ['8 ft', '9 ft', '16 ft'])
              '$width Garage Door Insulation Kit',
          ],
          aliases: const [
            'pipe insulation',
            'weatherstrip',
            'radiant barrier',
            'garage door insulation',
          ],
        ),
      ),
      _type(
        'Sound Isolation and Fastener Detail',
        _insulationProducts(
          baseName: 'Sound Fastener Detail',
          unit: 'each',
          variants: [
            for (final size in ['2 x 4 ft', '4 x 8 ft'])
              for (final item in [
                'Acoustic Panel',
                'Sound Dampening Panel',
                'Mass Loaded Vinyl Sheet',
              ])
                '$size $item',
            for (final width in ['1-3/8 in', '1-5/8 in', '2 in'])
              '$width Sound Isolation Clip 50 Pack',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              '$length Sound Isolation Track',
            for (final item in [
              'Insulation Support Wire 100 Pack',
              'Vapor Barrier Cap Nail 250 Pack',
              'Impaling Clip 100 Pack',
              'Foam Board Washer 100 Pack',
              'Blown In Mesh Netting 8 ft x 100 ft',
              'Recessed Can Light Cover 10 Pack',
              'Soffit Vent Baffle 25 Pack',
            ])
              item,
          ],
          aliases: const [
            'sound panel',
            'mass loaded vinyl',
            'sound isolation clip',
            'sound isolation track',
            'support wire',
            'cap nail',
            'impaling clip',
            'baffle',
          ],
        ),
      ),
    ]),
  ],
);
