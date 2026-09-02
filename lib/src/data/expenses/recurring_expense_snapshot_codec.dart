import 'recurring_expense_records.dart';

class RecurringExpenseSnapshotData {
  const RecurringExpenseSnapshotData({
    required this.templates,
    required this.occurrences,
  });

  const RecurringExpenseSnapshotData.empty()
    : templates = const [],
      occurrences = const [];

  final List<StoredRecurringExpenseTemplate> templates;
  final List<StoredRecurringExpenseOccurrence> occurrences;

  Map<String, Object?> toJson() => {
    'templates': templates.map((item) => item.toJson()).toList(),
    'occurrences': occurrences.map((item) => item.toJson()).toList(),
  };

  factory RecurringExpenseSnapshotData.fromJson(Map<String, Object?> json) {
    final templates = _requiredList(json, 'templates')
        .map(
          (value) => StoredRecurringExpenseTemplate.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList();
    final occurrences = _requiredList(json, 'occurrences')
        .map(
          (value) => StoredRecurringExpenseOccurrence.fromJson(
            (value as Map).cast<String, Object?>(),
          ),
        )
        .toList();
    if (templates.map((item) => item.templateId).toSet().length !=
        templates.length) {
      throw const FormatException('Duplicate recurring expense identity.');
    }
    if (occurrences.map((item) => item.occurrenceId).toSet().length !=
        occurrences.length) {
      throw const FormatException('Duplicate recurring payment identity.');
    }
    final byId = {for (final item in templates) item.templateId: item};
    for (final occurrence in occurrences) {
      final template = byId[occurrence.templateId];
      if (template == null ||
          template.organizationId != occurrence.organizationId) {
        throw const FormatException('Recurring payment has no valid template.');
      }
    }
    final openCounts = <String, int>{};
    for (final occurrence in occurrences.where((item) => item.isOpen)) {
      openCounts.update(
        occurrence.templateId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    if (openCounts.values.any((count) => count > 1)) {
      throw const FormatException(
        'A recurring expense has more than one open payment.',
      );
    }
    return RecurringExpenseSnapshotData(
      templates: List.unmodifiable(templates),
      occurrences: List.unmodifiable(occurrences),
    );
  }
}

int compareRecurringTemplateIds(
  StoredRecurringExpenseTemplate a,
  StoredRecurringExpenseTemplate b,
) => a.templateId.compareTo(b.templateId);

int compareRecurringOccurrenceIds(
  StoredRecurringExpenseOccurrence a,
  StoredRecurringExpenseOccurrence b,
) => a.occurrenceId.compareTo(b.occurrenceId);

List<Object?> _requiredList(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List) throw FormatException('Missing or invalid $key.');
  return value;
}
