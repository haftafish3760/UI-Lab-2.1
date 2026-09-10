import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_extension.dart';
import '../../data/notifications/native_notification_gateway.dart';
import '../../data/notifications/native_notification_ui_controller.dart';
import '../../shared/section_card.dart';
import '../../theme/app_semantic_colors.dart';

class DeviceReminderStatus extends StatelessWidget {
  const DeviceReminderStatus({required this.requestSound, super.key});

  final bool requestSound;

  @override
  Widget build(BuildContext context) {
    final controller = NativeNotificationUiScope.maybeOf(context);
    if (controller == null ||
        controller.phase == NativeNotificationUiPhase.loading ||
        (controller.phase != NativeNotificationUiPhase.failed &&
            (controller.permission ==
                    NativeNotificationPermissionState.unsupported ||
                controller.isGranted))) {
      return const SizedBox.shrink();
    }
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final requesting = controller.phase == NativeNotificationUiPhase.requesting;
    final failed = controller.phase == NativeNotificationUiPhase.failed;
    final body = failed
        ? context.l10n.deviceRemindersFailed
        : controller.permissionWasRequested
        ? context.l10n.deviceRemindersDenied
        : context.l10n.deviceRemindersOffBody;
    return SectionCard(
      key: const ValueKey('device-reminder-status'),
      backgroundColor: failed
          ? semantic.dangerSurface
          : semantic.plannedSurface,
      borderColor: failed ? semantic.danger : semantic.planned,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            failed
                ? Icons.error_outline_rounded
                : Icons.notifications_off_outlined,
            color: failed ? semantic.danger : semantic.planned,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  failed
                      ? context.l10n.deviceRemindersUnavailableTitle
                      : context.l10n.deviceRemindersOffTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(body),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const ValueKey('enable-device-reminders'),
                  onPressed: requesting
                      ? null
                      : failed
                      ? controller.load
                      : () => controller.enable(sound: requestSound),
                  icon: requesting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          failed
                              ? Icons.refresh_rounded
                              : Icons.notifications_active_outlined,
                        ),
                  label: Text(
                    requesting
                        ? context.l10n.deviceRemindersEnabling
                        : failed
                        ? context.l10n.deviceRemindersRetry
                        : context.l10n.deviceRemindersEnable,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
