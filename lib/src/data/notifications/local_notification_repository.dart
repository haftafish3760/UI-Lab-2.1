import 'dart:io';

import '../storage/dual_slot_json_store.dart';
import '../storage/domain_snapshot_store.dart';
import '../storage/serialized_async_actions.dart';
import 'notification_records.dart';
import 'notification_repository.dart';
import 'notification_repository_guards.dart';
import 'notification_snapshot_codec.dart';
import 'notification_terms.dart';

typedef NotificationSnapshotWriter = DualSlotSnapshotWriter;

class LocalNotificationRepository implements NotificationRepository {
  LocalNotificationRepository._({
    required this._snapshotStore,
    required this._events,
    required this._deliveries,
  });

  /// Test/demo repository with the same authorization, revision, and mutation
  /// behavior as the file-backed repository but no persistence boundary.
  /// Production startup injects a private file-backed instance instead.
  LocalNotificationRepository.transient()
    : _snapshotStore = null,
      _events = {},
      _deliveries = {};

  factory LocalNotificationRepository.withStorage(
    DomainSnapshotStore<NotificationSnapshotData> storage,
  ) => LocalNotificationRepository._(
    snapshotStore: storage,
    events: {
      for (final item in storage.value.events) item.notificationId: item,
    },
    deliveries: {
      for (final item in storage.value.deliveries) item.deliveryId: item,
    },
  );

  static const int schemaVersion = 1;
  static const String directoryName = 'notification_records';

  final DomainSnapshotStore<NotificationSnapshotData>? _snapshotStore;
  Map<String, StoredNotificationEvent> _events;
  Map<String, StoredNotificationDelivery> _deliveries;
  final _writes = SerializedAsyncActions();
  Future<AsyncActionPause> pauseOperations() => _writes.pauseAndDrain();

  bool get recoveredFromDamagedSnapshot =>
      _snapshotStore?.recoveredFromDamagedSnapshot ?? false;

  static Future<LocalNotificationRepository> open(
    Directory storageDirectory, {
    NotificationSnapshotWriter? snapshotWriter,
  }) async {
    try {
      final store = await DualSlotJsonStore.open<NotificationSnapshotData>(
        directory: storageDirectory,
        fileStem: 'notifications',
        schemaVersion: schemaVersion,
        emptyValue: const NotificationSnapshotData.empty(),
        encodePayload: (snapshot) => snapshot.toJson(),
        decodePayload: NotificationSnapshotData.fromJson,
        snapshotWriter: snapshotWriter,
      );
      return LocalNotificationRepository._(
        snapshotStore: store,
        events: {
          for (final event in store.value.events) event.notificationId: event,
        },
        deliveries: {
          for (final delivery in store.value.deliveries)
            delivery.deliveryId: delivery,
        },
      );
    } on DualSlotSnapshotCorruptionException catch (error) {
      throw NotificationStorageCorruptionException(error.message);
    }
  }

  @override
  Future<List<StoredNotificationEvent>> queryEvents(
    NotificationEventQuery query,
  ) async {
    final events = _events.values.where(query.matches).toList()
      ..sort(compareNotificationEvents);
    return List.unmodifiable(events);
  }

  @override
  Future<StoredNotificationEvent?> findEvent({
    required String notificationId,
    required NotificationAccess access,
  }) async {
    final event = _events[notificationId];
    return event != null && access.allowsEvent(event) ? event : null;
  }

  @override
  Future<List<StoredNotificationDelivery>> queryDeliveries(
    NotificationDeliveryQuery query,
  ) async {
    final deliveries = _deliveries.values.where(query.matches).toList()
      ..sort(compareNotificationDeliveries);
    return List.unmodifiable(deliveries);
  }

  @override
  Future<StoredNotificationDelivery?> findDelivery({
    required String deliveryId,
    required NotificationAccess access,
  }) async {
    final delivery = _deliveries[deliveryId];
    return delivery != null && access.allowsDelivery(delivery)
        ? delivery
        : null;
  }

