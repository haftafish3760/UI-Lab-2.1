part of '../../work_supply_catalog.dart';

final plumbingSealsServiceCategory = _category(
  'Seals Packing and Thread Service',
  [
    _system('Faucet and Valve Seals', [
      _type(
        'Faucet Washers and Seats',
        _plumbingSealServiceItems(
          baseName: 'Faucet Washer and Seat Part',
          unit: 'pack',
          variants: [
            for (final size in [
              '00',
              '0',
              '1/4 in',
              '3/8 in',
              '1/2 in',
              '5/8 in',
            ])
              for (final part in [
                'flat faucet washer',
                'beveled faucet washer',
                'seat washer',
                'bib washer',
              ])
                '$size $part',
            'assorted faucet washer kit',
            'assorted faucet seat kit',
            'assorted faucet washer and screw kit',
          ],
          aliases: const [
            'faucet washer',
            'bib washer',
            'seat washer',
            'faucet seat',
            'washer assortment',
          ],
        ),
      ),
      _type(
        'O-Rings and Packing',
        _plumbingSealServiceItems(
          baseName: 'Faucet O-Ring and Packing Part',
          unit: 'pack',
          variants: [
            for (final size in [
              'small',
              'medium',
              'large',
              'assorted',
              '1/4 in',
              '3/8 in',
              '1/2 in',
            ])
              for (final part in [
                'o-ring',
                'flat o-ring',
                'round o-ring',
                'stem packing',
              ])
                '$size $part',
            'graphite valve packing',
            'teflon valve packing',
            'bonnet packing',
            'packing nut washer',
          ],
          aliases: const [
            'o ring',
            'oring',
            'o-ring',
            'stem packing',
            'valve packing',
            'bonnet packing',
            'packing washer',
          ],
        ),
      ),
    ]),
    _system('Toilet and Tank Seals', [
      _type(
        'Tank and Flush Seals',
        _plumbingSealServiceItems(
          baseName: 'Toilet Tank Seal Part',
          unit: 'each',
          variants: [
            for (final part in [
              '2 in flush valve seal',
              '3 in flush valve seal',
              'dual flush seal',
              'tank to bowl sponge gasket',
              'tank to bowl rubber gasket',
              'tank bolt gasket set',
              'fill valve shank washer',
              'flush valve locknut',
              'fill valve locknut',
              'toilet supply shank washer',
            ])
              part,
          ],
          aliases: const [
            'flush valve seal',
            'tank gasket',
            'tank to bowl gasket',
            'tank bolt gasket',
            'fill valve washer',
            'toilet gasket',
          ],
        ),
      ),
      _type(
        'Closet Seal Detail',
        _plumbingSealServiceItems(
          baseName: 'Closet Seal Part',
          unit: 'each',
          variants: [
            for (final part in [
              'standard wax ring',
              'extra thick wax ring',
              'wax ring with horn',
              'wax-free toilet seal',
              'rubber closet seal',
              'foam closet seal',
              'toilet seal extension kit',
            ])
              part,
          ],
          aliases: const [
            'wax ring',
            'closet seal',
            'toilet seal',
            'wax free seal',
            'rubber toilet seal',
          ],
        ),
      ),
    ]),
    _system('Hose Bibb and Vacuum Breaker Repair', [
      _type(
        'Hose Bibb Repair Seals',
        _plumbingSealServiceItems(
          baseName: 'Hose Bibb Repair Part',
          unit: 'pack',
          variants: [
            for (final part in [
              'hose bibb washer',
              'hose washer',
              'sillcock stem packing',
              'sillcock handle screw',
              'sillcock packing nut',
              'frost free stem washer',
              'frost free vacuum breaker kit',
              'anti-siphon vacuum breaker kit',
              'vacuum breaker cap',
              'vacuum breaker washer',
            ])
              part,
          ],
          aliases: const [
            'hose washer',
            'hose bib washer',
            'sillcock repair',
            'vacuum breaker',
            'anti siphon',
            'anti-siphon',
          ],
        ),
      ),
    ]),
    _system('Thread Sealing Detail', [
      _type(
        'Thread Sealant Detail',
        _plumbingSealServiceItems(
          baseName: 'Thread Sealant Supply',
          unit: 'each',
          variants: [
            for (final size in ['1.5 oz', '4 oz', '8 oz', '16 oz', '32 oz'])
              for (final type in [
                'white pipe joint compound',
                'gray pipe joint compound',
                'blue thread sealant',
                'gas line thread sealant',
                'ptfe paste',
              ])
                '$size $type',
            for (final tape in [
              'white ptfe tape',
              'yellow gas ptfe tape',
              'pink water line ptfe tape',
              'blue monster style tape',
              'stainless steel thread tape',
            ])
              tape,
          ],
          aliases: const [
            'pipe dope',
            'thread paste',
            'thread sealant',
            'ptfe tape',
            'teflon tape',
            'gas tape',
          ],
        ),
      ),
    ]),
  ],
);

List<WorkSupplyItem> _plumbingSealServiceItems({
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
          ..._plumbingSealServiceShorthand(variant),
        ],
      ),
  ];
}

List<String> _plumbingSealServiceShorthand(String variant) {
  final normalized = variant.toLowerCase();
  final terms = <String>[];
  if (normalized.contains('o-ring')) terms.add('o ring');
  if (normalized.contains('ptfe')) terms.add('teflon');
  if (normalized.contains('wax-free')) terms.add('wax free');
  if (normalized.contains('vacuum breaker')) terms.add('anti siphon');
  if (normalized.contains('pipe joint compound')) terms.add('pipe dope');
  if (normalized.contains('hose bibb')) terms.add('hose bib');
  return terms;
}
