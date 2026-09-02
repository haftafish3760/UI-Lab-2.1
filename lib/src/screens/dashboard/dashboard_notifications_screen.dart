import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../data/notifications/notification_records.dart';
import '../../data/notifications/notification_terms.dart';
import '../../data/notifications/notification_ui_controller.dart';
import '../../layout/app_layout_engine.dart';
import '../../shared/section_card.dart';
import '../expenses/expense_permissions.dart';
import '../work/work_detail_header.dart';
import 'dashboard_notification_copy.dart';
import 'notification_source_route.dart';

class DashboardNotificationsScreen extends StatelessWidget {
  const DashboardNotificationsScreen({required this.permissions, super.key});

  final ExpensePermissions permissions;

  @override
  Widget build(BuildContext context) {
    final controller = NotificationUiScope.of(context);
    final asOf = DateUtils.dateOnly(DateTime.now());
    final items = controller.events;
    return Scaffold(
      key: const ValueKey('dashboard-notifications-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final insets = AppLayoutEngine.pageInsetsFor(constraints.maxWidth);
            return ListView(
              padding: EdgeInsets.fromLTRB(insets.left, 10, insets.right, 28),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkDetailHeader(
                          label: context.l10n.notificationsTitle,
                          selectedDay: asOf,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.notificationsHeading,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                            ),
                            if (controller.hasUnread)
                              TextButton(
                                onPressed: controller.markAllRead,
                                child: Text(
                                  context.l10n.notificationsMarkAllRead,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(context.l10n.notificationsDescription),
                        const SizedBox(height: 12),
                        if (controller.phase == NotificationUiPhase.loading &&
                            items.isEmpty)
                          const SectionCard(
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (controller.phase ==
                                NotificationUiPhase.failed &&
                            items.isEmpty)
                          SectionCard(
                            child: Text(context.l10n.notificationsLoadFailed),
                          )
                        else if (items.isEmpty)
                          SectionCard(
                            child: Text(context.l10n.notificationsEmpty),
                          )
                        else
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _NotificationRow(
                              item: items[index],
                              asOf: asOf,
                              onOpen: () =>
                                  _open(context, controller, items[index]),
                            ),
                            if (index != items.length - 1)
                              const SizedBox(height: 8),
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

  Future<void> _open(
    BuildContext context,
    NotificationUiController controller,
    StoredNotificationEvent item,
  ) async {
    await controller.markRead(item);
    if (!context.mounted) return;
    final route = notificationSourceRoute(
      item,
      expensePermissions: permissions,
    );
    if (route != null) {
      await Navigator.of(context).push(route);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.notificationsLoadFailed)),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.item,
    required this.asOf,
    required this.onOpen,
  });

  final StoredNotificationEvent item;
  final DateTime asOf;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRead = item.readState == NotificationReadState.read;
    final copy = dashboardNotificationCopy(context, item, asOf: asOf);
    final readState = isRead
        ? context.l10n.notificationReadState
        : context.l10n.notificationUnreadState;
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${copy.title}. ${copy.message}. $readState.',
      child: Material(
        key: ValueKey('notification-${item.notificationId}'),
        color: isRead ? colors.surfaceContainerLow : colors.secondaryContainer,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.outline),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          mouseCursor: SystemMouseCursors.click,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_outlined,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          copy.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(copy.message),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
