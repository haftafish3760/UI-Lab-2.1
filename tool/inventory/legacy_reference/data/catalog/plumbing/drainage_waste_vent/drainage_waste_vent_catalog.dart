part of '../../../work_supply_catalog.dart';

final plumbingDrainageWasteVentCategory = _category('Drainage Waste Vent', [
  _system('Tubular Drain', [
    _type(
      'Traps',
      _variants(
        'Tubular P-Trap',
        'each',
        ['1-1/4 in', '1-1/2 in'],
        ['p trap', 'sink trap'],
      ),
    ),
    _type(
      'Tailpieces',
      _variants('Tailpiece', 'each', _tubularSizes, [
        'sink tailpiece',
        'lav tailpiece',
      ]),
    ),
    _type(
      'Trap Adapters',
      _variants(
        'Trap Adapter',
        'each',
        ['1-1/4 in', '1-1/2 in', '2 in'],
        ['trap adaptor'],
      ),
    ),
    _type(
      'Extension Tubes',
      _variants('Tubular Extension Tube', 'each', _tubularSizes, [
        'extension tube',
        'tailpiece extension',
      ]),
    ),
    _type(
      'Slip Joint Nuts and Washers',
      _variants(
        'Slip Joint Nut and Washer',
        'each',
        ['1-1/4 in', '1-1/2 in'],
        ['slip nut', 'slip washer', 'trap washer'],
      ),
    ),
    _type(
      'Disposal Drain Parts',
      _variants(
        'Disposal Drain Elbow',
        'each',
        ['1-1/2 in'],
        ['disposal elbow', 'garbage disposal drain'],
      ),
    ),
  ]),
]);
