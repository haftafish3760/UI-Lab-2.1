part of '../../../work_supply_catalog.dart';

final hvacCondensateCategory = _category('Condensate', [
  _system('Drainage', [
    _type(
      'Condensate Pipe',
      _variants(
        'Condensate PVC Pipe',
        'stick',
        ['3/4 in', '1 in'],
        ['condensate line'],
      ),
    ),
    _type(
      'Condensate Fittings',
      _variants(
        'Condensate PVC Coupling',
        'each',
        ['3/4 in', '1 in'],
        ['condensate coupling', 'pvc drain coupling', 'pvc drain cplg'],
      ),
    ),
    _type(
      'Condensate Drain Fittings and Cleanouts',
      _variants(
        'Condensate Drain Service Fitting',
        'each',
        [
          '3/4 in PVC Tee Cleanout',
          '3/4 in PVC Trap',
          '3/4 in PVC Union',
          '3/4 in PVC Male Adapter',
          '3/4 in PVC Female Adapter',
          '3/4 in PVC 90 Elbow',
          '3/4 in PVC 45 Elbow',
          '3/4 in PVC Cap',
          '3/4 in PVC Plug',
          '1 in PVC Tee Cleanout',
          '1 in PVC Trap',
          '1 in PVC Union',
          '1 in PVC Male Adapter',
          '1 in PVC Female Adapter',
          '1 in PVC 90 Elbow',
          '1 in PVC 45 Elbow',
          '1 in PVC Cap',
          '1 in PVC Plug',
        ],
        [
          'condensate cleanout',
          'condensate trap',
          'condensate tee',
          'condensate pvc fitting',
          'pvc condensate fitting',
        ],
      ),
    ),
    _type(
      'Condensate Safety Switches',
      _variants(
        'Condensate Safety Switch',
        'each',
        [
          'Primary Drain Float Switch',
          'Secondary Pan Float Switch',
          'Inline Condensate Safety Switch',
          'Wet Switch Flood Detector',
          'Rectorseal Style Condensate Switch',
          'Overflow Safety Switch',
        ],
        [
          'float switch',
          'condensate float switch',
          'wet switch',
          'overflow switch',
          'pan switch',
        ],
      ),
    ),
    _type(
      'Condensate Pumps',
      _variants(
        'Condensate Pump',
        'each',
        [
          '115V',
          '230V',
          '115V With Safety Switch',
          '230V With Safety Switch',
          'High Lift 115V',
          'Mini Split 115V',
        ],
        ['little pump', 'condensate pump', 'mini split pump'],
      ),
    ),
    _type(
      'Condensate Tubing Hose and Pump Parts',
      _variants(
        'Condensate Drain Tubing',
        'roll',
        [
          '3/8 in ID Clear Vinyl Tubing 20 ft',
          '1/2 in ID Clear Vinyl Tubing 20 ft',
          '5/8 in ID Clear Vinyl Tubing 20 ft',
          '3/8 in ID Braided Vinyl Tubing 20 ft',
          '1/2 in ID Braided Vinyl Tubing 20 ft',
          '5/8 in ID Braided Vinyl Tubing 20 ft',
          '3/4 in Flexible Condensate Drain Hose 6 ft',
          '3/4 in Flexible Condensate Drain Hose 10 ft',
        ],
        [
          'vinyl tubing',
          'clear tubing',
          'condensate tubing',
          'pump tubing',
          'condensate hose',
        ],
      ),
    ),
    _type(
      'Drain Treatment',
      _variants(
        'Condensate Drain Tablets',
        'pack',
        [
          'standard pack',
          'drain pan tablet bottle',
          'drain pan strip pack',
          'condensate drain cleaner quart',
          'condensate drain brush kit',
        ],
        ['pan tabs', 'drain pan tablets', 'drain line cleaner'],
      ),
    ),
  ]),
]);
