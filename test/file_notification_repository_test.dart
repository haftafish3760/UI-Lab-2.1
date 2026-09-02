import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_records.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_terms.dart';

void main() {
  test('publish, read state, exact route, and restart are durable', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notification-restart-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileNotificationRepository.open(directory);
    final service = AuthorizedNotificationService(repository);
    final event = _event();
    final deliveries = _deliveries(event);
    final first = await service.publish(
      event: event,
      deliveries: deliveries,
      permissions: _systemPermissions(),
      occurredAtUtc: DateTime.utc(2027, 9, 1, 12),
    );
    final retry = await service.publish(
      event: event,
      deliveries: deliveries,
      permissions: _systemPermissions(),
      occurredAtUtc: DateTime.utc(2027, 9, 1, 12, 1),
    );
    expect(first.wasAlreadyPublished, isFalse);
    expect(retry.wasAlreadyPublished, isTrue);
    expect(retry.event.notificationId, event.notificationId);
    expect(retry.deliveries, hasLength(2));
    final alex = _employeePermissions('employee-alex');
    expect(
      await service.queryEvents(
        permissions: alex,
        availableAtUtc: DateTime.utc(2027, 9, 2, 8, 59),
      ),
      isEmpty,
    );
    final due = await service.queryEvents(
      permissions: alex,
      availableAtUtc: DateTime.utc(2027, 9, 2, 9),
    );
    expect(due, hasLength(1));
    expect(due.single.route.module, NotificationSourceModule.expenses);
    expect(
      due.single.route.sourceType,
      NotificationSourceType.recurringExpense,
    );
    expect(due.single.route.sourceRecordId, 'commercial-insurance');
    expect(due.single.route.sourceChildId, 'commercial-insurance:2027-09-10');
    expect(due.single.content.titleKey, 'notification.recurringExpense.title');
    final read = await service.changeReadState(
      notificationId: event.notificationId,
      state: NotificationReadState.read,
      expectedRevision: 1,
      permissions: alex,
      occurredAtUtc: DateTime.utc(2027, 9, 2, 9, 1),
    );
    expect(read.lifecycle.revision, 2);
    expect(read.auditTrail.last.action, NotificationAuditAction.read);

    final reopened = await FileNotificationRepository.open(directory);
    final reopenedService = AuthorizedNotificationService(reopened);
    expect(
      await reopenedService.unreadCount(
        permissions: alex,
        availableAtUtc: DateTime.utc(2027, 9, 2, 10),
      ),
      0,
    );
    expect(
      (await reopenedService.queryEvents(
        permissions: alex,
        availableAtUtc: DateTime.utc(2027, 9, 2, 10),
      )).single.readState,
      NotificationReadState.read,
    );
  });

  test(
    'authorization isolates recipients, companies, and read state',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'notification-auth-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = await FileNotificationRepository.open(directory);
      final service = AuthorizedNotificationService(repository);
      await _publish(service, _event());
      await _publish(
        service,
        _event(
          id: 'jamie-work',
          deduplicationKey: 'work:job-42:jamie:assigned',
          recipientEmployeeId: 'employee-jamie',
          kind: NotificationEventKind.workAssigned,
          category: NotificationEventCategory.assignment,
          route: NotificationSourceRoute(
            module: NotificationSourceModule.work,
            sourceType: NotificationSourceType.job,
            sourceRecordId: 'job-42',
          ),
        ),
      );
      await _publish(
        service,
        _event(
          id: 'other-company',
          deduplicationKey: 'expense:other-company',
          organizationId: 'organization-2',
          recipientEmployeeId: 'employee-other',
        ),
        permissions: _systemPermissions(organizationId: 'organization-2'),
      );

      final alex = _employeePermissions('employee-alex');
      expect(
        await service.queryEvents(
          permissions: alex,
          availableAtUtc: DateTime.utc(2027, 9, 3),
        ),
        hasLength(1),
      );
      await expectLater(
        service.changeReadState(
          notificationId: 'jamie-work',
          state: NotificationReadState.read,
          expectedRevision: 1,
          permissions: alex,
          occurredAtUtc: DateTime.utc(2027, 9, 3),
        ),
        throwsA(isA<NotificationPermissionDeniedException>()),
      );

      final companyAdmin = NotificationCommandPermissions(
        organizationId: 'organization-1',
        actorEmployeeId: 'employee-admin',
        permissionRevision: 'permissions-admin-1',
        readScope: NotificationReadScope.company,
      );
      expect(
        await service.queryEvents(
          permissions: companyAdmin,
          availableAtUtc: DateTime.utc(2027, 9, 3),
        ),
        hasLength(2),
      );

      final noRead = NotificationCommandPermissions(
        organizationId: 'organization-1',
        actorEmployeeId: 'employee-alex',
        permissionRevision: 'permissions-none',
        readScope: null,
      );
      await expectLater(
        service.queryEvents(
          permissions: noRead,
          availableAtUtc: DateTime.utc(2027, 9, 3),
        ),
        throwsA(isA<NotificationPermissionDeniedException>()),
      );
    },
  );

  test('platform delivery transitions are audited and idempotent', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notification-delivery-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileNotificationRepository.open(directory);
    final service = AuthorizedNotificationService(repository);
    final event = _event();
    await _publish(service, event);
    final permissions = _systemPermissions();

    final scheduled = await service.updateDelivery(
      deliveryId: '${event.notificationId}:push',
      state: NotificationDeliveryState.scheduled,
      expectedRevision: 1,
      permissions: permissions,
      occurredAtUtc: DateTime.utc(2027, 9, 1, 13),
      adapterReference: 'android-local-42',
    );
    expect(scheduled.lifecycle.revision, 2);
    expect(scheduled.attemptCount, 0);
    final delivered = await service.updateDelivery(
      deliveryId: scheduled.deliveryId,
      state: NotificationDeliveryState.delivered,
      expectedRevision: 2,
      permissions: permissions,
      occurredAtUtc: DateTime.utc(2027, 9, 2, 9),
    );
    expect(delivered.adapterReference, 'android-local-42');
    expect(delivered.attemptCount, 1);
    expect(
      delivered.auditTrail.last.action,
      NotificationAuditAction.deliverySucceeded,
    );

    final retry = await service.updateDelivery(
      deliveryId: delivered.deliveryId,
      state: NotificationDeliveryState.delivered,
      expectedRevision: 2,
      permissions: permissions,
      occurredAtUtc: DateTime.utc(2027, 9, 2, 9, 1),
    );
    expect(retry.lifecycle.revision, 3);
    expect(retry.attemptCount, 1);
    await expectLater(
      service.updateDelivery(
        deliveryId: delivered.deliveryId,
        state: NotificationDeliveryState.cancelled,
        expectedRevision: 3,
        permissions: permissions,
        occurredAtUtc: DateTime.utc(2027, 9, 2, 9, 2),
      ),
      throwsA(isA<NotificationInvalidTransitionException>()),
    );
  });

  test(
    'failed delivery can be rescheduled without losing its identity',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'notification-retry-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final repository = await FileNotificationRepository.open(directory);
      final service = AuthorizedNotificationService(repository);
      final event = _event();
      await _publish(service, event);
      final permissions = _systemPermissions();
      final failed = await service.updateDelivery(
        deliveryId: '${event.notificationId}:sound',
        state: NotificationDeliveryState.failed,
        expectedRevision: 1,
        permissions: permissions,
        occurredAtUtc: DateTime.utc(2027, 9, 2, 8),
        failureCode: 'platform-permission-denied',
      );
      expect(failed.attemptCount, 1);
      expect(failed.failureCode, 'platform-permission-denied');
      final rescheduled = await service.updateDelivery(
        deliveryId: failed.deliveryId,
        state: NotificationDeliveryState.scheduled,
        expectedRevision: 2,
        permissions: permissions,
        occurredAtUtc: DateTime.utc(2027, 9, 2, 8, 5),
        adapterReference: 'sound-request-42',
      );
      expect(rescheduled.failureCode, isNull);
      expect(rescheduled.attemptCount, 1);
      final delivered = await service.updateDelivery(
        deliveryId: failed.deliveryId,
        state: NotificationDeliveryState.delivered,
        expectedRevision: 3,
        permissions: permissions,
        occurredAtUtc: DateTime.utc(2027, 9, 2, 9),
      );
      expect(delivered.attemptCount, 2);
      expect(delivered.adapterReference, 'sound-request-42');
    },
  );

  test('damaged newest snapshot falls back to the prior valid slot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notification-recover-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileNotificationRepository.open(directory);
    final service = AuthorizedNotificationService(repository);
    final event = _event();
    await _publish(service, event);
    await service.changeReadState(
      notificationId: event.notificationId,
      state: NotificationReadState.read,
      expectedRevision: 1,
      permissions: _employeePermissions('employee-alex'),
      occurredAtUtc: DateTime.utc(2027, 9, 2, 10),
    );
    await File.fromUri(
      directory.uri.resolve('notifications-1.json'),
    ).writeAsString('damaged');

    final reopened = await FileNotificationRepository.open(directory);
    expect(reopened.recoveredFromDamagedSnapshot, isTrue);
    final restored = await reopened.findEvent(
      notificationId: event.notificationId,
      access: NotificationAccess.own(
        organizationId: 'organization-1',
        employeeId: 'employee-alex',
      ),
    );
    expect(restored?.readState, NotificationReadState.unread);
  });

  test('failed write preserves the last valid notification snapshot', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notification-write-fail-',
    );
    addTearDown(() => directory.delete(recursive: true));
    var writes = 0;
    final repository = await FileNotificationRepository.open(
      directory,
      snapshotWriter: (target, bytes) async {
        writes += 1;
        if (writes == 2) throw const FileSystemException('disk full');
        await target.writeAsBytes(bytes, flush: true);
      },
    );
    final service = AuthorizedNotificationService(repository);
    final event = _event();
    await _publish(service, event);
    await expectLater(
      service.changeReadState(
        notificationId: event.notificationId,
        state: NotificationReadState.read,
        expectedRevision: 1,
        permissions: _employeePermissions('employee-alex'),
        occurredAtUtc: DateTime.utc(2027, 9, 2, 10),
      ),
      throwsA(isA<NotificationStorageException>()),
    );
    final current = await repository.findEvent(
      notificationId: event.notificationId,
      access: NotificationAccess.own(
        organizationId: 'organization-1',
        employeeId: 'employee-alex',
      ),
    );
    expect(current?.readState, NotificationReadState.unread);
    final reopened = await FileNotificationRepository.open(directory);
    expect(
      (await reopened.findEvent(
        notificationId: event.notificationId,
        access: NotificationAccess.own(
          organizationId: 'organization-1',
          employeeId: 'employee-alex',
        ),
      ))?.readState,
      NotificationReadState.unread,
    );
  });

  test('deduplication key cannot be reused for different content', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notification-dedup-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileNotificationRepository.open(directory);
    final service = AuthorizedNotificationService(repository);
    final event = _event();
    await _publish(service, event);
    final conflict = _event(
      id: 'different-id',
      deduplicationKey: event.deduplicationKey,
    );
    await expectLater(
      _publish(service, conflict),
      throwsA(isA<NotificationConflictException>()),
    );
    expect(
      await service.queryEvents(
        permissions: _employeePermissions('employee-alex'),
        availableAtUtc: DateTime.utc(2027, 9, 3),
      ),
      hasLength(1),
    );
  });

  test('expired notifications stay out of the active unread count', () async {
    final directory = await Directory.systemTemp.createTemp(
      'notification-expiry-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final repository = await FileNotificationRepository.open(directory);
    final service = AuthorizedNotificationService(repository);
    await _publish(service, _event(expiresAtUtc: DateTime.utc(2027, 9, 2, 12)));
    final permissions = _employeePermissions('employee-alex');
    expect(
      await service.unreadCount(
        permissions: permissions,
        availableAtUtc: DateTime.utc(2027, 9, 2, 12),
      ),
      0,
    );
    expect(
      await service.queryEvents(
        permissions: permissions,
        availableAtUtc: DateTime.utc(2027, 9, 2, 12),
        includeExpired: true,
      ),
      hasLength(1),
    );
  });
}

