import 'package:flutter/material.dart';

import '../layout/dashboard_layout.dart';
import '../theme/app_theme.dart';

const _destinations = [
  (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
  (Icons.work_outline_rounded, Icons.work_rounded, 'Work'),
  (Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Expenses'),
  (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Materials'),
  (Icons.build_outlined, Icons.build_rounded, 'Maintenance'),
];

class DashboardNavigationRail extends StatelessWidget {
  const DashboardNavigationRail({required this.onUnavailable, super.key});

  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return Container(
      key: const ValueKey('dashboard-navigation-rail'),
      width: DashboardLayout.railWidth,
      color: colors.header,
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.entries,
                foregroundColor: colors.onHeader,
                child: const Icon(Icons.handyman_rounded, size: 19),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'MAINTAINIAC',
                  style: TextStyle(
                    color: colors.onHeader,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < _destinations.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: index == 0 ? colors.headerControl : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: index == 0
                      ? null
                      : () => onUnavailable(_destinations[index].$3),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          index == 0
                              ? _destinations[index].$2
                              : _destinations[index].$1,
                          color: index == 0
                              ? colors.onHeader
                              : colors.onHeader.withValues(alpha: .72),
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _destinations[index].$3,
                            style: TextStyle(
                              color: index == 0
                                  ? colors.onHeader
                                  : colors.onHeader.withValues(alpha: .72),
                              fontSize: 12.5,
                              fontWeight: index == 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Text(
            'Dashboard review build',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onHeader.withValues(alpha: .58),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({required this.onUnavailable, super.key});

  final ValueChanged<String> onUnavailable;

  @override
  Widget build(BuildContext context) => NavigationBar(
    key: const ValueKey('dashboard-bottom-navigation'),
    selectedIndex: 0,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    onDestinationSelected: (index) {
      if (index != 0) onUnavailable(_destinations[index].$3);
    },
    destinations: [
      for (var index = 0; index < _destinations.length; index++)
        NavigationDestination(
          icon: Icon(_destinations[index].$1),
          selectedIcon: Icon(_destinations[index].$2),
          label: _destinations[index].$3,
        ),
    ],
  );
}
