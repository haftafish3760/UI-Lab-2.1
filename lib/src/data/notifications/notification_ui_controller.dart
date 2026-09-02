import 'dart:async';

import 'package:flutter/widgets.dart';

import 'authorized_notification_service.dart';
import 'notification_records.dart';
import 'notification_terms.dart';

enum NotificationUiPhase { loading, ready, failed }

class NotificationUiController extends ChangeNotifier {
  NotificationUiController(this._service, this._permissions, this._sourceReady);

  final AuthorizedNotificationService _service;
  final NotificationCommandPermissions _permissions;
  Future<void> _sourceReady;
  List<StoredNotificationEvent> _events = const [];
  NotificationUiPhase _phase = NotificationUiPhase.loading;
  String? _failureMessage;
  DateTime? _availableAtUtc;
  bool _disposed = false;
  int _loadGeneration = 0;

  List<StoredNotificationEvent> get events => _events;
  NotificationUiPhase get phase => _phase;
  String? get failureMessage => _failureMessage;
  int get unreadCount => _events
      .where((event) => event.readState == NotificationReadState.unread)
      .length;
  bool get hasUnread => unreadCount > 0;

  Future<void> load({required DateTime availableAt}) async {
    final generation = ++_loadGeneration;
    _availableAtUtc = availableAt.toUtc();
    _phase = NotificationUiPhase.loading;
    _failureMessage = null;
    _notify();
    try {
      await _sourceReady;
      final loaded = await _service.queryEvents(
        permissions: _permissions,
        availableAtUtc: _availableAtUtc,
        channel: NotificationDeliveryChannel.inApp,
      );
      if (_disposed || generation != _loadGeneration) return;
      _events = List.unmodifiable(
        loaded.where(
          (event) => event.readState != NotificationReadState.dismissed,
        ),
      );
      _phase = NotificationUiPhase.ready;
    } on Object {
      if (_disposed || generation != _loadGeneration) return;
      _phase = NotificationUiPhase.failed;
      _failureMessage = 'Notifications could not be loaded.';
    }
    _notify();
  }

  void sourceChanged(Future<void> sourceReady) {
    _sourceReady = sourceReady;
    final availableAt = _availableAtUtc;
    if (availableAt != null) {
      unawaited(load(availableAt: availableAt));
    }
  }

  Future<bool> markRead(StoredNotificationEvent event) async {
    if (event.readState != NotificationReadState.unread) return true;
    return _changeState(event, NotificationReadState.read);
  }

  Future<StoredNotificationEvent?> eventForOpen(String notificationId) async {
    try {
      await _sourceReady;
      var event = await _service.findEvent(
        notificationId: notificationId,
        permissions: _permissions,
      );
      if (event == null || event.readState == NotificationReadState.dismissed) {
        return null;
      }
      if (event.readState == NotificationReadState.unread) {
        event = await _service.changeReadState(
          notificationId: event.notificationId,
          state: NotificationReadState.read,
          expectedRevision: event.lifecycle.revision,
          permissions: _permissions,
          occurredAtUtc: DateTime.now().toUtc(),
          note: 'Opened from a device notification.',
        );
        _replace(event);
        _notify();
      }
      return event;
    } on Object {
      _failureMessage = 'Notifications could not be loaded.';
      _phase = NotificationUiPhase.failed;
      _notify();
      return null;
    }
  }

  Future<bool> markAllRead() async {
    final unread = _events
        .where((event) => event.readState == NotificationReadState.unread)
        .toList();
    for (final event in unread) {
      if (!await _changeState(event, NotificationReadState.read)) return false;
    }
    return true;
  }

  Future<bool> _changeState(
    StoredNotificationEvent event,
    NotificationReadState state,
  ) async {
    try {
      final updated = await _service.changeReadState(
        notificationId: event.notificationId,
        state: state,
        expectedRevision: event.lifecycle.revision,
        permissions: _permissions,
        occurredAtUtc: DateTime.now().toUtc(),
      );
      _replace(updated);
      _failureMessage = null;
      _notify();
      return true;
    } on Object {
      _failureMessage = 'That notification changed. The list was refreshed.';
      final availableAt = _availableAtUtc;
      if (availableAt != null) await load(availableAt: availableAt);
      return false;
    }
  }

  void _replace(StoredNotificationEvent updated) {
    _events = List.unmodifiable([
      for (final item in _events)
        if (item.notificationId == updated.notificationId) updated else item,
    ]);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class NotificationUiScope extends InheritedNotifier<NotificationUiController> {
  const NotificationUiScope({
    required NotificationUiController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static NotificationUiController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<NotificationUiScope>();
    assert(scope != null, 'NotificationUiScope is missing.');
    return scope!.notifier!;
  }
}
