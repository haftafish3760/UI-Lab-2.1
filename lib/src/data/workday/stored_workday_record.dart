enum StoredWorkdayStatus { active, paused, ended }

/// Confirmed workday state. UI selection and unconfirmed odometer text are not
/// records. Times are UTC instants; odometers are exact tenths of a mile.
class StoredWorkdayRecord {
  StoredWorkdayRecord({
    required this.id,
    required this.organizationId,
    required this.employeeId,
    required this.vehicleId,
    required this.startedAt,
    required this.updatedAt,
    required this.startOdometerTenths,
    required this.currentOdometerTenths,
    required this.status,
    this.pausedAt,
    this.endedAt,
    this.pausedMicroseconds = 0,
    this.gpsAssistanceRequested = false,
  }) {
    if ([
          id,
          organizationId,
          employeeId,
          vehicleId,
        ].any((value) => value.trim().isEmpty) ||
        !startedAt.isUtc ||
        !updatedAt.isUtc ||
        (pausedAt != null && !pausedAt!.isUtc) ||
        (endedAt != null && !endedAt!.isUtc) ||
        updatedAt.isBefore(startedAt) ||
        startOdometerTenths < 0 ||
        currentOdometerTenths < startOdometerTenths ||
        pausedMicroseconds < 0) {
      throw ArgumentError('Invalid confirmed workday.');
    }
    if ((status == StoredWorkdayStatus.paused) != (pausedAt != null) ||
        (status == StoredWorkdayStatus.ended) != (endedAt != null)) {
      throw ArgumentError('Workday status and timestamps disagree.');
    }
    if (pausedAt != null &&
        (pausedAt!.isBefore(startedAt) || pausedAt!.isAfter(updatedAt))) {
      throw ArgumentError('Invalid pause instant.');
    }
    if (endedAt != null && endedAt != updatedAt) {
      throw ArgumentError('Ended workday must retain its closing instant.');
    }
    if (pausedMicroseconds >
        (pausedAt ?? endedAt ?? updatedAt)
            .difference(startedAt)
            .inMicroseconds) {
      throw ArgumentError('Pause duration exceeds workday duration.');
    }
  }
  final String id;
  final String organizationId;
  final String employeeId;
  final String vehicleId;
  final DateTime startedAt;
  final DateTime updatedAt;
  final int startOdometerTenths;
  final int currentOdometerTenths;
  final StoredWorkdayStatus status;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final int pausedMicroseconds;
  final bool gpsAssistanceRequested;

  factory StoredWorkdayRecord.start({
    required String id,
    required String organizationId,
    required String employeeId,
    required String vehicleId,
    required DateTime at,
    required int odometerTenths,
    bool gpsAssistanceRequested = false,
  }) => StoredWorkdayRecord(
    id: id,
    organizationId: organizationId,
    employeeId: employeeId,
    vehicleId: vehicleId,
    gpsAssistanceRequested: gpsAssistanceRequested,
    startedAt: at.toUtc(),
    updatedAt: at.toUtc(),
    startOdometerTenths: odometerTenths,
    currentOdometerTenths: odometerTenths,
    status: StoredWorkdayStatus.active,
  );

  Duration elapsedAt(DateTime at) {
    final until = endedAt ?? pausedAt ?? at.toUtc();
    final elapsed =
        until.difference(startedAt).inMicroseconds - pausedMicroseconds;
    return Duration(microseconds: elapsed < 0 ? 0 : elapsed);
  }

  StoredWorkdayRecord pause(DateTime at) {
    _requireTransition(at, StoredWorkdayStatus.active);
    return _next(
      at: at,
      status: StoredWorkdayStatus.paused,
      pausedAt: at.toUtc(),
    );
  }

  StoredWorkdayRecord resume(DateTime at) {
    _requireTransition(at, StoredWorkdayStatus.paused);
    return _next(
      at: at,
      status: StoredWorkdayStatus.active,
      pausedMicroseconds:
          pausedMicroseconds + at.toUtc().difference(pausedAt!).inMicroseconds,
    );
  }

  StoredWorkdayRecord end({required DateTime at, required int odometerTenths}) {
    if (status == StoredWorkdayStatus.ended) {
      throw StateError('Workday is already ended.');
    }
    _requireTransition(at, status);
    if (odometerTenths < currentOdometerTenths) {
      throw ArgumentError('Odometer cannot decrease.');
    }
    final paused =
        pausedMicroseconds +
        (pausedAt == null
            ? 0
            : at.toUtc().difference(pausedAt!).inMicroseconds);
    return _next(
      at: at,
      status: StoredWorkdayStatus.ended,
      endedAt: at.toUtc(),
      pausedMicroseconds: paused,
      odometerTenths: odometerTenths,
    );
  }

  void _requireTransition(DateTime at, StoredWorkdayStatus expected) {
    if (status != expected || at.toUtc().isBefore(updatedAt)) {
      throw StateError('Workday transition is stale or out of order.');
    }
  }

  StoredWorkdayRecord _next({
    required DateTime at,
    required StoredWorkdayStatus status,
    DateTime? pausedAt,
    DateTime? endedAt,
    int? pausedMicroseconds,
    int? odometerTenths,
  }) => StoredWorkdayRecord(
    id: id,
    organizationId: organizationId,
    employeeId: employeeId,
    vehicleId: vehicleId,
    gpsAssistanceRequested: gpsAssistanceRequested,
    startedAt: startedAt,
    updatedAt: at.toUtc(),
    startOdometerTenths: startOdometerTenths,
    currentOdometerTenths: odometerTenths ?? currentOdometerTenths,
    status: status,
    pausedAt: pausedAt,
    endedAt: endedAt,
    pausedMicroseconds: pausedMicroseconds ?? this.pausedMicroseconds,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'organizationId': organizationId,
    'employeeId': employeeId,
    'vehicleId': vehicleId,
    'startedAt': startedAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'startOdometerTenths': startOdometerTenths,
    'currentOdometerTenths': currentOdometerTenths,
    'status': status.name,
    'pausedAt': pausedAt?.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'pausedMicroseconds': pausedMicroseconds,
    'gpsAssistanceRequested': gpsAssistanceRequested,
  };
  factory StoredWorkdayRecord.fromJson(Map<String, Object?> json) =>
      StoredWorkdayRecord(
        id: json['id'] as String,
        organizationId: json['organizationId'] as String,
        employeeId: json['employeeId'] as String,
        vehicleId: json['vehicleId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        startOdometerTenths: json['startOdometerTenths'] as int,
        currentOdometerTenths: json['currentOdometerTenths'] as int,
        status: StoredWorkdayStatus.values.byName(json['status'] as String),
        pausedAt: json['pausedAt'] == null
            ? null
            : DateTime.parse(json['pausedAt'] as String),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt'] as String),
        pausedMicroseconds: json['pausedMicroseconds'] as int,
        gpsAssistanceRequested:
            json['gpsAssistanceRequested'] as bool? ?? false,
      );
}
