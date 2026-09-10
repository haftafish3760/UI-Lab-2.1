import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/screens/work/signature_ink.dart';

void main() {
  test('signature ink owns immutable normalized coordinates', () {
    final points = <(double, double)>[(0.1, 0.2), (0.3, 0.4)];
    final ink = SignatureInk([points]);
    points.clear();
    expect(ink.hasInk, isTrue);
    expect(() => ink.strokes.first.clear(), throwsUnsupportedError);
    expect(SignatureInk.fromJson(ink.toJson()).toJson(), ink.toJson());
  });
  test(
    'malformed or unsupported handwriting is rejected without partial recovery',
    () {
      for (final value in [
        {'version': 2, 'strokes': []},
        {
          'version': 1,
          'strokes': [[]],
        },
        {
          'version': 1,
          'strokes': [
            [
              [0.1, 0.2],
              [1.1, 0.3],
            ],
          ],
        },
        {
          'version': 1,
          'strokes': [
            [
              [double.nan, 0.2],
            ],
          ],
        },
        {
          'version': 1,
          'strokes': [
            [
              ['0.1', 0.2],
            ],
          ],
        },
      ]) {
        expect(() => SignatureInk.fromJson(value), throwsFormatException);
      }
      expect(SignatureInk([]).hasInk, isFalse);
      expect(
        SignatureInk([
          [(0.1, 0.2)],
        ]).hasInk,
        isFalse,
      );
    },
  );
}
