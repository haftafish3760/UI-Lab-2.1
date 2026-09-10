import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/expenses/expense_line_draft_input.dart';

void main() {
  test('legacy unfinished line preserves raw input and edit identity', () {
    final legacy = <String, Object?>{
      'editingId': 'existing-line',
      'input': <String, Object?>{
        'itemId': 'existing-line',
        'category': 'materials',
        'unit': 'box',
        'description': ' Unfinished part ',
        'partNumber': 'SKU-',
        'quantity': '1.',
        'unitsPerPackage': '',
        'unitPrice': '12.',
        'jobId': 'job-a',
        'jobLabel': 'Original job',
      },
    };
    final restored = PendingExpenseLineInput.fromPayload(legacy);
    expect(restored.editingId, 'existing-line');
    expect(restored.input.itemId, 'existing-line');
    expect(restored.input.quantity, '1.');
    expect(restored.input.unitsPerPackage, '');
    expect(restored.toPayload(), legacy);
    (legacy['input'] as Map)['quantity'] = '999';
    expect(restored.input.quantity, '1.');
    final encoded = restored.toPayload();
    (encoded['input'] as Map)['jobId'] = 'other-job';
    expect(restored.input.jobId, 'job-a');
  });

  test(
    'new unfinished line keeps null edit target and rejects malformed input',
    () {
      final raw = <String, Object?>{
        'editingId': null,
        'input': <String, Object?>{
          'itemId': 'new-line',
          'category': 'other',
          'unit': 'each',
          'description': '',
          'partNumber': '',
          'quantity': '-',
          'unitsPerPackage': '1',
          'unitPrice': '',
          'jobId': null,
          'jobLabel': null,
        },
      };
      final restored = PendingExpenseLineInput.fromPayload(raw);
      expect(restored.editingId, isNull);
      expect(restored.input.quantity, '-');
      expect(restored.toPayload(), raw);
      (raw['input'] as Map)['quantity'] = 3;
      expect(
        () => PendingExpenseLineInput.fromPayload(raw),
        throwsA(isA<TypeError>()),
      );
    },
  );
}
