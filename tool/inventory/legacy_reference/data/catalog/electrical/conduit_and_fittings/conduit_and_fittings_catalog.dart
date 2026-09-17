part of '../../../work_supply_catalog.dart';

final electricalConduitAndFittingsCategory = _category('Conduit and Fittings', [
  _system('EMT', [
    _type(
      'EMT Conduit',
      _variants('EMT Conduit', 'stick', _electricalRacewaySizes, ['thinwall']),
    ),
    _type(
      'EMT Connectors',
      _variants('EMT Connector', 'each', _electricalRacewaySizes, [
        'set screw connector',
      ]),
    ),
    _type(
      'EMT Couplings',
      _variants('EMT Coupling', 'each', _electricalRacewaySizes, [
        'set screw coupling',
      ]),
    ),
    _type(
      'EMT 90 Elbows',
      _variants('EMT 90 Elbow', 'each', _electricalRacewaySizes, [
        'emt sweep',
        'thinwall 90',
      ]),
    ),
    _type(
      'EMT Straps',
      _variants('EMT Strap', 'each', _electricalRacewaySizes, [
        'one hole strap',
        'two hole strap',
      ]),
    ),
  ]),
  _system('PVC Electrical', [
    _type(
      'PVC Electrical Conduit',
      _variants('PVC Electrical Conduit', 'stick', _electricalRacewaySizes, [
        'gray pvc conduit',
      ]),
    ),
    _type(
      'PVC Electrical Elbows',
      _variants('PVC Electrical 90 Elbow', 'each', _electricalRacewaySizes, [
        'sweep 90',
      ]),
    ),
    _type(
      'PVC Electrical Couplings',
      _variants('PVC Electrical Coupling', 'each', _electricalRacewaySizes, [
        'gray pvc coupling',
      ]),
    ),
    _type(
      'PVC Electrical Male Adapters',
      _variants(
        'PVC Electrical Male Adapter',
        'each',
        _electricalRacewaySizes,
        ['terminal adapter', 'male terminal adapter'],
      ),
    ),
    _type(
      'PVC Electrical Female Adapters',
      _variants(
        'PVC Electrical Female Adapter',
        'each',
        _electricalRacewaySizes,
        ['female terminal adapter'],
      ),
    ),
  ]),
  _system('Rigid and IMC', [
    _type(
      'Rigid Conduit',
      _variants('Rigid Metal Conduit', 'stick', _electricalRacewaySizes, [
        'rmc',
        'rigid pipe',
      ]),
    ),
    _type(
      'Rigid Couplings',
      _variants('Rigid Coupling', 'each', _electricalRacewaySizes, [
        'rmc coupling',
        'imc coupling',
      ]),
    ),
    _type(
      'Rigid Locknuts',
      _variants('Rigid Locknut', 'each', _electricalRacewaySizes, [
        'conduit locknut',
      ]),
    ),
  ]),
]);

const _electricalRacewaySizes = [
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '2-1/2 in',
  '3 in',
  '3-1/2 in',
  '4 in',
  '5 in',
  '6 in',
];
