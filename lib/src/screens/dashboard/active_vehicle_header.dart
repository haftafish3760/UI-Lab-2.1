import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ActiveVehicleHeader extends StatefulWidget {
  const ActiveVehicleHeader({super.key});

  @override
  State<ActiveVehicleHeader> createState() => _ActiveVehicleHeaderState();
}

class _ActiveVehicleHeaderState extends State<ActiveVehicleHeader> {
  var _vehicleIndex = 0;

  static const _vehicles = [
    ('Transit 12', '42,116.4 mi'),
    ('Service Van 4', '18,908.7 mi'),
    ('Pickup 2', '76,204.1 mi'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ink,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scaledLabelSize = MediaQuery.textScalerOf(context).scale(14);
          final wide = constraints.maxWidth >= 900 && scaledLabelSize <= 18;
          return Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              wide
                  ? 24
                  : constraints.maxWidth >= 600
                  ? 16
                  : 8,
              7,
              wide
                  ? 24
                  : constraints.maxWidth >= 600
                  ? 16
                  : 8,
              7,
            ),
            child: wide
                ? _wideHeader()
                : constraints.maxWidth >= 600
                ? _tabletHeader()
                : _compactHeader(),
          );
        },
      ),
    );
  }

  Widget _wideHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final activeCenter = width / 2;
        const edgeInset = 40.0;
        const controlWidth = 48.0;
        const activeWidth = 290.0;
        const actionWidth = 156.0;
        final leadingEnd = edgeInset + controlWidth;
        final trailingStart = width - edgeInset - controlWidth;
        final activeStart = activeCenter - activeWidth / 2;
        final activeEnd = activeCenter + activeWidth / 2;
        final startCenter = (leadingEnd + activeStart) / 2;
        final viewCenter = (activeEnd + trailingStart) / 2;
        return SizedBox(
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PositionedDirectional(start: edgeInset, child: _menuButton()),
              PositionedDirectional(
                start: startCenter - actionWidth / 2,
                width: actionWidth,
                child: const _StartButton(),
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(width: activeWidth, child: _vehicleSummary()),
              ),
              PositionedDirectional(
                start: viewCenter - actionWidth / 2,
                width: actionWidth,
                child: const _RoleSelector(),
              ),
              PositionedDirectional(end: 96, child: _notificationButton()),
              PositionedDirectional(end: edgeInset, child: _settingsButton()),
            ],
          ),
        );
      },
    );
  }

  Widget _compactHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _menuButton(),
            const SizedBox(width: 4),
            Expanded(child: _vehicleSummary()),
            const SizedBox(width: 8),
            _settingsButton(),
          ],
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack = constraints.maxWidth < 300;
            if (stack) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StartButton(),
                  SizedBox(height: 8),
                  _RoleSelector(),
                ],
              );
            }
            return const Row(
              children: [
                Expanded(child: _StartButton()),
                SizedBox(width: 8),
                Expanded(child: _RoleSelector()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _tabletHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _menuButton(),
            const SizedBox(width: 8),
            Expanded(child: _vehicleSummary()),
            const SizedBox(width: 8),
            _settingsButton(),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: const Row(
              children: [
                Expanded(child: SizedBox(height: 46, child: _StartButton())),
                SizedBox(width: 12),
                Expanded(child: SizedBox(height: 46, child: _RoleSelector())),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _menuButton() => IconButton(
    onPressed: _noop,
    tooltip: 'Open navigation menu',
    color: Colors.white,
    icon: const Icon(Icons.menu),
  );
  Widget _settingsButton() => IconButton(
    onPressed: _noop,
    tooltip: 'Dashboard and trip settings',
    color: Colors.white,
    icon: const Icon(Icons.settings_outlined),
  );
  Widget _notificationButton() => Badge(
    label: const Text('2'),
    child: IconButton(
      onPressed: _noop,
      tooltip: 'Notifications, 2 unread',
      color: Colors.white,
      iconSize: 30,
      constraints: const BoxConstraints.tightFor(width: 52, height: 52),
      icon: const Icon(Icons.notifications_outlined),
    ),
  );

  Widget _vehicleSummary() {
    final vehicle = _vehicles[_vehicleIndex];
    return _VehicleSummary(
      name: vehicle.$1,
      mileage: vehicle.$2,
      selectedIndex: _vehicleIndex,
      vehicles: _vehicles,
      onSelected: (index) => setState(() => _vehicleIndex = index),
    );
  }

  static void _noop() {}
}

class _VehicleSummary extends StatelessWidget {
  const _VehicleSummary({
    required this.name,
    required this.mileage,
    required this.selectedIndex,
    required this.vehicles,
    required this.onSelected,
  });

  final String name;
  final String mileage;
  final int selectedIndex;
  final List<(String, String)> vehicles;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 380;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PopupMenuButton<int>(
        initialValue: selectedIndex,
        tooltip: 'Change active vehicle',
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (var index = 0; index < vehicles.length; index++)
            PopupMenuItem<int>(
              value: index,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  index == selectedIndex
                      ? Icons.check_circle_rounded
                      : Icons.directions_car_outlined,
                  color: index == selectedIndex ? AppColors.green : null,
                ),
                title: Text(
                  vehicles[index].$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(vehicles[index].$2),
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 8, 6),
          decoration: BoxDecoration(
            color: const Color(0xFF162529),
            border: Border.all(color: const Color(0xFF607B82), width: 1.2),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ACTIVE VEHICLE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 13 : 14,
                        fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
                        letterSpacing: .35,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$name · $mileage',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD0D9DA),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.08,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _noop,
      icon: const Icon(Icons.play_arrow_rounded, size: 20),
      label: const Text('Start workday'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF20F060),
        foregroundColor: Colors.black,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void _noop() {}
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 46, minWidth: 118),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF24353A),
        border: Border.all(color: const Color(0xFF607B82), width: 1.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              'View: Admin',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 5),
          Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
        ],
      ),
    );
  }
}
