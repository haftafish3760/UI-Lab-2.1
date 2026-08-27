import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

const dashboardDestinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: 'Dashboard',
  ),
  NavigationDestination(
    icon: Icon(Icons.work_outline),
    selectedIcon: Icon(Icons.work),
    label: 'Work',
  ),
  NavigationDestination(
    icon: Icon(Icons.receipt_long_outlined),
    selectedIcon: Icon(Icons.receipt_long),
    label: 'Expenses',
  ),
  NavigationDestination(
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    label: 'Inventory',
  ),
  NavigationDestination(
    icon: Icon(Icons.build_outlined),
    selectedIcon: Icon(Icons.build),
    label: 'Maintenance',
  ),
];

class DesktopNavigation extends StatelessWidget {
  const DesktopNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              child: Icon(Icons.handyman),
            ),
            title: Text(
              'MAINTAINIAC',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            subtitle: Text(
              'Field records',
              style: TextStyle(color: Color(0xFFB8C6C2)),
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < dashboardDestinations.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  selected: i == 0,
                  selectedTileColor: const Color(0xFF29423C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: IconTheme(
                    data: IconThemeData(
                      color: i == 0 ? const Color(0xFF62D59D) : Colors.white70,
                    ),
                    child: dashboardDestinations[i].icon,
                  ),
                  title: Text(
                    dashboardDestinations[i].label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  onTap: () {},
                ),
              ),
            ),
          const Spacer(),
          const Text(
            'Records stay available offline.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB8C6C2), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
