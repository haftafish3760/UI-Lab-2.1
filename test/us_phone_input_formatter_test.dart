import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/shared/us_phone_input_formatter.dart';

void main() {
  const formatter = UsPhoneInputFormatter();
  TextEditingValue value(String text) => TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
  test('pasted national and country-prefixed numbers format consistently', () {
    for (final text in ['5551234567', '+1 (555) 123-4567']) {
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, value(text)).text,
        '(555) 123-4567',
      );
    }
  });
  test('overlong number is rejected without changing existing input', () {
    final old = value('(555) 123-4567');
    expect(formatter.formatEditUpdate(old, value('(555) 123-45678')), old);
  });
  test(
    'backspace over separator deletes a digit instead of trapping caret',
    () {
      final old = const TextEditingValue(
        text: '(555) 123-4567',
        selection: TextSelection.collapsed(offset: 10),
      );
      final edited = const TextEditingValue(
        text: '(555) 1234567',
        selection: TextSelection.collapsed(offset: 9),
      );
      expect(
        UsPhoneInputFormatter.digits(
          formatter.formatEditUpdate(old, edited).text,
        ),
        '555124567',
      );
    },
  );
}