Future<NotificationPublishResult> _publish(
  AuthorizedNotificationService service,
  StoredNotificationEvent event, {
  NotificationCommandPermissions? permissions,
}) => service.publish(
  event: event,
  deliveries: _deliveries(event),
  permissions: permissions ?? _systemPermissions(),
  occurredAtUtc: DateTime.utc(2027, 9, 1, 12),
);

StoredNotificationEvent _event({
  String id = 'insurance-reminder-2027-09-02',
  String deduplicationKey =
      'recurring-expense:commercial-insurance:2027-09-10:7-days',
  String organizationId = 'organization-1',
  String recipientEmployeeId = 'employee-alex',
  NotificationEventKind kind = NotificationEventKind.recurringExpenseDue,
  NotificationEventCategory category = NotificationEventCategory.reminder,
  NotificationSourceRoute? route,
  DateTime? expiresAtUtc,
}) => StoredNotificationEvent(
  notificationId: id,
  deduplicationKey: deduplicationKey,
  organizationId: organizationId,
  recipientEmployeeId: recipientEmployeeId,
  category: category,
  kind: kind,
  route:
      route ??
      NotificationSourceRoute(
        module: NotificationSourceModule.expenses,
        sourceType: NotificationSourceType.recurringExpense,
        sourceRecordId: 'commercial-insurance',
        sourceChildId: 'commercial-insurance:2027-09-10',
      ),
  content: NotificationContent(
    titleKey: 'notification.recurringExpense.title',
    messageKey: 'notification.recurringExpense.dueInDays',
    arguments: const {'title': 'Commercial vehicle insurance', 'days': '7'},
  ),
  scheduledAtUtc: DateTime.utc(2027, 9, 2, 9),
  expiresAtUtc: expiresAtUtc,
  channels: const {
    NotificationDeliveryChannel.inApp,
    NotificationDeliveryChannel.push,
    NotificationDeliveryChannel.sound,
  },
  readState: NotificationReadState.unread,
  lifecycle: NotificationLifecycle(
    revision: 1,
    createdAtUtc: DateTime.utc(2027, 9, 1),
    updatedAtUtc: DateTime.utc(2027, 9, 1),
  ),
);

