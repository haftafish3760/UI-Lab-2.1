part of 'dashboard_screen.dart';

extension _DashboardWorkdayPersistence on _DashboardScreenState {
  DashboardWorkdaySession? get _workday =>
      WorkdayPersistenceScope.maybeOf(context) == null
      ? _fixtureWorkday
      : _savedWorkdayView();
  set _workday(DashboardWorkdaySession? value) => _fixtureWorkday = value;

  WorkdaySnapshot? get _storedActiveWorkday {
    final employee = OperationalScope.of(context).selectedEmployeeId;
    return employee == null
        ? null
        : WorkdayPersistenceScope.maybeOf(context)?.activeFor(employee);
  }

  DashboardWorkdaySession? _savedWorkdayView() {
    final record = _storedActiveWorkday?.record;
    if (record == null) return null;
    final vehicle = demoVehicles
        .where((item) => item.id == record.vehicleId)
        .firstOrNull;
    return DashboardWorkdaySession(
      vehicleId: record.vehicleId,
      vehicleLabel: vehicle?.name ?? record.vehicleId,
      startedAt: record.startedAt.toLocal(),
      startOdometerTenths: record.startOdometerTenths,
      currentOdometerTenths: record.currentOdometerTenths,
      gpsAssistanceEnabled: record.gpsAssistanceRequested,
      status: record.status == StoredWorkdayStatus.paused
          ? DashboardWorkdayStatus.paused
          : DashboardWorkdayStatus.active,
      pausedAt: record.pausedAt?.toLocal(),
      accumulatedPause: Duration(microseconds: record.pausedMicroseconds),
    );
  }

  Future<void> _pauseStoredWorkday(WorkdaySnapshot snapshot) async {
    final session = WorkdayPersistenceScope.maybeOf(context)!;
    if (!session.isReady || session.isSaving) return;
    final result = await session.change(
      id: snapshot.record.id,
      expectedRevision: snapshot.revision,
      at: DateTime.now().toUtc(),
      status: snapshot.record.status == StoredWorkdayStatus.paused
          ? StoredWorkdayStatus.active
          : StoredWorkdayStatus.paused,
    );
    if (mounted && result.message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _endStoredWorkday(WorkdaySnapshot snapshot) async {
    final session = WorkdayPersistenceScope.maybeOf(context)!;
    if (!session.isReady || session.isSaving) return;
    final odometer = session.odometerFor(snapshot.record.vehicleId);
    if (odometer == null) return;
    await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EndWorkdayDialog(
        initialOdometerTenths: odometer.readingTenths,
        minimumOdometerTenths: odometer.readingTenths,
        session: session,
        workday: snapshot,
      ),
    );
  }
}
