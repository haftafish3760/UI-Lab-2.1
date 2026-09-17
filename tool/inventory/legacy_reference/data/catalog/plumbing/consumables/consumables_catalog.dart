part of '../../../work_supply_catalog.dart';

final plumbingConsumablesCategory = _category('Consumables', [
  _system('Sealants', [
    _type(
      'Thread Sealants',
      _variants(
        'Pipe Joint Compound',
        'tube',
        ['4 oz', '8 oz', '16 oz'],
        ['pipe dope', 'thread paste', 'thread sealant'],
      ),
    ),
    _type(
      'Thread Tape',
      _variants(
        'PTFE Thread Tape',
        'roll',
        ['1/2 in x 260 in', '3/4 in x 520 in'],
        ['teflon tape'],
      ),
    ),
    _type(
      'PVC Cement',
      _variants(
        'PVC Cement',
        'can',
        ['4 oz', '8 oz', '16 oz'],
        [
          'glue',
          'pvc glue',
          'solvent cement',
          'clear cement',
          'clear pvc glue',
        ],
      ),
    ),
    _type(
      'CPVC Cement',
      _variants(
        'CPVC Cement',
        'can',
        ['4 oz', '8 oz', '16 oz'],
        ['cpvc glue', 'yellow glue', 'cpvc solvent cement'],
      ),
    ),
    _type(
      'PVC Primer',
      _variants(
        'PVC Primer',
        'can',
        ['4 oz', '8 oz', '16 oz', '32 oz'],
        ['purple primer', 'pipe primer'],
      ),
    ),
    _type(
      'Plumber Putty',
      _variants(
        'Plumber Putty',
        'tub',
        ['14 oz', '32 oz', '5 lb'],
        ['putty', 'sink putty'],
      ),
    ),
    _type(
      'Silicone Sealant',
      _variants(
        'Silicone Sealant',
        'tube',
        ['2.8 oz clear', '10 oz clear', '10 oz white'],
        ['silicone caulk', 'kitchen bath silicone'],
      ),
    ),
    _type(
      'Pipe Lubricant',
      _variants(
        'Pipe Lubricant',
        'tub',
        ['1 qt', '1 gal'],
        ['pipe lube', 'gasket lubricant', 'joint lubricant'],
      ),
    ),
  ]),
  _system('Copper Soldering Consumables', [
    _type(
      'Lead-Free Plumbing Solder',
      _variants(
        'Lead-Free Plumbing Solder',
        'spool',
        ['1/16 in 4 oz', '1/8 in 4 oz', '1/8 in 8 oz', '1/8 in 1 lb'],
        [
          'lead free solder',
          'plumbing solder',
          'sweat solder',
          'tin antimony solder',
          'silver bearing solder',
          'lf solder',
        ],
      ),
    ),
    _type(
      'Water Soluble Flux',
      _variants(
        'Water Soluble Flux',
        'jar',
        ['1.7 oz', '4 oz', '8 oz'],
        [
          'solder flux',
          'plumbing flux',
          'tinning flux',
          'paste flux',
          'water soluble solder flux',
        ],
      ),
    ),
    _type(
      'Acid Brush',
      _variants(
        'Acid Brush',
        'brush',
        ['single', '3 pack', '12 pack'],
        ['flux brush', 'solder brush', 'acid brushes'],
      ),
    ),
    _type(
      'Copper Fitting Brush',
      _variants(
        'Copper Fitting Brush',
        'brush',
        ['1/2 in', '3/4 in', '1 in', '1/2 in and 3/4 in combo'],
        [
          'fitting brush',
          'copper fitting brush',
          'wire fitting brush',
          'tube brush',
          'sweat fitting brush',
        ],
      ),
    ),
    _type(
      'Plumber Sand Cloth',
      _variants(
        'Plumber Sand Cloth',
        'roll',
        ['1-1/2 in x 5 yd', '1-1/2 in x 10 yd'],
        [
          'sand cloth',
          'emery cloth',
          'abrasive cloth',
          'plumber sand cloth',
          'copper cleaning cloth',
        ],
      ),
    ),
    _type(
      'Soldering Heat Shield',
      _variants(
        'Soldering Heat Shield',
        'pad',
        ['9 in x 12 in', '12 in x 18 in'],
        [
          'heat shield',
          'flame protector',
          'soldering heat shield',
          'torch shield',
          'flame shield',
        ],
      ),
    ),
    _type(
      'Propane Torch Fuel',
      _variants(
        'Propane Torch Fuel',
        'cylinder',
        ['14.1 oz', '16 oz'],
        ['propane bottle', 'propane cylinder', 'torch fuel', 'lp fuel'],
      ),
    ),
    _type(
      'MAP-Pro Torch Fuel',
      _variants(
        'MAP-Pro Torch Fuel',
        'cylinder',
        ['14.1 oz'],
        ['mapp gas', 'map gas', 'map-pro', 'map pro fuel', 'torch fuel'],
      ),
    ),
    _type(
      'Soldering Torch Head',
      _variants(
        'Soldering Torch Head',
        'torch head',
        ['basic torch head', 'self lighting torch head'],
        [
          'torch head',
          'solder torch',
          'plumbing torch',
          'self lighting torch',
          'trigger start torch',
        ],
      ),
    ),
  ]),
]);
