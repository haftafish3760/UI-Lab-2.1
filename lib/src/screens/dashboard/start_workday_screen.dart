import '../../data/workday/odometer_input.dart';
import '../../data/workday/start_workday_draft_workflow.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations_extension.dart';
import '../../theme/app_theme.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'active_vehicle_header.dart';
import 'dashboard_models.dart';
import 'dashboard_workday_models.dart';
import '../../data/storage/draft_autosave_session.dart';
import '../../data/workday/workday_persistence_session.dart';
import '../../shared/draft_navigation_guard.dart';
import '../../shared/editor_draft_status.dart';

part 'start_workday_draft_recovery.dart';
part 'start_workday_sections.dart';

class StartWorkdayScreen extends StatefulWidget {
  const StartWorkdayScreen({this.recoveredWorkflow, super.key});

  final StartWorkdayDraftController? recoveredWorkflow;

  @override
  State<StartWorkdayScreen> createState() => _StartWorkdayScreenState();
}

class _StartWorkdayScreenState extends State<StartWorkdayScreen>
    with DraftNavigationGuard<StartWorkdayScreen> {
  late StartWorkdayDraftController? _workflow = widget.recoveredWorkflow;
  DraftAutosaveSession? get _draft => _workflow?.session;
  StreamSubscription<DraftSaveState>? _draftSubscription;
  bool _opening = true;
  bool _saving = false;
  @override
  DraftAutosaveSession? get navigationDraft => _draft;
  @override
  bool get blockDraftNavigation => _saving;
  void _refresh(VoidCallback action) => setState(action);
  int _readingFor(String id) {
    final saved = WorkdayPersistenceScope.maybeOf(context);
    return saved == null
        ? OperationalScope.of(context).confirmedOdometerTenthsFor(id)
        : saved.odometerFor(id)?.readingTenths ?? 0;
  }

  TextEditingController? _odometerController;
  var _gpsAssistance = false;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_odometerController == null) {
      final scope = OperationalScope.of(context);
      _odometerController = TextEditingController(
        text: formatOdometerTenths(_readingFor(scope.selectedVehicleId)),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openDraft());
      });
    }
  }

  @override
  void dispose() {
    unawaited(_draftSubscription?.cancel());
    unawaited(_draft?.close().catchError((Object _) {}));
    _odometerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    if (_opening) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back to Dashboard',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: leaveDraftRoute,
          ),
        ),
        body: Center(child: Text(_errorText ?? 'Opening saved workday input…')),
      );
    }
    final odometerController = _odometerController!;
    final vehicle = dashboardVehicleById(scope.selectedVehicleId);
    final employee = demoEmployees.firstWhere(
      (candidate) => candidate.id == (scope.selectedEmployeeId ?? 'alex'),
      orElse: () => demoEmployees.first,
    );
    return guardDraftNavigation(
      Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = math.max(
              0,
              constraints.maxWidth - insets.horizontal,
            );
            final layout = AppLayoutEngine.dashboardFor(
              available.toDouble(),
              textScaler: MediaQuery.textScalerOf(context),
            );
            return SingleChildScrollView(
              padding: insets.copyWith(top: 12, bottom: 28),
              child: Center(
                child: SizedBox(
                  width: layout.workspaceWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ActiveVehicleHeader(
                        ownerPresentation: true,
                        ownerTitle: context.l10n.dashboardStartWorkday,
                        onVehicleChanged: (id) {
                          odometerController.text = formatOdometerTenths(
                            _readingFor(id),
                          );
                          setState(() => _errorText = null);
                          _captureDraft();
                        },
                        view: scope.view,
                        onViewChanged: scope.setView,
                        activeEmployee: scope.view == AppViewMode.admin
                            ? employee
                            : null,
                        onEmployeeSelected: (selected) {
                          scope.selectEmployee(selected.id);
                          _captureDraft();
                        },
                        onCompanyOverview: () => scope.selectEmployee(null),
                        showPrimaryAction: false,
                        leadingIcon: Icons.arrow_back_rounded,
                        leadingTooltip: 'Back to Dashboard',
                        onLeading: leaveDraftRoute,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Start workday',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Confirm the person, vehicle, and physical odometer before field activity begins.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StartWorkdaySections(
                        layout: layout,
                        employeeName: employee.name,
                        vehicle: vehicle,
                        onVehicleChanged: (selected) {
                          scope.selectVehicle(selected.id);
                          odometerController.text = formatOdometerTenths(
                            _readingFor(selected.id),
                          );
                          setState(() => _errorText = null);
                          _captureDraft();
                        },
                        odometerController: odometerController,
                        odometerError: _errorText,
                        gpsAssistance: _gpsAssistance,
                        onGpsChanged: (value) => setState(() {
                          _gpsAssistance = value;
                          _captureDraft();
                        }),
                      ),
                      const SizedBox(height: 16),
                      if (_draft != null)
                        EditorDraftStatus(
                          state: _draft!.state,
                          onRetry: () => _draft!.retry(),
                          onDiscard: _discardDraft,
                        ),
                      if (_opening) const Text('Opening saved workday input…'),
                      if (_saving) const Text('Saving workday…'),
                      _StartReviewBar(
                        vehicle: vehicle,
                        onCancel: leaveDraftRoute,
                        onStart: () => _submit(scope, vehicle),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _submit(OperationalScopeController scope, DashboardVehicle vehicle) {
    if (_opening || _saving) return;
    final reading = _parseOdometerTenths(_odometerController!.text);
    final stored = WorkdayPersistenceScope.maybeOf(context);
    final previous =
        stored?.odometerFor(vehicle.id)?.readingTenths ??
        scope.confirmedOdometerTenthsFor(vehicle.id);
    if (reading == null) {
      setState(() => _errorText = 'Enter a valid odometer reading.');
      return;
    }
    if (reading < previous) {
      setState(
        () => _errorText =
            'The reading cannot be lower than the last confirmed value, ${formatOdometerTenths(previous)}.',
      );
      return;
    }
    if (stored != null) {
      unawaited(
        _confirmStored(
          StartWorkdayResult(
            vehicleId: vehicle.id,
            vehicleLabel: vehicle.name,
            startOdometerTenths: reading,
            gpsAssistanceEnabled: _gpsAssistance,
          ),
        ),
      );
      return;
    }
    scope.confirmOdometer(vehicleId: vehicle.id, readingTenths: reading);
    Navigator.of(context).pop(
      StartWorkdayResult(
        vehicleId: vehicle.id,
        vehicleLabel: vehicle.name,
        startOdometerTenths: reading,
        gpsAssistanceEnabled: _gpsAssistance,
      ),
    );
  }
}
