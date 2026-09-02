import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';
import '../shared/section_card.dart';

class VehicleDirectoryScreen extends StatefulWidget {
  const VehicleDirectoryScreen({super.key});

  @override
  State<VehicleDirectoryScreen> createState() => _VehicleDirectoryScreenState();
}

class _VehicleDirectoryScreenState extends State<VehicleDirectoryScreen> {
  final _vehicles = <_VehicleProfile>[
    const _VehicleProfile(
      id: 'transit-12',
      name: 'Transit 12',
      yearMakeModel: '2021 Ford Transit',
      odometer: '42,116.4 mi',
      assignment: 'Assigned to Alex Morgan',
      status: 'In service',
    ),
    const _VehicleProfile(
      id: 'service-van-4',
      name: 'Service Van 4',
      yearMakeModel: '2019 Chevrolet Express',
      odometer: '18,908.7 mi',
      assignment: 'Assigned to Jordan Lee',
      status: 'In service',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final active = _vehicles.where((vehicle) => vehicle.active).toList();
    final inactive = _vehicles.where((vehicle) => !vehicle.active).toList();
    return Scaffold(
      key: const ValueKey('vehicle-directory-screen'),
      appBar: AppBar(title: const Text('Vehicle profiles')),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-vehicle-button'),
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add vehicle'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(insets.left, 14, insets.right, 96),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Vehicle records',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mileage, assignment, fuel, maintenance, and truck stock stay attached to the vehicle.',
                      ),
                      const SizedBox(height: 14),
                      _VehicleSection(
                        title: 'Active vehicles',
                        vehicles: active,
                        onEdit: _edit,
                      ),
                      const SizedBox(height: 12),
                      _VehicleSection(
                        title: 'Inactive vehicles',
                        vehicles: inactive,
                        onEdit: _edit,
                        empty: 'No inactive vehicles are retained.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit([_VehicleProfile? profile]) async {
    final updated = await Navigator.of(context).push<_VehicleProfile>(
      MaterialPageRoute(builder: (_) => _VehicleEditor(initial: profile)),
    );
    if (!mounted || updated == null) return;
    setState(() {
      final index = _vehicles.indexWhere((vehicle) => vehicle.id == updated.id);
      if (index < 0) {
        _vehicles.add(updated);
      } else {
        _vehicles[index] = updated;
      }
    });
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({
    required this.title,
    required this.vehicles,
    required this.onEdit,
    this.empty = 'No vehicles are in this section.',
  });
  final String title;
  final List<_VehicleProfile> vehicles;
  final ValueChanged<_VehicleProfile> onEdit;
  final String empty;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Text('${vehicles.length}'),
        ),
        if (vehicles.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text(empty))
        else
          for (final vehicle in vehicles)
            ListTile(
              key: ValueKey('vehicle-profile-${vehicle.id}'),
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text(vehicle.name),
              subtitle: Text(
                '${vehicle.yearMakeModel} · ${vehicle.odometer}\n${vehicle.assignment}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onEdit(vehicle),
            ),
      ],
    ),
  );
}

class _VehicleEditor extends StatefulWidget {
  const _VehicleEditor({this.initial});
  final _VehicleProfile? initial;

  @override
  State<_VehicleEditor> createState() => _VehicleEditorState();
}

class _VehicleEditorState extends State<_VehicleEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _model = TextEditingController(
    text: widget.initial?.yearMakeModel ?? '',
  );
  late final _odometer = TextEditingController(
    text: widget.initial?.odometer ?? '',
  );
  late final _assignment = TextEditingController(
    text: widget.initial?.assignment ?? 'Unassigned',
  );
  late var _active = widget.initial?.active ?? true;

  @override
  void dispose() {
    _name.dispose();
    _model.dispose();
    _odometer.dispose();
    _assignment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.initial == null ? 'Add vehicle' : 'Edit vehicle'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Vehicle information',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'The confirmed odometer becomes the shared starting point for mileage and maintenance records.',
                    ),
                    const SizedBox(height: 14),
                    _field(_name, 'Vehicle name or unit number'),
                    _field(_model, 'Year, make, and model'),
                    _field(_odometer, 'Confirmed odometer reading'),
                    _field(_assignment, 'Assigned employee or crew'),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vehicle is active'),
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _save,
                      child: const Text('Save vehicle'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
    ),
  );

  void _save() {
    if (_name.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      _VehicleProfile(
        id:
            widget.initial?.id ??
            'vehicle-${DateTime.now().microsecondsSinceEpoch}',
        name: _name.text.trim(),
        yearMakeModel: _model.text.trim(),
        odometer: _odometer.text.trim(),
        assignment: _assignment.text.trim(),
        status: _active ? 'In service' : 'Inactive',
        active: _active,
      ),
    );
  }
}

class _VehicleProfile {
  const _VehicleProfile({
    required this.id,
    required this.name,
    required this.yearMakeModel,
    required this.odometer,
    required this.assignment,
    required this.status,
    this.active = true,
  });
  final String id;
  final String name;
  final String yearMakeModel;
  final String odometer;
  final String assignment;
  final String status;
  final bool active;
}
