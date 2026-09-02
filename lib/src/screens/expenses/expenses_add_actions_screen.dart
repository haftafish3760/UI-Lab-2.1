part of 'expenses_screen.dart';

class _ExpenseAddActionsScreen extends StatelessWidget {
  const _ExpenseAddActionsScreen({
    required this.date,
    required this.permissions,
  });

  final DateTime date;
  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: const ValueKey('expense-add-actions-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final availableWidth = constraints.maxWidth - insets.horizontal;
            final shortcuts = AppLayoutEngine.workShortcutsFor(
              availableWidth.clamp(0, 620),
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExpensesScopeHeader(
                          view: scope.view,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                          onSettings: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ExpensesSettingsScreen(),
                            ),
                          ),
                          showSettings: permissions.canConfigureDisplay,
                          workspaceLabel: 'Add expense',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          operationalDateLabel(context, date),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: shortcuts.gap,
                          runSpacing: shortcuts.gap,
                          children: [
                            if (permissions.canCreate) ...[
                              _ExpenseAddActionTile(
                                width: shortcuts.tileWidth,
                                icon: Icons.add_card_outlined,
                                label: 'Record expense',
                                onTap: () => Navigator.pop(
                                  context,
                                  _ExpenseAction.expense,
                                ),
                              ),
                              _ExpenseAddActionTile(
                                width: shortcuts.tileWidth,
                                icon: Icons.local_gas_station_outlined,
                                label: 'Add fuel',
                                onTap: () =>
                                    Navigator.pop(context, _ExpenseAction.fuel),
                              ),
                            ],
                            if (permissions.canAttachReceipt)
                              _ExpenseAddActionTile(
                                width: shortcuts.tileWidth,
                                icon: Icons.receipt_long_outlined,
                                label: 'Add receipt',
                                onTap: () => Navigator.pop(
                                  context,
                                  _ExpenseAction.receipt,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseAddActionTile extends StatelessWidget {
  const _ExpenseAddActionTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
