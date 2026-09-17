part of '../../../work_supply_catalog.dart';

final plumbingHangersAndSupportsCategory = _category('Hangers and Supports', [
  _system('Pipe Supports', [
    _type(
      'Pipe Straps',
      _variants('Pipe Strap', 'each', _pipeSizes, [
        'pipe strap',
        'one hole strap',
        'two hole strap',
      ]),
    ),
    _type(
      'Riser Clamps',
      _variants('Riser Clamp', 'each', _pipeSizes, ['pipe clamp']),
    ),
    _type(
      'Split Ring Hangers',
      _variants('Split Ring Hanger', 'each', _pipeSizes, [
        'pipe hanger',
        'split ring',
      ]),
    ),
    _type(
      'J-Hooks',
      _variants('Pipe J-Hook', 'each', _supplySizes, [
        'pex j hook',
        'pipe hook',
      ]),
    ),
    _type(
      'Bell Hangers',
      _variants('Bell Hanger', 'each', _supplySizes, [
        'copper bell hanger',
        'pipe bell hanger',
      ]),
    ),
    _type(
      'Stud Guards',
      _variants(
        'Stud Guard Plate',
        'each',
        ['1-1/2 x 3 in', '1-1/2 x 5 in', '3 x 5 in'],
        ['nail plate', 'stud plate', 'protection plate'],
      ),
    ),
    _type(
      'Pipe Insulation',
      _variants(
        'Pipe Insulation',
        'stick',
        ['1/2 in x 6 ft', '3/4 in x 6 ft', '1 in x 6 ft'],
        ['foam pipe wrap', 'pipe sleeve'],
      ),
    ),
  ]),
  _system('Service Fasteners Anchors and Rod Stock', [
    _type(
      'Threaded Rod and Hanger Hardware',
      _variants(
        'Threaded Rod',
        'stick',
        [
          '1/4 in x 36 in',
          '3/8 in x 36 in',
          '1/2 in x 36 in',
          '3/8 in x 6 ft',
          '1/2 in x 6 ft',
          '3/8 in x 10 ft',
          '1/2 in x 10 ft',
        ],
        ['all thread', 'all-thread', 'thread rod', 'rod stock'],
      ),
    ),
    _type(
      'Rod Nuts Washers and Strut Hardware',
      _variants(
        'Rod and Strut Hardware',
        'pack',
        [
          '1/4 in Hex Nut 100 Pack',
          '3/8 in Hex Nut 100 Pack',
          '1/2 in Hex Nut 50 Pack',
          '1/4 in Fender Washer 100 Pack',
          '3/8 in Fender Washer 100 Pack',
          '1/2 in Fender Washer 50 Pack',
          '1/4 in Rod Coupling Nut 10 Pack',
          '3/8 in Rod Coupling Nut 10 Pack',
          '1/2 in Rod Coupling Nut 10 Pack',
          '3/8 in Strut Nut 25 Pack',
          '1/2 in Strut Nut 25 Pack',
        ],
        ['coupling nut', 'strut nut', 'unistrut nut', 'washer', 'hex nut'],
      ),
    ),
    _type(
      'Concrete Screws and Masonry Anchors',
      _variants(
        'Concrete Screw Anchor',
        'box',
        [
          '3/16 in x 1-1/4 in',
          '3/16 in x 1-3/4 in',
          '1/4 in x 1-3/4 in',
          '1/4 in x 2-1/4 in',
          '1/4 in x 3-1/4 in',
        ],
        ['tapcon', 'masonry screw', 'blue screw', 'concrete anchor screw'],
      ),
    ),
    _type(
      'Rod Hanger Anchors and Beam Clamps',
      _variants(
        'Rod Hanger Anchor',
        'each',
        [
          '1/4 in Drop-In Anchor',
          '3/8 in Drop-In Anchor',
          '1/2 in Drop-In Anchor',
          '1/4 in Wedge Anchor',
          '3/8 in Wedge Anchor',
          '1/2 in Wedge Anchor',
          '3/8 in Beam Clamp',
          '1/2 in Beam Clamp',
          '3/8 in Ceiling Flange',
          '1/2 in Ceiling Flange',
        ],
        ['drop in anchor', 'wedge anchor', 'beam clamp', 'ceiling flange'],
      ),
    ),
  ]),
]);
