part of 'work_supply_catalog.dart';

bool _isHvacSpecialtyCategoryForCore(WorkSupplyItem item, String text) {
  final category = item.category.toLowerCase();
  if (category.startsWith('pro hvac') && text.contains('service valve cap')) {
    return false;
  }
  return category.startsWith('pro hvac') ||
      category.contains('rooftop and package unit') ||
      category.contains('hydronic and boiler');
}
