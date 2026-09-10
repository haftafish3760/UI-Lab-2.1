import '../app.dart';
import '../data/storage/local_installation_switch_coordinator.dart';
import 'open_ui_lab_application.dart';

/// Adapts the mounted application to the storage switch workflow. The host owns
/// presentation and must block pointer, keyboard, back and accessibility entry
/// points, and complete presentApplication only after mount/unmount finishes.
/// There are no SQL, schema, route names or layout keys in this adapter.
class MountedApplicationSwitchRuntime implements InstallationSwitchRuntime {
  MountedApplicationSwitchRuntime({
    required this.currentApplication,
    required this.presentApplication,
    required this.blockEntryPoints,
    required this.settleView,
    required this.loadApplication,
  });
  final UiLabApp? Function() currentApplication;
  final Future<void> Function(UiLabApp?) presentApplication;
  final void Function(bool) blockEntryPoints;
  final Future<void> Function() settleView;
  final Future<UiLabApp> Function() loadApplication;
  UiLabApp? _active;
  bool _paused = false, _closing = false, _readyToOpen = false;
  bool _opening = false;

  @override
  Future<void Function()> pauseAndFlush() async {
    final application = currentApplication();
    final lifecycle = application?.storageLifecycle;
    if (_active != null ||
        _paused ||
        _closing ||
        lifecycle == null ||
        !lifecycle.isAttached) {
      throw StateError('No available mounted runtime can be paused.');
    }
    _active = application;
    try {
      blockEntryPoints(true);
      await settleView();
      if (!identical(application, currentApplication())) {
        throw StateError('The mounted application changed before pause.');
      }
      final resume = await lifecycle.pauseAndFlush();
      _paused = true;
      return () {
        if (!_paused || _closing || !identical(_active, application)) return;
        resume();
        _paused = false;
        _active = null;
        blockEntryPoints(false);
      };
    } on Object {
      _active = null;
      blockEntryPoints(false);
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    final application = _active;
    if (!_paused ||
        _closing ||
        application == null ||
        !identical(application, currentApplication())) {
      throw StateError('Only the paused mounted application can close.');
    }
    _closing = true;
    await presentApplication(null);
    if (currentApplication() != null) {
      throw StateError('The previous application did not detach.');
    }
    await application.storageLifecycle!.close();
    _active = null;
    _paused = false;
    _readyToOpen = true;
  }

  @override
  Future<void> openSelected() async {
    if (_opening || !_readyToOpen || currentApplication() != null) {
      throw StateError('The previous runtime has not closed.');
    }
    // Reserve before awaiting the loader, independently of any caller's
    // coordinator. Failed loads release the reservation for explicit retry.
    _opening = true;
    try {
      await _loadAndPresentSelected();
    } finally {
      _opening = false;
    }
  }

  Future<void> _loadAndPresentSelected() async {
    final next = await loadApplication();
    try {
      if (next.storageLifecycle == null) {
        throw StateError('The new application has no storage lifecycle.');
      }
      await presentApplication(next);
      if (!identical(next, currentApplication()) ||
          !next.storageLifecycle!.isAttached) {
        throw StateError('The selected application did not attach.');
      }
      _readyToOpen = false;
      _closing = false;
      blockEntryPoints(false);
    } on Object {
      if (next.storageLifecycle?.isAttached ?? false) {
        // A partially successful presentation must never open a second runtime.
        _readyToOpen = false;
      } else {
        await closeUnstartedApplication(next);
      }
      rethrow;
    }
  }
}
