import '../expenses/expense_itemization.dart';
import 'receipt_reading_rows.dart';

/// A printed purchase candidate. Every field still requires human review.
/// Package contents and stock quantity are deliberately not inferred here.
class ReceiptItemProposal {
  ReceiptItemProposal({
    required this.id,
    required this.description,
    required List<ReceiptReadingRow> sourceRows,
    this.quantity,
    this.purchaseUnit,
    this.unitPrice,
    this.lineTotalMinor,
    this.calculatedTotalMinor,
    List<String> warnings = const [],
  }) : sourceRows = List.unmodifiable(sourceRows),
       warnings = List.unmodifiable(warnings);
  final String id, description;
  final ExpenseDecimalValue? quantity, unitPrice;
  final String? purchaseUnit;
  final int? lineTotalMinor, calculatedTotalMinor;
  final List<ReceiptReadingRow> sourceRows;
  final List<String> warnings;
}

class ReceiptItemParseResult {
  ReceiptItemParseResult({
    required List<ReceiptItemProposal> items,
    required List<ReceiptReadingRow> unresolvedRows,
  }) : items = List.unmodifiable(items),
       unresolvedRows = List.unmodifiable(unresolvedRows);
  final List<ReceiptItemProposal> items;

  /// Includes adjustments and unsupported money rows; never silently adopted.
  final List<ReceiptReadingRow> unresolvedRows;
}
