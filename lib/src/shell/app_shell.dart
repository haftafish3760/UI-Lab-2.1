import 'package:flutter/material.dart';

import '../layout/app_layout_engine.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/expenses/expense_welcome_screen.dart';
import '../screens/expenses/expense_permissions.dart';
import '../shared/app_preferences.dart';
import '../shared/operational_scope.dart';
import '../shared/module_landing_navigation.dart';
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
  bool _openingExpenses = false;
  bool _dashboardHandlesBack = false;
  bool _selectingModule = false;
  final _navigation = List.generate(5, (_) => ModuleLandingNavigation());
  ModuleLandingNavigation get _dashboardNavigation => _navigation[0];

  NavigatorState? get _activeNavigator =>
      _navigation[_selectedIndex].key.currentState;

  Widget _moduleNavigator(
    ModuleLandingNavigation navigation,
    Widget home,
  ) => NotificationListener<NavigationNotification>(
    onNotification: (notification) {
      if (navigation == _dashboardNavigation &&
          _dashboardHandlesBack != notification.canHandlePop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _dashboardHandlesBack != notification.canHandlePop) {
            setState(() => _dashboardHandlesBack = notification.canHandlePop);
          }
        });
      }
      return false;
    },
    child: ModuleLandingScope(
      navigation: navigation,
      child: Navigator(
        key: navigation.key,
        observers: [navigation],
        onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => home),
      ),
    ),
  );

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
    final navigation = AppLayoutEngine.navigationFor(availableSize);
    final desktop = navigation == AppNavigationMode.rail;
    return PopScope(
      canPop: _selectedIndex == 0 && !_dashboardHandlesBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = _activeNavigator;
        if (navigator != null && navigator.canPop()) {
          // maybePop consults the editor's save/discard guard. Do not jump
          // modules when a protected route elects to stay open.
          navigator.maybePop();
        } else if (_selectedIndex != 0) {
          _selectModule(0);
        }
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
                          children: [
                            for (
                              var index = 0;
                              index < _modules.length;
                              index++
                            )
                              _moduleNavigator(
                                _navigation[index],
                                _modules[index],
                              ),
                          ],
                        ),
                      ),
                      if (desktop && _selectedIndex == 1)
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 728),
                            child: const PrototypeAdBanner(),
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
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: _selectedIndex == 1 ? 728 : double.infinity,
                      ),
                      child: const PrototypeAdBanner(),
                    ),
                  ),
                  AppBottomNavigation(
                    selectedIndex: _selectedIndex,
                    onSelected: _selectModule,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectModule(int index) async {
    if (_selectingModule || _openingExpenses) return;
    _selectingModule = true;
    try {
      if (!await _navigation[_selectedIndex].returnToLanding()) return;
      if (!mounted) return;
      await _openModule(index);
    } finally {
      _selectingModule = false;
    }
  }

  Future<void> _openModule(int index) async {
    final preferences = AppPreferencesScope.maybeOf(context);
    final permissions = expensePermissionsForView(
      OperationalScope.of(context).view,
    );
    if (index == 2 &&
        permissions.canView &&
        permissions.canConfigureDisplay &&
        preferences != null &&
        !preferences.expenseSetupCompleted) {
      _openingExpenses = true;
      try {
        final completed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ExpenseWelcomeScreen(preferences: preferences),
          ),
        );
        if (!mounted || completed != true) return;
      } finally {
        _openingExpenses = false;
      }
    }
    if (!mounted) return;
    setState(() => _selectedIndex = index);
  }

  void _openMenu() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const OperationsMenuScreen()));
}
