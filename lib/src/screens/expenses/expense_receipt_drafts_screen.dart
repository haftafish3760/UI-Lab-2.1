import 'package:flutter/material.dart';

import '../../data/prototype_operations_store.dart';
import '../../data/receipts/receipt_draft_ui_adapter.dart';
import '../../data/receipts/receipt_draft_ui_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/app_view_mode.dart';
import '../../shared/localized_date.dart';
import '../../shared/operational_scope.dart';
import '../../theme/app_theme.dart';
import '../dashboard/dashboard_models.dart';
import 'expense_models.dart';
import 'expense_permissions.dart';
import 'expenses_scope_header.dart';
import 'expenses_settings_screen.dart';
import 'receipt_intake_screen.dart';

class ExpenseReceiptDraftsScreen extends StatelessWidget {
  const ExpenseReceiptDraftsScreen({
    this.permissions = const ExpensePermissions.development(),
    super.key,
  });

  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    if (!permissions.canView || !permissions.canAttachReceipt) {
      return const Scaffold(
        key: ValueKey('expense-receipt-drafts-screen'),
        body: SafeArea(
          child: Center(
            child: Text('You do not have permission to review receipts.'),
          ),
        ),
      );
    }
    final scope = OperationalScope.of(context);
    final controller = ReceiptDraftUiScope.maybeOf(context);
    final allDrafts = controller == null
        ? PrototypeOperationsScope.of(context).expenseStore.receiptDrafts
        : controller.records
              .map(
                (stored) => ReceiptDraftUiAdapter.toUi(
                  stored,
                  (employeeId) => dashboardEmployeeById(employeeId).name,
                ),
              )
              .toList(growable: false);
    final ownerEmployeeId = scope.selectedEmployeeId ?? 'alex';
    final drafts =
        scope.view == AppViewMode.admin && scope.selectedEmployeeId == null
        ? allDrafts
        : allDrafts
              .where((draft) => draft.ownerEmployeeId == ownerEmployeeId)
              .toList(growable: false);
    return Scaffold(
      key: const ValueKey('expense-receipt-drafts-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: insets.copyWith(top: 10, bottom: 32),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
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
                          workspaceLabel: 'Receipt drafts',
                          showBackButton: true,
                          showEmployeeStrip: false,
                          onBack: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Receipt drafts',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text('Continue an unfinished receipt review.'),
                        const SizedBox(height: 14),
                        if (controller?.showRecoveryNotice == true) ...[
                          _ReceiptDraftStatus(
                            key: const ValueKey(
                              'receipt-drafts-recovery-notice',
                            ),
                            message:
                                'Receipt drafts were recovered from the last safe copy.',
                            actionLabel: 'Dismiss',
                            onAction: controller!.dismissRecoveryNotice,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (controller?.failure case final failure?) ...[
                          _ReceiptDraftStatus(
                            key: const ValueKey('receipt-drafts-failure'),
                            message: failure.message,
                            actionLabel: failure.requiresReload
                                ? 'Reload'
                                : 'Try again',
                            onAction: () {
                              controller!.load();
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (controller?.isLoading == true && drafts.isEmpty)
                          const LinearProgressIndicator(
                            key: ValueKey('receipt-drafts-loading'),
                          )
                        else if (drafts.isEmpty)
                          const _EmptyReceiptDrafts()
                        else
                          for (
                            var index = 0;
                            index < drafts.length;
                            index++
                          ) ...[
                            _ReceiptDraftCard(
                              draft: drafts[index],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<ExpenseRecord>(
                                  builder: (_) => ReceiptIntakeScreen(
                                    draftId: drafts[index].id,
                                    expenseDate: drafts[index].expenseDate,
                                    draftTitle: drafts[index].title,
                                    permissions: permissions,
                                  ),
                                ),
                              ),
                            ),
                            if (index != drafts.length - 1)
                              const SizedBox(height: 10),
                          ],
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

class _EmptyReceiptDrafts extends StatelessWidget {
  const _EmptyReceiptDrafts();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('receipt-drafts-empty'),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: const Text('No unfinished receipt drafts.'),
  );
}

class _ReceiptDraftStatus extends StatelessWidget {
  const _ReceiptDraftStatus({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      border: Border.all(color: Theme.of(context).colorScheme.outline),
      borderRadius: BorderRadius.circular(AppRadii.control),
    ),
    child: Row(
      children: [
        Expanded(child: Text(message)),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    ),
  );
}

class _ReceiptDraftCard extends StatelessWidget {
  const _ReceiptDraftCard({required this.draft, required this.onTap});

  final ExpenseReceiptDraft draft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey('expense-receipt-draft-${draft.id}'),
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outline),
        borderRadius: BorderRadius.circular(AppRadii.control),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        draft.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${draft.imageCount == 0 ? 'Manual entry' : '${draft.imageCount} ${draft.imageCount == 1 ? 'image' : 'images'}'} · ${operationalDateLabel(context, draft.updatedOn, weekday: false)}',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
