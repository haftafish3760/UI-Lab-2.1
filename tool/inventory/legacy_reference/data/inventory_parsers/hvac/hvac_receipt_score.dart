part of '../../work_supply_receipt_parser.dart';

/// Combines the focused HVAC receipt scoring domains.
int _hvacReceiptScore(String text, String trade, WorkSupplyItem item) {
  if (trade != 'hvac') return 0;
  return _hvacEquipmentAndAirFilterReceiptScore(text, item) +
      _hvacAirDistributionAndGasReceiptScore(text, item) +
      _hvacServiceEquipmentAndToolReceiptScore(text, item);
}
