import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/work/estimate_confirmation.dart';
import 'package:ui_lab_2_1/src/data/work/models/estimate_models.dart';
import 'package:ui_lab_2_1/src/data/work/models/work_models.dart';
import 'package:ui_lab_2_1/src/data/work/quote_status.dart';
import 'quote_draft_workflow_test.dart' show quoteInput;

void main() {
  final day = DateTime(2026, 9, 28);
  final quote = buildConfirmedEstimate(quoteInput('owner'), now: day);
  bool matches(
    WorkRecord record, {
    QuoteStatus? status,
    String query = '',
    bool allDates = true,
    DateTime? selectedDay,
  }) => quoteMatchesFilters(
    record,
    today: day,
    selectedDay: selectedDay ?? day,
    allDates: allDates,
    includeClosedRecords: false,
    query: query,
    selectedStatus: status,
  );

  test('explicit closed status shows records hidden from the general list', () {
    for (final pair in [
      (EstimateStage.declined, QuoteStatus.declined),
      (EstimateStage.expired, QuoteStatus.expired),
      (EstimateStage.converted, QuoteStatus.converted),
      (EstimateStage.archived, QuoteStatus.archived),
    ]) {
      final record = quote.withEstimateStage(pair.$1, day);
      expect(matches(record), isFalse);
      expect(matches(record, status: pair.$2), isTrue);
      expect(matches(record, status: QuoteStatus.ready), isFalse);
    }
  });

  test('explicit status still applies date and customer search', () {
    final record = quote.withEstimateStage(EstimateStage.declined, day);
    expect(
      matches(record, status: QuoteStatus.declined, query: '  JAMIE  '),
      isTrue,
    );
    expect(
      matches(record, status: QuoteStatus.declined, query: 'different client'),
      isFalse,
    );
    expect(
      matches(record, status: QuoteStatus.declined, allDates: false),
      isTrue,
    );
    expect(
      matches(
        record,
        status: QuoteStatus.declined,
        allDates: false,
        selectedDay: DateTime(2025),
      ),
      isFalse,
    );
  });

  test(
    'drafts stay separate and ordinary open quotes remain in general list',
    () {
      final draft = quote.withEstimateStage(EstimateStage.draft, day);
      expect(matches(draft), isFalse);
      expect(matches(draft, status: QuoteStatus.draft), isTrue);
      expect(
        matches(quote.withEstimateStage(EstimateStage.readyToSend, day)),
        isTrue,
      );
    },
  );
}
