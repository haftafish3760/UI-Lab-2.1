part of 'start_workday_screen.dart';

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
        _SectionHeading(
          icon: Icons.directions_car_outlined,
          title: context.l10n.selectVehicleLabel,
        ),
        const SizedBox(height: 12),
        _ReviewRow(label: 'Employee', value: employeeName),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: const ValueKey('start-day-vehicle-field'),
          child: DropdownButtonFormField<String>(
            key: ValueKey(vehicle.id),
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
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.startWorkday,
            foregroundColor: AppColors.ink,
          ),
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

int? _parseOdometerTenths(String text) => tryParseWorkdayOdometerMiles(text);
