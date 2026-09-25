import 'package:flutter/services.dart';

/// Formats the owner's current US phone entry contract without losing pasted
/// country prefixes or moving the caret to the end on every edit.
class UsPhoneInputFormatter extends TextInputFormatter {
  const UsPhoneInputFormatter();
  static String digits(String text) {
    var result = text.replaceAll(RegExp(r'\D'), '');
    if (result.length == 11 && result.startsWith('1')) {
      result = result.substring(1);
    }
    return result;
  }

  static String format(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 3) return '($value';
    if (value.length <= 6) {
      return '(${value.substring(0, 3)}) ${value.substring(3)}';
    }
    return '(${value.substring(0, 3)}) ${value.substring(3, 6)}-${value.substring(6)}';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    var value = digits(newValue.text);
    // Backspacing over an inserted separator must remove the preceding digit,
    // rather than reinserting the separator and trapping the caret.
    if (newValue.text.length < oldValue.text.length &&
        value == digits(oldValue.text) &&
        oldValue.selection.isCollapsed &&
        newValue.selection.isCollapsed) {
      final caret = newValue.selection.extentOffset.clamp(
        0,
        newValue.text.length,
      );
      final before = newValue.text
          .substring(0, caret)
          .replaceAll(RegExp(r'\D'), '')
          .length;
      if (before > 0) {
        value = value.substring(0, before - 1) + value.substring(before);
      }
    }
    if (value.length > 10) return oldValue;
    final formatted = format(value);
    final end = newValue.selection.extentOffset.clamp(0, newValue.text.length);
    var before = newValue.text
        .substring(0, end)
        .replaceAll(RegExp(r'\D'), '')
        .length;
    if (newValue.text.replaceAll(RegExp(r'\D'), '').length == 11 && before > 0) {
      before--;
    }
    var caret = 0;
    for (var seen = 0; caret < formatted.length && seen < before; caret++) {
      if (RegExp(r'\d').hasMatch(formatted[caret])) seen++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}
