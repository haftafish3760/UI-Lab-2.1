part of 'work_supply_catalog.dart';

bool _hasExactElectricalSize(String text, Iterable<String> sizes) {
  return sizes.any((size) {
    final escaped = RegExp.escape(size);
    return RegExp(
      '(?<![0-9/-])$escaped(?:\\s*(?:in|inch|"))?(?![0-9/-])',
    ).hasMatch(text);
  });
}

bool _isCommonElectricalWallPlate(WorkSupplyItem item) {
  final variant = item.variant.toLowerCase();
  if (!_hasAny(variant, const ['1 gang', '2 gang', '3 gang'])) return false;
  if (!_hasAny(variant, const ['white', 'ivory', 'light almond'])) return false;
  if (item.itemType == 'Bulk Covers and Wall Plates') {
    return variant.contains('nylon');
  }
  return true;
}

bool _isCommonElectricalCableRoll(WorkSupplyItem item) {
  final variant = item.variant.toLowerCase();
  if (_hasAny(variant, const ['250 ft', '500 ft'])) return false;
  if (item.itemType == 'Expanded THHN Copper Wire Rolls') {
    return _hasAny(variant, const ['black', 'white', 'red', 'green']);
  }
  return true;
}

bool _isCommonElectricalFlexibleRaceway(WorkSupplyItem item) {
  final text = item.variant.toLowerCase();
  return _hasExactElectricalSize(text, const ['3/8', '1/2', '3/4', '1']);
}

bool _isCommonElectricalPhotocell(WorkSupplyItem item) {
  final variant = item.variant.toLowerCase();
  return variant.contains('120v') &&
      _hasAny(variant, const ['15 amp', '20 amp']);
}

bool _isCommonElectricalConduitBody(WorkSupplyItem item) {
  final variant = item.variant.toLowerCase();
  if (!_hasExactElectricalSize(variant, const ['1/2', '3/4', '1'])) {
    return false;
  }
  return RegExp(r'\blb body\b').hasMatch(variant);
}
