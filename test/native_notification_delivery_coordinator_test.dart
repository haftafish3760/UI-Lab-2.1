import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lab_2_1/src/data/notifications/authorized_notification_service.dart';
import 'package:ui_lab_2_1/src/data/notifications/file_notification_repository.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_copy.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_delivery_coordinator.dart';
import 'package:ui_lab_2_1/src/data/notifications/native_notification_gateway.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_demo_policy.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_records.dart';
import 'package:ui_lab_2_1/src/data/notifications/notification_terms.dart';

void main() {
  test('permission is explicit and a queued record is not delivery', () async {
    final harness = await _Harness.create(
      permission: NativeNotificationPermissionState.notGranted,
    );
    final event = await harness.publish('insurance', const {
      NotificationDeliveryChannel.push,
    });

    final result = await harness.coordinator.synchronize(
      asOfUtc: harness.now,
      locale: const Locale('en', 'US'),
    );

    expect(result.state, NativeNotificationSyncState.permissionRequired);
    expect(harness.gateway.posts, isEmpty);
    expect(
      (await harness.deliveries(event.notificationId)).single.state,
      NotificationDeliveryState.pending,
    );
  });

  test(
    'push and sound schedule one native alert with two audit rows',
    () async {
      final harness = await _Harness.create();
      final event = await harness.publish('insurance', const {
        NotificationDeliveryChannel.push,
        NotificationDeliveryChannel.sound,
      });

      final result = await harness.coordinator.synchronize(
        asOfUtc: harness.now,
        locale: const Locale('en', 'US'),
      );

      expect(result.scheduledCount, 1);
      expect(harness.gateway.posts, hasLength(1));
      expect(harness.gateway.posts.single.playSound, isTrue);
      expect(harness.gateway.posts.single.payload, event.notificationId);
      expect(harness.gateway.posts.single.title, 'Maintainiac reminder');
      expect(
        harness.gateway.posts.single.body,
        'Open Maintainiac to review a scheduled reminder.',
      );
      final deliveries = await harness.deliveries(event.notificationId);
      expect(deliveries, hasLength(2));
      expect(
        deliveries.every(
          (delivery) => delivery.state == NotificationDeliveryState.scheduled,
        ),
        isTrue,
      );
      expect(
        deliveries.map((item) => item.adapterReference).toSet(),
        hasLength(1),
      );
    },
  );

  test('a missing future OS request is rescheduled after restart', () async {
    final harness = await _Harness.create();
    final event = await harness.publish('insurance', const {
      NotificationDeliveryChannel.push,
    });
    await harness.coordinator.synchronize(
      asOfUtc: harness.now,
      locale: const Locale('en', 'US'),
    );
    harness.gateway.pending.clear();

    await harness.coordinator.synchronize(
      asOfUtc: harness.now,
      locale: const Locale('en', 'US'),
    );

    expect(harness.gateway.posts, hasLength(2));
    expect(
      (await harness.deliveries(event.notificationId)).single.state,
      NotificationDeliveryState.scheduled,
    );
  });

  test(
    'a dismissed source cancels its native request and audit rows',
    () async {
      final harness = await _Harness.create();
      final event = await harness.publish('insurance', const {
        NotificationDeliveryChannel.push,
        NotificationDeliveryChannel.sound,
      });
      await harness.coordinator.synchronize(
        asOfUtc: harness.now,
        locale: const Locale('en', 'US'),
      );
      await harness.service.changeReadState(
        notificationId: event.notificationId,
        state: NotificationReadState.dismissed,
        expectedRevision: event.lifecycle.revision,
        permissions: demoNotificationPublisherPermissions(),
        occurredAtUtc: harness.now.add(const Duration(minutes: 1)),
      );

      await harness.coordinator.synchronize(
        asOfUtc: harness.now.add(const Duration(minutes: 2)),
        locale: const Locale('en', 'US'),
      );

      expect(harness.gateway.cancelled, hasLength(1));
      expect(
        (await harness.deliveries(event.notificationId)).every(
          (delivery) => delivery.state == NotificationDeliveryState.cancelled,
        ),
        isTrue,
      );
    },
  );

  test(
    'native ID collisions fail closed instead of replacing a reminder',
    () async {
      final harness = await _Harness.create(idResolver: (_) => 71);
      await harness.publish('insurance', const {
        NotificationDeliveryChannel.push,
      });
      await harness.publish('vehicle-payment', const {
        NotificationDeliveryChannel.push,
      });

      await harness.coordinator.synchronize(
        asOfUtc: harness.now,
        locale: const Locale('en', 'US'),
      );

      expect(harness.gateway.posts, hasLength(1));
      final all = await harness.service.queryDeliveries(
        permissions: demoNotificationPublisherPermissions(),
      );
      expect(
        all.where((item) => item.state == NotificationDeliveryState.failed),
        hasLength(1),
      );
      expect(
        all
            .singleWhere(
              (item) => item.state == NotificationDeliveryState.failed,
            )
            .failureCode,
        NativeNotificationDeliveryCoordinator.nativeIdCollisionFailureCode,
      );
    },
  );

  test('lock-screen copy is generic and localized', () {
    expect(
      nativeNotificationCopyFor(const Locale('es', 'US')).title,
      'Recordatorio de Maintainiac',
    );
    expect(
      nativeNotificationCopyFor(const Locale('fr', 'CA')).title,
      'Rappel Maintainiac',
    );
  });
}

