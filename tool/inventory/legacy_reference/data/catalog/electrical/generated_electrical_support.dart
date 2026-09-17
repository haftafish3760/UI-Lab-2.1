part of '../../work_supply_catalog.dart';

List<WorkSupplyItem> _electricalProducts({
  required String baseName,
  required String unit,
  required List<String> variants,
  required List<String> aliases,
}) {
  return [
    for (final variant in variants)
      WorkSupplyItem(
        id: '',
        name: '$variant $baseName',
        trade: '',
        category: '',
        system: '',
        itemType: '',
        variant: variant,
        unit: unit,
        aliases: aliases,
      ),
  ];
}

const _electricalNmbCableSizes = [
  '14/2',
  '14/3',
  '12/2',
  '12/3',
  '10/2',
  '10/3',
  '8/2',
  '8/3',
  '6/2',
  '6/3',
];

const _electricalUfbCableSizes = [
  '14/2',
  '14/3',
  '12/2',
  '12/3',
  '10/2',
  '10/3',
  '8/2',
  '6/2',
];

const _electricalCommonCableLengths = [
  '25 ft',
  '50 ft',
  '100 ft',
  '250 ft',
  '500 ft',
];

const _electricalThhnGauges = [
  '14 AWG',
  '12 AWG',
  '10 AWG',
  '8 AWG',
  '6 AWG',
  '4 AWG',
  '3 AWG',
  '2 AWG',
];

const _electricalLargeWireSizes = [
  '1 AWG',
  '1/0 AWG',
  '2/0 AWG',
  '3/0 AWG',
  '4/0 AWG',
  '250 kcmil',
  '300 kcmil',
  '350 kcmil',
  '400 kcmil',
  '500 kcmil',
];

const _electricalWireColors = [
  'Black',
  'White',
  'Red',
  'Blue',
  'Green',
  'Brown',
  'Orange',
  'Yellow',
];

const _electricalBulkWireColors = [
  'Black',
  'White',
  'Red',
  'Blue',
  'Green',
  'Brown',
  'Orange',
  'Yellow',
  'Gray',
  'Purple',
];

const _electricalServiceCableSizes = [
  '6/3',
  '4/3',
  '2/3',
  '1/0-3',
  '2/0-3',
  '4/0-3',
];

const _electricalDeviceColors = [
  'White',
  'Ivory',
  'Light Almond',
  'Gray',
  'Black',
];

const _electricalBulkDeviceColors = [
  'White',
  'Ivory',
  'Light Almond',
  'Gray',
  'Black',
  'Brown',
];

const _electricalEmtParts = [
  '10 ft Conduit',
  'Set Screw Connector',
  'Compression Connector',
  'Set Screw Coupling',
  'Compression Coupling',
  'One Hole Strap',
  'Two Hole Strap',
  '90 Elbow',
  'Pull Elbow',
  'Insulated Bushing',
];

const _electricalPvcRacewayParts = [
  '10 ft Conduit',
  '90 Elbow',
  '45 Elbow',
  'Coupling',
  'Male Terminal Adapter',
  'Female Adapter',
  'Expansion Coupling',
  'Junction Box Adapter',
  'Conduit Strap',
  'LB Conduit Body',
  'Pull Box',
];

const _electricalBulkRacewaySizes = [
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
