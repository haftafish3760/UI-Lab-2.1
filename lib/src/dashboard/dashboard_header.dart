import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.showWideActions,
    required this.onOpenMenu,
    required this.onOpenSettings,
    required this.onAddRecord,
    super.key,
  });

  final bool showWideActions;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenSettings;
  final VoidCallback onAddRecord;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return Container(
      key: const ValueKey('dashboard-header'),
      decoration: BoxDecoration(
        color: colors.header,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.headerControl),
      ),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          return Row(
            children: [
              _HeaderIcon(
                icon: Icons.menu_rounded,
                tooltip: 'Business menu',
                onPressed: onOpenMenu,
              ),
              const SizedBox(width: 6),
              if (compact)
                const Expanded(child: _CompactOperationalContext())
              else ...[
                const SizedBox(
                  width: 230,
                  child: _HeaderControl(
                    label: 'VIEW',
                    value: 'Technician · Alex Morgan',
                    icon: Icons.engineering_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(
                  width: 220,
                  child: _HeaderControl(
                    label: 'ACTIVE VEHICLE',
                    value: 'Transit 12',
                    icon: Icons.local_shipping_outlined,
                  ),
                ),
                const Spacer(),
                if (showWideActions) ...[
                  OutlinedButton.icon(
                    onPressed: onAddRecord,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onHeader,
                      side: BorderSide(color: colors.headerControl),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text('Add record'),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
              const SizedBox(width: 6),
              _HeaderIcon(
                icon: Icons.settings_outlined,
                tooltip: 'Dashboard settings',
                onPressed: onOpenSettings,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CompactOperationalContext extends StatelessWidget {
  const _CompactOperationalContext();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return Semantics(
      label: 'Technician view. Alex Morgan. Active vehicle Transit 12.',
      button: true,
      child: Container(
        key: const ValueKey('compact-operational-context'),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: colors.headerControl,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_shipping_outlined,
              color: colors.onHeader,
              size: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Alex Morgan · Transit 12',
                style: TextStyle(
                  color: colors.onHeader,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.expand_more_rounded, color: colors.onHeader, size: 18),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      color: colors.onHeader,
      style: IconButton.styleFrom(
        backgroundColor: colors.headerControl,
        minimumSize: const Size(44, 44),
        fixedSize: const Size(44, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _HeaderControl extends StatelessWidget {
  const _HeaderControl({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<DashboardColors>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.headerControl,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.onHeader, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.onHeader.withValues(alpha: .7),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.onHeader,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.expand_more_rounded, color: colors.onHeader, size: 18),
        ],
      ),
    );
  }
}
