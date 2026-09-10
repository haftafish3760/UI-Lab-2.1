import 'package:flutter/material.dart';

import '../data/prototype_operations_store.dart';
import '../data/work/directory_persistence_session.dart';
import '../data/work/vehicle_directory_profile.dart';
import '../data/work/vehicle_directory_demo.dart';
import 'vehicle_editor_screen.dart';

import '../layout/app_layout_engine.dart';
import '../shared/section_card.dart';

class VehicleDirectoryScreen extends StatefulWidget {
  const VehicleDirectoryScreen({super.key});

  @override
  State<VehicleDirectoryScreen> createState() => _VehicleDirectoryScreenState();
}

class _VehicleDirectoryScreenState extends State<VehicleDirectoryScreen> {
  final _fixtureVehicles = [...demoVehicleDirectoryProfiles];
  DirectoryPersistenceSession? get _directory =>
      PrototypeOperationsScope.maybeOf(context)?.directorySession;
  List<VehicleDirectoryProfile> get _vehicles =>
      _directory?.vehicles ?? _fixtureVehicles;
  bool _initialized = false;
  bool _ready = false;
  String? _error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final directory = _directory;
    if (directory == null || !directory.permissions.canViewVehicles) {
      _ready = true;
      return;
    }
    directory.reloadVehicles().then((success) {
      if (mounted) {
        setState(() {
          _ready = success;
          _error = success ? null : directory.failureMessage;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final directory = _directory;
    if (directory != null && !directory.permissions.canViewVehicles) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle profiles')),
        body: const Center(
          child: Text('Vehicle records are not available for this account.'),
        ),
      );
    }
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle profiles')),
        body: Center(child: Text(_error ?? 'Opening vehicle records…')),
      );
    }
    final canEdit = directory?.permissions.canManageVehicles ?? true;
    final active = _vehicles.where((vehicle) => vehicle.active).toList();
    final inactive = _vehicles.where((vehicle) => !vehicle.active).toList();
    return Scaffold(
      key: const ValueKey('vehicle-directory-screen'),
      appBar: AppBar(title: const Text('Vehicle profiles')),
      floatingActionButton: !canEdit
          ? null
          : FloatingActionButton.extended(
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
                        'Keep vehicle identity, assignment notes, and confirmed odometer readings together.',
                      ),
                      const SizedBox(height: 14),
                      _VehicleSection(
                        title: 'Active vehicles',
                        vehicles: active,
                        onEdit: canEdit ? _edit : null,
                        odometerLabel: _odometerLabel,
                      ),
                      const SizedBox(height: 12),
                      _VehicleSection(
                        title: 'Inactive vehicles',
                        vehicles: inactive,
                        onEdit: canEdit ? _edit : null,
                        odometerLabel: _odometerLabel,
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

  String _odometerLabel(String id) {
    final reading = _directory?.vehicleOdometer(id);
    return reading == null
        ? 'Odometer not confirmed'
        : '${reading.readingTenths ~/ 10}.${reading.readingTenths % 10} mi';
  }

  Future<void> _edit([VehicleDirectoryProfile? profile]) async {
    if (_directory != null && !_directory!.permissions.canManageVehicles) {
      return;
    }
    final updated = await Navigator.of(context).push<VehicleDirectoryProfile>(
      MaterialPageRoute(builder: (_) => VehicleEditorScreen(initial: profile)),
    );
    if (!mounted || updated == null) return;
    if (_directory != null) {
      setState(() {});
      return;
    }
    setState(() {
      final index = _fixtureVehicles.indexWhere(
        (vehicle) => vehicle.id == updated.id,
      );
      if (index < 0) {
        _fixtureVehicles.add(updated);
      } else {
        _fixtureVehicles[index] = updated;
      }
    });
  }
}

class _VehicleSection extends StatelessWidget {
  const _VehicleSection({
    required this.title,
    required this.vehicles,
    required this.onEdit,
    required this.odometerLabel,
    this.empty = 'No vehicles are in this section.',
  });
  final String title;
  final List<VehicleDirectoryProfile> vehicles;
  final ValueChanged<VehicleDirectoryProfile>? onEdit;
  final String Function(String) odometerLabel;
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
                '${vehicle.yearMakeModel} · ${odometerLabel(vehicle.id)}\n${vehicle.assignment}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onEdit == null ? null : () => onEdit!(vehicle),
            ),
      ],
    ),
  );
}
