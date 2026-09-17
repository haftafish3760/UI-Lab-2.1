part of '../../../work_supply_catalog.dart';

final masonryConcreteConcreteCategory = _category('Concrete', [
  _system('Bagged Mix', [
    _type(
      'Concrete Mix',
      _variants(
        'Concrete Mix',
        'bag',
        ['40 lb', '60 lb', '80 lb'],
        ['ready mix concrete'],
      ),
    ),
    _type(
      'Mortar Mix',
      _variants('Mortar Mix', 'bag', ['60 lb', '80 lb'], ['mortar']),
    ),
  ]),
]);
