part of 'work_supply_receipt_parser.dart';

int _tradeContextScore(String text, WorkSupplyItem item) {
  final trade = item.trade.toLowerCase();
  final category = item.category.toLowerCase();
  final system = item.system.toLowerCase();
  var score = 0;
  score += _carpentryReceiptScore(text, category, system, item);
  score += _cabinetsCountertopsReceiptScore(text, trade, category, item);
  score += _windowsDoorsReceiptScore(text, trade, category, item);
  score += _garageDoorsOpenersReceiptScore(text, trade, category, item);
  score += _applianceInstallationRepairReceiptScore(
    text,
    trade,
    category,
    item,
  );
  score += _wellSepticWaterTreatmentReceiptScore(text, trade, category, item);
  score += _electricalReceiptScore(text, trade, category, system, item);
  score += _plumbingReceiptScore(text, trade, category, system, item);
  score += _hvacReceiptScore(text, trade, item);
  score += _drywallReceiptScore(text, trade, category, item);
  score += _paintingReceiptScore(text, trade, category, item);
  score += _roofingReceiptScore(text, trade, category, item);
  score += _tileReceiptScore(text, trade, category, item);
  score += _flooringReceiptScore(text, trade, category, item);
  score += _insulationReceiptScore(text, trade, category, item);
  score += _sidingExteriorReceiptScore(text, trade, category, item);
  score += _fencingReceiptScore(text, trade, category, item);
  score += _masonryConcreteReceiptScore(text, trade, category, item);
  score += _landscapingReceiptScore(text, trade, category, item);
  score += _lowVoltageDataReceiptScore(text, trade, category, item);
  score += _toolsSafetyReceiptScore(text, trade, category, item);
  return score;
}
