import 'package:flutter/widgets.dart';

import 'authorized_notification_service.dart';
import 'native_notification_copy.dart';
import 'native_notification_gateway.dart';
import 'native_notification_id.dart';
import 'notification_records.dart';
import 'notification_terms.dart';

enum NativeNotificationSyncState { unsupported, permissionRequired, complete }

class NativeNotificationSyncResult {
  const NativeNotificationSyncResult({
    required this.state,
    required this.scheduledCount,
    required this.cancelledCount,
  });

  final NativeNotificationSyncState state;
  final int scheduledCount;
  final int cancelledCount;
}

typedef NativeNotificationIdResolver = int Function(String notificationId);

class NativeNotificationDeliveryCoordinator {
  NativeNotificationDeliveryCoordinator(
    this._service,
    this._permissions,
    this._gateway, [
    this._idResolver = nativeNotificationIdFor,
  ]);

  static const nativeScheduleFailureCode = 'native-schedule-failed';
  static const nativeIdCollisionFailureCode = 'native-id-collision';

  final AuthorizedNotificationService _service;
  final NotificationCommandPermissions _permissions;
  final NativeNotificationGateway _gateway;
  final NativeNotificationIdResolver _idResolver;

  Future<void> recordOpened({
    required String notificationId,
    required DateTime occurredAtUtc,
  }) async {
    final deliveries = await _service.queryDeliveries(
      permissions: _permissions,
      notificationId: notificationId,
    );
    await _markDelivered(
      deliveries
          .where(
            (delivery) => delivery.state == NotificationDeliveryState.scheduled,
          )
          .toList(),
      _idResolver(notificationId),
      occurredAtUtc,
    );
  }

  Future<NativeNotificationSyncResult> synchronize({
    required DateTime asOfUtc,
    required Locale locale,
  }) async {
    final permission = await _gateway.permissionState();
    if (permission == NativeNotificationPermissionState.unsupported) {
      return const NativeNotificationSyncResult(
        state: NativeNotificationSyncState.unsupported,
        scheduledCount: 0,
        cancelledCount: 0,
      );
    }
    if (permission != NativeNotificationPermissionState.granted) {
      return const NativeNotificationSyncResult(
        state: NativeNotificationSyncState.permissionRequired,
        scheduledCount: 0,
        cancelledCount: 0,
      );
    }

    final events = await _service.queryEvents(
      permissions: _permissions,
      includeExpired: true,
    );
    final eventById = {for (final event in events) event.notificationId: event};
    final deliveries = await _service.queryDeliveries(
      permissions: _permissions,
    );
    final groups = <String, List<StoredNotificationDelivery>>{};
    for (final delivery in deliveries) {
      groups.putIfAbsent(delivery.notificationId, () => []).add(delivery);
    }
    final platformIds = <int, String>{};
    final pendingPlatformIds = await _gateway.pendingNotificationIds();
    var scheduledCount = 0;
    var cancelledCount = 0;

    for (final entry in groups.entries) {
      final live = entry.value.where(_canStillChange).toList();
      if (live.isEmpty) continue;
      final event = eventById[entry.key];
      final platformId = _idResolver(entry.key);
      final otherNotification = platformIds[platformId];
      if (otherNotification != null && otherNotification != entry.key) {
        await _markFailed(live, nativeIdCollisionFailureCode, asOfUtc);
        continue;
      }
      platformIds[platformId] = entry.key;

      if (event == null ||
          event.readState == NotificationReadState.dismissed ||
          event.expiresAtUtc?.isAfter(asOfUtc.toUtc()) == false) {
        await _gateway.cancel(platformId);
        await _cancel(live, platformId, asOfUtc);
        cancelledCount++;
        continue;
      }

      final alreadyPending = pendingPlatformIds.contains(platformId);
      if (alreadyPending) {
        await _markScheduled(live, platformId, asOfUtc);
        continue;
      }
      final anyScheduled = live.any(
        (delivery) => delivery.state == NotificationDeliveryState.scheduled,
      );
      if (anyScheduled && !event.scheduledAtUtc.isAfter(asOfUtc.toUtc())) {
        continue;
      }

      final copy = nativeNotificationCopyFor(locale);
      try {
        final postResult = await _gateway.post(
          NativeNotificationRequest(
            platformId: platformId,
            notificationId: event.notificationId,
            title: copy.title,
            body: copy.body,
            payload: event.notificationId,
            scheduledAtUtc: event.scheduledAtUtc,
            playSound: live.any(
              (delivery) =>
                  delivery.channel == NotificationDeliveryChannel.sound,
            ),
          ),
        );
        final scheduled = await _markScheduled(live, platformId, asOfUtc);
        if (postResult == NativeNotificationPostResult.shownNow) {
          await _markDelivered(scheduled, platformId, asOfUtc);
        }
        scheduledCount++;
      } on Object {
        final current = await _service.queryDeliveries(
          permissions: _permissions,
          notificationId: event.notificationId,
        );
        await _markFailed(
          current.where(_canStillChange).toList(),
          nativeScheduleFailureCode,
          asOfUtc,
        );
      }
    }

    return NativeNotificationSyncResult(
      state: NativeNotificationSyncState.complete,
      scheduledCount: scheduledCount,
      cancelledCount: cancelledCount,
    );
  }

