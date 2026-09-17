part of '../../../work_supply_catalog.dart';

final plumbingPumpsCategory = _category('Pumps', [
  _system('Sump and Condensate', [
    _type(
      'Sump Pumps',
      _variants(
        'Sump Pump',
        'each',
        ['1/4 hp', '1/3 hp', '1/2 hp', '3/4 hp'],
        ['submersible pump'],
      ),
    ),
    _type(
      'Condensate Pumps',
      _variants(
        'Condensate Pump',
        'each',
        ['115V', '230V'],
        ['condensate removal pump'],
      ),
    ),
    _type(
      'Pump Check Valves',
      _variants(
        'Pump Check Valve',
        'each',
        ['1-1/4 in', '1-1/2 in', '2 in'],
        ['sump check valve'],
      ),
    ),
    _type(
      'Pump Discharge Hose Kits',
      _variants(
        'Pump Discharge Hose Kit',
        'kit',
        ['1-1/4 in x 24 ft', '1-1/2 in x 24 ft', '2 in x 24 ft'],
        ['sump pump hose', 'discharge hose'],
      ),
    ),
    _type(
      'Pump Discharge Adapters',
      _variants(
        'Sump Pump Discharge Adapter',
        'each',
        [
          '1-1/4 in PVC adapter',
          '1-1/4 in barbed adapter',
          '1-1/2 in PVC adapter',
          '1-1/2 in barbed adapter',
        ],
        ['sump pump adapter', 'pump adapter', 'barbed adapter', 'pvc adapter'],
      ),
    ),
    _type(
      'Condensate Pump Tubing',
      _variants(
        'Condensate Pump Tubing',
        'roll',
        ['3/8 in x 20 ft', '3/8 in x 50 ft', '1/2 in x 20 ft'],
        ['condensate tubing', 'vinyl tubing'],
      ),
    ),
    _type(
      'Pump Float Switches',
      _variants(
        'Pump Float Switch',
        'each',
        ['tethered', 'vertical', 'piggyback'],
        ['sump float', 'float switch'],
      ),
    ),
  ]),
  _system('Well Service', [
    _type(
      'Well Pumps',
      _variants(
        'Well Pump',
        'each',
        ['1/2 hp shallow well', '3/4 hp shallow well', '1 hp deep well'],
        ['jet pump', 'deep well pump', 'shallow well pump'],
      ),
    ),
    _type(
      'Pressure Tanks',
      _variants(
        'Well Pressure Tank',
        'each',
        ['20 gal', '32 gal', '44 gal'],
        ['pressure tank', 'well tank'],
      ),
    ),
    _type(
      'Pressure Switches',
      _variants(
        'Well Pressure Switch',
        'each',
        ['30/50 psi', '40/60 psi'],
        ['pump pressure switch', 'well switch'],
      ),
    ),
    _type(
      'Well Pump Control Boxes',
      _variants(
        'Well Pump Control Box',
        'each',
        ['1/2 hp', '3/4 hp', '1 hp'],
        ['pump control box', 'submersible pump control'],
      ),
    ),
    _type(
      'Well Pipe and Adapters',
      _variants(
        'Well Pipe Adapter',
        'each',
        [
          '3/4 in insert',
          '1 in insert',
          '1-1/4 in insert',
          '1 in pitless adapter',
          '1-1/4 in pitless adapter',
        ],
        ['well pipe fitting', 'poly pipe insert', 'pitless adapter'],
      ),
    ),
    _type(
      'Well Check Valves',
      _variants(
        'Well Pump Check Valve',
        'each',
        ['1 in', '1-1/4 in'],
        ['well check valve', 'pump check valve'],
      ),
    ),
    _type(
      'Well Pressure Gauges',
      _variants(
        'Well Pressure Gauge',
        'each',
        ['0-100 psi', '0-160 psi'],
        ['pump pressure gauge', 'well gauge'],
      ),
    ),
    _type(
      'Well Tank Tees',
      _variants(
        'Well Tank Tee',
        'each',
        ['1 x 11 in', '1 x 13 in', '1-1/4 x 11 in'],
        ['pressure tank tee', 'tank tee kit'],
      ),
    ),
    _type(
      'Well Service Fittings',
      _variants(
        'Well Service Fitting',
        'each',
        ['1 in barbed coupling', '1 in barbed elbow', '1 in barbed adapter'],
        ['well barb fitting', 'poly well fitting'],
      ),
    ),
  ]),
]);
