import 'notification_records.dart';
import 'notification_repository.dart';
import 'notification_terms.dart';

class NotificationCommandPermissions {
  NotificationCommandPermissions({
    required this.organizationId,
    required this.actorEmployeeId,
    required this.permissionRevision,
    required this.readScope,
    this.teamEmployeeIds = const {},
    this.canPublish = false,
    this.canPublishToOtherEmployees = false,
    this.canChangeOwnReadState = true,
    this.canChangeOtherReadState = false,
    this.canManageDelivery = false,
  });

  final String organizationId;
  final String actorEmployeeId;
  final String permissionRevision;
  final NotificationReadScope? readScope;
  final Set<String> teamEmployeeIds;
  final bool canPublish;
  final bool canPublishToOtherEmployees;
  final bool canChangeOwnReadState;
  final bool canChangeOtherReadState;
  final bool canManageDelivery;

  NotificationAccess? get readAccess => switch (readScope) {
    null => null,
    NotificationReadScope.own => NotificationAccess.own(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
    NotificationReadScope.team => NotificationAccess.team(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
      teamEmployeeIds: teamEmployeeIds,
    ),
    NotificationReadScope.company => NotificationAccess.company(
      organizationId: organizationId,
      employeeId: actorEmployeeId,
    ),
  };

  bool scopeIncludes(String employeeId) => switch (readScope) {
    NotificationReadScope.company => true,
    NotificationReadScope.team =>
      employeeId == actorEmployeeId || teamEmployeeIds.contains(employeeId),
    NotificationReadScope.own => employeeId == actorEmployeeId,
    null => false,
  };
}

class AuthorizedNotificationService {
  const AuthorizedNotificationService(this._repository);

  final NotificationRepository _repository;

  Future<List<StoredNotificationEvent>> queryEvents({
    required NotificationCommandPermissions permissions,
    DateTime? availableAtUtc,
    NotificationEventCategory? category,
    NotificationEventKind? kind,
    NotificationSourceModule? module,
    NotificationSourceType? sourceType,
    String? sourceRecordId,
    NotificationDeliveryChannel? channel,
    NotificationReadState? readState,
    bool includeExpired = false,
  }) async => _repository.queryEvents(
    NotificationEventQuery(
      access: _requireReadAccess(permissions),
      availableAtUtc: availableAtUtc,
      category: category,
      kind: kind,
      module: module,
      sourceType: sourceType,
      sourceRecordId: sourceRecordId,
      channel: channel,
      readState: readState,
      includeExpired: includeExpired,
    ),
  );

  Future<int> unreadCount({
    required NotificationCommandPermissions permissions,
    required DateTime availableAtUtc,
  }) async => (await queryEvents(
    permissions: permissions,
    availableAtUtc: availableAtUtc,
    readState: NotificationReadState.unread,
  )).length;

  Future<StoredNotificationEvent?> findEvent({
    required String notificationId,
    required NotificationCommandPermissions permissions,
  }) => _repository.findEvent(
    notificationId: notificationId,
    access: _requireReadAccess(permissions),
  );

  Future<List<StoredNotificationDelivery>> queryDeliveries({
    required NotificationCommandPermissions permissions,
    DateTime? fromInclusiveUtc,
    DateTime? toExclusiveUtc,
    NotificationDeliveryChannel? channel,
    NotificationDeliveryState? state,
    String? notificationId,
  }) async {
    _requireAction(
      permissions.canManageDelivery,
      'view platform notification deliveries',
    );
    return _repository.queryDeliveries(
      NotificationDeliveryQuery(
        access: _requireReadAccess(permissions),
        fromInclusiveUtc: fromInclusiveUtc,
        toExclusiveUtc: toExclusiveUtc,
        channel: channel,
        state: state,
        notificationId: notificationId,
      ),
    );
  }

