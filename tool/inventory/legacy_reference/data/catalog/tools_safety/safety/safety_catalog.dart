part of '../../../work_supply_catalog.dart';

final toolsSafetySafetyCategory = _category('Safety', [
  _system('PPE', [
    _type(
      'Gloves',
      _variants(
        'Work Gloves',
        'pair',
        ['medium', 'large', 'x-large'],
        ['safety gloves'],
      ),
    ),
    _type(
      'Disposable Gloves',
      _variants(
        'Nitrile Disposable Gloves',
        'box',
        ['medium 100 count', 'large 100 count', 'x-large 100 count'],
        ['nitrile gloves', 'disposable gloves'],
      ),
    ),
    _type(
      'Eye Protection',
      _variants(
        'Safety Glasses',
        'pair',
        ['clear', 'tinted', 'anti-fog'],
        ['eye pro'],
      ),
    ),
  ]),
]);
