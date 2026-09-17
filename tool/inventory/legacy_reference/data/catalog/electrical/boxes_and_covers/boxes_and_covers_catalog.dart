part of '../../../work_supply_catalog.dart';

final electricalBoxesAndCoversCategory = _category('Boxes and Covers', [
  _system('Electrical Boxes', [
    _type(
      'Device Boxes',
      _variants(
        'Device Box',
        'each',
        ['1 gang', '2 gang', '3 gang', '4 gang'],
        ['switch box'],
      ),
    ),
    _type(
      'Junction Boxes',
      _variants(
        'Junction Box',
        'each',
        ['4 in square', '4-11/16 in square', 'round'],
        ['j box'],
      ),
    ),
  ]),
  _system('Covers', [
    _type(
      'Device Covers',
      _variants(
        'Device Cover Plate',
        'each',
        ['1 gang', '2 gang', '3 gang', '4 gang'],
        ['wall plate'],
      ),
    ),
    _type(
      'Blank Covers',
      _variants(
        'Blank Cover',
        'each',
        ['1 gang', '4 in square', '4-11/16 in square'],
        ['blank plate'],
      ),
    ),
  ]),
]);
