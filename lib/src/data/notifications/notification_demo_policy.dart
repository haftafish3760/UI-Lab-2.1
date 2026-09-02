import 'authorized_notification_service.dart';
import 'notification_repository.dart';

const demoNotificationOrganizationId = 'maintainiac-demo-company';
const demoNotificationEmployeeId = 'alex';
const demoNotificationPermissionRevision = 'demo-notification-permissions-1';

NotificationCommandPermissions demoNotificationUserPermissions() =>
    NotificationCommandPermissions(
      organizationId: demoNotificationOrganizationId,
      actorEmployeeId: demoNotificationEmployeeId,
      permissionRevision: demoNotificationPermissionRevision,
      readScope: NotificationReadScope.own,
      canChangeOwnReadState: true,
    );

NotificationCommandPermissions demoNotificationPublisherPermissions() =>
    NotificationCommandPermissions(
      organizationId: demoNotificationOrganizationId,
      actorEmployeeId: 'notification-source-service',
      permissionRevision: demoNotificationPermissionRevision,
      readScope: NotificationReadScope.company,
      canPublish: true,
      canPublishToOtherEmployees: true,
      canChangeOwnReadState: true,
      canChangeOtherReadState: true,
      canManageDelivery: true,
    );
