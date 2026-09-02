part of 'work_screen.dart';

enum _WorkAction {
  createEstimate,
  createInvoice,
  createJob,
  recordPayment,
  addContact,
}

extension on _WorkAction {
  String get label => switch (this) {
    _WorkAction.createEstimate => 'New Estimate',
    _WorkAction.createInvoice => 'New Invoice',
    _WorkAction.createJob => 'New Job',
    _WorkAction.recordPayment => 'Record Payment',
    _WorkAction.addContact => 'Add Customer',
  };

  String get detail => switch (this) {
    _WorkAction.createEstimate => 'Price proposed work',
    _WorkAction.createInvoice => 'Bill completed work',
    _WorkAction.createJob => 'Plan service work',
    _WorkAction.recordPayment => 'Record money received',
    _WorkAction.addContact => 'Save a customer',
  };

  IconData get icon => switch (this) {
    _WorkAction.createInvoice => Icons.receipt_long_rounded,
    _WorkAction.createEstimate => Icons.assignment_rounded,
    _WorkAction.createJob => Icons.handyman_rounded,
    _WorkAction.recordPayment => Icons.payments_rounded,
    _WorkAction.addContact => Icons.person_add_alt_1_rounded,
  };
}

class _WorkActionsScreen extends StatelessWidget {
  const _WorkActionsScreen.home({required this.day, required this.actions})
    : screenKey = const ValueKey('work-actions-screen'),
      actionKeyPrefix = 'work-action';

  const _WorkActionsScreen.day({required this.day, required this.actions})
    : screenKey = const ValueKey('work-day-actions-screen'),
      actionKeyPrefix = 'work-day-action';

  final DateTime day;
  final List<_WorkAction> actions;
  final ValueKey<String> screenKey;
  final String actionKeyPrefix;

  @override
  Widget build(BuildContext context) {
    final scope = OperationalScope.of(context);
    return Scaffold(
      key: screenKey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final available = constraints.maxWidth - insets.horizontal;
            final layout = AppLayoutEngine.detailWorkspaceFor(
              available,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: SizedBox(
                    width: layout.workspaceWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkScopeHeader(
                          view: scope.view,
                          selectedDay: day,
                          selectedEmployeeId: scope.selectedEmployeeId,
                          workspaceLabel: 'Add Work',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          showDateDescription: false,
                          onBack: () => Navigator.of(context).pop(),
                          onViewChanged: scope.setView,
                          onEmployeeChanged: scope.selectEmployee,
                        ),
                        const SizedBox(height: 14),
                        _WorkActionGrid(
                          actions: actions,
                          actionKeyPrefix: actionKeyPrefix,
                          onSelected: (action) =>
                              Navigator.of(context).pop(action),
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

class _WorkActionGrid extends StatelessWidget {
  const _WorkActionGrid({
    required this.actions,
    required this.actionKeyPrefix,
    required this.onSelected,
  });

  final List<_WorkAction> actions;
  final String actionKeyPrefix;
  final ValueChanged<_WorkAction> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = AppLayoutEngine.workShortcutsFor(
        constraints.maxWidth,
        textScaler: MediaQuery.textScalerOf(context),
      );
      return Wrap(
        alignment: WrapAlignment.start,
        spacing: layout.gap,
        runSpacing: layout.gap,
        children: [
          for (final action in actions)
            SizedBox(
              width: layout.tileWidth,
              child: _WorkActionTile(
                action: action,
                iconExtent: layout.iconExtent,
                actionKey: ValueKey('$actionKeyPrefix-${action.name}'),
                onTap: () => onSelected(action),
              ),
            ),
        ],
      );
    },
  );
}

class _WorkActionTile extends StatelessWidget {
  const _WorkActionTile({
    required this.action,
    required this.iconExtent,
    required this.actionKey,
    required this.onTap,
  });

  final _WorkAction action;
  final double iconExtent;
  final ValueKey<String> actionKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final (accent, surface) = switch (action) {
      _WorkAction.createJob => (semantic.current, semantic.currentSurface),
      _WorkAction.createEstimate => (semantic.planned, semantic.plannedSurface),
      _WorkAction.createInvoice => (semantic.success, semantic.successSurface),
      _WorkAction.recordPayment => (semantic.success, semantic.successSurface),
      _WorkAction.addContact => (semantic.current, semantic.currentSurface),
    };
    return Semantics(
      button: true,
      label: '${action.label}. ${action.detail}',
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          side: BorderSide(color: accent, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: actionKey,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 112),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: iconExtent,
                    height: iconExtent,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: Icon(action.icon, color: accent, size: 29),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    action.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _recordIcon(WorkRecordKind kind) => switch (kind) {
  WorkRecordKind.job => Icons.handyman_outlined,
  WorkRecordKind.invoice => Icons.receipt_long_outlined,
  WorkRecordKind.estimate => Icons.request_quote_outlined,
};