  bool _canStillChange(StoredNotificationDelivery delivery) =>
      delivery.state != NotificationDeliveryState.delivered &&
      delivery.state != NotificationDeliveryState.cancelled;

  Future<List<StoredNotificationDelivery>> _markScheduled(
    List<StoredNotificationDelivery> deliveries,
    int platformId,
    DateTime occurredAtUtc,
  ) async {
    final updated = <StoredNotificationDelivery>[];
    for (final delivery in deliveries) {
      if (delivery.state == NotificationDeliveryState.scheduled) {
        updated.add(delivery);
        continue;
      }
      updated.add(
        await _service.updateDelivery(
          deliveryId: delivery.deliveryId,
          state: NotificationDeliveryState.scheduled,
          expectedRevision: delivery.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: occurredAtUtc,
          adapterReference: 'local-notification:$platformId',
          note: 'Native reminder accepted by the operating system.',
        ),
      );
    }
    return updated;
  }

  Future<void> _markDelivered(
    List<StoredNotificationDelivery> deliveries,
    int platformId,
    DateTime occurredAtUtc,
  ) async {
    for (final delivery in deliveries) {
      if (delivery.state != NotificationDeliveryState.scheduled) continue;
      await _service.updateDelivery(
        deliveryId: delivery.deliveryId,
        state: NotificationDeliveryState.delivered,
        expectedRevision: delivery.lifecycle.revision,
        permissions: _permissions,
        occurredAtUtc: occurredAtUtc,
        adapterReference: 'local-notification:$platformId',
        note: 'Native reminder was posted to the operating system.',
      );
    }
  }

  Future<void> _markFailed(
    List<StoredNotificationDelivery> deliveries,
    String failureCode,
    DateTime occurredAtUtc,
  ) async {
    for (final delivery in deliveries) {
      await _service.updateDelivery(
        deliveryId: delivery.deliveryId,
        state: NotificationDeliveryState.failed,
        expectedRevision: delivery.lifecycle.revision,
        permissions: _permissions,
        occurredAtUtc: occurredAtUtc,
        failureCode: failureCode,
        note: 'Native reminder scheduling failed.',
      );
    }
  }

  Future<void> _cancel(
    List<StoredNotificationDelivery> deliveries,
    int platformId,
    DateTime occurredAtUtc,
  ) async {
    for (final delivery in deliveries) {
      await _service.updateDelivery(
        deliveryId: delivery.deliveryId,
        state: NotificationDeliveryState.cancelled,
        expectedRevision: delivery.lifecycle.revision,
        permissions: _permissions,
        occurredAtUtc: occurredAtUtc,
        adapterReference: 'local-notification:$platformId',
        note: 'The source reminder is no longer active.',
      );
    }
  }
}
