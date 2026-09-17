part of '../../work_supply_receipt_parser.dart';

/// Dispatches HVAC core receipt matching to clearly scoped parser files.
WorkSupplyItem? _directHvacCoreMatch(String text, {String? tradeScope}) {
  if (tradeScope == null ||
      tradeScope.trim().isEmpty ||
      tradeScope.trim().toLowerCase() != 'hvac') {
    return null;
  }
  return _directHvacAirDrainAndDuctMatch(text) ??
      _directHvacEquipmentAndServicePartsMatch(text);
}
