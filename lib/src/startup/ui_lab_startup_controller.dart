import 'package:flutter/widgets.dart';
import '../data/storage/local_installation_selection.dart';
import '../data/storage/local_restore_workflow.dart';
import '../app.dart';
import '../data/storage/local_installation_switch_coordinator.dart';
import 'application_host_controller.dart';
import 'mounted_application_switch_runtime.dart';

/// Composition seam for local restore. Settings can later use a restore service
/// without learning how the application is mounted or where SQL is stored.
class UiLabStartupController extends ApplicationHostController {
  UiLabStartupController({required this.loadApplication}) {
    installationRuntime = MountedApplicationSwitchRuntime(
      currentApplication: () {
        final application = currentApplication;
        return application is UiLabApp ? application : null;
      },
      blockEntryPoints: blockEntryPoints,
      settleView: settleView,
      presentApplication: presentApplication,
      loadApplication: () async => await loadApplication() as UiLabApp,
    );
  }
  final Future<Widget> Function() loadApplication;
  late final InstallationSwitchRuntime installationRuntime;
  LocalRestoreWorkflow? _restoreWorkflow;

  /// Presentation receives one workflow, never selection storage or a database.
  LocalRestoreController? get restoreWorkflow => _restoreWorkflow;

  /// Called once by application composition with its live access authority.
  /// The selection's lifetime belongs to that composition, not a Settings route.
  void configureRestore({
    required LocalInstallationSelection selection,
    required void Function() authorize,
  }) {
    if (_restoreWorkflow != null) {
      throw StateError(
        'Restore is already configured for this application host.',
      );
    }
    _restoreWorkflow = LocalRestoreWorkflow(
      selection: selection,
      runtime: installationRuntime,
      authorize: authorize,
      currentDatabaseFile: () {
        final application = currentApplication;
        if (application is! UiLabApp) {
          throw StateError('The local application is not attached.');
        }
        final file = application.workSession?.repository.database.storageFile;
        if (file == null) {
          throw StateError('The local installation is unavailable.');
        }
        return file;
      },
    );
  }
}
