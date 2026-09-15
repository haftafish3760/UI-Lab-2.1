import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/receipts/receipt_date_proposal.dart';

void main() {
  test('unambiguous formats preserve calendar date', () {
    for (final printed in [
      'DATE 2026-09-14',
      '09/14/2026 13:24',
      '14/09/2026',
    ]) {
      expect(proposeReceiptDate([printed]).date, DateTime(2026, 9, 14));
    }
  });
  test('day/month ambiguity is not guessed from US assumptions', () {
    final result = proposeReceiptDate(['03/04/2026']);
    expect(result.date, isNull);
    expect(result.warnings, isNotEmpty);
    expect(proposeReceiptDate(['09/14/26']).date, isNull);
  });
  test('invalid dates never roll into another month', () {
    for (final printed in [
      '2025-02-29',
      '2026-02-31',
      '2026-00-14',
      '2026-13-14',
    ]) {
      expect(proposeReceiptDate([printed]).date, isNull);
    }
    expect(proposeReceiptDate(['2024-02-29']).date, DateTime(2024, 2, 29));
  });
  test('competing transaction dates remain a user choice', () {
    final result = proposeReceiptDate(['2026-09-14', 'RETURN BY 2026-10-14']);
    expect(result.date, isNull);
    expect(result.warnings.single, contains('More than one date'));
    expect(
      proposeReceiptDate(['2026-09-14', '2026-09-14']).date,
      DateTime(2026, 9, 14),
    );
  });
}
