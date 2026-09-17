part of '../../work_supply_receipt_parser.dart';

bool _isReceiptNoiseLine(String text) {
  return RegExp(
        r'^(subtotal|sub total|total|sales tax|tax|cash|change|card approved|'
        r'credit card|debit card|visa|mastercard|amex|discover|approval|'
        r'balance due|amount due)(\s+\d+(?:\.\d{2})?)?$',
      ).hasMatch(text) ||
      RegExp(
        r'^(subtotal|sub total|total|sales tax|tax|cash|change|'
        r'card approved|credit card|debit card|visa|mastercard|amex|'
        r'discover|approval|balance due|amount due)'
        r'(\s+\d+(?:\s+\d{2})?)?$',
      ).hasMatch(text) ||
      RegExp(
        r'^(visa|mastercard|amex|discover|credit card|debit card)\s+'
        r'approved(?:\s+auth)?\s+\d+$',
      ).hasMatch(text) ||
      RegExp(r'^cashier\s+\d+\s+reg\s+\d+\s+thank\s+you$').hasMatch(text) ||
      RegExp(r'\b(?:promo|promotion|coupon|discount|savings)\b').hasMatch(text);
}
