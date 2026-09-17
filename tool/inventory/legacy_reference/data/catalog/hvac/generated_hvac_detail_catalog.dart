part of '../../work_supply_catalog.dart';

final hvacGeneratedDetailCatalogCategory = _category(
  'Pro HVAC Detail Expansion Stock',
  [
    _system('Filter IAQ and Return Air Detail', [
      _type('Expanded Filter Size Detail', _hvacDetailFilterProducts()),
      _type('Humidifier UV and IAQ Detail', _hvacDetailIaqProducts()),
    ]),
    _system('Duct Fabrication and Air Distribution Detail', [
      _type('Round Sheet Metal Fitting Detail', _hvacDetailRoundDuctProducts()),
      _type(
        'Register Grille Boot Detail',
        _hvacDetailAirDistributionProducts(),
      ),
      _type(
        'Rectangular Trunk Plenum Detail',
        _hvacDetailTrunkPlenumProducts(),
      ),
    ]),
    _system('HVAC Electrical and Control Detail', [
      _type('Capacitor Contactor Relay Detail', _hvacDetailControlProducts()),
      _type(
        'Disconnect Whip and Low Voltage Detail',
        _hvacDetailElectricalProducts(),
      ),
    ]),
    _system('Refrigerant Mini Split and Condensate Detail', [
      _type('Line Set and Mini Split Detail', _hvacDetailLineSetProducts()),
      _type('Condensate Pump Drain Detail', _hvacDetailCondensateProducts()),
    ]),
    _system('Furnace Heat Service Detail', [
      _type('Ignition Sensor and Switch Detail', _hvacDetailFurnaceProducts()),
      _type('Motor Blower and Fan Detail', _hvacDetailMotorProducts()),
    ]),
    _system('HVAC Consumables and Service Tools Detail', [
      _type('Cleaner Sealant and Tape Detail', _hvacDetailConsumableProducts()),
      _type('Refrigerant Tool Accessory Detail', _hvacDetailToolProducts()),
    ]),
  ],
);

List<WorkSupplyItem> _hvacDetailProducts({
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
