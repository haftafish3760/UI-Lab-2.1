part of '../../work_supply_catalog.dart';

final plumbingDrainFinishServiceCategory = _category(
  'Drain and Finish Service Stock',
  [
    _system('Sink Drain Finish Parts', [
      _type(
        'Basket Strainers and Sink Drains',
        _plumbingDrainFinishItems(
          baseName: 'Sink Drain Finish Part',
          unit: 'each',
          variants: [
            for (final finish in [
              'stainless',
              'chrome',
              'brushed nickel',
              'matte black',
              'oil rubbed bronze',
            ])
              for (final part in [
                'kitchen basket strainer',
                'deep cup basket strainer',
                'bar sink basket strainer',
                'disposal flange and stopper',
                'sink drain stopper',
              ])
                '$finish $part',
          ],
          aliases: const [
            'basket strainer',
            'sink strainer',
            'sink drain',
            'sink repair kit',
            'disposal flange',
            'drain stopper',
          ],
        ),
      ),
      _type(
        'Dishwasher and Disposal Connections',
        _plumbingDrainFinishItems(
          baseName: 'Dishwasher Disposal Drain Part',
          unit: 'each',
          variants: [
            for (final part in [
              '7/8 in dishwasher drain hose',
              '5/8 in dishwasher drain hose',
              'dishwasher branch tailpiece',
              'air gap body',
              'air gap chrome cap',
              'air gap brushed nickel cap',
              'air gap matte black cap',
              'disposal connector kit',
              'disposal elbow gasket kit',
              'rubber disposal splash guard',
            ])
              part,
          ],
          aliases: const [
            'dishwasher hose',
            'dishwasher branch',
            'air gap',
            'garbage disposal connector',
            'disposal gasket',
            'splash guard',
          ],
        ),
      ),
    ]),
    _system('Tubular Drain Adapters and Trim', [
      _type(
        'Trap Adapters and Transition Parts',
        _plumbingDrainFinishItems(
          baseName: 'Tubular Drain Adapter',
          unit: 'each',
          variants: [
            for (final size in ['1-1/4 in', '1-1/2 in', '2 in'])
              for (final style in [
                'slip joint trap adapter',
                'marvel adapter',
                'desanco adapter',
                'compression trap adapter',
                'wall bend',
                'trap arm',
              ])
                '$size $style',
          ],
          aliases: const [
            'trap adapter',
            'trap adaptor',
            'marvel adapter',
            'desanco',
            'wall bend',
            'trap arm',
          ],
        ),
      ),
      _type(
        'Slip Joint Trim Hardware',
        _plumbingDrainFinishItems(
          baseName: 'Slip Joint Trim Part',
          unit: 'pack',
          variants: [
            for (final size in ['1-1/4 in', '1-1/2 in'])
              for (final part in [
                'chrome slip nut',
                'plastic slip nut',
                'rubber reducing washer',
                'poly washer',
                'beveled washer',
                'escutcheon plate',
              ])
                '$size $part',
          ],
          aliases: const [
            'slip nut',
            'slip washer',
            'trap washer',
            'reducing washer',
            'escutcheon',
            'cover plate',
          ],
        ),
      ),
    ]),
    _system('Cleanout and Access Parts', [
      _type(
        'Cleanout Covers and Plugs',
        _plumbingDrainFinishItems(
          baseName: 'Cleanout Access Part',
          unit: 'each',
          variants: [
            for (final size in ['1-1/2 in', '2 in', '3 in', '4 in'])
              for (final part in [
                'flush cleanout plug',
                'countersunk cleanout plug',
                'raised head cleanout plug',
                'brass cleanout plug',
                'plastic cleanout plug',
                'round cleanout cover',
                'square cleanout cover',
              ])
                '$size $part',
          ],
          aliases: const [
            'cleanout',
            'clean out',
            'cleanout plug',
            'cleanout cover',
            'access cover',
          ],
        ),
      ),
      _type(
        'Floor Drain Finish Parts',
        _plumbingDrainFinishItems(
          baseName: 'Floor Drain Finish Part',
          unit: 'each',
          variants: [
            for (final size in ['2 in', '3 in', '4 in', '5 in', '6 in'])
              for (final part in [
                'round floor drain grate',
                'square floor drain grate',
                'snap-in strainer',
                'screw-down strainer',
                'sediment bucket',
                'trap primer adapter',
              ])
                '$size $part',
          ],
          aliases: const [
            'floor drain grate',
            'floor drain strainer',
            'drain cover',
            'trap primer',
            'sediment bucket',
          ],
        ),
      ),
    ]),
    _system('Toilet Finish and Flange Repair', [
      _type(
        'Closet Flange Repair Hardware',
        _plumbingDrainFinishItems(
          baseName: 'Closet Flange Repair Part',
          unit: 'each',
          variants: [
            for (final part in [
              'stainless repair ring',
              'split repair ring',
              'half moon repair ring',
              'offset repair plate',
              'flange spacer 1/4 in',
              'flange spacer 1/2 in',
              'inside fit repair flange',
              'outside fit repair flange',
              'closet flange extension kit',
              'closet bolt repair kit',
            ])
              part,
          ],
          aliases: const [
            'toilet flange repair',
            'closet flange repair',
            'flange repair ring',
            'flange spacer',
            'closet bolt kit',
          ],
        ),
      ),
      _type(
        'Toilet Finish Trim',
        _plumbingDrainFinishItems(
          baseName: 'Toilet Finish Trim Part',
          unit: 'pack',
          variants: [
            for (final finish in ['white', 'chrome', 'brushed nickel'])
              for (final part in [
                'closet bolt caps',
                'hinge bolt caps',
                'supply line escutcheon',
                'tank lever trim nut',
              ])
                '$finish $part',
          ],
          aliases: const [
            'toilet bolt caps',
            'closet bolt caps',
            'toilet trim',
            'supply escutcheon',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _plumbingDrainFinishItems({
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
          ..._plumbingDrainFinishShorthand(variant),
        ],
      ),
  ];
}

List<String> _plumbingDrainFinishShorthand(String variant) {
  final normalized = variant.toLowerCase();
  final terms = <String>[];
  if (normalized.contains('dishwasher')) terms.add('dw hose');
  if (normalized.contains('disposal')) terms.add('garbage disposal');
  if (normalized.contains('1-1/4 in')) terms.add('1-1/4');
  if (normalized.contains('1-1/2 in')) terms.add('1-1/2');
  if (normalized.contains('cleanout')) terms.add('clean out');
  if (normalized.contains('escutcheon')) terms.add('cover plate');
  if (normalized.contains('closet')) terms.add('toilet');
  if (normalized.contains('floor drain')) terms.add('drain grate');
  return terms;
}