  Future<NotificationPublishResult> publish({
    required StoredNotificationEvent event,
    required List<StoredNotificationDelivery> deliveries,
    required NotificationCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) {
    _requireAction(permissions.canPublish, 'publish notifications');
    _requireOrganization(event.organizationId, permissions);
    _requirePublishTarget(event.recipientEmployeeId, permissions);
    for (final delivery in deliveries) {
      _requireOrganization(delivery.organizationId, permissions);
      _requirePublishTarget(delivery.recipientEmployeeId, permissions);
    }
    return _repository.publish(
      event: event,
      deliveries: deliveries,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  Future<StoredNotificationEvent> changeReadState({
    required String notificationId,
    required NotificationReadState state,
    required int expectedRevision,
    required NotificationCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? note,
  }) async {
    final event = await _requireEvent(notificationId, permissions);
    final isOwn = event.recipientEmployeeId == permissions.actorEmployeeId;
    _requireAction(
      isOwn
          ? permissions.canChangeOwnReadState
          : permissions.canChangeOtherReadState &&
                permissions.scopeIncludes(event.recipientEmployeeId),
      'change that notification state',
    );
    return _repository.changeReadState(
      notificationId: notificationId,
      state: state,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note),
    );
  }

  Future<StoredNotificationDelivery> updateDelivery({
    required String deliveryId,
    required NotificationDeliveryState state,
    required int expectedRevision,
    required NotificationCommandPermissions permissions,
    required DateTime occurredAtUtc,
    String? adapterReference,
    String? failureCode,
    String? note,
  }) async {
    _requireAction(
      permissions.canManageDelivery,
      'update platform notification delivery',
    );
    final delivery = await _repository.findDelivery(
      deliveryId: deliveryId,
      access: _companyAccess(permissions),
    );
    if (delivery == null) {
      throw const NotificationNotFoundException(
        'Notification delivery does not exist.',
      );
    }
    _requirePublishTarget(delivery.recipientEmployeeId, permissions);
    return _repository.updateDelivery(
      deliveryId: deliveryId,
      state: state,
      expectedRevision: expectedRevision,
      context: _context(permissions, occurredAtUtc, note),
      adapterReference: adapterReference,
      failureCode: failureCode,
    );
  }

  Future<StoredNotificationEvent> _requireEvent(
    String notificationId,
    NotificationCommandPermissions permissions,
  ) async {
    final event = await _repository.findEvent(
      notificationId: notificationId,
      access: _companyAccess(permissions),
    );
    if (event == null) {
      throw const NotificationNotFoundException('Notification does not exist.');
    }
    return event;
  }

  NotificationAccess _requireReadAccess(
    NotificationCommandPermissions permissions,
  ) {
    final access = permissions.readAccess;
    if (access == null) {
      throw const NotificationPermissionDeniedException(
        'This employee cannot view notifications.',
      );
    }
    return access;
  }

  NotificationAccess _companyAccess(
    NotificationCommandPermissions permissions,
  ) => NotificationAccess.company(
    organizationId: permissions.organizationId,
    employeeId: permissions.actorEmployeeId,
  );

  void _requirePublishTarget(
    String employeeId,
    NotificationCommandPermissions permissions,
  ) {
    if (employeeId == permissions.actorEmployeeId) return;
    if (!permissions.canPublishToOtherEmployees ||
        !permissions.scopeIncludes(employeeId)) {
      throw const NotificationPermissionDeniedException(
        'This actor cannot target that employee.',
      );
    }
  }

  void _requireOrganization(
    String organizationId,
    NotificationCommandPermissions permissions,
  ) {
    if (organizationId != permissions.organizationId) {
      throw const NotificationPermissionDeniedException(
        'The notification is outside this company.',
      );
    }
  }

  void _requireAction(bool allowed, String action) {
    if (!allowed) {
      throw NotificationPermissionDeniedException('This actor cannot $action.');
    }
  }

  NotificationMutationContext _context(
    NotificationCommandPermissions permissions,
    DateTime occurredAtUtc,
    String? note,
  ) => NotificationMutationContext(
    actorId: permissions.actorEmployeeId,
    permissionRevision: permissions.permissionRevision,
    occurredAtUtc: occurredAtUtc,
    note: note,
  );
}
