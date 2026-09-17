part of '../../work_supply_catalog.dart';

final drywallGeneratedDetailCatalogCategory = _category(
  'Drywall Detail Stock',
  [
    _system('Board and Specialty Panels', [
      _type(
        'Drywall Board Detail',
        _drywallProducts(
          baseName: 'Drywall Board Detail',
          unit: 'sheet',
          variants: [
            for (final thickness in ['1/4 in', '3/8 in', '1/2 in', '5/8 in'])
              for (final size in ['4 x 8', '4 x 10', '4 x 12'])
                for (final face in [
                  'Regular',
                  'Lightweight',
                  'Mold Resistant',
                  'Fire Rated Type X',
                  'Abuse Resistant',
                ])
                  '$thickness $size $face',
            for (final size in ['2 x 2', '2 x 4'])
              for (final texture in ['Fissured', 'Smooth', 'Reveal Edge'])
                '$size $texture Acoustic Ceiling Tile',
          ],
          aliases: const [
            'drywall sheet',
            'sheetrock',
            'gypsum board',
            'mold resistant board',
            'type x board',
            'ceiling tile',
          ],
        ),
      ),
      _type(
        'Patch and Backer Panels',
        _drywallProducts(
          baseName: 'Patch Panel Detail',
          unit: 'each',
          variants: [
            for (final size in ['2 x 2', '2 x 4', '4 x 4'])
              for (final type in ['Drywall Repair Panel', 'Cement Patch Board'])
                '$size $type',
            for (final size in ['6 x 6', '8 x 8', '12 x 12'])
              '$size Aluminum Wall Patch',
          ],
          aliases: const [
            'repair panel',
            'patch panel',
            'wall patch',
            'drywall patch',
          ],
        ),
      ),
    ]),
    _system('Compound Tape and Finish Accessories', [
      _type(
        'Compound and Tape Detail',
        _drywallProducts(
          baseName: 'Drywall Finish Detail',
          unit: 'each',
          variants: [
            for (final size in ['1 gal', '3.5 qt', '4.5 gal'])
              for (final mix in [
                'All Purpose Joint Compound',
                'Plus 3 Joint Compound',
                'Topping Compound',
              ])
                '$size $mix',
            for (final minutes in ['5 min', '20 min', '45 min', '90 min'])
              for (final weight in ['5 lb', '18 lb'])
                '$minutes $weight Setting Type Compound',
            for (final length in ['75 ft', '250 ft', '500 ft'])
              for (final tape in ['Paper Tape', 'Fiberglass Mesh Tape'])
                '$length $tape',
          ],
          aliases: const [
            'joint compound',
            'drywall mud',
            'plus 3',
            'easy sand',
            'setting compound',
            'paper tape',
            'mesh tape',
          ],
        ),
      ),
      _type(
        'Bead and Trim Detail',
        _drywallProducts(
          baseName: 'Drywall Bead Detail',
          unit: 'piece',
          variants: [
            for (final length in ['8 ft', '10 ft', '12 ft'])
              for (final bead in [
                'Metal Corner Bead',
                'Vinyl Corner Bead',
                'Bullnose Corner Bead',
                'L Bead',
                'J Bead',
                'Tear Away Bead',
                'Control Joint',
                'Reveal Bead',
                'Shadow Bead',
              ])
                '$length $bead',
            for (final size in ['3/4 in', '1 in', '1-1/4 in'])
              '$size Bullnose Three-Way Corner Cap',
          ],
          aliases: const [
            'corner bead',
            'vinyl bead',
            'bullnose bead',
            'tear away bead',
            'control joint',
            'reveal bead',
            'shadow bead',
          ],
        ),
      ),
    ]),
    _system('Metal Framing and Drop Ceiling Detail', [
      _type(
        'Metal Framing Detail',
        _drywallProducts(
          baseName: 'Drywall Metal Framing Detail',
          unit: 'piece',
          variants: [
            for (final gauge in ['25 ga', '20 ga', '18 ga'])
              for (final width in ['2-1/2 in', '3-5/8 in', '6 in'])
                for (final length in ['8 ft', '10 ft', '12 ft'])
                  '$gauge $width x $length Metal Stud',
            for (final gauge in ['25 ga', '20 ga'])
              for (final width in ['2-1/2 in', '3-5/8 in', '6 in'])
                for (final length in ['10 ft', '12 ft'])
                  '$gauge $width x $length Metal Track',
            for (final length in ['8 ft', '10 ft', '12 ft'])
              for (final channel in [
                'Hat Channel',
                'Resilient Channel',
                'Z Furring Channel',
              ])
                '$length $channel',
          ],
          aliases: const [
            'metal stud',
            'steel stud',
            'metal track',
            'hat channel',
            'resilient channel',
            'z furring',
          ],
        ),
      ),
      _type(
        'Ceiling Grid Detail',
        _drywallProducts(
          baseName: 'Drop Ceiling Detail',
          unit: 'piece',
          variants: [
            for (final color in ['White', 'Black'])
              for (final item in [
                '12 ft Main Runner',
                '4 ft Cross Tee',
                '2 ft Cross Tee',
                '12 ft Wall Angle',
              ])
                '$color $item',
            for (final gauge in ['12 ga', '16 ga'])
              for (final length in ['100 ft', '300 ft'])
                '$gauge $length Ceiling Hanger Wire',
            for (final item in ['Hold Down Clip', 'Grid Repair Clip']) item,
          ],
          aliases: const [
            'ceiling grid',
            'main runner',
            'cross tee',
            'wall angle',
            'hanger wire',
          ],
        ),
      ),
    ]),
    _system('Sanding Texture Access and Protection', [
      _type(
        'Sanding Texture and Access Detail',
        _drywallProducts(
          baseName: 'Drywall Finish Tool Detail',
          unit: 'each',
          variants: [
            for (final grit in ['80 grit', '120 grit', '150 grit', '220 grit'])
              for (final tool in ['Sanding Screen', 'Sanding Sponge'])
                '$grit $tool',
            for (final size in ['6 in', '10 in', '12 in'])
              for (final type in [
                'Plastic Access Panel',
                'Fire Rated Access Door',
              ])
                '$size x $size $type',
            for (final texture in ['Orange Peel', 'Knockdown', 'Popcorn'])
              for (final package in ['Aerosol', 'Powder Mix', 'Premixed'])
                '$package $texture Texture',
            for (final item in [
              'Zip Door Dust Barrier Kit',
              'Dust Barrier Pole',
              'Texture Hopper Nozzle Kit',
              'Drywall Pole Sander Head',
              '12 in Stainless Taping Knife',
            ])
              item,
          ],
          aliases: const [
            'sanding screen',
            'sanding sponge',
            'access panel',
            'access door',
            'texture spray',
            'texture mix',
            'dust barrier',
            'taping knife',
          ],
        ),
      ),
    ]),
  ],
);
