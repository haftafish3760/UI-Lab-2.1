part of 'work_supply_catalog.dart';

String _plumbingTierText(WorkSupplyItem item) =>
    '${item.name} ${item.category} ${item.system} ${item.itemType} ${item.variant}'
        .toLowerCase();

const _plumbingCompleteTermSignals = [
  'specialty',
  'legacy',
  'roof drain',
  'interceptor',
  'mop sink',
  'industrial',
];

const _plumbingCoreWellServiceSignals = [
  'well pump',
  'pressure switch',
  'well switch',
  'pump control box',
  'pressure tank',
  'well tank',
  'tank tee',
  'pressure tank tee',
  'well pipe',
  'pitless adapter',
  'well service fitting',
  'well barb fitting',
  'poly well fitting',
  'well check valve',
  'pump check valve',
  'pressure gauge',
];

const _plumbingProfessionalTermSignals = [
  'backflow',
  'boiler',
  'hydronic',
  'cast iron',
  'no-hub',
  'grease',
  'flushometer',
  'roof drain',
  'interceptor',
  'mop sink',
  'commercial',
];

const _plumbingCommercialOnlyCoreTermExclusions = [
  'no-hub',
  'cast iron',
  'backflow',
  'boiler',
  'hydronic',
  'grease',
  'flushometer',
  'roof drain',
  'interceptor',
  'mop sink',
  '2-1/2',
  '12 in pvc',
  '12 in abs',
  '12 in cast',
];

const _plumbingAlwaysCoreServiceSignals = [
  'angle stop',
  'push angle stop',
  'supply stop',
  'shutoff',
  't&p valve',
  'tpr valve',
  'relief valve',
  'water heater connector',
  'water heater supply connector',
  'vacuum breaker',
  'hose bibb',
  'sillcock',
  'frost-free sillcock',
  'anti siphon',
  'pipe dope',
  'pipe joint compound',
  'thread sealant',
  'o-ring',
  'o ring',
  'crimp ring',
  'clamp ring',
  'cinch ring',
  'toilet seat bolt',
  'shower cartridge',
  'shower valve trim kit',
];

const _plumbingCoreValveAndWaterHeaterSignals = [
  'angle stop',
  'ball valve',
  'hose bibb',
  'sillcock',
  'vacuum breaker',
  't&p valve',
  'tpr valve',
  'relief valve',
  'water heater connector',
  'water heater supply connector',
  'drain valve',
];

const _plumbingCoreFittingMaterialSignals = [
  'pex',
  'push-fit',
  'cpvc',
  'copper',
  'pvc schedule 40',
  'pvc dwv',
  'brass',
];

const _plumbingCoreFittingFamilySignals = [
  '90 elbow',
  '45 elbow',
  'tee',
  'wye',
  'sanitary tee',
  'coupling',
  'adapter',
  'mip adapter',
  'fip adapter',
  'sxm adapter',
  'sxf adapter',
  'male adapter',
  'female adapter',
  'trap adapter',
  'stop',
  'angle stop',
  'drop-ear',
  'drop ear',
  'bushing',
  'cleanout',
  'test tee',
  'crimp ring',
  'clamp ring',
  'cinch ring',
];

const _plumbingCoreFittingSizeSignals = [
  '3/8',
  '1/2',
  '3/4',
  '1 in',
  '1 x',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
  '4 in',
];

const _plumbingCoreDrainServiceSignals = [
  'p-trap',
  'p trap',
  'sink trap',
  'tailpiece',
  'extension tube',
  'slip nut',
  'slip joint',
  'slip joint washer',
  'basket strainer',
  'sink drain',
  'drain stopper',
  'trap adapter',
  'trap washer',
  'disposal drain',
];

const _plumbingCoreDrainFinishSignals = [
  'dishwasher',
  'dishwasher drain',
  'dishwasher hose',
  'disposal',
  'air gap',
  'splash guard',
  'trap adapter',
  'marvel adapter',
  'desanco',
  'compression trap adapter',
  'cleanout',
  'closet flange',
  'flange repair',
  'closet bolt',
  'toilet seat bolt',
  'escutcheon',
  'tailpiece',
  'extension tube',
  'slip nut',
  'slip joint',
  'slip joint washer',
  'basket strainer',
  'sink drain',
  'drain stopper',
];

const _plumbingCoreSealServiceSignals = [
  'flush valve seal',
  'tank gasket',
  'tank to bowl',
  'tank bolt',
  'fill valve shank washer',
  'toilet supply shank washer',
  'wax ring',
  'o-ring',
  'o ring',
  'packing',
  'pipe joint compound',
  'thread sealant',
];

const _plumbingCoreSupportSignals = [
  'pipe strap',
  'pipe j-hook',
  'j-hook',
  'stud guard',
  'nail plate',
  'pipe insulation',
  'bell hanger',
  'split ring',
];

const _residentialSupplySizes = ['1/2', '3/4', '1 in', '3/8', '5/8'];

const _coreDrainSizes = ['1-1/4', '1-1/2', '2 in', '3 in', '4 in'];

const _standardPlumbingSizes = [
  '1/4',
  '3/8',
  '1/2',
  '3/4',
  '1 in',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
];

const _standardExpandedResidentialSizes = [
  '1/4',
  '3/8',
  '1/2',
  '3/4',
  '1 in',
  '1 x',
  '1-1/4',
  '1-1/2',
  '2 in',
  '3 in',
];

const _coreFittingTypes = [
  '90 elbow',
  'elbow',
  'tee',
  'coupling',
  'adapter',
  'cap',
  'plug',
  'cleanout',
  'valve',
  'stop',
  'trap',
  'washer',
  'ring',
];

const _standardFittingTypes = [
  'male adapter',
  'female adapter',
  'transition',
  'union',
  'bushing',
  'reducer',
  'nipple',
  'flange',
  'cleanout',
  'repair',
  'tailpiece',
];

const _standardExpandedFittingTypes = [
  '90 elbows',
  '45 elbows',
  'tees',
  'couplings',
  'reducing couplings',
  'caps',
  'male adapters',
  'female adapters',
  'reducer bushings',
  'wyes',
  'sanitary tees',
  'cleanouts',
];

const _standardResidentialSystems = [
  'brass',
  'black iron',
  'galvanized',
  'copper',
  'pvc',
  'pex',
  'cpvc',
  'dwv',
];

const _standardExpandedResidentialSystems = [
  'brass',
  'copper',
  'pvc schedule 40',
  'pvc dwv',
  'pex',
  'cpvc',
  'push-fit',
];

const _plumbingLightIndustrialSignals = [
  '2 in',
  '3 in',
  '4 in',
  'backflow',
  'boiler',
  'hydronic',
  'pump',
  'well',
  'black iron',
  'galvanized',
  'cast iron',
  'no-hub',
  'dwv',
  'commercial',
];

const _plumbingCommercialOverlapSignals = [
  '3 in',
  '4 in',
  '6 in',
  '8 in',
  'cast iron',
  'no-hub',
  'black iron',
  'galvanized',
  'dwv',
  'backflow',
  'boiler',
  'hydronic',
  'flushometer',
  'commercial',
];
