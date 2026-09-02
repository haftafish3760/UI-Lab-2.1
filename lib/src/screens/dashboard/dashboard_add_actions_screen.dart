import 'package:flutter/material.dart';

import '../../layout/app_layout_engine.dart';
import '../../shared/localized_date.dart';
import '../../shared/section_card.dart';

enum DashboardAddAction {
  schedule,
  job,
  estimate,
  invoice,
  expense,
  fuel,
  receipt,
  dayRecord,
}

extension DashboardAddActionPresentation on DashboardAddAction {
  String get label => switch (this) {
    DashboardAddAction.schedule => 'Schedule Job',
    DashboardAddAction.job => 'Create Job',
    DashboardAddAction.estimate => 'Create Estimate',
    DashboardAddAction.invoice => 'Create Invoice',
    DashboardAddAction.expense => 'Record Expense',
    DashboardAddAction.fuel => 'Record Fuel',
    DashboardAddAction.receipt => 'Add Receipt',
    DashboardAddAction.dayRecord => 'Add Day Record',
  };

  String get detail => switch (this) {
    DashboardAddAction.schedule => 'Create and schedule work for this date',
    DashboardAddAction.job => 'Create and schedule service work',
    DashboardAddAction.estimate => 'Prepare a customer proposal',
    DashboardAddAction.invoice => 'Bill for completed work',
    DashboardAddAction.expense => 'Record a business cost',
    DashboardAddAction.fuel => 'Record a vehicle fuel purchase',
    DashboardAddAction.receipt => 'Capture or choose receipt evidence',
    DashboardAddAction.dayRecord => 'Add an authorized historical entry',
  };

  IconData get icon => switch (this) {
    DashboardAddAction.schedule => Icons.event_available_outlined,
    DashboardAddAction.job => Icons.home_repair_service_outlined,
    DashboardAddAction.estimate => Icons.request_quote_outlined,
    DashboardAddAction.invoice => Icons.receipt_long_outlined,
    DashboardAddAction.expense => Icons.add_card_outlined,
    DashboardAddAction.fuel => Icons.local_gas_station_outlined,
    DashboardAddAction.receipt => Icons.document_scanner_outlined,
    DashboardAddAction.dayRecord => Icons.playlist_add_outlined,
  };

  Key get controlKey => switch (this) {
    DashboardAddAction.schedule => const ValueKey('add-schedule-action'),
    DashboardAddAction.dayRecord => const ValueKey('add-entry-action'),
    _ => ValueKey('dashboard-add-$name-action'),
  };
}

class DashboardAddActionsScreen extends StatelessWidget {
  const DashboardAddActionsScreen({
    required this.day,
    required this.actions,
    super.key,
  });

  final DateTime day;
  final List<DashboardAddAction> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('dashboard-add-actions-screen'),
      appBar: AppBar(title: const Text('Dashboard Actions')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            final availableWidth = constraints.maxWidth - insets.horizontal;
            final layout = AppLayoutEngine.workShortcutsFor(
              availableWidth,
              textScaler: MediaQuery.textScalerOf(context),
            );
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 16, insets.right, 24),
              children: [
                Text(
                  operationalDateLabel(context, day),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose an action. Each shortcut opens the screen that owns that record.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: layout.gap,
                  runSpacing: layout.gap,
                  children: [
                    for (final action in actions)
                      SizedBox(
                        width: layout.tileWidth,
                        child: _DashboardActionTile(
                          action: action,
                          onPressed: () => Navigator.of(context).pop(action),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardActionTile extends StatelessWidget {
  const _DashboardActionTile({required this.action, required this.onPressed});

  final DashboardAddAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SectionCard(
      padding: EdgeInsets.zero,
      backgroundColor: colors.surfaceContainerLow,
      child: InkWell(
        key: action.controlKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: colors.primary, size: 28),
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
              const SizedBox(height: 4),
              Text(
                action.detail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
