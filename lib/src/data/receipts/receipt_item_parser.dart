import '../expenses/expense_itemization.dart';
import 'receipt_item_proposal.dart';
import 'receipt_photo_text.dart';
import 'receipt_reading_rows.dart';

const receiptItemParserVersion = 'structural-items-v2';

/// Structural, local parsing only: no merchant profiles, catalog or generator.
/// Unknown quantity is not one. A missing line amount is not the receipt total.
ReceiptItemParseResult proposeReceiptItems(
  ReceiptPhotoText source, {
  required String sourceId,
}) {
  final rows = receiptRowsWithEvidence(source);
  final items = <ReceiptItemProposal>[];
  final unresolved = <ReceiptReadingRow>[];
  final pending = <ReceiptReadingRow>[];
  var summaryStarted = false;
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final text = row.text;
    if (_summary.hasMatch(text)) {
      unresolved.addAll(pending);
      pending.clear();
      summaryStarted = true;
      continue;
    }
    if (_administrative.hasMatch(text) ||
        _tender.hasMatch(text) ||
        _separator.hasMatch(text)) {
      unresolved.addAll(pending);
      pending.clear();
      continue;
    }
    if (_adjustment.hasMatch(text)) {
      unresolved.addAll(pending);
      unresolved.add(row);
      pending.clear();
      continue;
    }
    if (summaryStarted) {
      if (_money.hasMatch(text)) unresolved.add(row);
      continue;
    }
    // A measured-fuel block can prove volume and price, but its final receipt
    // total cannot prove a printed fuel line total (other purchases may exist).
    final volume = _fuelVolume.firstMatch(text);
    if (volume != null && index + 1 < rows.length && pending.length == 1) {
      final priceRow = rows[index + 1];
      final price = _fuelPrice.firstMatch(priceRow.text);
      if (price != null && _fuelUnit(volume[1]!) == _fuelUnit(price[1]!)) {
        final quantity = _decimal(volume[2]!);
        final unitPrice = _decimal(price[2]!);
        if (quantity != null && !quantity.isZero && unitPrice != null) {
          items.add(
            ReceiptItemProposal(
              id: '$sourceId:item:${pending.first.index}',
              description: pending.single.text,
              sourceRows: [...pending, row, priceRow],
              quantity: quantity,
              purchaseUnit: _fuelUnit(volume[1]!),
              unitPrice: unitPrice,
              calculatedTotalMinor: _multiplyMinor(quantity, unitPrice),
              warnings: const [
                'Check the fuel amount; no separate line total was found.',
              ],
            ),
          );
          pending.clear();
          index++;
          continue;
        }
      }
    }
    if (volume != null || _fuelPrice.hasMatch(text)) {
      unresolved.addAll([...pending, row]);
      pending.clear();
      continue;
    }
    final explicit = _quantityPrice.firstMatch(text);
    if (explicit != null) {
      final rawPrefix = text.substring(0, explicit.start).trim();
      final prefix =
          RegExp(r'^qty\s*[:=]?$', caseSensitive: false).hasMatch(rawPrefix)
          ? ''
          : rawPrefix;
      final description = prefix.isEmpty
          ? pending.map((r) => r.text).join(' ')
          : prefix;
      final quantity = _decimal(explicit[1]!);
      final price = _decimal(explicit[3]!);
      final amount = _minor(explicit[4]!);
      if (description.isNotEmpty &&
          quantity != null &&
          !quantity.isZero &&
          price != null &&
          amount != null) {
        final calculated = _multiplyMinor(quantity, price);
        items.add(
          ReceiptItemProposal(
            id: '$sourceId:item:${prefix.isEmpty ? pending.first.index : row.index}',
            description: description,
            sourceRows: [if (prefix.isEmpty) ...pending, row],
            quantity: quantity,
            purchaseUnit: explicit[2],
            unitPrice: price,
            lineTotalMinor: amount,
            calculatedTotalMinor: calculated,
            warnings: [
              if (calculated != amount)
                'Quantity and price do not match the printed amount. Check this item.',
              if (explicit[2] == null) 'Confirm the purchase unit.',
            ],
          ),
        );
      } else {
        unresolved.addAll([...pending, row]);
      }
      pending.clear();
      continue;
    }
    final money = _money.firstMatch(text);
    if (money != null) {
      final prefix = text.substring(0, money.start).trim();
      final description = prefix.isEmpty
          ? pending.map((r) => r.text).join(' ')
          : prefix;
      final amount = _minor(money[1]!);
      // Multiple amounts without explicit quantity syntax are ambiguous.
      if (description.isNotEmpty &&
          amount != null &&
          !_numberMoney.hasMatch(description) &&
          !_fuelPrice.hasMatch(text)) {
        items.add(
          ReceiptItemProposal(
            id: '$sourceId:item:${prefix.isEmpty ? pending.first.index : row.index}',
            description: description,
            sourceRows: [if (prefix.isEmpty) ...pending, row],
            lineTotalMinor: amount,
            warnings: const ['Confirm quantity, purchase unit and unit price.'],
          ),
        );
      } else {
        unresolved.addAll([...pending, row]);
      }
      pending.clear();
      continue;
    }
    if (_fuelVolume.hasMatch(text) ||
        _fuelPrice.hasMatch(text) ||
        RegExp(r'\d+[,.]\d+').hasMatch(text)) {
      unresolved.addAll([...pending, row]);
      pending.clear();
      continue;
    }
    if (RegExp(r'[A-Za-z]').hasMatch(text)) {
      pending.add(row);
      // A large header/paragraph is not a proven wrapped item description.
      if (pending.length > 2) {
        unresolved.add(pending.removeAt(0));
      }
    }
  }
  unresolved.addAll(pending);
  return ReceiptItemParseResult(items: items, unresolvedRows: unresolved);
}

