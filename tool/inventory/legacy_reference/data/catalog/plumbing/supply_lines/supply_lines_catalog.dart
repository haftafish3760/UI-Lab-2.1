part of '../../../work_supply_catalog.dart';

final plumbingSupplyLinesCategory = _category('Supply Lines', [
  _system('Fixture Connectors', [
    _type(
      'Faucet Connectors',
      _variants(
        'Faucet Supply Line',
        'each',
        [
          '3/8 x 12 in',
          '3/8 x 16 in',
          '3/8 x 20 in',
          '3/8 x 24 in',
          '1/2 x 16 in',
          '1/2 x 20 in',
        ],
        ['braided line', 'lav supply', 'faucet connector'],
      ),
    ),
    _type(
      'Toilet Connectors',
      _variants(
        'Toilet Supply Line',
        'each',
        ['3/8 x 9 in', '3/8 x 12 in', '3/8 x 16 in', '3/8 x 20 in'],
        ['closet line', 'toilet connector'],
      ),
    ),
    _type(
      'Appliance Connectors',
      _variants(
        'Appliance Supply Line',
        'each',
        ['1/4 x 10 ft', '3/8 x 60 in', '3/4 x 5 ft'],
        ['icemaker line', 'dishwasher line', 'washer hose'],
      ),
    ),
    _type(
      'Ice Maker Lines',
      _variants(
        'Ice Maker Supply Line',
        'each',
        ['1/4 x 10 ft', '1/4 x 15 ft', '1/4 x 25 ft'],
        [
          'ice maker line',
          'icemaker line',
          'refrigerator water line',
          'fridge water line',
          'poly ice maker line',
        ],
      ),
    ),
    _type(
      'Washing Machine Hoses',
      _variants(
        'Washing Machine Hose',
        'each',
        ['3/4 x 4 ft', '3/4 x 5 ft', '3/4 x 6 ft'],
        [
          'washer hose',
          'washing machine line',
          'washer supply hose',
          'laundry hose',
        ],
      ),
    ),
    _type(
      'Gas Appliance Connectors',
      _variants(
        'Gas Appliance Connector',
        'each',
        [
          '1/2 x 24 in',
          '1/2 x 36 in',
          '1/2 x 48 in',
          '5/8 x 24 in',
          '5/8 x 36 in',
        ],
        ['gas flex', 'gas connector'],
      ),
    ),
  ]),
]);