List<StoredNotificationDelivery> _deliveries(StoredNotificationEvent event) => [
  for (final channel in const {
    NotificationDeliveryChannel.push,
    NotificationDeliveryChannel.sound,
  })
    StoredNotificationDelivery(
      deliveryId: '${event.notificationId}:${channel.name}',
      notificationId: event.notificationId,
      organizationId: event.organizationId,
      recipientEmployeeId: event.recipientEmployeeId,
      channel: channel,
      scheduledAtUtc: event.scheduledAtUtc,
      state: NotificationDeliveryState.pending,
      attemptCount: 0,
      lifecycle: NotificationLifecycle(
        revision: 1,
        createdAtUtc: DateTime.utc(2027, 9, 1),
        updatedAtUtc: DateTime.utc(2027, 9, 1),
      ),
    ),
];

NotificationCommandPermissions _systemPermissions({
  String organizationId = 'organization-1',
}) => NotificationCommandPermissions(
  organizationId: organizationId,
  actorEmployeeId: 'system-notification-service',
  permissionRevision: 'system-policy-1',
  readScope: NotificationReadScope.company,
  canPublish: true,
  canPublishToOtherEmployees: true,
  canManageDelivery: true,
);

NotificationCommandPermissions _employeePermissions(String employeeId) =>
    NotificationCommandPermissions(
      organizationId: 'organization-1',
      actorEmployeeId: employeeId,
      permissionRevision: 'employee-policy-1',
      readScope: NotificationReadScope.own,
    );
