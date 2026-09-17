part of '../../work_supply_catalog.dart';

final roofingGeneratedDetailCatalogCategory = _category(
  'Roofing Detail Stock',
  [
    _system('Shingles Underlayment and Roof Deck Detail', [
      _type(
        'Shingle and Starter Detail',
        _roofingProducts(
          baseName: 'Roof Covering Detail',
          unit: 'bundle',
          variants: [
            for (final color in _roofingShingleColors)
              for (final style in [
                '3 Tab Shingle Bundle',
                'Architectural Shingle Bundle',
                'Hip and Ridge Cap Shingle Bundle',
                'Starter Strip Shingle Bundle',
              ])
                '$color $style',
            for (final color in _roofingShingleColors)
              '$color Shingle Repair Patch Pack',
          ],
          aliases: const [
            'shingle bundle',
            'architectural shingle',
            'starter shingle',
            'ridge cap shingle',
            'shingle repair',
          ],
        ),
      ),
      _type(
        'Underlayment and Roof Deck Detail',
        _roofingProducts(
          baseName: 'Roof Deck Underlayment Detail',
          unit: 'roll',
          variants: [
            for (final coverage in ['2 sq', '5 sq', '10 sq'])
              for (final type in [
                'Synthetic Underlayment',
                '15 lb Felt Underlayment',
                '30 lb Felt Underlayment',
                'Ice and Water Shield',
              ])
                '$coverage $type',
            for (final thickness in [
              '7/16 in',
              '15/32 in',
              '19/32 in',
              '23/32 in',
            ])
              '4 x 8 $thickness OSB Roof Sheathing',
            'H-Clip Panel Spacer 250 Pack',
          ],
          aliases: const [
            'synthetic underlayment',
            'felt paper',
            'ice shield',
            'roof sheathing',
            'roof deck',
            'h clip',
          ],
        ),
      ),
    ]),
    _system('Flashing Vents and Metal Roofing Detail', [
      _type(
        'Flashing Metal and Pipe Boot Detail',
        _roofingProducts(
          baseName: 'Roof Flashing Detail',
          unit: 'each',
          variants: [
            for (final finish in ['Galvanized', 'Black', 'White', 'Copper'])
              for (final length in ['8 ft', '10 ft'])
                for (final trim in [
                  'Drip Edge',
                  'Rake Edge',
                  'Valley Flashing',
                  'Sidewall Flashing',
                  'Endwall Flashing',
                ])
                  '$finish $length $trim',
            for (final size in ['1-1/2 in', '2 in', '3 in', '4 in'])
              for (final material in ['Rubber', 'Silicone', 'Lead'])
                '$size $material Pipe Boot Flashing',
            for (final finish in ['Galvanized', 'Aluminum', 'Copper'])
              for (final pack in ['10 Pack', '50 Pack'])
                '$finish 4 x 4 x 8 in Step Flashing $pack',
          ],
          aliases: const [
            'drip edge',
            'rake edge',
            'valley flashing',
            'sidewall flashing',
            'endwall flashing',
            'pipe boot',
            'step flashing',
          ],
        ),
      ),
      _type(
        'Metal Roofing Trim and Closure Detail',
        _roofingProducts(
          baseName: 'Metal Roofing Detail',
          unit: 'piece',
          variants: [
            for (final color in ['Black', 'Brown', 'White', 'Galvalume'])
              for (final length in ['8 ft', '10 ft', '12 ft'])
                for (final trim in [
                  'Ridge Cap',
                  'Rake Trim',
                  'Eave Trim',
                  'Transition Flashing',
                  'Z Bar Flashing',
                ])
                  '$color $length Metal Roof $trim',
            for (final profile in ['Inside', 'Outside'])
              for (final length in ['3 ft', '4 ft'])
                '$length $profile Foam Closure Strip',
            for (final color in ['Black', 'Brown', 'White'])
              for (final length in ['1 in', '1-1/2 in', '2 in'])
                '$color $length Metal Roofing Screw 250 Pack',
          ],
          aliases: const [
            'metal roof',
            'ridge cap',
            'rake trim',
            'eave trim',
            'closure strip',
            'metal roofing screw',
          ],
        ),
      ),
    ]),
    _system('Gutters Soffit Low Slope and Safety Detail', [
      _type(
        'Gutter Soffit and Fascia Detail',
        _roofingProducts(
          baseName: 'Roof Drainage Exterior Detail',
          unit: 'piece',
          variants: [
            for (final color in ['White', 'Brown', 'Black'])
              for (final size in ['5 in', '6 in'])
                for (final length in ['10 ft', '16 ft'])
                  '$color $size K Style Gutter $length',
            for (final color in ['White', 'Brown'])
              for (final width in ['8 in', '10 in', '12 in'])
                '$color $width Aluminum Fascia Cover',
            for (final color in ['White', 'Brown'])
              for (final style in ['Vented', 'Solid'])
                '$color $style Soffit Panel',
            for (final length in ['3 ft', '4 ft', '6 ft'])
              for (final guard in [
                'Micro Mesh Gutter Guard',
                'Foam Gutter Guard',
              ])
                '$length $guard',
          ],
          aliases: const [
            'k style gutter',
            'gutter',
            'fascia cover',
            'soffit panel',
            'gutter guard',
          ],
        ),
      ),
      _type(
        'Low Slope Repair and Roof Safety Detail',
        _roofingProducts(
          baseName: 'Low Slope Safety Detail',
          unit: 'each',
          variants: [
            for (final size in ['1 gal', '3.5 gal', '5 gal'])
              for (final coating in [
                'Elastomeric Roof Coating',
                'Silicone Roof Coating',
                'Cold Process Roof Adhesive',
              ])
                '$size $coating',
            for (final width in ['4 in', '6 in', '12 in'])
              for (final tape in [
                'Peel and Stick Roof Repair Tape',
                'TPO Seam Tape',
              ])
                '$width $tape',
            for (final item in [
              'EPDM Patch Kit',
              'TPO Patch Kit',
              'Reusable Roof Anchor',
              'Ridge Roof Anchor',
              'Roof Harness Anchor Kit',
              'Ladder Roof Hook Kit',
            ])
              item,
          ],
          aliases: const [
            'epdm patch',
            'tpo patch',
            'roof repair tape',
            'roof coating',
            'roof anchor',
            'roof harness',
          ],
        ),
      ),
    ]),
  ],
);

const _roofingShingleColors = [
  'Black',
  'Charcoal',
  'Weathered Wood',
  'Driftwood',
  'Brown',
  'Shakewood',
];
