/// A user-confirmed local calendar date and clock time. They are not converted
/// through UTC when viewing historical day records from another time zone.
class StoredDayNote {
  StoredDayNote({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.date,
    required this.timeMinutes,
    required this.text,
    required this.createdAt,
  }) {
    final parsed = DateTime.tryParse(date);
    if ([
          id,
          organizationId,
          employeeId,
          text,
        ].any((value) => value.trim().isEmpty) ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        parsed == null ||
        '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}' !=
            date ||
        timeMinutes < 0 ||
        timeMinutes >= 1440 ||
        !createdAt.isUtc) {
      throw ArgumentError('Invalid confirmed day note.');
    }
  }
  final String id;
  final String organizationId;
  final String employeeId;
  final String date;
  final int timeMinutes;
  final String text;
  final DateTime createdAt;
  Map<String, Object?> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'employeeId': employeeId,
    'date': date,
    'timeMinutes': timeMinutes,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
  factory StoredDayNote.fromJson(Map<String, Object?> json) => StoredDayNote(
    id: json['id'] as String,
    organizationId: json['organizationId'] as String,
    employeeId: json['employeeId'] as String,
    date: json['date'] as String,
    timeMinutes: json['timeMinutes'] as int,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
