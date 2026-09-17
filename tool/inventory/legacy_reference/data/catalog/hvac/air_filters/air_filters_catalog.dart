part of '../../../work_supply_catalog.dart';

final hvacAirFiltersCategory = _category('Air Filters', [
  _system('Pleated Filters', [
    _type(
      'Return Filters',
      _variants('Pleated Air Filter', 'each', _filterSizes, [
        'furnace filter',
        'ac filter',
      ]),
    ),
  ]),
]);