class _Harness {
  _Harness._(this.service, this.gateway, this.coordinator, this.now);

  final AuthorizedNotificationService service;
  final _FakeNativeNotificationGateway gateway;
  final NativeNotificationDeliveryCoordinator coordinator;
  final DateTime now;

  static Future<_Harness> create({
    NativeNotificationPermissionState permission =
        NativeNotificationPermissionState.granted,
    NativeNotificationIdResolver? idResolver,
  }) async {
    final service = AuthorizedNotificationService(
      FileNotificationRepository.transient(),
    );
    final gateway = _FakeNativeNotificationGateway(permission);
    final coordinator = NativeNotificationDeliveryCoordinator(
      service,
      demoNotificationPublisherPermissions(),
      gateway,
      idResolver ?? ((id) => id.hashCode & 0x7fffffff),
    );
    return _Harness._(
      service,
      gateway,
      coordinator,
      DateTime.utc(2027, 9, 1, 12),
    );
  }

  Future<StoredNotificationEvent> publish(
    String id,
    Set<NotificationDeliveryChannel> channels,
  ) async {
    final event = StoredNotificationEvent(
      notificationId: 'expense-$id-reminder',
      deduplicationKey: 'expense-$id-reminder:alex',
      organizationId: demoNotificationOrganizationId,
      recipientEmployeeId: demoNotificationEmployeeId,
      category: NotificationEventCategory.reminder,
      kind: NotificationEventKind.recurringExpenseDue,
      route: NotificationSourceRoute(
        module: NotificationSourceModule.expenses,
        sourceType: NotificationSourceType.recurringExpense,
        sourceRecordId: id,
      ),
      content: NotificationContent(
        titleKey: 'notification.recurringExpense.title',
        messageKey: 'notification.recurringExpense.due',
      ),
      scheduledAtUtc: now.add(const Duration(days: 1)),
      channels: channels,
      readState: NotificationReadState.unread,
      lifecycle: NotificationLifecycle(
        revision: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
      ),
    );
    final result = await service.publish(
      event: event,
      deliveries: [
        for (final channel in channels)
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
              createdAtUtc: now,
              updatedAtUtc: now,
            ),
          ),
      ],
      permissions: demoNotificationPublisherPermissions(),
      occurredAtUtc: now,
    );
    return result.event;
  }

  Future<List<StoredNotificationDelivery>> deliveries(String notificationId) =>
      service.queryDeliveries(
        permissions: demoNotificationPublisherPermissions(),
        notificationId: notificationId,
      );
}

class _FakeNativeNotificationGateway implements NativeNotificationGateway {
  _FakeNativeNotificationGateway(this.permission);

  NativeNotificationPermissionState permission;
  final posts = <NativeNotificationRequest>[];
  final pending = <int>{};
  final cancelled = <int>[];
  final _tapController = StreamController<String>.broadcast();

  @override
  Stream<String> get tappedPayloads => _tapController.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<NativeNotificationPermissionState> permissionState() async =>
      permission;

  @override
  Future<NativeNotificationPermissionState> requestPermission({
    required bool sound,
  }) async => permission;

  @override
  Future<Set<int>> pendingNotificationIds() async => {...pending};

  @override
  Future<NativeNotificationPostResult> post(
    NativeNotificationRequest request,
  ) async {
    posts.add(request);
    pending.add(request.platformId);
    return NativeNotificationPostResult.scheduled;
  }

  @override
  Future<void> cancel(int platformId) async {
    cancelled.add(platformId);
    pending.remove(platformId);
  }

  @override
  Future<String?> takeLaunchPayload() async => null;
}
