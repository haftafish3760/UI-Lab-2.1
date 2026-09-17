part of '../../work_supply_catalog.dart';

final plumbingGeneratedCopperFittingTypes = _generatedSupplyFittingTypes(
  material: 'Copper',
  aliases: const ['copper', 'sweat'],
  sizes: _generatedCopperSizes,
);

final plumbingGeneratedPvcSchedule40FittingTypes = _generatedPipeFittingTypes(
  material: 'PVC Schedule 40',
  aliases: const ['pvc', 'sch40', 'schedule 40'],
  sizes: _generatedPressurePipeSizes,
);

final plumbingGeneratedCpvcFittingTypes = _generatedSupplyFittingTypes(
  material: 'CPVC',
  aliases: const ['cpvc', 'cream pipe'],
  sizes: _generatedSupplySizes,
);

final plumbingGeneratedPexFittingTypes = _generatedSupplyFittingTypes(
  material: 'PEX',
  aliases: const ['pex', 'crimp', 'cinch'],
  sizes: _generatedPexSizes,
);

final plumbingGeneratedPvcDwvFittingTypes = _generatedDwvFittingTypes(
  material: 'PVC DWV',
  aliases: const ['dwv', 'drain', 'pvc drain'],
  sizes: _generatedDwvSizes,
);

final plumbingGeneratedAbsDwvFittingTypes = _generatedDwvFittingTypes(
  material: 'ABS DWV',
  aliases: const ['abs', 'abs dwv', 'black drain', 'black dwv'],
  sizes: _generatedDwvSizes,
);

final plumbingGeneratedBlackIronFittingTypes = _generatedThreadedFittingTypes(
  material: 'Black Iron',
  aliases: const ['black iron', 'black pipe', 'threaded'],
  sizes: _generatedThreadedSizes,
);

final plumbingGeneratedGalvanizedFittingTypes = _generatedThreadedFittingTypes(
  material: 'Galvanized',
  aliases: const ['galv', 'galvanized', 'threaded'],
  sizes: _generatedThreadedSizes,
);

final plumbingGeneratedBrassFittingTypes = _generatedThreadedFittingTypes(
  material: 'Brass',
  aliases: const ['brass', 'threaded'],
  sizes: _generatedBrassSizes,
);

final plumbingGeneratedPushFitFittingTypes = _generatedSupplyFittingTypes(
  material: 'Push-Fit',
  aliases: const ['push fit', 'push to connect', 'sharkbite style'],
  sizes: _generatedPushFitSizes,
);

List<WorkSupplyItemType> _generatedSupplyFittingTypes({
  required String material,
  required List<String> aliases,
  required List<String> sizes,
}) {
  return [
    _generatedType(
      material,
      '90 Elbows Expanded',
      '$material 90 Elbow',
      sizes,
      [...aliases, '90', 'elbow', 'ell'],
    ),
    _generatedType(
      material,
      '45 Elbows Expanded',
      '$material 45 Elbow',
      sizes,
      [...aliases, '45', 'elbow'],
    ),
    _generatedType(
      material,
      'Street 90 Elbows Expanded',
      '$material Street 90 Elbow',
      sizes,
      [...aliases, 'street 90', 'street elbow'],
    ),
    _generatedType(
      material,
      'Street 45 Elbows Expanded',
      '$material Street 45 Elbow',
      sizes,
      [...aliases, 'street 45', 'street elbow'],
    ),
    _generatedType(
      material,
      'Tees Expanded',
      '$material Tee',
      _teeMatrix(sizes),
      [...aliases, 'tee', 't', 'reducing tee'],
    ),
    _generatedType(
      material,
      'Couplings Expanded',
      '$material Coupling',
      sizes,
      [...aliases, 'coupling', 'coupler'],
    ),
    _generatedType(
      material,
      'Reducing Couplings Expanded',
      '$material Reducing Coupling',
      _reducerMatrix(sizes),
      [...aliases, 'reducer', 'reducing coupling'],
    ),
    _generatedType(material, 'Caps Expanded', '$material Cap', sizes, [
      ...aliases,
      'cap',
      'end cap',
    ]),
    _generatedType(
      material,
      'Male Adapters Expanded',
      '$material Male Adapter',
      sizes,
      [...aliases, 'male adapter', 'mip adapter'],
    ),
    _generatedType(
      material,
      'Female Adapters Expanded',
      '$material Female Adapter',
      sizes,
      [...aliases, 'female adapter', 'fip adapter'],
    ),
  ];
}

