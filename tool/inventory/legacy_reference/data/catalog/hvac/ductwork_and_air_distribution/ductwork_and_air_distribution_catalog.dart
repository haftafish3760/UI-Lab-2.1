part of '../../../work_supply_catalog.dart';

final hvacDuctworkAndAirDistributionCategory = _category(
  'Ductwork and Air Distribution',
  [
    _system('Flexible Duct', [
      _type(
        'Insulated Flex Duct',
        _variants(
          'Insulated Flex Duct',
          'box',
          ['6 in R-6', '8 in R-6', '10 in R-6', '12 in R-6', '8 in R-8'],
          ['flex duct', 'insulated duct'],
        ),
      ),
    ]),
    _system('Metal Duct Fittings', [
      _type(
        'Duct Elbows',
        _variants(
          'Duct Elbow',
          'each',
          ['6 in', '8 in', '10 in', '12 in'],
          ['sheet metal elbow'],
        ),
      ),
      _type(
        'Duct Collars',
        _variants(
          'Duct Start Collar',
          'each',
          ['6 in', '8 in', '10 in', '12 in'],
          ['takeoff collar'],
        ),
      ),
      _type(
        'Duct Connectors',
        _variants(
          'Duct Connector',
          'each',
          ['6 in crimped', '8 in crimped', '10 in crimped', '12 in crimped'],
          ['duct coupling', 'snap lock connector'],
        ),
      ),
      _type(
        'Duct Cleats and S-Lock',
        _variants(
          'Duct Cleat',
          'pack',
          ['drive cleat', 's-lock', 'standing s-lock'],
          ['drive cleat', 's lock', 'duct cleat'],
        ),
      ),
    ]),
    _system('Duct Supports', [
      _type(
        'Duct Hanger Strap',
        _variants(
          'Duct Hanger Strap',
          'roll',
          ['1 in x 100 ft', '1-1/2 in x 100 ft', '2 in x 100 ft'],
          ['hanger strap', 'duct strap', 'plumbers tape'],
        ),
      ),
      _type(
        'Sheet Metal Screws',
        _variants(
          'Sheet Metal Screw',
          'box',
          ['#8 x 1/2 in', '#8 x 3/4 in', '#10 x 1 in'],
          ['zip screw', 'tek screw', 'duct screw'],
        ),
      ),
    ]),
    _system('Registers and Grilles', [
      _type(
        'Floor Registers',
        _variants(
          'Floor Register',
          'each',
          ['2 x 10', '2 x 12', '4 x 10', '4 x 12'],
          ['vent register'],
        ),
      ),
      _type(
        'Return Grilles',
        _variants(
          'Return Air Grille',
          'each',
          ['14 x 20', '16 x 20', '20 x 20', '20 x 25'],
          ['return grille'],
        ),
      ),
    ]),
  ],
);
