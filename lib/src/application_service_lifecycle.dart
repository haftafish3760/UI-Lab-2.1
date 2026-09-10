part of 'app.dart';

extension _ApplicationServiceLifecycle on _UiLabAppState {
  Future<void Function()> _pauseApplicationServices() async {
    if (_servicesSuspended || !mounted) {
      throw StateError('Application services cannot pause in this state.');
    }
    _servicesSuspended = true;
    _routePause.setPaused(true);
    _nativeNotificationTapSubscription.pause();
    void resumeEvents() {
      if (!mounted) return;
      _servicesSuspended = false;
      _routePause.setPaused(false);
      _nativeNotificationTapSubscription.resume();
      if (_deferredSourceChange) {
        _deferredSourceChange = false;
        _onNotificationSourceChanged();
      }
    }

    try {
      await _initialSourceSettled;
      final lease = await pauseOperationSources([
        if (_receiptSubmission?.media case final media?) media.pauseOperations,
        if (_mediaCoordinator case final media?) media.pauseOperations,
        if (_receiptSubmission case final receipts?) receipts.pauseOperations,
        if (_recurringPayment case final recurring?) recurring.pauseOperations,
        _preferences.pauseOperations,
        _notificationSourceActions.pauseAndDrain,
        _notificationTapActions.pauseAndDrain,
        _notificationController.pauseOperations,
        _nativeNotificationController.pauseOperations,
      ]);
      return () {
        lease.release();
        resumeEvents();
      };
    } on Object {
      resumeEvents();
      rethrow;
    }
  }
}
