import 'package:flutter/material.dart';

enum DashboardWorkdayStatus { active, paused, ended }

enum DashboardWorkdayAction {
  pauseOrResume,
  endDay,
  addStop,
  addFuel,
  addExpense,
  addReceipt,
  addNote,
  createEstimate,
  configureActions,
}

@immutable
class DashboardWorkdayActionSpec {
  const DashboardWorkdayActionSpec({
    required this.action,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final DashboardWorkdayAction action;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  DashboardWorkdayActionSpec forStatus(DashboardWorkdayStatus status) {
    if (action != DashboardWorkdayAction.pauseOrResume ||
        status != DashboardWorkdayStatus.paused) {
      return this;
    }
    return const DashboardWorkdayActionSpec(
      action: DashboardWorkdayAction.pauseOrResume,
      label: 'Resume workday',
      description: 'Continue the workday timer and field activity.',
      icon: Icons.play_arrow_rounded,
      color: Color(0xFF087A4A),
    );
  }
}

const dashboardWorkdayActions = <DashboardWorkdayActionSpec>[
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.pauseOrResume,
    label: 'Pause workday',
    description: 'Pause the workday timer without ending the day.',
    icon: Icons.pause_rounded,
    color: Color(0xFFA55B00),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.endDay,
    label: 'End workday',
    description: 'Review the ending odometer and close today’s workday.',
    icon: Icons.stop_rounded,
    color: Color(0xFFB13B36),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.addStop,
    label: 'Add a stop',
    description: 'Record an unplanned customer, supplier, or other stop.',
    icon: Icons.add_location_alt_outlined,
    color: Color(0xFF2D6680),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.addFuel,
    label: 'Add fuel',
    description: 'Record fuel with receipt and odometer information.',
    icon: Icons.local_gas_station_outlined,
    color: Color(0xFF2D6680),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.addExpense,
    label: 'Add expense',
    description: 'Record a business cost and optionally link it to a job.',
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF79527A),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.addReceipt,
    label: 'Add receipt photos',
    description: 'Capture or attach clearly labeled receipt evidence.',
    icon: Icons.add_a_photo_outlined,
    color: Color(0xFF65727A),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.addNote,
    label: 'Add work note',
    description: 'Record a note in today’s chronological entries.',
    icon: Icons.note_add_outlined,
    color: Color(0xFF65727A),
  ),
  DashboardWorkdayActionSpec(
    action: DashboardWorkdayAction.createEstimate,
    label: 'Create estimate',
    description: 'Start a proposal when this employee has permission.',
    icon: Icons.request_quote_outlined,
    color: Color(0xFF087A4A),
  ),
];

const workdaySettingsAction = DashboardWorkdayActionSpec(
  action: DashboardWorkdayAction.configureActions,
  label: 'Choose actions',
  description: 'Choose which permitted shortcuts appear on this screen.',
  icon: Icons.tune_rounded,
  color: Color(0xFF526771),
);

const defaultDashboardWorkdayActions = <DashboardWorkdayAction>{
  DashboardWorkdayAction.pauseOrResume,
  DashboardWorkdayAction.endDay,
  DashboardWorkdayAction.addStop,
  DashboardWorkdayAction.addFuel,
  DashboardWorkdayAction.addExpense,
  DashboardWorkdayAction.addReceipt,
};

@immutable
class StartWorkdayResult {
  const StartWorkdayResult({
    required this.vehicleId,
    required this.vehicleLabel,
    required this.startOdometerTenths,
    required this.gpsAssistanceEnabled,
  });

  final String vehicleId;
  final String vehicleLabel;
  final int startOdometerTenths;
  final bool gpsAssistanceEnabled;
}

@immutable
class DashboardWorkdaySession {
  const DashboardWorkdaySession({
    required this.vehicleId,
    required this.vehicleLabel,
    required this.startedAt,
    required this.startOdometerTenths,
    required this.currentOdometerTenths,
    required this.gpsAssistanceEnabled,
    this.status = DashboardWorkdayStatus.active,
    this.pausedAt,
    this.accumulatedPause = Duration.zero,
  });

  factory DashboardWorkdaySession.start(
    StartWorkdayResult result, {
    DateTime? at,
  }) => DashboardWorkdaySession(
    vehicleId: result.vehicleId,
    vehicleLabel: result.vehicleLabel,
    startedAt: at ?? DateTime.now(),
    startOdometerTenths: result.startOdometerTenths,
    currentOdometerTenths: result.startOdometerTenths,
    gpsAssistanceEnabled: result.gpsAssistanceEnabled,
  );

  final String vehicleId;
  final String vehicleLabel;
  final DateTime startedAt;
  final int startOdometerTenths;
  final int currentOdometerTenths;
  final bool gpsAssistanceEnabled;
  final DashboardWorkdayStatus status;
  final DateTime? pausedAt;
  final Duration accumulatedPause;

  int get milesTenths =>
      (currentOdometerTenths - startOdometerTenths).clamp(0, 9999999).toInt();

  Duration elapsedAt(DateTime now) {
    final end = status == DashboardWorkdayStatus.paused ? pausedAt ?? now : now;
    final elapsed = end.difference(startedAt) - accumulatedPause;
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  DashboardWorkdaySession togglePause({DateTime? at}) {
    final now = at ?? DateTime.now();
    if (status == DashboardWorkdayStatus.paused) {
      return copyWith(
        status: DashboardWorkdayStatus.active,
        clearPausedAt: true,
        accumulatedPause: accumulatedPause + now.difference(pausedAt ?? now),
      );
    }
    return copyWith(status: DashboardWorkdayStatus.paused, pausedAt: now);
  }

  DashboardWorkdaySession copyWith({
    DashboardWorkdayStatus? status,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    Duration? accumulatedPause,
    int? currentOdometerTenths,
  }) => DashboardWorkdaySession(
    vehicleId: vehicleId,
    vehicleLabel: vehicleLabel,
    startedAt: startedAt,
    startOdometerTenths: startOdometerTenths,
    currentOdometerTenths: currentOdometerTenths ?? this.currentOdometerTenths,
    gpsAssistanceEnabled: gpsAssistanceEnabled,
    status: status ?? this.status,
    pausedAt: clearPausedAt ? null : pausedAt ?? this.pausedAt,
    accumulatedPause: accumulatedPause ?? this.accumulatedPause,
  );
}
