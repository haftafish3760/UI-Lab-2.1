part of '../../work_supply_catalog.dart';

final carpentryGeneratedDetailCatalogCategory = _category(
  'Carpentry Detail Stock',
  [
    _system('Engineered Framing and Structural Lumber', [
      _type(
        'Engineered Beams and Rim Board',
        _carpentryProducts(
          baseName: 'Engineered Lumber Detail',
          unit: 'piece',
          variants: [
            for (final depth in _carpentryEngineeredDepths)
              for (final length in _carpentryEngineeredLengths)
                for (final width in ['1-3/4 in', '3-1/2 in'])
                  '$width x $depth x $length LVL Beam',
            for (final depth in _carpentryEngineeredDepths)
              for (final length in _carpentryEngineeredLengths)
                '$depth x $length I Joist',
            for (final depth in _carpentryEngineeredDepths)
              for (final thickness in ['1 in', '1-1/8 in'])
                '$thickness x $depth x 12 ft Rim Board',
          ],
          aliases: const [
            'lvl',
            'lvl beam',
            'i joist',
            'engineered joist',
            'rim board',
          ],
        ),
      ),
      _type(
        'Framing Blocking and Fire Stop',
        _carpentryProducts(
          baseName: 'Framing Blocking Detail',
          unit: 'piece',
          variants: [
            for (final size in ['2 x 4', '2 x 6', '2 x 8'])
              for (final length in ['8 ft', '10 ft', '12 ft'])
                '$size x $length Fire Blocking',
            for (final size in ['2 x 4', '2 x 6'])
              for (final length in ['8 ft', '10 ft', '12 ft'])
                '$size x $length Ladder Blocking',
            for (final gauge in ['16 ga', '18 ga'])
              for (final width in ['1-1/4 in', '1-1/2 in'])
                '$gauge x $width Metal Strapping',
          ],
          aliases: const [
            'fire blocking',
            'blocking',
            'ladder blocking',
            'metal strapping',
          ],
        ),
      ),
    ]),
    _system('Subfloor Wall and Roof Panels', [
      _type(
        'Structural Panels',
        _carpentryProducts(
          baseName: 'Structural Panel Detail',
          unit: 'sheet',
          variants: [
            for (final thickness in ['7/16 in', '15/32 in', '19/32 in'])
              for (final rating in ['Wall Sheathing', 'Roof Sheathing'])
                '$thickness 4 x 8 OSB $rating',
            for (final thickness in ['19/32 in', '23/32 in'])
              for (final edge in ['Square Edge', 'Tongue and Groove'])
                '$thickness 4 x 8 Subfloor $edge',
            for (final thickness in ['15/32 in', '19/32 in', '23/32 in'])
              '4 x 8 CDX Plywood $thickness',
          ],
          aliases: const [
            'osb sheathing',
            'roof sheathing',
            'wall sheathing',
            'subfloor',
            't&g subfloor',
            'cdx plywood',
          ],
        ),
      ),
      _type(
        'Underlayment and Finish Panels',
        _carpentryProducts(
          baseName: 'Finish Panel Detail',
          unit: 'sheet',
          variants: [
            for (final thickness in ['1/4 in', '3/8 in', '1/2 in'])
              for (final panel in ['Lauan Underlayment', 'Birch Plywood'])
                '$thickness 4 x 8 $panel',
            for (final finish in ['White', 'Maple', 'Oak'])
              for (final thickness in ['1/2 in', '3/4 in'])
                '$thickness 4 x 8 $finish Melamine Panel',
          ],
          aliases: const [
            'underlayment',
            'lauan',
            'birch plywood',
            'melamine panel',
            'finish plywood',
          ],
        ),
      ),
    ]),
    _system('Interior Trim Boards and Moulding', [
      _type(
        'Trim Profiles',
        _carpentryProducts(
          baseName: 'Trim Profile Detail',
          unit: 'piece',
          variants: [
            for (final material in ['Pine', 'MDF', 'PVC'])
              for (final length in ['8 ft', '12 ft', '16 ft'])
                for (final profile in _carpentryTrimProfiles)
                  '$material $length $profile',
            for (final material in ['Pine', 'Oak', 'Poplar'])
              for (final size in ['1 x 2', '1 x 3', '1 x 4', '1 x 6'])
                for (final length in ['6 ft', '8 ft', '10 ft'])
                  '$material $size x $length Finish Board',
          ],
          aliases: const [
            'baseboard',
            'casing',
            'crown',
            'shoe mould',
            'quarter round',
            'stop mould',
            'finish board',
          ],
        ),
      ),
      _type(
        'Stair and Railing Parts',
        _carpentryProducts(
          baseName: 'Stair and Railing Detail',
          unit: 'piece',
          variants: [
            for (final material in ['Pine', 'Oak', 'Poplar'])
              for (final width in ['36 in', '42 in', '48 in'])
                '$material $width Stair Tread',
            for (final material in ['Pine', 'Oak'])
              for (final length in ['8 ft', '12 ft', '16 ft'])
                '$material $length Handrail',
            for (final finish in _carpentryHardwareFinishes)
              for (final item in ['Handrail Bracket', 'Baluster Shoe'])
                '$finish $item',
          ],
          aliases: const [
            'stair tread',
            'stair retread',
            'handrail',
            'rail bracket',
            'baluster shoe',
          ],
        ),
      ),
    ]),
    _system('Doors Jambs and Cabinet Hardware', [
      _type(
        'Door Slabs Jambs and Casing Sets',
        _carpentryProducts(
          baseName: 'Door Detail',
          unit: 'each',
          variants: [
            for (final width in ['24 in', '28 in', '30 in', '32 in', '36 in'])
              for (final swing in ['LH', 'RH'])
                '$width $swing Prehung Interior Door',
            for (final width in ['24 in', '28 in', '30 in', '32 in', '36 in'])
              '$width Hollow Core Door Slab',
            for (final width in ['4-9/16 in', '6-9/16 in'])
              for (final item in ['Door Jamb Kit', 'Extension Jamb Kit'])
                '$width $item',
          ],
          aliases: const [
            'prehung door',
            'interior door',
            'door slab',
            'jamb kit',
            'extension jamb',
          ],
        ),
      ),
      _type(
        'Cabinet and Shelf Hardware Detail',
        _carpentryProducts(
          baseName: 'Cabinet Hardware Detail',
          unit: 'each',
          variants: [
            for (final finish in _carpentryHardwareFinishes)
              for (final size in ['3 in', '4 in', '5 in', '6 in'])
                '$finish $size Cabinet Pull',
            for (final finish in _carpentryHardwareFinishes)
              for (final type in ['Round Cabinet Knob', 'Bar Cabinet Knob'])
                '$finish $type',
            for (final length in ['14 in', '16 in', '18 in', '20 in', '22 in'])
              for (final rating in ['75 lb', '100 lb'])
                '$length $rating Soft Close Drawer Slide',
            for (final color in ['White', 'Almond', 'Nickel'])
              for (final item in ['Shelf Pin', 'Shelf Support Clip'])
                '$color $item',
          ],
          aliases: const [
            'cabinet pull',
            'cabinet knob',
            'drawer slide',
            'soft close slide',
            'shelf pin',
            'shelf support',
          ],
        ),
      ),
    ]),
  ],
);

const _carpentryEngineeredDepths = ['9-1/2 in', '11-7/8 in', '14 in', '16 in'];

const _carpentryEngineeredLengths = ['12 ft', '16 ft', '20 ft', '24 ft'];

const _carpentryTrimProfiles = [
  'Baseboard',
  'Casing',
  'Crown Moulding',
  'Quarter Round',
  'Shoe Mould',
  'Stop Mould',
];