  @override
  Future<NotificationPublishResult> publish({
    required StoredNotificationEvent event,
    required List<StoredNotificationDelivery> deliveries,
    required NotificationMutationContext context,
  }) => _writes.run(() async {
    final sameId = _events[event.notificationId];
    final sameDeduplication = _events.values
        .where(
          (candidate) =>
              candidate.organizationId == event.organizationId &&
              candidate.deduplicationKey == event.deduplicationKey,
        )
        .firstOrNull;
    final existing = sameId ?? sameDeduplication;
    if (existing != null) {
      return _existingPublishResult(existing, event, deliveries);
    }
    _validatePublishBundle(event, deliveries);
    final createdEvent = event.copyWith(
      readState: NotificationReadState.unread,
      lifecycle: NotificationLifecycle(
        revision: 1,
        createdAtUtc: context.occurredAtUtc,
        updatedAtUtc: context.occurredAtUtc,
      ),
      auditTrail: [
        context.audit(
          action: NotificationAuditAction.created,
          fromRevision: null,
          toRevision: 1,
        ),
      ],
    );
    final createdDeliveries = deliveries
        .map(
          (delivery) => delivery.copyWith(
            state: NotificationDeliveryState.pending,
            attemptCount: 0,
            lastAttemptAtUtc: null,
            adapterReference: null,
            failureCode: null,
            lifecycle: NotificationLifecycle(
              revision: 1,
              createdAtUtc: context.occurredAtUtc,
              updatedAtUtc: context.occurredAtUtc,
            ),
            auditTrail: [
              context.audit(
                action: NotificationAuditAction.created,
                fromRevision: null,
                toRevision: 1,
              ),
            ],
          ),
        )
        .toList();
    final nextEvents = {..._events, createdEvent.notificationId: createdEvent};
    final nextDeliveries = {
      ..._deliveries,
      for (final delivery in createdDeliveries) delivery.deliveryId: delivery,
    };
    await _persist(nextEvents, nextDeliveries);
    return NotificationPublishResult(
      event: createdEvent,
      deliveries: List.unmodifiable(createdDeliveries),
      wasAlreadyPublished: false,
    );
  });

  @override
  Future<StoredNotificationEvent> changeReadState({
    required String notificationId,
    required NotificationReadState state,
    required int expectedRevision,
    required NotificationMutationContext context,
  }) => _writes.run(() async {
    final current = _events[notificationId];
    if (current == null) {
      throw NotificationNotFoundException(
        'Notification $notificationId does not exist.',
      );
    }
    if (current.readState == state) return current;
    _requireRevision(current.lifecycle.revision, expectedRevision);
    if (current.readState == NotificationReadState.dismissed &&
        state != NotificationReadState.unread) {
      throw const NotificationInvalidTransitionException(
        'Restore a dismissed notification before changing it again.',
      );
    }
    final nextRevision = current.lifecycle.revision + 1;
    final updated = current.copyWith(
      readState: state,
      lifecycle: current.lifecycle.next(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.audit(
          action: auditActionForReadState(current.readState, state),
          fromRevision: current.lifecycle.revision,
          toRevision: nextRevision,
        ),
      ],
    );
    await _persist({..._events, notificationId: updated}, _deliveries);
    return updated;
  });

  @override
  Future<StoredNotificationDelivery> updateDelivery({
    required String deliveryId,
    required NotificationDeliveryState state,
    required int expectedRevision,
    required NotificationMutationContext context,
    String? adapterReference,
    String? failureCode,
  }) => _writes.run(() async {
    final current = _deliveries[deliveryId];
    if (current == null) {
      throw NotificationNotFoundException(
        'Notification delivery $deliveryId does not exist.',
      );
    }
    final resolvedAdapterReference =
        adapterReference ?? current.adapterReference;
    final resolvedFailureCode = state == NotificationDeliveryState.failed
        ? failureCode ?? current.failureCode
        : null;
    if (current.state == state &&
        current.adapterReference == resolvedAdapterReference &&
        current.failureCode == resolvedFailureCode) {
      return current;
    }
    _requireRevision(current.lifecycle.revision, expectedRevision);
    validateDeliveryTransition(current.state, state);
    if (state == NotificationDeliveryState.failed &&
        (resolvedFailureCode == null || resolvedFailureCode.trim().isEmpty)) {
      throw const NotificationInvalidTransitionException(
        'A failed delivery requires a stable failure code.',
      );
    }
    final attempted =
        state == NotificationDeliveryState.delivered ||
        state == NotificationDeliveryState.failed;
    final nextRevision = current.lifecycle.revision + 1;
    final updated = current.copyWith(
      state: state,
      attemptCount: current.attemptCount + (attempted ? 1 : 0),
      lastAttemptAtUtc: attempted ? context.occurredAtUtc : null,
      adapterReference: resolvedAdapterReference,
      failureCode: resolvedFailureCode,
      lifecycle: current.lifecycle.next(context.occurredAtUtc),
      auditTrail: [
        ...current.auditTrail,
        context.audit(
          action: auditActionForDelivery(state),
          fromRevision: current.lifecycle.revision,
          toRevision: nextRevision,
        ),
      ],
    );
    await _persist(_events, {..._deliveries, deliveryId: updated});
    return updated;
  });

