part of '../../../work_supply_catalog.dart';

final drywallCompoundAndMudCategory = _category('Compound and Mud', [
  _system('Premixed Compound', [
    _type(
      'All Purpose Joint Compound',
      _variants(
        'All Purpose Joint Compound',
        'bucket',
        ['1 gal', '3.5 gal', '4.5 gal', '5 gal'],
        ['mud', 'drywall mud'],
      ),
    ),
    _type(
      'Lightweight Joint Compound',
      _variants(
        'Lightweight Joint Compound',
        'bucket',
        ['1 gal', '3.5 gal', '4.5 gal', '5 gal'],
        ['plus 3 mud', 'lightweight mud'],
      ),
    ),
    _type(
      'Topping Compound',
      _variants(
        'Topping Compound',
        'bucket',
        ['3.5 gal', '4.5 gal', '5 gal'],
        ['finish mud'],
      ),
    ),
  ]),
  _system('Setting Compound', [
    _type(
      'Hot Mud',
      _variants(
        'Setting Type Joint Compound',
        'bag',
        ['5 min 18 lb', '20 min 18 lb', '45 min 18 lb', '90 min 18 lb'],
        ['quick set mud', 'easy sand'],
      ),
    ),
  ]),
]);
