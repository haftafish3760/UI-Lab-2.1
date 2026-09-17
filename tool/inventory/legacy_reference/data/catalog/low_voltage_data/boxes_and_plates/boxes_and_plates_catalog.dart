part of '../../../work_supply_catalog.dart';

final lowVoltageDataBoxesAndPlatesCategory = _category('Boxes and Plates', [
  _system('Low Voltage Boxes', [
    _type(
      'Low Voltage Mounting Bracket',
      _variants(
        'Low Voltage Mounting Bracket',
        'each',
        ['1 gang', '2 gang', '3 gang'],
        ['mud ring', 'lv bracket'],
      ),
    ),
    _type(
      'Media Enclosure',
      _variants(
        'Structured Media Enclosure',
        'each',
        ['14 in', '28 in', '42 in'],
        ['media panel'],
      ),
    ),
  ]),
  _system('Wall Plates', [
    _type(
      'Keystone Wall Plate',
      _variants(
        'Keystone Wall Plate',
        'each',
        ['1 port', '2 port', '4 port', '6 port'],
        ['data plate'],
      ),
    ),
  ]),
]);
