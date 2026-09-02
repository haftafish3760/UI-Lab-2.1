import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/modules/module_home_screen.dart';
import '../screens/work/work_screen.dart';
import 'app_menu_scope.dart';
import 'app_navigation.dart';
import 'expense_repository_status_banner.dart';
import 'operations_menu_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  var _selectedIndex = 0;

  static const _modules = <Widget>[
    DashboardScreen(),
    WorkScreen(),
    ExpensesScreen(),
    InventoryScreen(),
    ModuleHomeScreen.maintenance(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }
        return _buildShell(
          context,
          Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }

  Widget _buildShell(BuildContext context, Size availableSize) {
    final navigation = AppLayoutEngine.navigationFor(
      availableSize,
      dashboard: _selectedIndex == 0,
    );
    final desktop = navigation == AppNavigationMode.rail;
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedIndex != 0) _selectModule(0);
      },
      child: Scaffold(
        body: SafeArea(
          bottom: desktop,
          child: Row(
            children: [
              if (desktop)
                DesktopAppNavigation(
                  selectedIndex: _selectedIndex,
                  onSelected: _selectModule,
                ),
              Expanded(
                child: AppMenuScope(
                  onOpen: _openMenu,
                  child: Column(
                    children: [
                      const ExpenseRepositoryStatusBanner(),
                      Expanded(
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: _modules,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: desktop
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PrototypeAdBanner(),
                  AppBottomNavigation(
                    selectedIndex: _selectedIndex,
                    onSelected: _selectModule,
                  ),
                ],
              ),
      ),
    );
  }

  void _selectModule(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  void _openMenu() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const OperationsMenuScreen()));
}
