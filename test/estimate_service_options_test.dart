import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_draft_controller.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/work_record_codec.dart';
import 'estimate_service_price_test.dart' as fixtures;

void main() {
  test(
    'multiple service dates and times survive draft and saved record codecs',
    () {
      final options = [DateTime(2026, 10, 2, 9, 30), DateTime(2026, 10, 5, 14)];
      final input = EstimateDraftInput.fromPayload({
        ...fixtures.priceInput('250').toPayload(),
        'proposedServiceOn': options.first.toIso8601String(),
        'proposedServiceDates': options
            .map((d) => d.toIso8601String())
            .toList(),
      });
      final restored = EstimateDraftInput.fromPayload(input.toPayload());
      final saved = decodeWorkRecord(
        encodeWorkRecord(
          buildConfirmedEstimate(restored, now: DateTime(2026, 9, 29)),
        ),
      );
      expect(saved.estimateDates!.serviceOptions, options);
      expect(saved.estimateDates!.hasActivityOn(DateTime(2026, 10, 5)), isTrue);
      final changed = EstimateDraftInput.fromPayload({
        ...restored.toPayload(),
        'baseRecord': encodeWorkRecord(saved),
        'proposedServiceDates': [
          options.first.toIso8601String(),
          DateTime(2026, 10, 5, 15).toIso8601String(),
        ],
      });
      final revised = buildConfirmedEstimate(
        changed,
        now: DateTime(2026, 9, 30),
      );
      expect(revised.revision, saved.revision + 1);
      expect(revised.estimateDates!.serviceOptions.last.hour, 15);
    },
  );

  test('legacy single proposed date remains visible without migration', () {
    final date = DateTime(2026, 10, 1, 11);
    final dates = EstimateDates(
      createdOn: date,
      lastEditedOn: date,
      proposedServiceOn: date,
    );
    expect(dates.serviceOptions, [date]);
  });
}