final _separator = RegExp(r'^[-=_*\s]+$');
final _administrative = RegExp(
  r'^(?:(?:receipt|invoice|date|time|cashier|register|terminal|pump|auth)\s*(?:no\.?|number|id|#|:|=)?\s*[\d:./ -]+$|thank\b|total\s+items\b|\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{2,4})',
  caseSensitive: false,
);
final _tender = RegExp(
  r'^(?:card(?:\s+payment)?|cash|change|visa|mastercard|eftpos|amount\s+paid|tendered)(?:\s+[*\d]+)?\s*[:=]?\s*\$?\d+(?:,\d{3})*\.\d{2}(?:\s+[A-Z]{3})?$',
  caseSensitive: false,
);
final _summary = RegExp(
  r'^(?:sub\s*total|grand\s+total|total(?:\s+due)?|amount\s+due|sales\s+tax|tax)\s*[:=]?\s*\$?-?[\d,.]+(?:\s+[A-Z]{3})?$',
  caseSensitive: false,
);
final _adjustment = RegExp(
  r'^(?:discount|coupon|savings|refund|deposit|fee)\b|^(?:return|tip)\s*[:=]?\s*\$?[\d,.]+$|^\d+(?:\.\d+)?%\s*(?:off|discount)\b|^-\s*\$?\d',
  caseSensitive: false,
);
const _amount = r'(\d+(?:,\d{3})*\.\d{2})';
final _money = RegExp(
  r'(?<![\d.,-])\$?' + _amount + r'\s*(?:USD|CAD|AUD)?$',
  caseSensitive: false,
);
final _numberMoney = RegExp(r'\d+[.,]\d{2}\b');
final _quantityPrice = RegExp(
  r'(?<![\w./-])(\d+(?:\.\d{1,6})?)\s*(?:([A-Za-z]+)\s+)?(?:x|@)\s*\$?(\d+(?:\.\d{1,6})?)\s+(?:=\s*)?\$?' +
      _amount +
      r'\s*(?:USD|CAD|AUD)?$',
  caseSensitive: false,
);
final _fuelVolume = RegExp(
  r'^(gallons?|gal|liters?|litres?|l)\s*[:=]?\s+(\d+(?:\.\d{1,6})?)$',
  caseSensitive: false,
);
final _fuelPrice = RegExp(
  r'^price\s+per\s+(gallon|gal|liter|litre|l)\s*[:=]?\s+\$?(\d+(?:\.\d{1,6})?)$',
  caseSensitive: false,
);
String _fuelUnit(String text) =>
    text.toLowerCase().startsWith('g') ? 'gallon' : 'liter';
ExpenseDecimalValue? _decimal(String text) {
  if (!RegExp(r'^\d{1,9}(?:\.\d{1,6})?$').hasMatch(text)) return null;
  try {
    return ExpenseDecimalValue.fromDecimalString(text);
  } on FormatException {
    return null;
  }
}

int? _minor(String text) {
  final value = _decimal(text.replaceAll(',', ''));
  if (value == null || value.scale > 2) return null;
  return value.unscaledValue *
      (value.scale == 0
          ? 100
          : value.scale == 1
          ? 10
          : 1);
}

int? _multiplyMinor(ExpenseDecimalValue quantity, ExpenseDecimalValue price) {
  final product =
      BigInt.from(quantity.unscaledValue) *
      BigInt.from(price.unscaledValue) *
      BigInt.from(100);
  final divisor = BigInt.from(10).pow(quantity.scale + price.scale);
  final rounded = (product + divisor ~/ BigInt.two) ~/ divisor;
  if (rounded > BigInt.from(99999999999)) return null;
  return rounded.toInt();
}