  NotificationPublishResult _existingPublishResult(
    StoredNotificationEvent existing,
    StoredNotificationEvent requested,
    List<StoredNotificationDelivery> requestedDeliveries,
  ) {
    if (existing.notificationId != requested.notificationId ||
        !sameNotificationDefinition(existing, requested)) {
      throw const NotificationConflictException(
        'Notification identity or deduplication key is already in use.',
      );
    }
    final existingDeliveries =
        _deliveries.values
            .where(
              (delivery) => delivery.notificationId == existing.notificationId,
            )
            .toList()
          ..sort(compareNotificationDeliveries);
    final requestedSorted = [...requestedDeliveries]
      ..sort(compareNotificationDeliveries);
    if (existingDeliveries.length != requestedSorted.length) {
      throw const NotificationConflictException(
        'The notification was retried with different delivery channels.',
      );
    }
    for (var index = 0; index < existingDeliveries.length; index++) {
      if (!sameDeliveryDefinition(
        existingDeliveries[index],
        requestedSorted[index],
      )) {
        throw const NotificationConflictException(
          'The notification was retried with different delivery details.',
        );
      }
    }
    return NotificationPublishResult(
      event: existing,
      deliveries: List.unmodifiable(existingDeliveries),
      wasAlreadyPublished: true,
    );
  }

  void _validatePublishBundle(
    StoredNotificationEvent event,
    List<StoredNotificationDelivery> deliveries,
  ) {
    if (event.readState != NotificationReadState.unread) {
      throw const NotificationConflictException(
        'A new notification must begin unread.',
      );
    }
    final expectedChannels = event.channels
        .where((channel) => channel != NotificationDeliveryChannel.inApp)
        .toSet();
    final deliveredChannels = <NotificationDeliveryChannel>{};
    final deliveryIds = <String>{};
    for (final delivery in deliveries) {
      if (!deliveryIds.add(delivery.deliveryId) ||
          !deliveredChannels.add(delivery.channel) ||
          delivery.notificationId != event.notificationId ||
          delivery.organizationId != event.organizationId ||
          delivery.recipientEmployeeId != event.recipientEmployeeId ||
          delivery.scheduledAtUtc != event.scheduledAtUtc ||
          delivery.state != NotificationDeliveryState.pending) {
        throw const NotificationConflictException(
          'Notification delivery bundle is inconsistent.',
        );
      }
    }
    if (!deliveredChannels.containsAll(expectedChannels) ||
        !expectedChannels.containsAll(deliveredChannels)) {
      throw const NotificationConflictException(
        'Every requested platform channel needs one delivery record.',
      );
    }
  }

  void _requireRevision(int current, int expected) {
    if (current != expected) {
      throw NotificationConflictException(
        'Expected revision $expected but current revision is $current.',
      );
    }
  }

  Future<void> _persist(
    Map<String, StoredNotificationEvent> events,
    Map<String, StoredNotificationDelivery> deliveries,
  ) async {
    try {
      await _snapshotStore?.persist(
        NotificationSnapshotData(
          events: events.values.toList()..sort(compareNotificationEvents),
          deliveries: deliveries.values.toList()
            ..sort(compareNotificationDeliveries),
        ),
      );
    } on DualSlotSnapshotWriteException catch (error) {
      throw NotificationStorageException(error.message);
    }
    _events = events;
    _deliveries = deliveries;
  }
}
