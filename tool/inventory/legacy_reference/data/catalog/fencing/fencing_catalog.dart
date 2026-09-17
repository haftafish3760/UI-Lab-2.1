part of '../../work_supply_catalog.dart';

final fencingCatalog = _trade('Fencing', const Color(0xFF8A704D), [
  _category('Fence Materials', [
    _system('Wood Fence', [
      _type('Pickets and Boards', [
        ..._variants(
          'Fence Picket',
          'each',
          ['5/8 in x 5-1/2 in x 6 ft', '3/4 in x 5-1/2 in x 6 ft'],
          const ['wood picket', 'privacy fence board'],
        ),
        ..._variants(
          'Fence Rail',
          'each',
          ['2 in x 3 in x 8 ft', '2 in x 4 in x 8 ft'],
          const ['wood rail', 'fence stringer'],
        ),
      ]),
    ]),
    _system('Vinyl Fence', [
      _type('Panels and Rails', [
        ..._variants(
          'Vinyl Fence Panel',
          'each',
          ['6 ft x 6 ft', '6 ft x 8 ft'],
          const ['privacy panel', 'vinyl panel'],
        ),
        ..._variants(
          'Vinyl Fence Rail',
          'each',
          ['6 ft', '8 ft'],
          const ['vinyl rail'],
        ),
      ]),
    ]),
    _system('Chain Link', [
      _type('Fabric and Rail', [
        ..._variants(
          'Chain Link Fabric Roll',
          'roll',
          ['4 ft x 50 ft', '5 ft x 50 ft', '6 ft x 50 ft'],
          const ['wire fence fabric', 'chainlink fabric'],
        ),
        ..._variants(
          'Top Rail',
          'each',
          ['1-3/8 in x 10 ft', '1-3/8 in x 21 ft'],
          const ['chain link rail'],
        ),
      ]),
    ]),
  ]),
  _category('Posts and Framework', [
    _system('Wood Posts', [
      _type('Fence Posts', [
        ..._variants(
          'Pressure Treated Fence Post',
          'each',
          ['4 in x 4 in x 8 ft', '4 in x 4 in x 10 ft', '6 in x 6 in x 8 ft'],
          const ['treated post', 'wood fence post'],
        ),
      ]),
    ]),
    _system('Metal Posts', [
      _type('Line and Terminal Posts', [
        ..._variants(
          'Chain Link Line Post',
          'each',
          ['1-5/8 in x 6 ft', '1-7/8 in x 8 ft'],
          const ['line post'],
        ),
        ..._variants(
          'Terminal Post',
          'each',
          ['2-3/8 in x 8 ft', '2-7/8 in x 8 ft'],
          const ['corner post', 'end post'],
        ),
      ]),
    ]),
  ]),
  _category('Gates and Hardware', [
    _system('Gate Hardware', [
      _type('Hinges and Latches', [
        ..._variants(
          'Gate Hinge Set',
          'set',
          ['Residential', 'Heavy Duty'],
          const ['fence hinge'],
        ),
        ..._variants(
          'Gate Latch',
          'each',
          ['Standard', 'Lockable'],
          const ['fence latch'],
        ),
      ]),
    ]),
    _system('Gate Frames', [
      _type('Gate Kits', [
        ..._variants(
          'Gate Frame Kit',
          'set',
          ['Wood', 'Chain Link'],
          const ['fence gate kit'],
        ),
      ]),
    ]),
  ]),
  _category('Wire and Farm Fence', [
    _system('Field Fence', [
      _type('Wire Rolls', [
        ..._variants(
          'Welded Wire Fence Roll',
          'roll',
          ['2 ft x 50 ft', '4 ft x 50 ft'],
          const ['welded wire'],
        ),
        ..._variants(
          'Barbed Wire Roll',
          'roll',
          ['2 Point 1320 ft', '4 Point 1320 ft'],
          const ['barb wire'],
        ),
      ]),
    ]),
  ]),
  _category('Fasteners and Accessories', [
    _system('Fasteners', [
      _type('Fence Fasteners', [
        ..._variants(
          'Fence Screw',
          'box',
          ['#8 x 1-1/2 in', '#9 x 2 in'],
          const ['wood fence screw'],
        ),
        ..._variants(
          'Fence Staple',
          'box',
          ['1-1/4 in', '1-3/4 in'],
          const ['wire staple'],
        ),
      ]),
    ]),
    _system('Concrete and Setting', [
      _type('Post Setting', [
        ..._variants(
          'Fast Setting Concrete Mix',
          'bag',
          ['50 lb', '60 lb', '80 lb'],
          const ['post concrete', 'fence post concrete'],
        ),
      ]),
    ]),
  ]),
  fencingGeneratedServiceCatalogCategory,
  fencingGeneratedDetailCatalogCategory,
  fencingGeneratedFieldCatalogCategory,
]);
