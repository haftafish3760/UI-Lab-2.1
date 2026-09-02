import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../shared/section_card.dart';
import 'active_vehicle_header.dart';
import 'dashboard_models.dart';
import 'dashboard_workday_models.dart';

class StartWorkdayScreen extends StatefulWidget {
  const StartWorkdayScreen({super.key});

  @override
  State<StartWorkdayScreen> createState() => _StartWorkdayScreenState();
}

class _StartWorkdayScreenState extends State<StartWorkdayScreen> {
  TextEditingController? _odometerController;
  var _gpsAssistance = false;
  String? _errorText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_odometerController == null) {
      final scope = OperationalScope.of(context);
      _odometerController = TextEditingController(
        text: formatOdometerTenths(
          scope.confirmedOdometerTenthsFor(scope.selectedVehicleId),
        ),
      );
    }
  }

  @override
  void dispose() {
    _odometerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    final odometerController = _odometerController!;
    final vehicle = dashboardVehicleById(scope.selectedVehicleId);
    final employee = demoEmployees.firstWhere(
      (candidate) => candidate.id == (scope.selectedEmployeeId ?? 'alex'),
      orElse: () => demoEmployees.first,
    );
    return Scaffold(
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
                      view: scope.view,
                      onViewChanged: scope.setView,
                      activeEmployee: scope.view == AppViewMode.admin
                          ? employee
                          : null,
                      onEmployeeSelected: (selected) =>
                          scope.selectEmployee(selected.id),
                      onCompanyOverview: () => scope.selectEmployee(null),
                      showPrimaryAction: false,
                      leadingIcon: Icons.arrow_back_rounded,
                      leadingTooltip: 'Back to Dashboard',
                      onLeading: () => Navigator.of(context).pop(),
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
                          scope.confirmedOdometerTenthsFor(selected.id),
                        );
                        setState(() => _errorText = null);
                      },
                      odometerController: odometerController,
                      odometerError: _errorText,
                      gpsAssistance: _gpsAssistance,
                      onGpsChanged: (value) =>
                          setState(() => _gpsAssistance = value),
                    ),
                    const SizedBox(height: 16),
                    _StartReviewBar(
                      vehicle: vehicle,
                      onCancel: () => Navigator.of(context).pop(),
                      onStart: () => _submit(scope, vehicle),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _submit(OperationalScopeController scope, DashboardVehicle vehicle) {
    final reading = _parseOdometerTenths(_odometerController!.text);
    final previous = scope.confirmedOdometerTenthsFor(vehicle.id);
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

class _StartWorkdaySections extends StatelessWidget {
  const _StartWorkdaySections({
    required this.layout,
    required this.employeeName,
    required this.vehicle,
    required this.onVehicleChanged,
    required this.odometerController,
    required this.odometerError,
    required this.gpsAssistance,
    required this.onGpsChanged,
  });

  final DashboardLayout layout;
  final String employeeName;
  final DashboardVehicle vehicle;
  final ValueChanged<DashboardVehicle> onVehicleChanged;
  final TextEditingController odometerController;
  final String? odometerError;
  final bool gpsAssistance;
  final ValueChanged<bool> onGpsChanged;

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _ContextSection(
        employeeName: employeeName,
        vehicle: vehicle,
        onVehicleChanged: onVehicleChanged,
      ),
      _OdometerSection(
        controller: odometerController,
        errorText: odometerError,
      ),
      _TripAssistanceSection(enabled: gpsAssistance, onChanged: onGpsChanged),
    ];
    if (layout.mode == DashboardLaneMode.single) {
      return Column(children: _withVerticalGaps(sections, layout.gap));
    }
    if (layout.mode == DashboardLaneMode.two) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: sections[0]),
              SizedBox(width: layout.gap),
              Expanded(child: sections[1]),
            ],
          ),
          SizedBox(height: layout.gap),
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: layout.laneWidth, child: sections[2]),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) SizedBox(width: layout.gap),
          SizedBox(width: layout.laneWidth, child: sections[index]),
        ],
      ],
    );
  }
}

class _ContextSection extends StatelessWidget {
  const _ContextSection({
    required this.employeeName,
    required this.vehicle,
    required this.onVehicleChanged,
  });

  final String employeeName;
  final DashboardVehicle vehicle;
  final ValueChanged<DashboardVehicle> onVehicleChanged;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          icon: Icons.badge_outlined,
          title: 'Work context',
        ),
        const SizedBox(height: 12),
        _ReviewRow(label: 'Employee', value: employeeName),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: const ValueKey('start-day-vehicle-field'),
          initialValue: vehicle.id,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Vehicle used today'),
          items: [
            for (final item in demoVehicles)
              DropdownMenuItem(value: item.id, child: Text(item.name)),
          ],
          onChanged: (id) {
            if (id != null) onVehicleChanged(dashboardVehicleById(id));
          },
        ),
        const SizedBox(height: 8),
        _ReviewRow(
          label: 'Date',
          value: operationalDateLabel(context, dashboardToday),
        ),
      ],
    ),
  );
}

class _OdometerSection extends StatelessWidget {
  const _OdometerSection({required this.controller, this.errorText});

  final TextEditingController controller;
  final String? errorText;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          icon: Icons.speed_outlined,
          title: 'Starting odometer',
        ),
        const SizedBox(height: 7),
        const Text('Enter the number shown on the physical vehicle odometer.'),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('start-day-odometer-field'),
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Current odometer',
            suffixText: 'mi',
            errorText: errorText,
          ),
        ),
      ],
    ),
  );
}

class _TripAssistanceSection extends StatelessWidget {
  const _TripAssistanceSection({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeading(
          icon: Icons.route_outlined,
          title: 'Trip assistance',
        ),
        const SizedBox(height: 5),
        SwitchListTile(
          key: const ValueKey('start-day-gps-switch'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Use GPS-assisted trip tracking'),
          subtitle: const Text(
            'Optional. The physical odometer remains the official mileage record.',
          ),
          value: enabled,
          onChanged: onChanged,
        ),
        const Text(
          'Location is not started or shared until you turn this on and start the workday.',
        ),
      ],
    ),
  );
}

class _StartReviewBar extends StatelessWidget {
  const _StartReviewBar({
    required this.vehicle,
    required this.onCancel,
    required this.onStart,
  });

  final DashboardVehicle vehicle;
  final VoidCallback onCancel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        Text(
          'Starting ${vehicle.name} creates one active workday record.',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
        FilledButton.icon(
          key: const ValueKey('confirm-start-workday-button'),
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start workday'),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 82,
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

List<Widget> _withVerticalGaps(List<Widget> children, double gap) => [
  for (var index = 0; index < children.length; index++) ...[
    if (index > 0) SizedBox(height: gap),
    children[index],
  ],
];

int? _parseOdometerTenths(String text) {
  final value = double.tryParse(text.replaceAll(',', '').trim());
  if (value == null || value.isNegative || value > 9999999) return null;
  return (value * 10).round();
}