List<WorkSupplyItemType> _generatedPipeFittingTypes({
  required String material,
  required List<String> aliases,
  required List<String> sizes,
}) {
  return [
    ..._generatedSupplyFittingTypes(
      material: material,
      aliases: aliases,
      sizes: sizes,
    ),
    _generatedType(material, 'Unions Expanded', '$material Union', sizes, [
      ...aliases,
      'union',
    ]),
    _generatedType(material, 'Plugs Expanded', '$material Plug', sizes, [
      ...aliases,
      'plug',
      'threaded plug',
    ]),
    _generatedType(
      material,
      'Reducer Bushings Expanded',
      '$material Reducer Bushing',
      _reducerMatrix(sizes),
      [...aliases, 'bushing', 'reducing bushing'],
    ),
  ];
}

List<WorkSupplyItemType> _generatedDwvFittingTypes({
  required String material,
  required List<String> aliases,
  required List<String> sizes,
}) {
  return [
    _generatedType(
      material,
      '90 Elbows Expanded',
      '$material 90 Elbow',
      sizes,
      [...aliases, '90', 'drain elbow'],
    ),
    _generatedType(
      material,
      '45 Elbows Expanded',
      '$material 45 Elbow',
      sizes,
      [...aliases, '45', 'drain 45'],
    ),
    _generatedType(material, 'Wyes Expanded', '$material Wye', sizes, [
      ...aliases,
      'wye',
      'y fitting',
    ]),
    _generatedType(
      material,
      'Sanitary Tees Expanded',
      '$material Sanitary Tee',
      _teeMatrix(sizes),
      [...aliases, 'san tee', 'sanitary tee'],
    ),
    _generatedType(
      material,
      'Couplings Expanded',
      '$material Coupling',
      sizes,
      [...aliases, 'coupling'],
    ),
    _generatedType(
      material,
      'Reducing Couplings Expanded',
      '$material Reducing Coupling',
      _reducerMatrix(sizes),
      [...aliases, 'reducer', 'reducing coupling'],
    ),
    _generatedType(
      material,
      'Cleanouts Expanded',
      '$material Cleanout',
      sizes,
      [...aliases, 'cleanout', 'clean out'],
    ),
  ];
}

List<WorkSupplyItemType> _generatedThreadedFittingTypes({
  required String material,
  required List<String> aliases,
  required List<String> sizes,
}) {
  return [
    ..._generatedPipeFittingTypes(
      material: material,
      aliases: aliases,
      sizes: sizes,
    ),
    _generatedType(
      material,
      'Nipples Expanded',
      '$material Nipple',
      _nippleMatrix(sizes),
      [...aliases, 'nipple', 'pipe nipple'],
    ),
    _generatedType(
      material,
      'Floor Flanges Expanded',
      '$material Floor Flange',
      sizes,
      [...aliases, 'floor flange', 'pipe flange'],
    ),
  ];
}

WorkSupplyItemType _generatedType(
  String material,
  String typeName,
  String baseName,
  List<String> variants,
  List<String> aliases,
) {
  return _type(typeName, _variants(baseName, 'each', variants, aliases));
}

List<String> _teeMatrix(List<String> sizes) {
  return [
    for (final left in sizes)
      for (final middle in sizes)
        for (final right in sizes)
          '${_compactSize(left)} x ${_compactSize(middle)} x ${_compactSize(right)}',
  ];
}

List<String> _reducerMatrix(List<String> sizes) {
  return [
    for (var large = 0; large < sizes.length; large++)
      for (var small = 0; small < sizes.length; small++)
        if (large != small)
          '${_compactSize(sizes[large])} x ${_compactSize(sizes[small])}',
  ];
}

String _compactSize(String size) => size.replaceAll(' in', '');

List<String> _nippleMatrix(List<String> sizes) {
  const lengths = [
    'Close',
    '1-1/2 in',
    '2 in',
    '3 in',
    '4 in',
    '6 in',
    '12 in',
  ];
  return [
    for (final size in sizes)
      for (final length in lengths) '$size x $length',
  ];
}

const _generatedSupplySizes = [
  '1/4 in',
  '3/8 in',
  '1/2 in',
  '5/8 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
];

const _generatedCopperSizes = [
  ..._generatedSupplySizes,
  '2-1/2 in',
  '3 in',
  '4 in',
];

const _generatedPexSizes = [
  '3/8 in',
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
];

const _generatedPushFitSizes = ['1/4 in', '3/8 in', '1/2 in', '3/4 in', '1 in'];

const _generatedPressurePipeSizes = [
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '2-1/2 in',
  '3 in',
  '4 in',
  '6 in',
];

const _generatedDwvSizes = [
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '3 in',
  '4 in',
  '6 in',
  '8 in',
];

const _generatedThreadedSizes = [
  '1/8 in',
  '1/4 in',
  '3/8 in',
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
  '2-1/2 in',
  '3 in',
  '4 in',
];

const _generatedBrassSizes = [
  '1/8 in',
  '1/4 in',
  '3/8 in',
  '1/2 in',
  '3/4 in',
  '1 in',
  '1-1/4 in',
  '1-1/2 in',
  '2 in',
];
