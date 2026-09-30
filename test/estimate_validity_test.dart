import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'estimate_service_price_test.dart' as fixtures;

void main() {
  test(
    'draft time does not consume validity and sending starts the period',
    () {
      final input = EstimateDraftInput.fromPayload({
        ...fixtures.priceInput('250').toPayload(),
        'expiresOn': null,
        'validityDays': 7,
        'finishedOn': DateTime(2026, 10, 2).toIso8601String(),
      });
      final saved = decodeWorkRecord(
        encodeWorkRecord(
          buildConfirmedEstimate(
            EstimateDraftInput.fromPayload(input.toPayload()),
            now: DateTime(2026, 10, 2),
          ),
        ),
      );
      expect(saved.estimateDates!.validityDays, 7);
      expect(saved.estimateDates!.finishedOn, DateTime(2026, 10, 2));
      expect(saved.estimateDates!.expiresOn, isNull);
      final sent = saved.estimateDates!.copyWith(
        sentOn: DateTime(2026, 10, 5, 16),
      );
      expect(sent.expiresOn, DateTime(2026, 10, 12));
    },
  );
  test('no validity default and legacy explicit expiration is preserved', () {
    final created = DateTime(2026, 9, 29);
    expect(
      EstimateDates(createdOn: created, lastEditedOn: created).expiresOn,
      isNull,
    );
    final old = EstimateDates(
      createdOn: created,
      lastEditedOn: created,
      expiresOn: DateTime(2026, 10, 31),
    );
    expect(
      old.copyWith(sentOn: DateTime(2026, 10, 5)).expiresOn,
      DateTime(2026, 10, 31),
    );
  });
  test(
    'changing validity revises customer content; creation date saves consistently',
    () {
      final original = buildConfirmedEstimate(
        fixtures.priceInput('250'),
        now: DateTime(2026, 9, 29),
      );
      final input = EstimateDraftInput.fromPayload({
        ...fixtures.priceInput('250').toPayload(),
        'baseRecord': encodeWorkRecord(original),
        'createdOn': DateTime(2026, 9, 30).toIso8601String(),
        'validityDays': 90,
      });
      final changed = buildConfirmedEstimate(input, now: DateTime(2026, 10, 1));
      expect(changed.revision, original.revision + 1);
      expect(changed.createdOn, DateTime(2026, 9, 30));
      expect(changed.estimateDates!.createdOn, changed.createdOn);
    },
  );
}
