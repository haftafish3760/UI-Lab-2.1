import 'package:flutter/material.dart';

import '../../l10n/app_localizations_extension.dart';
import '../layout/app_layout_engine.dart';
import '../theme/app_theme.dart';

enum AppModule { dashboard, work, expenses, inventory, maintenance }

class AppDestination {
  const AppDestination({
    required this.module,
    required this.icon,
    required this.selectedIcon,
  });

  final AppModule module;
  final IconData icon;
  final IconData selectedIcon;

  String label(BuildContext context) => switch (module) {
    AppModule.dashboard => context.l10n.navDashboard,
    AppModule.work => context.l10n.navWork,
    AppModule.expenses => context.l10n.navExpenses,
    AppModule.inventory => context.l10n.navInventory,
    AppModule.maintenance => context.l10n.navMaintenance,
  };

  String compactLabel(BuildContext context) => switch (module) {
    AppModule.dashboard => context.l10n.navDashboardCompact,
    _ => label(context),
  };

  Color color(BuildContext context) {
    final colors = Theme.of(context).extension<AppModuleColors>()!;
    return switch (module) {
      AppModule.dashboard => colors.dashboard,
      AppModule.work => colors.work,
      AppModule.expenses => colors.expenses,
      AppModule.inventory => colors.inventory,
      AppModule.maintenance => colors.maintenance,
    };
  }

  NavigationDestination bottomDestination(BuildContext context) {
    final tone = color(context);
    return NavigationDestination(
      key: ValueKey('app-destination-${module.name}'),
      icon: Icon(icon, color: tone),
      selectedIcon: Icon(
        selectedIcon,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        size: 28,
      ),
      label: compactLabel(context),
    );
  }
}

const appDestinations = <AppDestination>[
  AppDestination(
    module: AppModule.dashboard,
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  AppDestination(
    module: AppModule.work,
    icon: Icons.work_outline,
    selectedIcon: Icons.work,
  ),
  AppDestination(
    module: AppModule.expenses,
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  AppDestination(
    module: AppModule.inventory,
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  AppDestination(
    module: AppModule.maintenance,
    icon: Icons.build_outlined,
    selectedIcon: Icons.build,
  ),
];

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final type = AppLayoutEngine.typographyFor(constraints.maxWidth);
      final colors = Theme.of(context).colorScheme;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        child: SafeArea(
          key: const ValueKey('app-bottom-safe-area'),
          top: false,
          minimum: const EdgeInsets.only(bottom: 4),
          maintainBottomViewPadding: true,
          child: SizedBox(
            height: type.bottomNavigationHeight,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: NavigationBar(
                height: type.bottomNavigationHeight,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: selectedIndex,
                destinations: [
                  for (final destination in appDestinations)
                    destination.bottomDestination(context),
                ],
                onDestinationSelected: onSelected,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PrototypeAdBanner extends StatelessWidget {
  const PrototypeAdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: context.l10n.advertisementPlaceholder,
      child: Container(
        key: const ValueKey('prototype-ad-banner'),
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 52),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                border: Border.all(color: colors.outline),
                borderRadius: BorderRadius.circular(AppRadii.control),
              ),
              child: const Icon(Icons.campaign_outlined, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.advertisement,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.l10n.sampleAdSpace,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(context.l10n.demo, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class DesktopAppNavigation extends StatelessWidget {
  const DesktopAppNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayoutEngine.railWidth,
      color: AppColors.header,
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.handyman, color: AppColors.green, size: 30),
                const SizedBox(height: 8),
                const Text(
                  'MAINTAINIAC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.onHeader,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.fieldRecords,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.onHeaderMuted),
                ),
                const SizedBox(height: 22),
                for (var index = 0; index < appDestinations.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        key: ValueKey(
                          'desktop-destination-${appDestinations[index].module.name}',
                        ),
                        selected: index == selectedIndex,
                        selectedTileColor: AppColors.headerControl,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.control),
                        ),
                        leading: Icon(
                          index == selectedIndex
                              ? appDestinations[index].selectedIcon
                              : appDestinations[index].icon,
                          color: appDestinations[index].color(context),
                        ),
                        title: Text(
                          appDestinations[index].label(context),
                          style: TextStyle(
                            color: index == selectedIndex
                                ? AppColors.onHeader
                                : AppColors.onHeaderMuted,
                            fontWeight: index == selectedIndex
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        onTap: () => onSelected(index),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.offlineRecordsAvailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.onHeaderMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
